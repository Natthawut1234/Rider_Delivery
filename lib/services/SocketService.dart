// services/socket_service.dart - Fixed version
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Fixed: Use correct server URL without path
  static const String serverUrl = BaseAPI_URL.SocketURL; 

  bool get isConnected => _isConnected && _socket != null && _socket!.connected;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      print('✅ Socket already connected');
      return;
    }

    try {
      print('🔄 Attempting to connect to $serverUrl');

      // Dispose existing socket first
      if (_socket != null) {
        _socket!.dispose();
        _socket = null;
      }

      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Add polling as fallback
            .setTimeout(10000) // 10 second timeout
            .setReconnectionAttempts(3)
            .setReconnectionDelay(2000)
            .enableAutoConnect() // Enable auto connect
            .enableForceNew() // Force new connection
            .build(),
      );

      // Setup connection handlers before connecting
      _socket!.onConnect((data) {
        print('✅ Socket connected successfully: ${_socket!.id}');
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
        _isConnected = false;
      });

      _socket!.onReconnect((data) {
        print('🔄 Socket reconnected: $data');
        _isConnected = true;
      });

      _socket!.onReconnectError((error) {
        print('🚫 Socket reconnection error: $error');
        _isConnected = false;
      });

      // Connect the socket
      _socket!.connect();

      // Wait for connection with longer timeout
      int attempts = 0;
      while (!isConnected && attempts < 30) { // 30 attempts = 6 seconds
        await Future.delayed(Duration(milliseconds: 200));
        attempts++;
      }

      if (!isConnected) {
        throw Exception('Socket connection timeout after 6 seconds');
      }

      print('✅ Socket connection established successfully');
    } catch (e) {
      print('❌ Socket connection failed: $e');
      _isConnected = false;
      _socket?.dispose();
      _socket = null;
      rethrow;
    }
  }

  void disconnect() {
    if (_socket != null) {
      print('🔴 Disconnecting socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('🔴 Socket disconnected and disposed');
    }
  }

  Future<void> reconnect() async {
    print('🔄 Reconnecting socket...');
    disconnect();
    await Future.delayed(Duration(milliseconds: 1000)); // Wait before reconnecting
    await connect();
  }

  // Test connection to server
  Future<bool> testServerConnection() async {
    try {
      print('🧪 Testing server connection to $serverUrl');
      // You might want to add HTTP ping test here if available
      return true;
    } catch (e) {
      print('❌ Server connection test failed: $e');
      return false;
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
      print('❌ Cannot emit $event: Socket not connected (connected: ${_socket?.connected}, has socket: ${_socket != null})');
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

  // Test connection with server response
  void testConnection() {
    if (isConnected) {
      print('🧪 Testing connection with ping...');
      _socket!.emit('ping', {
        'message': 'Connection test from rider',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      print('❌ Cannot test connection: Socket not connected');
      print('Connection status: ${getConnectionStatus()}');
    }
  }

  // Check if server is reachable
  Future<bool> isServerReachable() async {
    try {
      // Simple connection test
      final testSocket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTimeout(3000)
            .setTransports(['polling']) // Use polling for quick test
            .disableAutoConnect()
            .build(),
      );

      bool connected = false;
      testSocket.onConnect((data) {
        connected = true;
      });

      testSocket.connect();
      
      // Wait for connection
      int attempts = 0;
      while (!connected && attempts < 15) { // 3 second timeout
        await Future.delayed(Duration(milliseconds: 200));
        attempts++;
      }

      testSocket.dispose();
      return connected;
    } catch (e) {
      print('❌ Server reachability test failed: $e');
      return false;
    }
  }
}