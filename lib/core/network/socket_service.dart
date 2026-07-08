import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  void connect(String accessToken) {
    _socket?.dispose();
    _socket = io.io(
      ApiConstants.baseUrl.replaceAll('/api', ''),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': accessToken, 'role': 'customer'})
          .build(),
    );
    _socket!.connect();
  }

  void watchRide(String rideId) => _socket?.emit('ride:watch', {'rideId': rideId});
  void unwatchRide(String rideId) => _socket?.emit('ride:unwatch', {'rideId': rideId});

  void onRideUpdate(void Function(Map<String, dynamic>) callback) {
    _socket?.on('ride:update', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onDriverLocation(void Function(double lat, double lng) callback) {
    _socket?.on('driver:location', (data) {
      callback((data['latitude'] as num).toDouble(), (data['longitude'] as num).toDouble());
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}