class ApiConstants {
  ApiConstants._();

  // Use the SAME local IP your driver app already uses (check its
  // api_constants.dart) — your laptop's IP on the network, not localhost,
  // since this runs on a real phone.
  static const String baseUrl = 'http://192.168.0.191:8000/api';

  // Auth
  static const String sendOtp = '/customer/auth/send-otp';
  static const String verifyOtp = '/customer/auth/verify-otp';
  static const String refreshToken = '/customer/auth/refresh-token';
  static const String logout = '/customer/auth/logout';

  // Profile
  static const String profile = '/customer/profile';

  // Rides
  static const String rideEstimate = '/customer/rides/estimate';
  static const String rides = '/customer/rides';
  static const String activeRide = '/customer/rides/active';
  static const String rideHistory = '/customer/rides/history';
  static String rideStatus(String rideId) => '/customer/rides/$rideId';
  static String cancelRide(String rideId) => '/customer/rides/$rideId/cancel';
  static String rateRide(String rideId) => '/customer/rides/$rideId/rate';
  static const String placesAutocomplete = '/customer/places/autocomplete';
  static const String placesDetails = '/customer/places/details';
  static const String reverseGeocode = '/customer/places/reverse-geocode';
  static const String wallet = '/customer/wallet';
  static const String walletAddMoney = '/customer/wallet/add-money';
  static const String walletPay = '/customer/wallet/pay';
  static const String route = '/customer/places/route';  
    }