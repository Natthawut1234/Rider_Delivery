import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import 'package:rider_delivery/APIs/Orders/models/Order_items.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';

class RiderControllerSocket extends ChangeNotifier {
  late RiderOrdersApi _api;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSocketConnected = false;
  Timer? _timer;

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSocketConnected => _isSocketConnected;

  // Filter orders by status
  List<Order> get availableOrders => _orders
      .where(
        (order) => order.status == 'waiting' || order.status == 'confirmed',
      )
      .toList();
  List<Order> get assignedOrders => _orders
      .where(
        (order) =>
            order.status == 'accepted' ||
            order.status == 'rider_assigned' ||
            order.status == 'preparing' ||
            order.status == 'ready' ||
            order.status == 'delivering',
      )
      .toList();
  List<Order> get historyOrders => _orders
      .where(
        (order) => order.status == 'completed' || order.status == 'cancelled',
      )
      .toList();

  RiderControllerSocket() {
    _api = RiderOrdersApi(BaseAPI_URL.baseURL);
  }

  // Initialize socket connection and start auto-refresh
  Future<void> initializeSocket() async {
    try {
      _setLoading(true);
      _clearError();

      // Check connection
      bool connected = await _api.checkConnection();
      _isSocketConnected = connected;

      if (connected) {
        await fetchOrdersByRider();
        _startAutoRefresh();
      } else {
        _setError('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
      }
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch orders for rider
  Future<void> fetchOrdersByRider() async {
    try {
      _setLoading(true);
      _clearError();

      // Get rider ID from AuthService
      final authService = AuthService();
      int? riderId = await authService.getRiderId();

      if (riderId == null) {
        _setError('ไม่พบข้อมูลผู้ขับขี่');
        print('❌ No rider_id found after checking AuthService');
        return;
      }

      print('✅ Found rider_id: $riderId');
      List<Map<String, dynamic>> ordersData = await _api.fetchJobs(
        riderId: riderId,
      );
      _orders = ordersData
          .map((orderData) => Order.fromJson(orderData))
          .toList();
      print('✅ Orders loaded: ${_orders.length} orders');

      // If no orders, just leave empty (don't show error)
      if (_orders.isEmpty) {
        print('📭 No orders available at the moment');
      }
    } catch (e) {
      _setError('เกิดข้อผิดพลาด: ${e.toString()}');
      print('❌ Error fetching orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      _setLoading(true);
      _clearError();

      // Get rider ID from AuthService
      final authService = AuthService();
      int? riderId = await authService.getRiderId();

      if (riderId == null) {
        _setError('ไม่พบข้อมูลผู้ขับขี่');
        return false;
      }

      await _api.updateStatus(
        orderId: orderId,
        riderId: riderId,
        status: newStatus,
      );

      // Update local order status
      int index = _orders.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        // Create new order with updated status
        Map<String, dynamic> updatedOrderData = _orders[index].toJson();
        updatedOrderData['status'] = newStatus;
        _orders[index] = Order.fromJson(updatedOrderData);
        notifyListeners();
      }

      print('✅ Order $orderId status updated to $newStatus');
      return true;
    } catch (e) {
      _setError('เกิดข้อผิดพลาด: ${e.toString()}');
      print('❌ Error updating order status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Accept order
  Future<bool> acceptOrder(int orderId) async {
    try {
      _setLoading(true);
      _clearError();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? riderId = prefs.getInt('rider_id');

      if (riderId == null) {
        _setError('ไม่พบข้อมูลผู้ขับขี่');
        return false;
      }

      Map<String, dynamic> response = await _api.acceptJob(
        orderId: orderId,
        riderId: riderId,
      );

      if (response['success'] == true || response['status'] == 'success') {
        await fetchOrdersByRider(); // Refresh orders
        print('✅ Order $orderId accepted');
        return true;
      } else {
        _setError(response['message'] ?? 'ไม่สามารถรับงานได้');
        return false;
      }
    } catch (e) {
      _setError('เกิดข้อผิดพลาด: ${e.toString()}');
      print('❌ Error accepting order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Start auto-refresh timer
  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isSocketConnected) {
        fetchOrdersByRider();
      }
    });
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error state
  void clearError() {
    _clearError();
  }

  // Retry connection
  Future<void> retry() async {
    await initializeSocket();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
