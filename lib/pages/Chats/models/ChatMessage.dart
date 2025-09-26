// pages/Chats/models/ChatMessage.dart
class ChatMessage {
  final int messageId;
  final int roomId;
  final int senderId;
  final String senderType;
  final String? senderName;
  final String? senderPhoto;
  final String? messageText;
  final String messageType;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    this.senderName,
    this.senderPhoto,
    this.messageText,
    required this.messageType,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: int.tryParse(json['message_id']?.toString() ?? '0') ?? 0,
      roomId: int.tryParse(json['room_id']?.toString() ?? '0') ?? 0,
      senderId: int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      senderType: json['sender_type']?.toString() ?? '',
      senderName: json['sender_name'],
      senderPhoto: json['sender_photo'],
      messageText: json['message_text'],
      messageType: json['message_type']?.toString() ?? 'text',
      imageUrl: json['image_url'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_type': senderType,
      'sender_name': senderName,
      'sender_photo': senderPhoto,
      'message_text': messageText,
      'message_type': messageType,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool isOwnMessage(int userId, String userType) {
    return senderId == userId && senderType == userType;
  }

  ChatMessage copyWith({
    int? messageId,
    int? roomId,
    int? senderId,
    String? senderType,
    String? senderName,
    String? senderPhoto,
    String? messageText,
    String? messageType,
    String? imageUrl,
    double? latitude,
    double? longitude,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
      messageText: messageText ?? this.messageText,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ChatRoom {
  final int? roomId;
  final int? orderId;
  final int? customerId;
  final int? riderId;
  final String? customerName;
  final String? customerPhoto;
  final String? customerPhone;
  final String? riderName;
  final String? riderPhoto;
  final String roomStatus;
  final String? orderStatus;
  final double? totalAmount;
  final String? deliveryAddress;
  final String? pickupAddress;
  final String? lastMessage;
  final String? messageType;
  final DateTime? lastMessageTime;
  final int? unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatRoom({
    required this.roomId,
    required this.orderId,
    required this.customerId,
    required this.riderId,
    this.customerName,
    this.customerPhoto,
    this.customerPhone,
    this.riderName,
    this.riderPhoto,
    required this.roomStatus,
    this.orderStatus,
    this.totalAmount,
    this.deliveryAddress,
    this.pickupAddress,
    this.lastMessage,
    this.messageType,
    this.lastMessageTime,
    this.unreadCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      roomId: int.tryParse(json['room_id']?.toString() ?? '0'),
      orderId: int.tryParse(json['order_id']?.toString() ?? '0'),
      customerId: int.tryParse(json['customer_id']?.toString() ?? '0'),
      riderId: int.tryParse(json['rider_id']?.toString() ?? '0'),
      customerName: json['customer_name'],
      customerPhoto: json['customer_photo'],
      customerPhone: json['customer_phone'],
      riderName: json['rider_name'],
      riderPhoto: json['rider_photo'],
      roomStatus: json['room_status'] ?? 'active',
      orderStatus: json['order_status'],
      totalAmount: json['total_amount'] != null
          ? double.tryParse(json['total_amount'].toString())
          : null,
      deliveryAddress: json['delivery_address'],
      pickupAddress: json['pickup_address'],
      lastMessage: json['last_message'],
      messageType: json['message_type'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'])
          : null,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'order_id': orderId,
      'customer_id': customerId,
      'rider_id': riderId,
      'customer_name': customerName,
      'customer_photo': customerPhoto,
      'customer_phone': customerPhone,
      'rider_name': riderName,
      'rider_photo': riderPhoto,
      'room_status': roomStatus,
      'order_status': orderStatus,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'pickup_address': pickupAddress,
      'last_message': lastMessage,
      'message_type': messageType,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ChatRoom copyWith({
    int? roomId,
    int? orderId,
    int? customerId,
    int? riderId,
    String? customerName,
    String? customerPhoto,
    String? customerPhone,
    String? riderName,
    String? riderPhoto,
    String? roomStatus,
    String? orderStatus,
    double? totalAmount,
    String? deliveryAddress,
    String? pickupAddress,
    String? lastMessage,
    String? messageType,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      roomId: roomId ?? this.roomId,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      riderId: riderId ?? this.riderId,
      customerName: customerName ?? this.customerName,
      customerPhoto: customerPhoto ?? this.customerPhoto,
      customerPhone: customerPhone ?? this.customerPhone,
      riderName: riderName ?? this.riderName,
      riderPhoto: riderPhoto ?? this.riderPhoto,
      roomStatus: roomStatus ?? this.roomStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      lastMessage: lastMessage ?? this.lastMessage,
      messageType: messageType ?? this.messageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SendMessageRequest {
  final int roomId;
  final String? messageText;
  final String messageType;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  SendMessageRequest({
    required this.roomId,
    this.messageText,
    this.messageType = 'text',
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'messageText': messageText,
      'messageType': messageType,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
