import 'dart:convert';
import 'package:rider_delivery/APIs/Orders/models/Order_items.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';
import 'package:rider_delivery/services/SocketService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RiderControllerSocket extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  final String baseUrl = BaseAPI_URL.SocketURL; // Fixed: Use correct URL

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  Order? _currentOrder;
  int? _currentMarketId;
  int? _currentUserId;
  bool _isDisposed = false; // Track disposal state
  // final Map<int, Map<String, dynamic>> _marketCache = {}; // cache market info

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get currentOrder => _currentOrder;
  bool get isSocketConnected => !_isDisposed && _socketService.isConnected;

  // แก้ไข initializeSocket method
  Future<void> initializeSocket({required int riderId}) async {
    try {
      print('🔌 [RiderSocket] Initializing socket for riderId=$riderId');

      await _socketService.connect();

      // ⭐ เพิ่มการ setup listeners ก่อน
      _setupSocketListeners();

      // ลงทะเบียนเป็นไรเดอร์
      _socketService.emit("register_user", {
        "riderId": riderId,
        "userType": "rider",
      });
      print('📡 [RiderSocket] Sent register_user with riderId=$riderId');

      // Join rider room
      _socketService.emit("join_room", {"room": "rider:$riderId"});
      print('📍 [RiderSocket] Joined rider room: rider:$riderId');

      // ⭐ ลบ duplicate listeners ออก (ย้ายไปใน _setupSocketListeners แล้ว)
    } catch (e) {
      print('❌ [RiderSocket] Socket init failed: $e');
      _error = 'Failed to connect to socket: $e';
      notifyListeners();
    }
  }

  // Fixed: Better listener setup with disposal check
  void _setupSocketListeners() {
    if (_isDisposed) return;

    print('🎧 Setting up socket listeners...');

    // Clear existing listeners first
    _socketService.off('connect');
    _socketService.off('disconnect');
    _socketService.off('order:updated');
    _socketService.off('new_order_notification');
    _socketService.off('customer:newOrder');
    _socketService.off('order_status_update');
    _socketService.off('error');
    _socketService.off('pong');

    // Connection status
    _socketService.on('connect', (data) {
      if (_isDisposed) return;
      print('✅ Socket connected successfully');
      _clearError();
      notifyListeners();
    });

    _socketService.on('disconnect', (data) {
      if (_isDisposed) return;
      print('❌ Socket disconnected');
      notifyListeners();
    });

    // Main order update listener
    _socketService.on('order:updated', (data) {
      if (_isDisposed) return;
      print('📦 Order updated: $data');
      _handleOrderUpdate(data);
    });

    // New order notifications
    _socketService.on('new_order_notification', (data) {
      if (_isDisposed) return;
      print('🔔 New order notification: $data');
      _handleNewOrderNotification(data);
    });

    _socketService.on('customer:newOrder', (data) {
      if (_isDisposed) return;
      print('👤 New order for customer: $data');
      _handleNewOrderNotification(data);
    });

    _socketService.on('order_status_update', (data) {
      if (_isDisposed) return;
      print('📊 Order status update: $data');
      _handleOrderUpdate(data);
    });

    _socketService.on('error', (error) {
      if (_isDisposed) return;
      print('🚫 Socket error: $error');
      _error = 'Socket error: ${error.toString()}';
      notifyListeners();
    });

    _socketService.on('pong', (data) {
      if (_isDisposed) return;
      print('💗 Heartbeat pong received');
    });

    print('✅ Socket listeners setup complete');
  }

  // Handle new order notification
  void _handleNewOrderNotification(dynamic data) {
    if (_isDisposed) return;
    print('🆕 Handling new order notification: $data');
    _refreshCurrentData();
  }

  // Helper method to refresh current data based on type
  Future<void> _refreshCurrentData() async {
    if (_isDisposed) return;

    if (_currentUserId != null) {
      await fetchOrdersByRider(riderId: _currentUserId!);
    } else {
      await fetchOrders();
    }
  }

  // Assign rider to order
  Future<bool> assignRider(int orderId, int riderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assign_rider'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'rider_id': riderId}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        _error = data['error'] ?? 'Failed to assign rider';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  // ปรับปรุง fetchOrdersByRider ให้รองรับออเดอร์ที่พร้อมให้ไรเดอร์รับ
  Future<void> fetchOrdersByRider({required int riderId}) async {
    if (_isDisposed) return;

    _setLoading(true);
    _clearError();
    _currentUserId = riderId;

    try {
      // ⭐ เปลี่ยน query เป็นการดึงออเดอร์ของไรเดอร์ + ออเดอร์ที่พร้อมรับ
      String url = '$baseUrl/orders?rider_id=$riderId';
      print('👤 Fetching orders for rider $riderId from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("fetch data: ${data}");

        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];

          // Convert to Order objects
          final parsedOrders = ordersData
              .map((orderJson) {
                try {
                  final order = Order.fromJson(orderJson);
                  return order;
                } catch (e) {
                  print('❌ Error parsing order: $e');
                  return null;
                }
              })
              .where((o) => o != null)
              .cast<Order>()
              .toList();

          // Sort by createdAt newest first, with available orders first
          _orders = parsedOrders
            ..sort((a, b) {
              // ออเดอร์ที่ยังไม่มีไรเดอร์และพร้อมรับ จะขึ้นก่อน
              if (a.riderId == null &&
                  [
                    'confirmed',
                    'accepted',
                    'preparing',
                    'ready_for_pickup',
                  ].contains(a.status) &&
                  b.riderId == riderId) {
                return -1;
              }
              if (b.riderId == null &&
                  [
                    'confirmed',
                    'accepted',
                    'preparing',
                    'ready_for_pickup',
                  ].contains(b.status) &&
                  a.riderId == riderId) {
                return 1;
              }
              return b.createdAt.compareTo(a.createdAt);
            });

          print('✅ Successfully loaded ${_orders.length} rider orders');

          // Group orders by status for logging
          final statusGroups = <String, int>{};
          final availableOrders = _orders
              .where(
                (o) =>
                    o.riderId == null &&
                    [
                      'confirmed',
                      'accepted',
                      'preparing',
                      'ready_for_pickup',
                    ].contains(o.status),
              )
              .length;

          for (var order in _orders) {
            statusGroups[order.status] = (statusGroups[order.status] ?? 0) + 1;
          }

          print('📊 Rider orders by status: $statusGroups');
          print('🎯 Available orders for pickup: $availableOrders');

          // // Hydrate missing marketLocation from cache / peers (non-blocking)
          // for (var i = 0; i < _orders.length; i++) {
          //   final o = _orders[i];
          //   if (o.marketLocation == null) {
          //     // Try cache first
          //     final cached = _marketCache[o.marketId];
          //     if (cached != null) {
          //       _orders[i] = o.copyWith(marketLocation: cached);
          //     } else {
          //       // Try reuse from another order in list
          //       final peer = _orders.firstWhere(
          //         (p) => p.marketId == o.marketId && p.marketLocation != null,
          //         orElse: () => o,
          //       );
          //       if (peer != o && peer.marketLocation != null) {
          //         _marketCache[o.marketId] = peer.marketLocation!;
          //         _orders[i] = o.copyWith(marketLocation: peer.marketLocation);
          //       }
          //     }
          //   }
          // }
        } else {
          _error = data['error'] ?? 'Failed to fetch rider orders';
          print('❌ API Error: $_error');
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode} - ${response.body}';
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // // Public method to ensure market info for a given orderId
  // Future<void> hydrateMarketInfoForOrder(int orderId) async {
  //   if (_isDisposed) return;
  //   final idx = _orders.indexWhere((o) => o.orderId == orderId);
  //   if (idx == -1) return;
  //   final order = _orders[idx];
  //   if (order.marketLocation != null) return; // already has

  //   // 1. Try cache
  //   final cached = _marketCache[order.marketId];
  //   if (cached != null) {
  //     _orders[idx] = order.copyWith(marketLocation: cached);
  //     notifyListeners();
  //     return;
  //   }

  //   // 2. Try peer order
  //   final peer = _orders.firstWhere(
  //     (p) => p.marketId == order.marketId && p.marketLocation != null,
  //     orElse: () => order,
  //   );
  //   if (peer != order && peer.marketLocation != null) {
  //     _marketCache[order.marketId] = peer.marketLocation!;
  //     _orders[idx] = order.copyWith(marketLocation: peer.marketLocation);
  //     notifyListeners();
  //     return;
  //   }

  //   // 3. Fetch from backend (best-effort). We don't know exact endpoint pattern; try plural then singular.
  //   final endpoints = [
  //     '${BaseAPI_URL.baseURL}/markets/${order.marketId}',
  //     '${BaseAPI_URL.baseURL}/market/${order.marketId}',
  //   ];
  //   for (final url in endpoints) {
  //     try {
  //       print(
  //         '🌐 Fetching market detail for marketId=${order.marketId} via $url',
  //       );
  //       final resp = await http.get(
  //         Uri.parse(url),
  //         headers: {'Content-Type': 'application/json'},
  //       );
  //       if (resp.statusCode == 200) {
  //         final body = json.decode(resp.body);
  //         final data = (body is Map && body['data'] is Map)
  //             ? Map<String, dynamic>.from(body['data'])
  //             : (body is Map ? body : null);
  //         if (data != null) {
  //           // Normalize key names potentially used
  //           final normalized = <String, dynamic>{...data};
  //           // Heuristic: if address not present but shop_address exists
  //           if (normalized['address'] == null &&
  //               normalized['shop_address'] != null) {
  //             normalized['address'] = normalized['shop_address'];
  //           }
  //           _marketCache[order.marketId] = normalized;
  //           _orders[idx] = order.copyWith(marketLocation: normalized);
  //           print('✅ Hydrated market location for order $orderId');
  //           notifyListeners();
  //           return;
  //         }
  //       } else {
  //         print('⚠️ Failed market detail fetch ($url): ${resp.statusCode}');
  //       }
  //     } catch (e) {
  //       print('⚠️ Market detail fetch error ($url): $e');
  //     }
  //   }
  //   print('⚠️ Could not hydrate market info for order $orderId');
  // }

  // Fixed: Update order status with better error handling
  Future<bool> updateOrderStatus(
    int orderId,
    String status, {
    Map<String, dynamic>? additionalData,
  }) async {
    if (_isDisposed) return false;

    try {
      print('🔄 Updating order $orderId status to $status');

      final response = await http.put(
        Uri.parse('$baseUrl/update_order_status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'status': status,
          'additional_data': additionalData,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Update local order status immediately
        final orderIndex = _orders.indexWhere(
          (order) => order.orderId == orderId,
        );
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
          print('✅ Local order updated immediately');
        }

        print('✅ Order $orderId status updated to $status');
        if (!_isDisposed) notifyListeners();
        return true;
      } else {
        _error = data['error'] ?? 'Failed to update order status';
        print('❌ Failed to update order status: $_error');
        if (!_isDisposed) notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  // Fixed: Safe loading state management
  void _setLoading(bool loading) {
    if (_isDisposed) return;
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Fixed: Safe error management
  void _clearError() {
    if (_isDisposed) return;
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void clearError() => _clearError();

  // Get orders by status with disposal check
  List<Order> getOrdersByStatus(String status) {
    if (_isDisposed) return [];
    final filtered = _orders.where((order) => order.status == status).toList();
    print('🔍 getOrdersByStatus($status): found ${filtered.length} orders');
    return filtered;
  }

  // Debug method
  void debugPrintOrdersState() {
    if (_isDisposed) {
      print('📊 Controller is disposed');
      return;
    }

    print('📊 Current orders state:');
    print('   Total orders: ${_orders.length}');
    print('   Current market ID: $_currentMarketId');
    print('   Current user ID: $_currentUserId');
    print('   Socket connected: $isSocketConnected');
    print('   Loading: $_isLoading');
    print('   Error: $_error');

    final statusGroups = <String, int>{};
    for (var order in _orders) {
      statusGroups[order.status] = (statusGroups[order.status] ?? 0) + 1;
    }
    print('   Orders by status: $statusGroups');
  }

  // Watch specific order
  void watchOrder(int orderId) {
    _socketService.emit("rider:watchOrder", orderId);
    print("👁️ [RiderSocket] Watching order $orderId");
  }

  // Send heartbeat to check connection
  void sendHeartbeat() {
    if (_isDisposed) return;
    if (_socketService.isConnected) {
      _socketService.emit('ping');
    }
  }

  // Fetch orders from API
  Future<void> fetchOrders({int? userId, String? status}) async {
    if (_isDisposed) return;

    _setLoading(true);
    _clearError();

    try {
      String url = '$baseUrl/orders';
      List<String> queryParams = [];

      if (userId != null) {
        queryParams.add('user_id=$userId');
      }
      if (status != null) {
        queryParams.add('status=$status');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      print('🔍 Fetching orders from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'] ?? [];
          _orders = ordersData
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
          print('✅ Successfully loaded ${_orders.length} orders');
        } else {
          _error = data['error'] ?? 'Failed to fetch orders';
          print('❌ API Error: $_error');
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ⭐ เพิ่ม method สำหรับดึงออเดอร์ที่พร้อมให้รับ
  List<Order> get availableOrders {
    if (_isDisposed) return [];
    return _orders
        .where(
          (order) =>
              order.riderId == null &&
              [
                'confirmed',
                'accepted',
                'preparing',
                'ready_for_pickup',
              ].contains(order.status),
        )
        .toList();
  }

  // ปรับปรุง _handleOrderUpdate ให้ refresh data เมื่อมีออเดอร์ใหม่
  void _handleOrderUpdate(dynamic data) {
    if (_isDisposed) return;

    if (data == null) {
      print('⚠️ Received null order update data');
      return;
    }

    print('🔄 Processing order update: $data');

    final orderId = data['order_id'];
    final status = data['status'];

    if (orderId == null) {
      print('⚠️ Order update missing order_id');
      return;
    }

    try {
      bool hasChanges = false;
      bool needsRefresh = false;

      // ⭐ ถ้าเป็นออเดอร์ที่เปลี่ยนเป็น confirmed/preparing/ready_for_pickup
      // ต้อง refresh เพื่อแสดงออเดอร์ใหม่ที่พร้อมรับ
      if (['confirmed', 'preparing', 'ready_for_pickup'].contains(status)) {
        print('🆕 New available order detected: $orderId with status: $status');
        needsRefresh = true;
      }

      // Update existing order in list
      final index = _orders.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        final oldStatus = _orders[index].status;
        final newStatus = data['status'] ?? _orders[index].status;
        final newRiderId = data['rider_id'] ?? _orders[index].riderId;

        if (oldStatus != newStatus || _orders[index].riderId != newRiderId) {
          _orders[index] = _orders[index].copyWith(
            status: newStatus,
            riderId: newRiderId,
            updatedAt: data['timestamp'] != null
                ? DateTime.parse(data['timestamp'])
                : DateTime.now(),
          );
          hasChanges = true;
          print(
            '📝 Updated order in list: $orderId ($oldStatus -> $newStatus)',
          );
        }
      } else {
        // ออเดอร์ใหม่ที่ไม่อยู่ใน list
        needsRefresh = true;
        print('🆕 New order not in list, need refresh: $orderId');
      }

      // Update current order if matches
      if (_currentOrder?.orderId == orderId) {
        final newStatus = data['status'] ?? _currentOrder!.status;
        final newRiderId = data['rider_id'] ?? _currentOrder!.riderId;

        if (_currentOrder!.status != newStatus ||
            _currentOrder!.riderId != newRiderId) {
          _currentOrder = _currentOrder?.copyWith(
            status: newStatus,
            riderId: newRiderId,
            updatedAt: data['timestamp'] != null
                ? DateTime.parse(data['timestamp'])
                : DateTime.now(),
          );
          hasChanges = true;
          print('📝 Updated current order: ${_currentOrder?.orderId}');
        }
      }

      // Refresh data if needed
      if (needsRefresh) {
        print('🔄 Refreshing rider orders due to new available order');
        _refreshCurrentData();
      } else if (hasChanges && !_isDisposed) {
        print('🔄 Notifying listeners of order update');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error handling order update: $e');
      if (!_isDisposed) {
        _error = 'Error processing order update: $e';
        notifyListeners();
      }
    }
  }

  // Get orders by different statuses
  List<Order> get pendingOrders => getOrdersByStatus('waiting');
  List<Order> get acceptedOrders => getOrdersByStatus('accepted');
  List<Order> get completedOrders => getOrdersByStatus('completed');
  List<Order> get rejectedOrders {
    if (_isDisposed) return [];
    return _orders
        .where(
          (order) => order.status == 'cancelled' || order.status == 'rejected',
        )
        .toList();
  }

  List<Order> get ordersWithRiders {
    if (_isDisposed) return [];
    return _orders.where((order) => order.hasRider).toList();
  }

  // Fixed: Safe disposal
  @override
  void dispose() {
    if (_isDisposed) return;

    print('🗑️ Disposing RiderControllerSocket...');
    _isDisposed = true;

    try {
      _socketService.disconnect();
    } catch (e) {
      print('⚠️ Error disconnecting socket during disposal: $e');
    }

    super.dispose();
    print('✅ RiderControllerSocket disposed safely');
  }
}

// Extension for Order copyWith method remains the same
extension OrderCopyWith on Order {
  Order copyWith({
    int? orderId,
    int? userId,
    int? marketId,
    int? riderId,
    String? shopName,
    String? clientName,
    int? sellPrice,
    String? address,
    String? deliveryType,
    String? paymentMethod,
    String? note,
    double? distanceKm,
    double? deliveryFee,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
    Map<String, dynamic>? marketLocation,
    Map<String, dynamic>? customerLocation,
    Map<String, dynamic>? distanceInfo,
    Map<String, dynamic>? deliverySummary,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      marketId: marketId ?? this.marketId,
      shopName: shopName ?? this.shopName,
      clientName: clientName ?? this.clientName,
      sellPrice: sellPrice ?? this.sellPrice,
      riderId: riderId ?? this.riderId,
      address: address ?? this.address,
      deliveryType: deliveryType ?? this.deliveryType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      distanceKm: distanceKm ?? this.distanceKm,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      marketLocation: marketLocation ?? this.marketLocation,
      customerLocation: customerLocation ?? this.customerLocation,
      distanceInfo: distanceInfo ?? this.distanceInfo,
      deliverySummary: deliverySummary ?? this.deliverySummary,
    );
  }
}
