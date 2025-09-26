// controllers/rider_chat_controller.dart
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
  int? _riderId;
  int? _userId; // ← เพิ่มบรรทัดนี้

  String? _riderName;
  String? _riderPhoto;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  int get unreadCount => _unreadCount;
  int? get riderId => _riderId;
  String? get riderName => _riderName;
  String? get riderPhoto => _riderPhoto;

  StreamSubscription? _msgSub, _roomSub, _readSub;

  RiderChatController() {
    _initializeRiderInfo();
    _setupConnectionListener();
    _setupRealtimeListeners();
  }

  Future<void> initializeRiderInfoIfNeeded() async {
    if (_userId == null || _riderId == null) {
      await _initializeRiderInfo();
    }
  }

  Future<void> _initializeRiderInfo() async {
    try {
      final prefs = await SharedPreferencesHelper.getInstance();

      // 🩹 พิมพ์ดูทั้งหมดก่อน (debug)
      final allKeys = prefs.getKeys();
      print("🔎 Keys in SharedPreferences:");
      for (var key in allKeys) {
        print("👉 $key = ${prefs.get(key)}");
      }

      // ✅ โหลดจาก user_rider (JSON)
      final userRiderString = prefs.getString('user_rider');
      if (userRiderString != null) {
        final userData = jsonDecode(userRiderString);
        _riderId = userData['rider_id'];
        _userId = userData['user_id']; // 35 (เพิ่มบรรทัดนี้)
        _riderName = userData['display_name'];
        _riderPhoto =
            userData['photo_url']; // ถ้าไม่มี key นี้ จะเป็น null ซึ่งไม่เป็นไร
        print("✅ Loaded from user_rider JSON");
        print("🏍️ Rider ID: $_riderId");
        print("👤 Rider Name: $_riderName");
        print("🖼️ Rider Photo: $_riderPhoto");
      } else {
        print("⚠️ user_rider not found!");
      }

      // ✅ โหลด token จาก key 'token' (ไม่ใช่ 'auth_token')
      final token = prefs.getString('token');
      if (token != null) {
        _chatService.setAuthToken(token);
        print("🔑 Token loaded: ${token.substring(0, 20)}...");
      }
      if (_riderId != null) {
        await connectToChat(); // ✅ ต่อ socket ตอนนี้ token จะถูกส่งไปแล้ว
        await loadChatRooms();
        await updateUnreadCount();
      } else {
        print("⚠️ Token not found in SharedPreferences");
      }

      // ✅ เริ่มเชื่อมต่อ socket และโหลดห้องแชท
      if (_riderId != null) {
        await connectToChat();
        await loadChatRooms();
        await updateUnreadCount();
      } else {
        print(
          "⚠️ Rider ID is null → ยังไม่ได้ login หรือ user_rider ไม่มีข้อมูล",
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Error initializing rider info: $e');
      debugPrint(stack.toString());
    }
  }

  int? get userId => _userId;

  void _setupConnectionListener() {
    _chatService.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();

      if (connected) {
        loadChatRooms();
      }
    });
  }

  // เชื่อมต่อ socket
  Future<void> connectToChat() async {
    if (_riderId == null) return;

    try {
      await _chatService.connectSocket(_riderId!);
    } catch (e) {
      debugPrint('Error connecting to chat: $e');
    }
  }

  // โหลดห้องแชท
  Future<void> loadChatRooms() async {
    if (_riderId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final rooms = await _chatService.getChatRooms(_riderId!);
      _chatRooms = rooms;

      _unreadCount = rooms.fold<int>(
        0,
        (sum, room) => sum + (room.unreadCount ?? 0),
      );
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // อัปเดตจำนวน unread
  Future<void> updateUnreadCount() async {
    if (_riderId == null) return;

    try {
      _unreadCount = await _chatService.getUnreadCount(_riderId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating unread count: $e');
    }
  }

  // สร้างห้องแชทใหม่
  Future<void> createChatRoomForOrder({
    required int orderId,
    required int customerId,
    required String customerName,
    String? customerPhoto,
  }) async {
    if (_riderId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final roomId = await _chatService.createChatRoom(
        orderId,
        customerId,
        _riderId!,
      );

      await loadChatRooms();

      debugPrint('Chat room created: $roomId');
    } catch (e) {
      debugPrint('Error creating chat room: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtimeListeners() {
    _msgSub = _chatService.messageStream.listen((m) {
      final idx = _chatRooms.indexWhere((r) => r.roomId == m.roomId);
      final isMine = m.senderId == _riderId;
      if (idx != -1) {
        final prev = _chatRooms[idx];
        _chatRooms[idx] = prev.copyWith(
          lastMessage: m.messageText,
          messageType: m.messageType,
          lastMessageTime: m.createdAt,
          unreadCount: isMine
              ? (prev.unreadCount ?? 0)
              : (prev.unreadCount ?? 0) + 1,
        );
        if (!isMine) _unreadCount += 1;
        notifyListeners();
      } else {
        // ถ้าไม่พบห้อง โหลดใหม่ (กันกรณีเพิ่งถูกสร้าง)
        loadChatRooms();
      }
    });

    _roomSub = _chatService.roomUpdateStream.listen((room) {
      final idx = _chatRooms.indexWhere((r) => r.roomId == room.roomId);
      if (idx == -1) {
        _chatRooms.insert(0, room);
      } else {
        _chatRooms[idx] = room;
      }
      _unreadCount = _chatRooms.fold(0, (s, r) => s + (r.unreadCount ?? 0));
      notifyListeners();
    });

    _readSub = _chatService.readStatusStream.listen((data) {
      final roomId = data['roomId'] as int?;
      if (roomId == null) return;
      final idx = _chatRooms.indexWhere((r) => r.roomId == roomId);
      if (idx != -1) {
        final prev = _chatRooms[idx].unreadCount ?? 0;
        _chatRooms[idx] = _chatRooms[idx].copyWith(unreadCount: 0);
        _unreadCount = (_unreadCount - prev).clamp(0, 999);
        notifyListeners();
      }
    });
  }

  // รีเฟรช
  Future<void> refreshChatRooms() async {
    await loadChatRooms();
  }

  // เข้าแชท → unread = 0
  void markRoomAsEntered(int roomId) {
    final index = _chatRooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      final prevUnread = _chatRooms[index].unreadCount ?? 0;
      _chatRooms[index] = _chatRooms[index].copyWith(unreadCount: 0);
      _unreadCount = (_unreadCount - prevUnread).clamp(0, 999);
      notifyListeners();
    }
  }

  // โทรศัพท์
  void makePhoneCall(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      debugPrint('ไม่พบหมายเลขโทรศัพท์');
      return;
    }

    try {
      debugPrint('กำลังโทรหา: $phoneNumber');
      // ใช้ url_launcher
      // launch('tel:$phoneNumber');
    } catch (e) {
      debugPrint('ไม่สามารถโทรศัพท์ได้: $e');
    }
  }

  // helper format เวลา
  String formatLastMessageTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'เมื่อกี้นี้';
    if (diff.inHours < 1) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inDays < 1) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // helper format ข้อความ
  String formatLastMessage(String? msg, String? type) {
    if (msg == null || msg.isEmpty) {
      return (type == 'image') ? '📷 รูปภาพ' : 'ไม่มีข้อความ';
    }
    return msg.length > 50 ? '${msg.substring(0, 50)}...' : msg;
  }

  // เปิดแชทกับลูกค้า
  void openChatWithCustomer({
    required BuildContext context,
    required int roomId,
    required int orderId,
    required String customerName,
    String? customerPhoto,
    String? customerPhone,
  }) {
    print('  - userId: $_userId'); // เพิ่ม debug
    print('  - userType: rider');
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

        'userId': _userId,
        'userName': _riderName,
        'userPhoto': _riderPhoto,
      },
    );
  }

  // สีสถานะ order
  Color getOrderStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'waiting':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'rider_assigned':
        return Colors.amber;
      case 'going_to_shop':
        return Colors.deepOrange;
      case 'arrived_at_shop':
        return Colors.brown;
      case 'picked_up':
        return Colors.teal;
      case 'delivering':
        return Colors.indigo;
      case 'arrived_at_customer':
        return Colors.cyan;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'preparing':
        return Colors.purple;
      case 'ready_for_pickup':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String getOrderStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'waiting':
        return 'รอร้านยืนยัน';
      case 'confirmed':
        return 'ร้านยืนยันแล้ว';
      case 'rider_assigned':
        return 'รอไปรับงาน';
      case 'going_to_shop':
        return 'กำลังไปที่ร้าน';
      case 'arrived_at_shop':
        return 'ถึงร้านแล้ว';
      case 'picked_up':
        return 'รับของแล้ว';
      case 'delivering':
        return 'กำลังส่ง';
      case 'arrived_at_customer':
        return 'ถึงบ้านลูกค้า';
      case 'completed':
        return 'ส่งสำเร็จ';
      case 'cancelled':
        return 'ออเดอร์ถูกยกเลิก';
      case 'preparing':
        return 'ร้านกำลังทำอาหาร';
      case 'ready_for_pickup':
        return 'อาหารพร้อมรับ';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _roomSub?.cancel();
    _readSub?.cancel();
    _chatService.dispose();
    super.dispose();
  }
}
