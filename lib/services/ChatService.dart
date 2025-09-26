// services/rider_chat_service.dart (Complete Final Fixed Version)
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/pages/Chats/models/ChatMessage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RiderChatService {
  static const String baseUrl = 'http://192.168.1.129:4000';
  static const String socketUrl = 'http://192.168.1.129:4000';

  late Dio _dio;
  IO.Socket? _socket;
  int? _currentUserId; // ✅ user_id (31) - สำหรับ authentication
  int? _currentRiderId; // ✅ rider_id (10) - สำหรับ business logic
  int? _currentRoomId;
  String? _authToken;

  // Stream controllers for real-time events
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _roomUpdateStreamController = StreamController<ChatRoom>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _readStatusStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStreamController = StreamController<bool>.broadcast();

  // Public streams
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  Stream<ChatRoom> get roomUpdateStream => _roomUpdateStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingStreamController.stream;
  Stream<Map<String, dynamic>> get readStatusStream => _readStatusStreamController.stream;
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
          print('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
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
      print('🔑 Auth token loaded: ${_authToken != null ? 'Found' : 'Not found'}');
    } catch (e) {
      print('❌ Error loading auth token: $e');
    }
  }

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    print('🔑 Auth token set manually');
  }

  // ✅ แก้ไข connectSocket ให้รับ riderId และหา userId ด้วย
  Future<void> connectSocket(int riderId) async {
    try {
      print('🔌 Connecting socket for rider $riderId');

      if (_socket?.connected ?? false) {
        print('🔌 Disconnecting existing socket');
        await disconnectSocket();
      }

      _currentRiderId = riderId;

      // ✅ หา user_id ที่ตรงกับ rider_id นี้จาก SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userRiderString = prefs.getString('user_rider');
      if (userRiderString != null) {
        final userData = jsonDecode(userRiderString);
        _currentUserId = userData['user_id']; // 31
        print('🔍 Rider mapping loaded: rider_id=$riderId -> user_id=$_currentUserId');
      } else {
        print('⚠️ Could not find user_rider in SharedPreferences');
      }

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

      print('🔌 Socket connection initiated for rider $riderId (user $_currentUserId)');
    } catch (e) {
      print('❌ Error connecting socket: $e');
      _connectionStreamController.add(false);
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Clear existing listeners to prevent duplicates
    _socket!.clearListeners();

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

    // ✅ แก้ไข new_message handler ให้รองรับทั้ง snake_case และ camelCase
    _socket!.on('new_message', (data) {
      try {
        print('📨 New message received: $data');
        
        // ✅ Parse message ให้รองรับทั้ง format
        final messageData = Map<String, dynamic>.from(data);
        
        // Map ให้เป็น format ที่ ChatMessage.fromJson() คาดหวัง
        final mappedData = {
          'message_id': messageData['message_id']?.toString() ?? messageData['messageId']?.toString(),
          'room_id': messageData['room_id']?.toString() ?? messageData['roomId']?.toString(),
          'sender_id': messageData['sender_id'] ?? messageData['senderId'],
          'sender_type': messageData['sender_type'] ?? messageData['senderType'],
          'sender_name': messageData['sender_name'] ?? messageData['senderName'],
          'sender_photo': messageData['sender_photo'] ?? messageData['senderPhoto'],
          'message_text': messageData['message_text'] ?? messageData['messageText'],
          'message_type': messageData['message_type'] ?? messageData['messageType'] ?? 'text',
          'image_url': messageData['image_url'] ?? messageData['imageUrl'],
          'latitude': messageData['latitude']?.toString(),
          'longitude': messageData['longitude']?.toString(),
          'is_read': messageData['is_read'] ?? messageData['isRead'] ?? false,
          'created_at': messageData['created_at'] ?? messageData['createdAt'],
          'updated_at': messageData['updated_at'] ?? messageData['updatedAt'] ?? messageData['created_at'] ?? messageData['createdAt'],
        };

        print('📨 Mapped message data: $mappedData');
        final message = ChatMessage.fromJson(mappedData);
        _messageStreamController.add(message);
        
      } catch (e, stackTrace) {
        print('❌ Error parsing new message: $e');
        print('❌ Stack trace: $stackTrace');
        print('❌ Raw data: $data');
      }
    });

    _socket!.on('user_typing', (data) {
      print('⌨️ User typing: $data');
      final typingData = Map<String, dynamic>.from(data);
      _typingStreamController.add(typingData);
    });

    _socket!.on('messages_read', (data) {
      print('👁️ Messages read: $data');
      _readStatusStreamController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_joined', (data) {
      print('👤 User joined room: ${data['userName']}');
    });

    _socket!.on('user_left', (data) {
      print('👤 User left room: ${data['userId']}');
    });

    // ✅ เพิ่ม listener สำหรับ message_sent confirmation
    _socket!.on('message_sent', (data) {
      print('📤 Message sent confirmation: $data');
    });
  }

  // ✅ แก้ไข joinRoom ให้ใช้ user_id สำหรับ socket communication
  Future<void> joinRoom(int roomId) async {
    if (_socket?.connected != true || _currentUserId == null) {
      print('❌ Cannot join room - socket not connected or user not set');
      throw Exception('Socket not connected or user not set');
    }

    print('🏠 Joining room $roomId for rider $_currentRiderId (user $_currentUserId)');
    _currentRoomId = roomId;

    // ✅ ส่ง user_id (31) ไปยัง socket แทน rider_id
    _socket!.emit('join_room', {
      'roomId': roomId,
      'userId': _currentUserId, // ส่ง user_id แทน rider_id
      'userType': 'rider',
    });
    
    // รอให้ server confirm
    await Future.delayed(const Duration(milliseconds: 1000));
    print('✅ Room join request sent, waiting for confirmation');
  }

  // Leave chat room
  void leaveRoom() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('🚪 Leaving room $_currentRoomId');
      _socket!.emit('leave_room', {'roomId': _currentRoomId});
      _currentRoomId = null;
    }
  }

  // ✅ แก้ไข sendMessage ให้ทำงานแบบ hybrid (HTTP + Socket)
  Future<void> sendMessage(SendMessageRequest request) async {
    try {
      final payload = request.toJson();
      print('📤 Sending message: $payload');

      // ✅ เพิ่ม user_id สำหรับ socket communication
      payload['userId'] = _currentUserId; // ใช้ user_id (31)
      payload['userType'] = 'rider';

      // ✅ 1) ส่งผ่าน HTTP API ก่อนเพื่อบันทึกลงฐานข้อมูล
      final response = await _dio.post(
        '/chat/rider/room/message',
        data: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ Message saved to database');
        
        // ✅ 2) หลังจากบันทึกสำเร็จแล้ว ส่ง socket emit
        if (_socket?.connected == true && _currentRoomId != null) {
          final socketPayload = {
            'roomId': request.roomId,
            'messageText': request.messageText,
            'messageType': request.messageType ?? 'text',
            'imageUrl': request.imageUrl,
            'latitude': request.latitude,
            'longitude': request.longitude,
          };
          
          print('📡 Emitting message via socket: $socketPayload');
          _socket!.emit('send_message', socketPayload);
          print('✅ Message emitted to socket for real-time broadcast');
        } else {
          print('⚠️ Socket not connected or not in room, message sent via HTTP only');
        }
        
      } else {
        throw Exception(response.data['message'] ?? 'ส่งข้อความไม่สำเร็จ');
      }
    } on DioException catch (e) {
      print('❌ HTTP send error: ${e.message}');
      throw Exception('ส่งข้อความไม่สำเร็จ: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e');
    }
  }

  // Start typing
  void startTyping() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('⌨️ Starting typing in room $_currentRoomId');
      _socket!.emit('typing_start', {'roomId': _currentRoomId});
    }
  }

  // Stop typing
  void stopTyping() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('⌨️ Stopping typing in room $_currentRoomId');
      _socket!.emit('typing_stop', {'roomId': _currentRoomId});
    }
  }

  // Mark as read
  void markAsRead() {
    if (_currentRoomId != null && _socket?.connected == true) {
      print('👁️ Marking messages as read in room $_currentRoomId');
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
    _currentUserId = null;
    _currentRiderId = null;
    _currentRoomId = null;
    _connectionStreamController.add(false);
  }

  // ===== HTTP API Methods =====

  // Get rider chat rooms - ใช้ rider_id สำหรับ API calls
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
      print('❌ DioException getting chat rooms: ${e.response?.statusCode} - ${e.message}');
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

        // ตรวจสอบ field ให้ตรงกับ API จริง
        final success = response.data['success'] ?? false;
        final messages = response.data['messages'] ?? [];

        return {'success': success, 'messages': messages};
      } else {
        final message = response.data['message'] ?? 'Unknown error';
        throw Exception(message);
      }
    } on DioException catch (e) {
      print('❌ DioException getting messages: ${e.response?.statusCode} - ${e.message}');
      if (e.response?.statusCode == 403) {
        throw Exception('ไม่มีสิทธิ์เข้าถึงห้องแชทนี้');
      }
      throw Exception('เกิดข้อผิดพลาด: ${e.message}');
    }
  }

  // Create chat room - ใช้ rider_id
  Future<int> createChatRoom(int orderId, int customerId, int riderId) async {
    try {
      print('🏗️ Creating chat room for order $orderId');
      final response = await _dio.post(
        '/chat/rider/room',
        data: {
          'orderId': orderId,
          'customerId': customerId,
          'riderId': riderId, // ใช้ rider_id
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

  // Mark messages as read (HTTP API) - ใช้ rider_id
  Future<void> markMessagesAsReadAPI(int roomId, int riderId) async {
    try {
      await _dio.put('/chat/rider/room/$roomId/mark-read/$riderId');
      print('✅ Messages marked as read via API');
    } on DioException catch (e) {
      print('❌ Error marking messages as read: ${e.message}');
    }
  }

  // Get unread count - ใช้ rider_id
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
  
  // ✅ เพิ่ม helper methods สำหรับ debugging
  int? get currentUserId => _currentUserId;
  int? get currentRiderId => _currentRiderId;
  int? get currentRoomId => _currentRoomId;
}