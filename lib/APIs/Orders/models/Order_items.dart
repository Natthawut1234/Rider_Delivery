import 'package:flutter/material.dart';

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class Order {
  final int orderId;
  final int userId;
  final int marketId;
  final String shopName;
  final String? clientName; // ชื่อผู้สั่ง
  final int? basePrice;
  final int? sellPrice;
  final int? riderId;
  final String? foodName;
  final String address;
  final String deliveryType;
  final String paymentMethod;
  final String? note;
  final double? distanceKm;
  final double deliveryFee;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final Map<String, dynamic>? marketLocation;
  final Map<String, dynamic>? customerLocation;
  final Map<String, dynamic>? distanceInfo;
  final Map<String, dynamic>? deliverySummary;

  Order({
    required this.orderId,
    required this.userId,
    required this.marketId,
    required this.shopName,
    this.clientName, // ชื่อผู้สั่ง
    this.basePrice,
    this.sellPrice,
    this.riderId,
    this.foodName,
    required this.address,
    required this.deliveryType,
    required this.paymentMethod,
    this.note,
    this.distanceKm,
    required this.deliveryFee,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,

    this.marketLocation,
    this.customerLocation,
    this.distanceInfo,
    this.deliverySummary,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // รองรับกรณีที่โครงสร้าง API มีฟิลด์ customer_location / market_location
    final dynamic marketLocRaw = json['market_location'];
    final dynamic customerLocRaw = json['customer_location'];

    Map<String, dynamic>? marketLoc = (marketLocRaw is Map)
        ? Map<String, dynamic>.from(marketLocRaw)
        : null;
    Map<String, dynamic>? customerLoc = (customerLocRaw is Map)
        ? Map<String, dynamic>.from(customerLocRaw)
        : null;

    // ชื่อผู้สั่งอาจอยู่ที่ json['name'] หรือซ่อนอยู่ใน customer_location.name
    final dynamic rawClientName = json['name'] ?? customerLoc?['name'];

    return Order(
      orderId: json['order_id'],
      userId: json['user_id'],
      marketId: json['market_id'],
      shopName: json['shop_name'] ?? marketLoc?['shop_name'] ?? '',
      clientName: rawClientName?.toString(),
      basePrice: json['base_price'],
      sellPrice: json['sell_price'],
      riderId: json['rider_id'],
      foodName: json['food_name'],
      address: json['address'] ?? customerLoc?['address'] ?? '',
      deliveryType: json['delivery_type'] ?? 'delivery',
      paymentMethod: json['payment_method'] ?? 'cash',
      note: json['note'],
      distanceKm: _toDouble(json['distance_km']),
      deliveryFee: _toDouble(json['delivery_fee']),
      totalPrice: _toDouble(json['total_price']),
      status: json['status'] ?? 'waiting',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      marketLocation: marketLoc,
      customerLocation: customerLoc,
      distanceInfo: json['distance_info'] is Map
          ? Map<String, dynamic>.from(json['distance_info'])
          : null,
      deliverySummary: json['delivery_summary'] is Map
          ? Map<String, dynamic>.from(json['delivery_summary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'market_id': marketId,
      'shop_name': shopName,
      'name': clientName, // ชื่อผู้สั่ง
      'base_price': basePrice,
      'sell_price': sellPrice,
      'rider_id': riderId,
      'address': address,
      'delivery_type': deliveryType,
      'payment_method': paymentMethod,
      'note': note,
      'distance_km': distanceKm,
      'delivery_fee': deliveryFee,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'market_location': marketLocation,
      'customer_location': customerLocation,
      'distance_info': distanceInfo,
      'delivery_summary': deliverySummary,
    };
  }

  // Helper methods for status checking
  bool get isPending => status == 'waiting';
  bool get isAccepted => status == 'accepted';
  bool get hasRider => riderId != null;
  bool get isRiderAssigned => status == 'rider_assigned';
  bool get isDelivering => status == 'delivering';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'waiting':
        return 'รอการยืนยัน';
      case 'accepted':
        return 'ร้านรับออเดอร์แล้ว';
      case 'rider_assigned':
        return 'กำลังหาไรเดอร์';
      case 'preparing':
        return 'กำลังเตรียมอาหาร';
      case 'ready_for_pickup':
        return 'พร้อมให้ไรเดอร์รับ';
      case 'picked_up':
        return 'ไรเดอร์รับแล้ว';
      case 'delivering':
        return 'กำลังจัดส่ง';
      case 'completed':
        return 'จัดส่งเสร็จสิ้น';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'accepted':
      case 'preparing':
        return Colors.blue;
      case 'rider_assigned':
      case 'ready_for_pickup':
        return Colors.purple;
      case 'picked_up':
      case 'delivering':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'waiting':
        return Icons.access_time;
      case 'accepted':
        return Icons.check_circle;
      case 'rider_assigned':
        return Icons.motorcycle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready_for_pickup':
        return Icons.shopping_bag;
      case 'picked_up':
        return Icons.delivery_dining;
      case 'delivering':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

class OrderItem {
  final int itemId;
  final int? orderId;
  final int foodId;
  final String foodName;
  final int quantity;
  final double? basePrice;
  final double sellPrice;
  final double subtotal;
  final List<dynamic> selectedOptions;

  OrderItem({
    required this.itemId,
    required this.orderId,
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.basePrice,
    required this.sellPrice,
    required this.subtotal,
    required this.selectedOptions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'],
      orderId: json['order_id'],
      foodId: json['food_id'],
      foodName: json['food_name'],
      quantity: json['quantity'],
      basePrice: _toDouble(json['base_price']),
      sellPrice: _toDouble(json['sell_price']),
      subtotal: _toDouble(json['subtotal']),
      selectedOptions: json['selected_options'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'order_id': orderId,
      'food_id': foodId,
      'food_name': foodName,
      'quantity': quantity,
      'base_price': basePrice,
      'sell_price': sellPrice,
      'subtotal': subtotal,
      'selected_options': selectedOptions,
    };
  }
}
