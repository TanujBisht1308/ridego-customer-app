import 'package:flutter/material.dart';
import '../../views/screens/confirm_ride_screen.dart';
import '../../views/screens/driver_assigned_screen.dart';
import '../../views/screens/finding_driver_screen.dart';
import '../../views/screens/home_screen.dart';
import '../../views/screens/live_tracking_screen.dart';
import '../../views/screens/login_screen.dart';
import '../../views/screens/otp_screen.dart';
import '../../views/screens/payment_screen.dart';
import '../../views/screens/profile_screen.dart';
import '../../views/screens/profile_setup_screen.dart';
import '../../views/screens/rating_review_screen.dart';
import '../../views/screens/ride_completed_screen.dart';
import '../../views/screens/ride_history_screen.dart';
import '../../views/screens/ride_in_progress_screen.dart';
import '../../views/screens/saved_places_screen.dart';
import '../../views/screens/search_destination_screen.dart';
import '../../views/screens/settings_screen.dart';
import '../../views/screens/help_support_screen.dart';
import '../../views/screens/splash_screen.dart';
import '../../views/screens/tracking_share_screen.dart';
import '../../views/screens/vehicle_selection_screen.dart';
import '../../views/screens/wallet_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String searchDestination = '/search-destination';
  static const String vehicleSelection = '/vehicle-selection';
  static const String confirmRide = '/confirm-ride';
  static const String findingDriver = '/finding-driver';
  static const String driverAssigned = '/driver-assigned';
  static const String liveTracking = '/live-tracking';
  static const String rideInProgress = '/ride-in-progress';
  static const String rideCompleted = '/ride-completed';
  static const String payment = '/payment';
  static const String ratingReview = '/rating-review';
  static const String rideHistory = '/ride-history';
  static const String wallet = '/wallet';
  static const String profile = '/profile';
  static const String savedPlaces = '/saved-places';
  static const String settings = '/settings';
  static const String helpSupport = '/help-support';
  static const String trackingShare = '/tracking-share';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        otp: (_) => const OtpScreen(),
        profileSetup: (_) => const ProfileSetupScreen(),
        home: (_) => const HomeScreen(),
        searchDestination: (_) => const SearchDestinationScreen(),
        vehicleSelection: (_) => const VehicleSelectionScreen(),
        confirmRide: (_) => const ConfirmRideScreen(),
        findingDriver: (_) => const FindingDriverScreen(),
        driverAssigned: (_) => const DriverAssignedScreen(),
        liveTracking: (_) => const LiveTrackingScreen(),
        rideInProgress: (_) => const RideInProgressScreen(),
        rideCompleted: (_) => const RideCompletedScreen(),
        payment: (_) => const PaymentScreen(),
        ratingReview: (_) => const RatingReviewScreen(),
        rideHistory: (_) => const RideHistoryScreen(),
        wallet: (_) => const WalletScreen(),
        profile: (_) => const ProfileScreen(),
        savedPlaces: (_) => const SavedPlacesScreen(),
        settings: (_) => const SettingsScreen(),
        helpSupport: (_) => const HelpSupportScreen(),
        trackingShare: (_) => const TrackingShareScreen(),
      };
}
