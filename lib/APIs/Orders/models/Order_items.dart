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

  Order({
    required this.orderId,
    required this.userId,
    required this.marketId,
    required this.shopName,
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
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      userId: json['user_id'],
      marketId: json['market_id'],
      shopName: json['shop_name'],
      riderId: json['rider_id'],
      foodName: json['food_name'],
      address: json['address'],
      deliveryType: json['delivery_type'],
      paymentMethod: json['payment_method'],
      note: json['note'],
      distanceKm: _toDouble(json['distance_km']),
      deliveryFee: _toDouble(json['delivery_fee']),
      totalPrice: _toDouble(json['total_price']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'market_id': marketId,
      'shop_name': shopName,
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
  final double sellPrice;
  final double subtotal;
  final List<dynamic> selectedOptions;

  OrderItem({
    required this.itemId,
    required this.orderId,
    required this.foodId,
    required this.foodName,
    required this.quantity,
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
      'sell_price': sellPrice,
      'subtotal': subtotal,
      'selected_options': selectedOptions,
    };
  }
}