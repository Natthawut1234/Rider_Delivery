// controllers/rider_chat_controller.dart (Fixed Version)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rider_delivery/pages/Chats/Utils/shared_preferences_helper.dart';
import 'package:rider_delivery/pages/Chats/models/ChatMessage.dart';
import 'package:rider_delivery/services/ChatService.dart';

class RiderChatController extends ChangeNotifier {
  final RiderChatService _chatService = RiderChatService();

  // State variables
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = false;
  bool _isConnected = false;
  int _unreadCount = 0;

  // Rider info
  int? _riderId;     // rider_id for business logic
  int? _userId;      // user_id for socket authentication
  String? _riderName;
  String? _riderPhoto;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  int get unreadCount => _unreadCount;
  int? get riderId => _riderId;
  int? get userId => _userId;
  String? get riderName => _riderName;
  String? get riderPhoto => _riderPhoto;

  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _roomUpdateSubscription;
  StreamSubscription? _readStatusSubscription;
  StreamSubscription? _connectionSubscription;

  RiderChatController() {
    print('🔧 Initializing RiderChatController');
    _initializeRiderInfo();
  }

  Future<void> initializeRiderInfoIfNeeded() async {
    if (_userId == null || _riderId == null) {
      await _initializeRiderInfo();
    }
  }

  Future<void> _initializeRiderInfo() async {
    try {
      final prefs = await SharedPreferencesHelper.getInstance();
      
      // Debug all keys
      final allKeys = prefs.getKeys();
      print("🔍 SharedPreferences keys:");
      for (var key in allKeys) {
        print("   $key = ${prefs.get(key)}");
      }

      // Load user_rider data
      final userRiderString = prefs.getString('user_rider');
      if (userRiderString != null) {
        final userData = jsonDecode(userRiderString);
        _riderId = userData['rider_id'];
        _userId = userData['user_id'];
        _riderName = userData['display_name'];
        _riderPhoto = userData['photo_url'];
        
        print("✅ Loaded rider info:");
        print("   rider_id: $_riderId");
        print("   user_id: $_userId");
        print("   name: $_riderName");
        print("   photo: $_riderPhoto");
      } else {
        print("⚠️ user_rider not found in SharedPreferences");
        return;
      }

      // Load and set auth token
      final token = prefs.getString('token');
      if (token != null) {
        _chatService.setAuthToken(token);
        print("🔑 Auth token loaded and set");
      } else {
        print("⚠️ Auth token not found");
      }

      // Initialize chat service if we have required data
      if (_riderId != null && _userId != null) {
        await _setupChatService();
      } else {
        print("⚠️ Missing required IDs - cannot initialize chat service");
      }

    } catch (e, stackTrace) {
      print('❌ Error initializing rider info: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _setupChatService() async {
    try {
      // Setup connection listener first
      _setupConnectionListener();
      
      // Setup realtime event listeners
      _setupRealtimeListeners();
      
      // Connect socket using riderId (which maps to userId internally)
      await _chatService.connectSocket(_riderId!);
      
      // Load initial data
      await loadChatRooms();
      await updateUnreadCount();
      
      print("✅ Chat service setup complete");
    } catch (e) {
      print('❌ Error setting up chat service: $e');
    }
  }

  void _setupConnectionListener() {
    _connectionSubscription?.cancel();
    _connectionSubscription = _chatService.connectionStream.listen((connected) {
      print('🔌 Connection status changed: $connected');
      _isConnected = connected;
      notifyListeners();

      if (connected) {
        // Reload rooms when reconnected
        loadChatRooms();
      }
    });
  }

  void _setupRealtimeListeners() {
    // Cancel existing subscriptions
    _messageSubscription?.cancel();
    _roomUpdateSubscription?.cancel();
    _readStatusSubscription?.cancel();

    // Message stream - update room's last message and unread count
    _messageSubscription = _chatService.messageStream.listen(
      (message) {
        print('📨 New message received in controller: ${message.messageText}');
        
        final roomIndex = _chatRooms.indexWhere((room) => 
          room.roomId.toString() == message.roomId.toString()
        );

        if (roomIndex != -1) {
          final currentRoom = _chatRooms[roomIndex];
          final isMyMessage = _isMyMessage(message);

          // Update room with new message info
          _chatRooms[roomIndex] = currentRoom.copyWith(
            lastMessage: message.messageText ?? 
              (message.messageType == 'image' ? '📷 รูปภาพ' : 'ข้อความ'),
            messageType: message.messageType,
            lastMessageTime: message.createdAt,
            unreadCount: isMyMessage 
              ? (currentRoom.unreadCount ?? 0)  // Don't increment for own messages
              : (currentRoom.unreadCount ?? 0) + 1,  // Increment for others' messages
          );

          // Update total unread count
          if (!isMyMessage) {
            _unreadCount += 1;
          }

          // Move updated room to top of list
          final updatedRoom = _chatRooms.removeAt(roomIndex);
          _chatRooms.insert(0, updatedRoom);

          notifyListeners();
        } else {
          // Room not found - reload all rooms
          print('⚠️ Message for unknown room ${message.roomId} - reloading rooms');
          loadChatRooms();
        }
      },
      onError: (error) {
        print('❌ Message stream error: $error');
      },
    );

    // Room update stream
    _roomUpdateSubscription = _chatService.roomUpdateStream.listen(
      (room) {
        print('🏠 Room update received: ${room.roomId}');
        
        final roomIndex = _chatRooms.indexWhere((r) => r.roomId == room.roomId);
        if (roomIndex == -1) {
          // New room - add to beginning
          _chatRooms.insert(0, room);
        } else {
          // Update existing room
          _chatRooms[roomIndex] = room;
        }
        
        // Recalculate total unread count
        _unreadCount = _chatRooms.fold<int>(
          0, 
          (sum, room) => sum + (room.unreadCount ?? 0)
        );
        
        notifyListeners();
      },
      onError: (error) {
        print('❌ Room update stream error: $error');
      },
    );

    // Read status stream - mark messages as read
    _readStatusSubscription = _chatService.readStatusStream.listen(
      (data) {
        print('👁️ Messages marked as read: $data');
        
        final roomId = data['roomId'];
        if (roomId != null) {
          final roomIndex = _chatRooms.indexWhere((r) => 
            r.roomId.toString() == roomId.toString()
          );
          
          if (roomIndex != -1) {
            final currentRoom = _chatRooms[roomIndex];
            final prevUnreadCount = currentRoom.unreadCount ?? 0;
            
            // Reset unread count for this room
            _chatRooms[roomIndex] = currentRoom.copyWith(unreadCount: 0);
            
            // Update total unread count
            _unreadCount = (_unreadCount - prevUnreadCount).clamp(0, 999);
            
            notifyListeners();
          }
        }
      },
      onError: (error) {
        print('❌ Read status stream error: $error');
      },
    );
  }

  // Helper to check if message is from current rider
  bool _isMyMessage(ChatMessage message) {
    // For rider: check if sender_type is 'rider' and sender_id matches our rider_id
    return message.senderType == 'rider' && 
           message.senderId?.toString() == _riderId?.toString();
  }

  // Connect to chat socket
  Future<void> connectToChat() async {
    if (_riderId == null) {
      print('⚠️ Cannot connect - riderId is null');
      return;
    }

    try {
      print('🔌 Connecting to chat socket for rider $_riderId');
      await _chatService.connectSocket(_riderId!);
    } catch (e) {
      print('❌ Error connecting to chat: $e');
    }
  }

  // Load chat rooms
  Future<void> loadChatRooms() async {
    if (_riderId == null) {
      print('⚠️ Cannot load rooms - riderId is null');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('📋 Loading chat rooms for rider $_riderId');
      final rooms = await _chatService.getChatRooms(_riderId!);
      
      // Sort rooms by last message time (newest first)
      rooms.sort((a, b) {
        final aTime = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      
      _chatRooms = rooms;

      // Calculate total unread count
      _unreadCount = rooms.fold<int>(
        0,
        (sum, room) => sum + (room.unreadCount ?? 0),
      );

      print('✅ Loaded ${rooms.length} chat rooms, unread: $_unreadCount');
    } catch (e) {
      print('❌ Error loading chat rooms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update unread count
  Future<void> updateUnreadCount() async {
    if (_riderId == null) return;

    try {
      _unreadCount = await _chatService.getUnreadCount(_riderId!);
      notifyListeners();
      print('🔢 Updated unread count: $_unreadCount');
    } catch (e) {
      print('❌ Error updating unread count: $e');
    }
  }

  // Create chat room for order
  Future<int?> createChatRoomForOrder({
    required int orderId,
    required int customerId,
    required String customerName,
    String? customerPhoto,
  }) async {
    if (_riderId == null) {
      print('⚠️ Cannot create room - riderId is null');
      return null;
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('🏗️ Creating chat room for order $orderId');
      final roomId = await _chatService.createChatRoom(
        orderId,
        customerId,
        _riderId!,
      );

      // Reload rooms to get the new room
      await loadChatRooms();

      print('✅ Chat room created: $roomId');
      return roomId;
    } catch (e) {
      print('❌ Error creating chat room: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh chat rooms
  Future<void> refreshChatRooms() async {
    await loadChatRooms();
  }

  // Mark room as entered (reset unread count)
  void markRoomAsEntered(int roomId) {
    final roomIndex = _chatRooms.indexWhere((r) => r.roomId == roomId);
    if (roomIndex != -1) {
      final currentRoom = _chatRooms[roomIndex];
      final prevUnreadCount = currentRoom.unreadCount ?? 0;
      
      // Reset unread count for this room
      _chatRooms[roomIndex] = currentRoom.copyWith(unreadCount: 0);
      
      // Update total unread count
      _unreadCount = (_unreadCount - prevUnreadCount).clamp(0, 999);
      
      notifyListeners();
      
      print('👁️ Room $roomId marked as entered, unread reset');
    }
  }

  // Make phone call
  void makePhoneCall(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      print('⚠️ No phone number provided');
      return;
    }

    try {
      print('📞 Calling: $phoneNumber');
      // TODO: Implement url_launcher
      // launch('tel:$phoneNumber');
    } catch (e) {
      print('❌ Cannot make phone call: $e');
    }
  }

  // Helper methods for formatting
  String formatLastMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'เมื่อกี้นี้';
    if (difference.inHours < 1) return '${difference.inMinutes} นาทีที่แล้ว';
    if (difference.inDays < 1) return '${difference.inHours} ชั่วโมงที่แล้ว';
    if (difference.inDays < 7) return '${difference.inDays} วันที่แล้ว';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String formatLastMessage(String? message, String? messageType) {
    if (message == null || message.isEmpty) {
      return messageType == 'image' ? '📷 รูปภาพ' : 'ไม่มีข้อความ';
    }
    return message.length > 50 ? '${message.substring(0, 50)}...' : message;
  }

  // Open chat with customer
  void openChatWithCustomer({
    required BuildContext context,
    required int roomId,
    required int orderId,
    required String customerName,
    String? customerPhoto,
    String? customerPhone,
  }) {
    print('🚀 Opening chat:');
    print('   roomId: $roomId');
    print('   orderId: $orderId');
    print('   userId: $_userId');
    print('   riderId: $_riderId');
    print('   userType: rider');

    // Mark room as entered to reset unread count
    markRoomAsEntered(roomId);

    Navigator.pushNamed(
      context,
      '/rider-chat',
      arguments: {
        'roomId': roomId,
        'orderId': orderId,
        'partnerName': customerName,
        'partnerPhoto': customerPhoto,
        'partnerPhone': customerPhone,
        'userType': 'rider',
        'userId': _userId,           // user_id for socket auth
        'riderId': _riderId,         // rider_id for business logic
        'userName': _riderName,
        'userPhoto': _riderPhoto,
      },
    );
  }

  // Order status helpers
  Color getOrderStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'waiting': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'rider_assigned': return Colors.amber;
      case 'going_to_shop': return Colors.deepOrange;
      case 'arrived_at_shop': return Colors.brown;
      case 'picked_up': return Colors.teal;
      case 'delivering': return Colors.indigo;
      case 'arrived_at_customer': return Colors.cyan;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'preparing': return Colors.purple;
      case 'ready_for_pickup': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  String getOrderStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'waiting': return 'รอร้านยืนยัน';
      case 'confirmed': return 'ร้านยืนยันแล้ว';
      case 'rider_assigned': return 'รอไปรับงาน';
      case 'going_to_shop': return 'กำลังไปที่ร้าน';
      case 'arrived_at_shop': return 'ถึงร้านแล้ว';
      case 'picked_up': return 'รับของแล้ว';
      case 'delivering': return 'กำลังส่ง';
      case 'arrived_at_customer': return 'ถึงบ้านลูกค้า';
      case 'completed': return 'ส่งสำเร็จ';
      case 'cancelled': return 'ออเดอร์ถูกยกเลิก';
      case 'preparing': return 'ร้านกำลังทำอาหาร';
      case 'ready_for_pickup': return 'อาหารพร้อมรับ';
      default: return 'ไม่ทราบสถานะ';
    }
  }

  @override
  void dispose() {
    print('🗑️ Disposing RiderChatController');
    
    // Cancel all subscriptions
    _messageSubscription?.cancel();
    _roomUpdateSubscription?.cancel();
    _readStatusSubscription?.cancel();
    _connectionSubscription?.cancel();
    
    // Dispose chat service
    _chatService.dispose();
    
    super.dispose();
  }
}