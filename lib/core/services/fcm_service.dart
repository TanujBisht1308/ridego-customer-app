import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    messaging.onTokenRefresh.listen(_registerToken);
  }

  Future<void> _registerToken(String token) async {
    try {
      await ApiClient.instance.dio.post(
        '/customer/fcm-token',
        data: {'fcmToken': token},
      );
    } catch (_) {
      // Non-critical
    }
  }
}