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

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get currentOrder => _currentOrder;
  bool get isSocketConnected => !_isDisposed && _socketService.isConnected;

  // Fixed: Better socket initialization with error handling
  Future<void> initializeSocket({
    int? userId,
    int? marketId,
    int? riderId,
  }) async {
    if (_isDisposed) {
      print('⚠️ Controller is disposed, cannot initialize socket');
      return;
    }

    try {
      print('🔌 Initializing socket connection...');
      _setLoading(true);

      // Store current user data
      _currentUserId = userId;
      _currentMarketId = marketId;

      // Test server connectivity first
      bool serverReachable = await _socketService.isServerReachable();
      if (!serverReachable) {
        throw Exception(
          'Server is not reachable at ${_socketService.getConnectionStatus()['serverUrl']}',
        );
      }

      // Connect to socket
      await _socketService.connect();

      if (_isDisposed) return; // Check if disposed during connection

      _setupSocketListeners();

      // Register user with comprehensive data
      Map<String, dynamic> registrationData = {};
      String userType = 'customer';

      if (userId != null) {
        registrationData['userId'] = userId;
        userType = 'customer';
      }
      if (marketId != null) {
        registrationData['marketId'] = marketId;
        userType = 'shop';
      }
      if (riderId != null) {
        registrationData['riderId'] = riderId;
        userType = 'rider';
      }

      registrationData['userType'] = userType;

      print('📝 Registering user with data: $registrationData');
      _socketService.emit("register_user", registrationData);

      // Join appropriate rooms
      if (userId != null) {
        final customerRoom = "customer:$userId";
        _socketService.emit("join_room", {"room": customerRoom});
        print('📍 Joined customer room: $customerRoom');
      }

      if (marketId != null) {
        final shopRoom = "shop:$marketId";
        _socketService.emit("join_room", {"room": shopRoom});
        print('📍 Joined shop room: $shopRoom');
      }

      if (riderId != null) {
        final riderRoom = "rider:$riderId";
        _socketService.emit("join_room", {"room": riderRoom});
        print('📍 Joined rider room: $riderRoom');
      }

      _clearError();
      print('✅ Socket initialization complete');
    } catch (e) {
      _error = 'Failed to connect to socket: $e';
      print('❌ Socket initialization failed: $e');
      print('📊 Connection status: ${_socketService.getConnectionStatus()}');
    } finally {
      _setLoading(false);
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

  // Fixed: Order update handling with disposal check
  void _handleOrderUpdate(dynamic data) {
    if (_isDisposed) return;

    if (data == null) {
      print('⚠️ Received null order update data');
      return;
    }

    print('🔄 Processing order update: $data');

    final orderId = data['order_id'];
    if (orderId == null) {
      print('⚠️ Order update missing order_id');
      return;
    }

    // Filter only relevant orders
    if (_currentMarketId != null && data['market_id'] != null) {
      if (data['market_id'] != _currentMarketId) {
        print(
          '🚫 Filtered out order from different market: ${data['market_id']} (current: $_currentMarketId)',
        );
        return;
      }
    }

    if (_currentUserId != null && data['user_id'] != null) {
      if (data['user_id'] != _currentUserId) {
        print(
          '🚫 Filtered out order from different user: ${data['user_id']} (current: $_currentUserId)',
        );
        return;
      }
    }

    try {
      bool hasChanges = false;

      // Update current order if it matches
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

      // Update order in list
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
            '📝 Updated order in list: $orderId ($oldStatus -> ${_orders[index].status})',
          );
        }
      } else {
        print('⚠️ Order $orderId not found in local list for update');
        hasChanges = true;
        _refreshCurrentData();
      }

      // Force UI update if there are changes
      if (hasChanges && !_isDisposed) {
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

  // Fixed: Fetch orders for rider with better error handling
  Future<void> fetchOrdersByRider({required int riderId}) async {
    if (_isDisposed) return;

    _setLoading(true);
    _clearError();
    _currentUserId = riderId;

    try {
      // Use the correct endpoint from your backend
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

          // Convert to Order objects and filter for this rider
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

          // Sort by createdAt newest first
          _orders = parsedOrders
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print('✅ Successfully loaded ${_orders.length} rider orders');

          // Group orders by status for logging
          final statusGroups = <String, int>{};
          for (var order in _orders) {
            statusGroups[order.status] = (statusGroups[order.status] ?? 0) + 1;
          }
          print('📊 Rider orders by status: $statusGroups');
        } else {
          _error = data['error'] ?? 'Failed to fetch rider orders';
          print('❌ API Error: $_error');
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode} - ${response.body}';
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

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
    if (_isDisposed) return;
    print('👁️ Watching order: $orderId');
    _socketService.emit("rider:watchOrder", orderId);
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
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      marketId: marketId ?? this.marketId,
      shopName: shopName,
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
    );
  }
}
