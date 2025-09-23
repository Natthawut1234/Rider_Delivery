// services/socket_service.dart
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Server configuration
  static const String serverUrl = '${BaseAPI_URL.HostSocketURL}'; // เปลี่ยนตาม server ของคุณ

  bool get isConnected => _isConnected && _socket != null && _socket!.connected;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      print('✅ Socket already connected');
      return;
    }

    try {
      print('🔄 Attempting to connect to $serverUrl');

      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Connection': 'upgrade'})
            .build(),
      );

      _socket!.onConnect((data) {
        print('✅ Socket connected: ${_socket!.id}');
        _isConnected = true;
      });

      _socket!.onDisconnect((data) {
        print('❌ Socket disconnected: $data');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        print('🚫 Socket connection error: $error');
        _isConnected = false;
      });

      _socket!.onError((error) {
        print('🚫 Socket error: $error');
      });

      _socket!.connect();

      // Wait for connection with timeout
      await Future.delayed(Duration(seconds: 2));

      if (!isConnected) {
        throw Exception('Failed to establish socket connection');
      }
    } catch (e) {
      print('❌ Socket connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('🔴 Socket disconnected and disposed');
    }
  }

  void reconnect() {
    print('🔄 Reconnecting socket...');
    disconnect();
    connect();
  }

  // Register user with socket
  void registerUser(int userId) {
    if (isConnected) {
      _socket!.emit('register_user', {'userId': userId});
      print('👤 User $userId registered with socket');
    } else {
      print('❌ Cannot register user: Socket not connected');
    }
  }

  // Watch order for real-time updates
  void watchOrder(int orderId) {
    if (isConnected) {
      String event = '';
      switch (()) {
        case 'customer':
          event = 'customer:watchOrder';
          break;
        case 'shop':
          event = 'shop:watchOrder';
          break;
        case 'rider':
          event = 'rider:watchOrder';
          break;
        default:
          event = 'customer:watchOrder';
      }

      _socket!.emit(event, orderId);
      print('👁️ Watching order $orderId');
    } else {
      print('❌ Cannot watch order: Socket not connected');
    }
  }

  // Accept order as shop
  void shopAcceptOrder(int orderId, int shopId) {
    if (isConnected) {
      _socket!.emit('shop:acceptOrder', {
        'order_id': orderId,
        'shop_id': shopId,
      });
      print('🏪 Shop $shopId accepting order $orderId');
    } else {
      print('❌ Cannot accept order: Socket not connected');
    }
  }

  // Accept order as rider
  void riderAcceptOrder(int orderId, int riderId) {
    if (isConnected) {
      _socket!.emit('rider:acceptOrder', {
        'order_id': orderId,
        'rider_id': riderId,
      });
      print('🏍️ Rider $riderId accepting order $orderId');
    } else {
      print('❌ Cannot accept order: Socket not connected');
    }
  }

  // Emit new order
  void emitNewOrder(Map<String, dynamic> orderData) {
    if (isConnected) {
      _socket!.emit('new_order', orderData);
      print('📦 New order emitted: ${orderData['order_id']}');
    } else {
      print('❌ Cannot emit new order: Socket not connected');
    }
  }

  // Listen to events
  void on(String event, dynamic Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
      print('👂 Listening to event: $event');
    } else {
      print('❌ Cannot listen to $event: Socket not initialized');
    }
  }

  // Remove event listener
  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
      print('🔇 Stopped listening to event: $event');
    }
  }

  // Emit custom event
  void emit(String event, [dynamic data]) {
    if (isConnected) {
      if (data != null) {
        _socket!.emit(event, data);
        print('📡 Emitted event: $event with data: $data');
      } else {
        _socket!.emit(event);
        print('📡 Emitted event: $event (no data)');
      }
    } else {
      print('❌ Cannot emit $event: Socket not connected');
    }
  }

  // Get connection status for debugging
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': _isConnected,
      'socketConnected': _socket?.connected ?? false,
      'socketId': _socket?.id ?? 'No ID',
      'serverUrl': serverUrl,
      'hasSocket': _socket != null,
    };
  }

  // Test connection
  void testConnection() {
    if (isConnected) {
      print('🧪 Testing connection...');
      _socket!.emit('test', {
        'message': 'Connection test',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      print('❌ Cannot test connection: Socket not connected');
      print('Connection status: ${getConnectionStatus()}');
    }
  }
}
