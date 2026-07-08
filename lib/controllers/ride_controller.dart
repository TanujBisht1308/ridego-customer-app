import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../models/driver_model.dart' hide VehicleOption;
import '../models/payment_method.dart';
import '../models/profile_menu_item.dart';
import '../models/ride_summary.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/transaction_item.dart';
import '../models/vehicle_option.dart';
import 'dart:convert';
import '../core/network/socket_service.dart';
import '../core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';

/// App-wide mutable state holder. A real app would replace this with a
/// proper state-management solution / backend calls, but for this UI build
/// it keeps every screen's interactions in sync with each other.
class RideController extends ChangeNotifier {
  RideController._();
  static final RideController instance = RideController._();

  // ---- Auth / session state ----
  final Dio _dio = ApiClient.instance.dio;
  bool isLoading = false;
  String? errorMessage;
  String? phoneNumber;
  String? customerId;
  bool isProfileComplete = false;
  bool isLoggedIn = false;

  Future<bool> sendOtp(String phone) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _dio.post(ApiConstants.sendOtp, data: {'phoneNumber': phone});
      phoneNumber = phone;
      isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _extractError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (phoneNumber == null) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _dio.post(ApiConstants.verifyOtp, data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      await _storeSession(data);
      isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _extractError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveCustomerProfile({required String fullName, String? email}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _dio.put(ApiConstants.profile, data: {
        'fullName': fullName,
        'email': email,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      userName = data['fullName'] ?? userName;
      userEmail = data['email'] ?? userEmail;
      isProfileComplete = data['isProfileComplete'] ?? true;
      walletBalance = (data['walletBalance'] as num?)?.toDouble() ?? walletBalance;
      await SecureStorageService.instance.write('cached_customer', jsonEncode(data));
      isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _extractError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Called once by splash — reads LOCAL storage only, no API call.
  // (Same lesson learned from the driver app: never validate session
  // against the API on splash, or an expired 15-min access token bounces
  // the user back to login even though they're still logged in.)
  Future<void> loadSession() async {
  final accessToken = await SecureStorageService.instance.read('access_token');
  final refreshToken = await SecureStorageService.instance.read('refresh_token');

  if (accessToken == null && refreshToken == null) {
    isLoggedIn = false;
    return;
  }

  final cached = await SecureStorageService.instance.read('cached_customer');
  if (cached == null) {
    isLoggedIn = false;
    return;
  }

  final data = jsonDecode(cached) as Map<String, dynamic>;
  userName = data['fullName'] ?? userName;
  userEmail = data['email'] ?? userEmail;
  userPhone = data['phoneNumber'] ?? userPhone;
  customerId = data['id'];
  isProfileComplete = data['isProfileComplete'] ?? false;
  walletBalance = (data['walletBalance'] as num?)?.toDouble() ?? walletBalance;
  isLoggedIn = true;

  // Connect socket AFTER isLoggedIn is confirmed true
  if (accessToken != null) {
    SocketService.instance.connect(accessToken);
  }
}
  Future<void> logoutSession() async {
    try {
      final refreshToken = await SecureStorageService.instance.read('refresh_token');
      await _dio.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
    } catch (_) {
      // ignore network errors on logout — clear locally regardless
    }
    stopPollingActiveRide();
    await SecureStorageService.instance.clear();
    isLoggedIn = false;
    isProfileComplete = false;
    customerId = null;
    phoneNumber = null;
    notifyListeners();
    SocketService.instance.disconnect();
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    final customer = data['customer'] as Map<String, dynamic>;
    await SecureStorageService.instance.write('access_token', data['accessToken']);
    await SecureStorageService.instance.write('refresh_token', data['refreshToken']);
    await SecureStorageService.instance.write('cached_customer', jsonEncode(customer));
    SocketService.instance.connect(data['accessToken']);

    customerId = customer['id'];
    userName = customer['fullName'] ?? userName;
    userEmail = customer['email'] ?? userEmail;
    userPhone = customer['phoneNumber'] ?? userPhone;
    isProfileComplete = customer['isProfileComplete'] ?? false;
    walletBalance = (customer['walletBalance'] as num?)?.toDouble() ?? walletBalance;
    isLoggedIn = true;
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return 'Something went wrong. Please check your connection.';
  }

  // ---- Profile ----
  String userName = 'John Doe';
  String userEmail = 'john@gmail.com';
  String userPhone = '+91 98765 43210';

  // ---- Ride summary (mutable; updated as the user moves through the flow) ----
  final RideSummary summary = RideSummary(
    pickup: AppStrings.currentLocation,
    drop: AppStrings.destination,
    distance: '12.4 km',
    time: '25 min',
    fare: AppStrings.fare,
    rideType: 'Sedan',
    paymentMethod: 'Cash',
  );
  String? rideOtp;
  DriverModel? assignedDriver;
  Map<String, double>? liveDriverPosition;

  // ---- Vehicles (populated from backend — see fetchFareEstimate) ----
  List<VehicleOption> vehicles = [];
  String? selectedVehicleId;

  Future<bool> fetchFareEstimate() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
    final response = await _dio.post(ApiConstants.rideEstimate, data: {
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropLat': dropLat,
        'dropLng': dropLng,
      });
      final data = response.data['data'] as Map<String, dynamic>;

      summary.distance = '${data['distanceKm']} km';
      summary.time = '${data['durationMinutes']} min';

      final vehicleIcons = {
        'bike': Icons.two_wheeler,
        'auto': Icons.directions_car_filled,
        'mini': Icons.local_taxi,
        'sedan': Icons.airport_shuttle,
      };
      final vehicleImages = {
        'bike': 'assets/images/vehicle_bike.png',
        'auto': 'assets/images/vehicle_auto.png',
        'mini': 'assets/images/vehicle_mini.png',
        'sedan': 'assets/images/vehicle_sedan.png',
      };

      final list = (data['vehicles'] as List).map((v) {
        final id = v['id'] as String;
        return VehicleOption(
          id: id,
          name: v['name'],
          priceRange: '₹${v['priceMin']} - ₹${v['priceMax']}',
          eta: '${v['etaMinutes']} min',
          seats: '${v['seats']}',
          icon: vehicleIcons[id] ?? Icons.directions_car,
          imagePath: vehicleImages[id] ?? '',
        );
      }).toList();

      if (list.isNotEmpty) list[0].selected = true;
      vehicles = list;
      selectedVehicleId = list.isNotEmpty ? list.first.id : null;
      if (list.isNotEmpty) {
        summary.rideType = list.first.name;
        summary.fare = list.first.priceRange.split(' - ').first;
      }

      isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _extractError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void selectVehicleById(String id) {
    for (final v in vehicles) {
      v.selected = v.id == id;
    }
    selectedVehicleId = id;
    final chosen = vehicles.firstWhere((v) => v.id == id);
    summary.rideType = chosen.name;
    summary.fare = chosen.priceRange.split(' - ').first;
    notifyListeners();
  }

  // ---- Active ride state ----
  bool activeRide = false;
  String? activeRideId;
  String rideStatus = 'none'; // pending | accepted | driverArrived | inProgress | completed | cancelled
  Timer? _pollTimer;

  void startRide() {
    activeRide = true;
    notifyListeners();
  }
  // ---- Wallet (real backend now) ----
  Future<void> fetchWallet() async {
    try {
      final response = await _dio.get(ApiConstants.wallet);
      final data = response.data['data'] as Map<String, dynamic>;
      walletBalance = (data['balance'] as num).toDouble();
      final list = (data['transactions'] as List).map((t) {
        final isCredit = t['type'] == 'credit';
        return TransactionItem(
          title: t['description'] ?? '',
          subtitle: _formatWalletDate(t['createdAt']),
          amount: '${isCredit ? '+' : '-'} ₹${(t['amount'] as num).toStringAsFixed(0)}',
        );
      }).toList();
      transactions
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // keep existing local state on failure
    }
  }

  String _formatWalletDate(String? iso) {
    if (iso == null) return '';
    try {
      final date = DateTime.parse(iso);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
  Future<bool> payRideFromWallet(double amount) async {
    try {
      final response = await _dio.post(ApiConstants.walletPay, data: {
        'amount': amount,
        if (activeRideId != null) 'rideId': activeRideId,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      walletBalance = (data['balance'] as num).toDouble();
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) return false; // insufficient balance
      return false;
    }
  }
  Future<bool> addMoneyToWallet(double amount) async {
    try {
      final response = await _dio.post(ApiConstants.walletAddMoney, data: {'amount': amount});
      final data = response.data['data'] as Map<String, dynamic>;
      walletBalance = (data['balance'] as num).toDouble();
      await fetchWallet(); // refresh full transaction list
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
  
  Future<bool> requestRide() async {
    if (selectedVehicleId == null) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _dio.post(ApiConstants.rides, data: {
        'pickupAddress': summary.pickup,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropAddress': summary.drop,
        'dropLat': dropLat,
        'dropLng': dropLng,
        'vehicleType': selectedVehicleId,
        'paymentMethod': summary.paymentMethod,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      activeRideId = data['rideId'];
      rideStatus = data['status'];
      rideOtp = data['rideOtp'];
      activeRide = true;
      isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _extractError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Polls the active ride every 3s. Calls onStatusChange whenever the
  // status string changes, so screens can navigate themselves.
  void startPollingActiveRide(void Function(String status) onStatusChange) {
  if (activeRideId == null) return;
  SocketService.instance.watchRide(activeRideId!);

  SocketService.instance.onRideUpdate((data) {
    final newStatus = data['status'] as String;
    if (data['rideOtp'] != null) rideOtp = data['rideOtp'];
    if (data['driver'] != null) {
      final d = data['driver'] as Map<String, dynamic>;
      assignedDriver = DriverModel(
        name: d['name'] ?? 'Driver',
        rating: (d['rating'] ?? 5.0).toStringAsFixed(1),
        vehicle: 'Assigned Vehicle',
        vehicleNumber: d['vehicleNumber'] ?? '',
        phone: d['phone'] ?? '',
      );
    }
    if (data['finalFare'] != null) {
      summary.fare = '₹${(data['finalFare'] as num).toStringAsFixed(0)}';
    }
    if (newStatus != rideStatus) {
      rideStatus = newStatus;
      notifyListeners();
      onStatusChange(newStatus);
    }
  });

  SocketService.instance.onDriverLocation((lat, lng) {
    liveDriverPosition = {'lat': lat, 'lng': lng};
    notifyListeners();
  });

  // Safety-net HTTP polling — catches status changes even if the socket
  // silently failed to connect or dropped without reconnecting.
  _pollTimer?.cancel();
  _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
    if (activeRideId == null) return;
    try {
      final response = await _dio.get('${ApiConstants.rides}/$activeRideId');
      final data = response.data['data'] as Map<String, dynamic>;
      final newStatus = data['status'] as String;
      if (data['rideOtp'] != null) rideOtp = data['rideOtp'];
      if (data['driver'] != null) {
        final d = data['driver'] as Map<String, dynamic>;
        assignedDriver = DriverModel(
          name: d['name'] ?? 'Driver',
          rating: (d['rating'] ?? 5.0).toStringAsFixed(1),
          vehicle: 'Assigned Vehicle',
          vehicleNumber: d['vehicleNumber'] ?? '',
          phone: d['phone'] ?? '',
        );
      }

      if (newStatus != rideStatus) {
        rideStatus = newStatus;
        notifyListeners();
        onStatusChange(newStatus);
      }
    } catch (_) {
      // ignore transient errors — will retry on next tick
    }
  });
}

  void stopPollingActiveRide() {
  _pollTimer?.cancel();
  _pollTimer = null;
  if (activeRideId != null) {
    SocketService.instance.unwatchRide(activeRideId!);
  }
}

  Future<bool> cancelActiveRide() async {
    if (activeRideId == null) return false;
    try {
      await _dio.post('${ApiConstants.rides}/$activeRideId/cancel');
      stopPollingActiveRide();
      rideStatus = 'cancelled';
      activeRideId = null;
      assignedDriver = null;
      rideOtp = null;
      activeRide = false;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void cancelRide() {
    activeRide = false;
    stopPollingActiveRide();
    activeRideId = null;
    assignedDriver = null;
    rideOtp = null;
    selectPayment(0);
    notifyListeners();
  }

  Future<bool> submitRideRating(int rating, String review) async {
    if (activeRideId == null) return false;
    try {
      await _dio.post(ApiConstants.rateRide(activeRideId!), data: {
        'rating': rating,
        'review': review,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchRideHistoryFromApi() async {
    try {
      final response = await _dio.get(ApiConstants.rideHistory, queryParameters: {'status': 'all'});
      final data = response.data['data'] as Map<String, dynamic>;
      final list = (data['rides'] as List).map((r) {
        final status = r['status'] == 'completed' ? 'Completed' : 'Cancelled';
        final fare = r['fare'] != null ? '₹${(r['fare'] as num).toStringAsFixed(0)}' : '₹0';
        return TransactionItem(
          title: r['pickupAddress'] ?? '',
          subtitle: '${r['dropAddress'] ?? ''} • ${r['date'] ?? ''}',
          amount: fare,
          status: status,
        );
      }).toList();
      rideHistory
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // keep whatever was already in rideHistory on failure
    }
  }

  // ---- Emergency ----
  static const String emergencyNumber = 'tel:112'; // India national emergency

  // ---- Tracking share ----
  // In production, your backend will generate a unique tracking URL per trip.
  // This is the placeholder structure; replace with a real URL from your API.
  String get trackingUrl => 'https://ridego.app/track/${_trackingId()}';
  String _trackingId() => 'RIDE${DateTime.now().millisecondsSinceEpoch % 100000}';

  // ---- Search ----
  final List<String> recentSearches = ['Noida Sector 18', 'IGI Airport, Delhi', 'Delhi Railway Station'];
  final List<String> popularPlaces = ['Connaught Place', 'India Gate, Delhi', 'Aerocity, Delhi'];
  // ---- Places / location ----
  double? pickupLat;
  double? pickupLng;
  double? dropLat;
  double? dropLng;
  String? _placesSessionToken;

  String _sessionToken() {
    _placesSessionToken ??= DateTime.now().millisecondsSinceEpoch.toString();
    return _placesSessionToken!;
  }

  void _endPlacesSession() => _placesSessionToken = null;

  // Called once on the home screen — gets real GPS, reverse-geocodes it,
  // and sets it as the pickup location.
  Future<bool> fetchCurrentLocationAsPickup() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final response = await _dio.get(ApiConstants.reverseGeocode, queryParameters: {
        'lat': pos.latitude,
        'lng': pos.longitude,
      });
      final data = response.data['data'] as Map<String, dynamic>;

      summary.pickup = data['address'];
      pickupLat = (data['latitude'] as num).toDouble();
      pickupLng = (data['longitude'] as num).toDouble();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Autocomplete suggestions as the user types in search_destination_screen.
  Future<List<Map<String, String>>> searchPlaces(String input) async {
    if (input.trim().isEmpty) return [];
    try {
      final response = await _dio.get(ApiConstants.placesAutocomplete, queryParameters: {
        'input': input,
        'sessionToken': _sessionToken(),
      });
      final data = response.data['data'] as List;
      return data.map((s) => {
            'placeId': s['placeId'] as String,
            'text': s['text'] as String,
          }).toList();
    } catch (_) {
      return [];
    }
  }

  // Called when the user taps a suggestion — resolves real lat/lng and
  // sets it as the drop location.
  Future<bool> selectDropPlace(String placeId) async {
    try {
      final response = await _dio.get(ApiConstants.placesDetails, queryParameters: {
        'placeId': placeId,
        'sessionToken': _sessionToken(),
      });
      final data = response.data['data'] as Map<String, dynamic>;

      setDrop(data['address']);
      dropLat = (data['latitude'] as num).toDouble();
      dropLng = (data['longitude'] as num).toDouble();
      _endPlacesSession();
      await fetchRoute();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- Saved Places (Home / Work quick actions) ----
  String? homeAddress;
  String? workAddress;
  final String airportAddress = 'IGI Airport, Delhi';

  void setHomeAddress(String value) {
    homeAddress = value.trim().isEmpty ? null : value.trim();
    notifyListeners();
  }

  void setWorkAddress(String value) {
    workAddress = value.trim().isEmpty ? null : value.trim();
    notifyListeners();
  }

  // ---- App Settings ----
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool locationSharingEnabled = true;
  String language = 'English';

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void toggleLocationSharing(bool value) {
    locationSharingEnabled = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void setDrop(String value) {
    if (value.trim().isEmpty) return;
    summary.drop = value.trim();
    if (!recentSearches.contains(summary.drop)) {
      recentSearches.insert(0, summary.drop);
      if (recentSearches.length > 5) recentSearches.removeLast();
    }
    notifyListeners();
  }

  // ---- Payment ----
  final List<PaymentMethodModel> paymentMethods = [
    PaymentMethodModel(title: 'Cash', subtitle: 'Pay directly to driver', icon: Icons.payments_outlined, selected: true),
    PaymentMethodModel(title: 'UPI', subtitle: 'Google Pay, PhonePe, Paytm', icon: Icons.qr_code_2),
    PaymentMethodModel(title: 'Credit / Debit Card', subtitle: 'Visa, Mastercard, Rupay', icon: Icons.credit_card),
    PaymentMethodModel(title: 'Wallet', subtitle: 'Balance ₹250', icon: Icons.account_balance_wallet_outlined),
  ];

  void selectPayment(int index) {
    for (var i = 0; i < paymentMethods.length; i++) {
      paymentMethods[i].selected = i == index;
    }
    summary.paymentMethod = paymentMethods[index].title;
    notifyListeners();
  }

  // ---- Wallet ----
  double walletBalance = 250.0;

  final List<TransactionItem> transactions = [
    const TransactionItem(title: 'Ride Payment', subtitle: 'Noida Sector 18 • 12 May, 10:30 AM', amount: '- ₹180'),
    const TransactionItem(title: 'Wallet Top-up', subtitle: 'Added money • 10 May, 09:15 PM', amount: '+ ₹500'),
  ];

  // ---- Ride history (populated from backend — see fetchRideHistoryFromApi) ----
  final List<TransactionItem> rideHistory = [];

  void addCompletedRide() {
    rideHistory.insert(
      0,
      TransactionItem(title: summary.pickup, subtitle: '${summary.drop} • Just now', amount: summary.fare, status: 'Completed'),
    );
    notifyListeners();
  }

 
  // ---- Rating ----
  int rating = 4;
  String review = '';

  void setRating(int value) {
    rating = value;
    notifyListeners();
  }

  // ---- Profile menu ----
  List<ProfileMenuItem> get profileMenus => const [
        ProfileMenuItem(title: 'Saved Places', icon: Icons.bookmark_border),
        ProfileMenuItem(title: 'Payment Methods', icon: Icons.payment),
        ProfileMenuItem(title: 'Settings', icon: Icons.settings_outlined),
        ProfileMenuItem(title: 'Help & Support', icon: Icons.help_outline),
        ProfileMenuItem(title: 'Logout', icon: Icons.logout),
      ];

  /// Resets the in-memory ride/payment/rating selections after a completed
  /// trip so the next ride starts fresh, like a real app would after the
  /// backend confirms the trip closed out.
  void resetForNextRide() {
    selectPayment(0);
    rating = 4;
    review = '';
    notifyListeners();
  }
  List<Map<String, double>> routePoints = [];

  Future<void> fetchRoute() async {
    if (pickupLat == null || pickupLng == null || dropLat == null || dropLng == null) return;
    try {
      final response = await _dio.get(ApiConstants.route, queryParameters: {
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropLat': dropLat,
        'dropLng': dropLng,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      routePoints = (data['points'] as List)
          .map((p) => {'lat': (p['latitude'] as num).toDouble(), 'lng': (p['longitude'] as num).toDouble()})
          .toList();
      notifyListeners();
    } catch (_) {
      routePoints = []; // falls back to straight line in RideMap
    }
  }
}