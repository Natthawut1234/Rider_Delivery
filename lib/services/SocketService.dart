// lib/services/SocketService.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RiderSocketService {
  static final RiderSocketService _i = RiderSocketService._internal();
  factory RiderSocketService() => _i;
  RiderSocketService._internal();

  IO.Socket? _socket;
  String? _baseUrl;

  bool get connected => _socket?.connected == true;

  void connect(String baseUrl, {String? token}) {
    if (_socket?.connected == true && _baseUrl == baseUrl) return;
    _baseUrl = baseUrl;

    _socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'forceNew': false,
      // ใส่ header token ถ้าระบบคุณตรวจสอบที่ socket handshake
      'extraHeaders': token != null ? {'Authorization': 'Bearer $token'} : null,
      // ถ้าเซิร์ฟเวอร์ตั้ง path อื่น ให้แก้ตรงนี้ให้ตรงกัน (ส่วนใหญ่ /socket.io/)
      'path': '/socket.io/',
    });

    _socket!.onConnect((_) {
      // print('[socket] connected');
    });
    _socket!.onDisconnect((_) {
      // print('[socket] disconnected');
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _baseUrl = null;
  }

  void joinOrderRoom(int orderId) {
    _socket?.emit('order:watch', {'order_id': orderId});
  }

  void leaveOrderRoom(int orderId) {
    _socket?.emit('order:unwatch', {'order_id': orderId});
  }

  void onOrderUpdated(void Function(dynamic data) handler) {
    _socket?.on('order:updated', handler);
  }

  void offOrderUpdated() {
    _socket?.off('order:updated');
  }
}
