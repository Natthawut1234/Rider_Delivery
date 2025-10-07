// services/rider_chat_service.dart (Fixed for rider_id/user_id separation)
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/pages/Chats/models/ChatMessage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RiderChatService {
  static const String baseUrl = 'http://172.29.173.44:4000';
  static const String socketUrl = 'http://172.29.173.44:4000';

  late Dio _dio;
  IO.Socket? _socket;
  int? _currentRiderId; // rider_id สำหรับ business logic
  int? _currentUserId; // user_id สำหรับ authentication
  int? _currentRoomId;
  String? _authToken;

  // Stream controllers for real-time events
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _roomUpdateStreamController = StreamController<ChatRoom>.broadcast();
  final _typingStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _readStatusStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStreamController = StreamController<bool>.broadcast();

  // Public streams
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  Stream<ChatRoom> get roomUpdateStream => _roomUpdateStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream =>
      _typingStreamController.stream;
  Stream<Map<String, dynamic>> get readStatusStream =>
      _readStatusStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  RiderChatService() {
    print('🔧 Initializing RiderChatService');
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get fresh token each time
          if (_authToken == null) {
            await _loadAuthToken();
          }
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          print('📡 API Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.response?.statusCode} ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('token');
      print(
        '🔑 Auth token loaded: ${_authToken != null ? 'Found' : 'Not found'}',
      );
    } catch (e) {
      print('❌ Error loading auth token: $e');
    }
  }

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    print('🔑 Auth token set manually');
  }

  // Connect to socket - รับ riderId และ userId แยกกัน
  Future<void> connectSocket(int riderId, int userId) async {
    try {
      print('🔌 Connecting socket for rider $riderId (user $userId)');

      if (_socket?.connected ?? false) {
        print('🔌 Disconnecting existing socket');
        await disconnectSocket();
      }

      _currentRiderId = riderId;
      _currentUserId = userId;

      // Ensure we have auth token
      if (_authToken == null) {
        await _loadAuthToken();
      }

      _socket = IO.io(
        '${socketUrl}/chat',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $_authToken'})
            .enableAutoConnect()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();

      print('🔌 Socket connection initiated for rider $riderId (user $userId)');
    } catch (e) {
      print('❌ Error connecting socket: $e');
      _connectionStreamController.add(false);
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.clearListeners(); // ✅ กันซ้ำ listener

    _socket!.on('connect', (data) {
      print('✅ Socket connected successfully');
      _connectionStreamController.add(true);
    });

    _socket!.on('disconnect', (data) {
      print('❌ Socket disconnected');
      _connectionStreamController.add(false);
    });

    _socket!.on('connect_error', (data) {
      print('❌ Socket connection error: $data');
      _connectionStreamController.add(false);
    });

    _socket!.on('error', (data) {
      print('❌ Socket error: $data');
    });

    _socket!.on('joined_room', (data) {
      print('🏠 Successfully joined room: ${data['roomId']} ✅');
    });

    _socket!.on('new_message', (data) {
      try {
        print('📨 New message received: $data');
        final msg = Map<String, dynamic>.from(data);

        final mapped = {
          'message_id':
              msg['message_id']?.toString() ?? msg['messageId']?.toString(),
          'room_id': msg['room_id']?.toString() ?? msg['roomId']?.toString(),
          'sender_id': msg['sender_id'] ?? msg['senderId'],
          'sender_type': msg['sender_type'] ?? msg['senderType'],
          'sender_name': msg['sender_name'] ?? msg['senderName'],
          'sender_photo': msg['sender_photo'] ?? msg['senderPhoto'],
          'message_text': msg['message_text'] ?? msg['messageText'],
          'message_type': msg['message_type'] ?? msg['messageType'] ?? 'text',
          'image_url': msg['image_url'] ?? msg['imageUrl'],
          'latitude': msg['latitude']?.toString(),
          'longitude': msg['longitude']?.toString(),
          'is_read': msg['is_read'] ?? msg['isRead'] ?? false,
          'created_at': msg['created_at'] ?? msg['createdAt'],
          'updated_at':
              msg['updated_at'] ?? msg['updatedAt'] ?? msg['created_at'],
        };

        final message = ChatMessage.fromJson(mapped);
        _messageStreamController.add(message);
        print('✅ Message added to stream');
      } catch (e, st) {
        print('❌ Error parsing message: $e');
        print(st);
      }
    });

    _socket!.on('user_typing', (data) {
      print('⌨️ User typing: $data');
      _typingStreamController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('messages_read', (data) {
      print('👁️ Messages read: $data');
      _readStatusStreamController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_joined', (data) {
      print('👤 User joined room: ${data['userName']}');
    });

    _socket!.on('message_sent', (data) {
      print('📤 Message sent confirmation: $data');
      // ❗ ไม่ต้อง add เข้า stream ที่นี่ เพราะ backend จะ broadcast new_message ให้อยู่แล้ว
    });
  }

  // Join chat room - ส่ง riderId (สำหรับตรวจสอบสิทธิ์)
  Future<void> joinRoom(int roomId) async {
    if (_socket?.connected != true || _currentRiderId == null) {
      print('❌ Cannot join room - socket not connected or rider not set');
      throw Exception('Socket not connected or rider not set');
    }

    print('🏠 Joining room $roomId for rider $_currentRiderId');
    _currentRoomId = roomId;

    // ส่ง riderId ไปให้ backend (backend จะแปลงเป็น user_id เอง)
    _socket!.emit('join_room', {
      'roomId': roomId,
      'userId': _currentRiderId, // ส่ง rider_id
      'userType': 'rider',
    });
  }

  // Leave chat room
  void leaveRoom() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('🚪 Leaving room $_currentRoomId');
      _socket!.emit('leave_room', {'roomId': _currentRoomId});
      _currentRoomId = null;
    }
  }

  // Send message - ส่ง riderId สำหรับการบันทึกในฐานข้อมูル
  Future<void> sendMessage(SendMessageRequest request) async {
    final payload = request.toJson();
    payload['userId'] = _currentRiderId;
    payload['userType'] = 'rider';

    if (_socket?.connected == true &&
        _currentRoomId != null &&
        _currentRoomId == request.roomId) {
      print('📡 Emitting message via socket only');
      _socket!.emit('send_message', payload);
      return;
    }

    // 🔁 fallback HTTP ถ้า socket ไม่ต่อ
    print('⚠️ Socket not connected → using HTTP');
    try {
      final response = await _dio.post(
        '/chat/rider/room/message',
        data: payload,
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'ส่งข้อความไม่สำเร็จ');
      }
    } on DioException catch (e) {
      print('❌ HTTP send error: ${e.message}');
      throw Exception('ส่งข้อความไม่สำเร็จ: ${e.message}');
    }
  }

  // Start typing
  void startTyping() {
    if (_currentRoomId != null && _socket?.connected == true) {
      _socket!.emit('typing_start', {'roomId': _currentRoomId});
    }
  }

  // Stop typing
  void stopTyping() {
    if (_currentRoomId != null && _socket?.connected == true) {
      _socket!.emit('typing_stop', {'roomId': _currentRoomId});
    }
  }

  // Mark as read
  void markAsRead() {
    if (_currentRoomId != null && _socket?.connected == true) {
      _socket!.emit('mark_as_read', {'roomId': _currentRoomId});
    }
  }

  // Disconnect socket
  Future<void> disconnectSocket() async {
    print('🔌 Disconnecting socket');
    leaveRoom();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentRiderId = null;
    _currentUserId = null;
    _currentRoomId = null;
    _connectionStreamController.add(false);
  }

  // ===== HTTP API Methods =====

  // Get rider chat rooms - ใช้ riderId สำหรับ API
  Future<List<ChatRoom>> getChatRooms(int? riderId) async {
    try {
      print('📋 Fetching chat rooms for rider $riderId');
      final response = await _dio.get('/chat/rider/rooms/$riderId');

      print('📋 Chat rooms response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> roomsJson = response.data['data'] ?? [];
        final rooms = roomsJson.map((json) => ChatRoom.fromJson(json)).toList();
        print('📋 Successfully loaded ${rooms.length} chat rooms');
        return rooms;
      } else {
        final message = response.data['message'] ?? 'Unknown error';
        print('❌ Failed to get chat rooms: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      print(
        '❌ DioException getting chat rooms: ${e.response?.statusCode} - ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('ไม่มีสิทธิ์เข้าถึง กรุณาล็อกอินใหม่');
      }
      throw Exception('เกิดข้อผิดพลาด: ${e.message}');
    } catch (e) {
      print('❌ Error getting chat rooms: $e');
      throw Exception('เกิดข้อผิดพลาดในการโหลดรายการแชท');
    }
  }

  // Get chat messages
  Future<Map<String, dynamic>> getChatMessages(
    int roomId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print('💬 Fetching messages for room $roomId');
      final response = await _dio.get(
        '/chat/rider/room/$roomId/messages',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        print('✅ Raw response: ${response.data}');

        final success = response.data['success'] ?? false;
        final messages = response.data['messages'] ?? [];

        return {'success': success, 'messages': messages};
      } else {
        final message = response.data['message'] ?? 'Unknown error';
        throw Exception(message);
      }
    } on DioException catch (e) {
      print(
        '❌ DioException getting messages: ${e.response?.statusCode} - ${e.message}',
      );
      if (e.response?.statusCode == 403) {
        throw Exception('ไม่มีสิทธิ์เข้าถึงห้องแชทนี้');
      }
      throw Exception('เกิดข้อผิดพลาด: ${e.message}');
    }
  }

  // Create chat room
  Future<int> createChatRoom(int orderId, int customerId, int riderId) async {
    try {
      print('🏗️ Creating chat room for order $orderId');
      final response = await _dio.post(
        '/chat/rider/room',
        data: {
          'orderId': orderId,
          'customerId': customerId,
          'riderId': riderId, // ส่ง rider_id
        },
      );

      if (response.statusCode == 200 && response.data['success']) {
        final roomId = response.data['data']['room_id'];
        print('✅ Chat room created: $roomId');
        return roomId;
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw Exception('เกิดข้อผิดพลาด: ${e.message}');
    }
  }

  // Upload image
  Future<String> uploadImage(String imagePath) async {
    try {
      print('📷 Uploading image: $imagePath');
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '/chat/rider/upload-image',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success']) {
        final imageUrl = response.data['image_url'];
        print('✅ Image uploaded: $imageUrl');
        return imageUrl;
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการอัพโลดรูปภาพ: ${e.message}');
    }
  }

  // Mark messages as read (HTTP API)
  Future<void> markMessagesAsReadAPI(int roomId, int riderId) async {
    try {
      await _dio.put('/chat/rider/room/$roomId/mark-read/$riderId');
      print('✅ Messages marked as read via API');
    } on DioException catch (e) {
      print('❌ Error marking messages as read: ${e.message}');
    }
  }

  // Get unread count - ใช้ riderId
  Future<int> getUnreadCount(int riderId) async {
    try {
      print('🔢 Getting unread count for rider $riderId');
      final response = await _dio.get('/chat/rider/unread-count/$riderId');

      if (response.statusCode == 200 && response.data['success']) {
        final count = response.data['unread_count'] ?? 0;
        print('🔢 Unread count: $count');
        return count;
      } else {
        print('⚠️ Failed to get unread count: ${response.data['message']}');
        return 0;
      }
    } on DioException catch (e) {
      print('❌ Error getting unread count: ${e.message}');
      return 0;
    }
  }

  // Dispose
  void dispose() {
    print('🗑️ Disposing RiderChatService');
    _messageStreamController.close();
    _roomUpdateStreamController.close();
    _typingStreamController.close();
    _readStatusStreamController.close();
    _connectionStreamController.close();
    disconnectSocket();
  }

  // Check connection status
  bool get isConnected => _socket?.connected ?? false;
}
