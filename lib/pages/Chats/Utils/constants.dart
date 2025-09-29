// utils/constants.dart
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';

class AppConstants {
  // API Configuration
  static const String BASE_URL = '${BaseAPI_URL.HostSocketURL}'; // แก้ไขเป็น URL จริงของ server
  static const String SOCKET_URL = '$BASE_URL';
  
  // API Endpoints
  static const String RIDER_CHAT_ROOMS = '/chat/rider/rooms';
  static const String CUSTOMER_CHAT_ROOMS = '/chat/customer/rooms';
  static const String CHAT_MESSAGES = '/chat/rider/room';
  static const String UPLOAD_IMAGE = '/chat/rider/upload-image';
  static const String MARK_AS_READ = '/chat/rider/room';
  static const String UNREAD_COUNT = '/chat/rider/unread-count';
  
  // Socket Events
  static const String SOCKET_CONNECT = 'connect';
  static const String SOCKET_DISCONNECT = 'disconnect';
  static const String SOCKET_ERROR = 'error';
  static const String JOIN_ROOM = 'join_room';
  static const String LEAVE_ROOM = 'leave_room';
  static const String SEND_MESSAGE = 'send_message';
  static const String NEW_MESSAGE = 'new_message';
  static const String TYPING_START = 'typing_start';
  static const String TYPING_STOP = 'typing_stop';
  static const String USER_TYPING = 'user_typing';
  static const String MARK_READ = 'mark_as_read';
  static const String MESSAGES_READ = 'messages_read';
  static const String USER_JOINED = 'user_joined';
  static const String USER_LEFT = 'user_left';
  
  // Message Types
  static const String MESSAGE_TYPE_TEXT = 'text';
  static const String MESSAGE_TYPE_IMAGE = 'image';
  static const String MESSAGE_TYPE_LOCATION = 'location';
  
  // User Types
  static const String USER_TYPE_CUSTOMER = 'customer';
  static const String USER_TYPE_RIDER = 'rider';
  
  // Room Status
  static const String ROOM_STATUS_ACTIVE = 'active';
  static const String ROOM_STATUS_CLOSED = 'closed';
  static const String ROOM_STATUS_ARCHIVED = 'archived';
  
  // Order Status
  static const String ORDER_STATUS_PENDING = 'pending';
  static const String ORDER_STATUS_CONFIRMED = 'confirmed';
  static const String ORDER_STATUS_PREPARING = 'preparing';
  static const String ORDER_STATUS_READY = 'ready';
  static const String ORDER_STATUS_PICKED_UP = 'picked_up';
  static const String ORDER_STATUS_DELIVERED = 'delivered';
  static const String ORDER_STATUS_CANCELLED = 'cancelled';
  
  // SharedPreferences Keys
  static const String PREF_AUTH_TOKEN = 'auth_token';
  static const String PREF_USER_ID = 'user_id';
  static const String PREF_RIDER_ID = 'rider_id';
  static const String PREF_USER_NAME = 'user_name';
  static const String PREF_RIDER_NAME = 'rider_name';
  static const String PREF_USER_PHOTO = 'user_photo';
  static const String PREF_RIDER_PHOTO = 'rider_photo';
  static const String PREF_USER_TYPE = 'user_type';
  static const String PREF_IS_LOGGED_IN = 'is_logged_in';
  
  // Image Configuration
  static const int MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
  static const int IMAGE_QUALITY = 80;
  static const int MAX_IMAGE_WIDTH = 1024;
  static const int MAX_IMAGE_HEIGHT = 1024;
  
  // Chat Configuration
  static const int MESSAGES_PER_PAGE = 50;
  static const int TYPING_TIMEOUT = 2; // seconds
  static const int CONNECTION_TIMEOUT = 10; // seconds
  static const int MAX_MESSAGE_LENGTH = 1000;
  
  // Colors (if needed)
  static const int PRIMARY_GREEN = 0xFF4CAF50;
  static const int LIGHT_GREEN = 0xFF8BC34A;
  static const int DARK_GREEN = 0xFF2E7D32;
  static const int GREY_LIGHT = 0xFFF5F5F5;
  static const int GREY_MEDIUM = 0xFFBDBDBD;
  static const int GREY_DARK = 0xFF757575;
  
  // Network Configuration
  static const Duration HTTP_TIMEOUT = Duration(seconds: 30);
  static const Duration SOCKET_TIMEOUT = Duration(seconds: 10);
  
  // Error Messages
  static const String ERROR_NETWORK = 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
  static const String ERROR_AUTH = 'กรุณาเข้าสู่ระบบใหม่';
  static const String ERROR_PERMISSION = 'ไม่มีสิทธิ์เข้าถึง';
  static const String ERROR_SERVER = 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่';
  static const String ERROR_FILE_SIZE = 'ไฟล์ใหญ่เกินไป';
  static const String ERROR_FILE_TYPE = 'ประเภทไฟล์ไม่ถูกต้อง';
  static const String ERROR_SOCKET_DISCONNECT = 'การเชื่อมต่อขาดหาย';
  
  // Success Messages  
  static const String SUCCESS_MESSAGE_SENT = 'ส่งข้อความแล้ว';
  static const String SUCCESS_IMAGE_UPLOADED = 'อัพโลดรูปภาพแล้ว';
  static const String SUCCESS_MARKED_READ = 'ทำเครื่องหมายอ่านแล้ว';
  
  // Validation
  static bool isValidImageSize(int bytes) {
    return bytes <= MAX_IMAGE_SIZE;
  }
  
  static bool isValidMessageLength(String message) {
    return message.length <= MAX_MESSAGE_LENGTH;
  }
  
  static bool isValidImageType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }
  
  // Helper methods
  static String getOrderStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case ORDER_STATUS_PENDING:
        return 'รอยืนยัน';
      case ORDER_STATUS_CONFIRMED:
        return 'ยืนยันแล้ว';
      case ORDER_STATUS_PREPARING:
        return 'กำลังเตรียม';
      case ORDER_STATUS_READY:
        return 'พร้อมส่ง';
      case ORDER_STATUS_PICKED_UP:
        return 'รับของแล้ว';
      case ORDER_STATUS_DELIVERED:
        return 'ส่งเสร็จแล้ว';
      case ORDER_STATUS_CANCELLED:
        return 'ยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }
  
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}