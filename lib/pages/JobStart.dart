import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import 'package:rider_delivery/APIs/Orders/models/Order_items.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';
import 'package:provider/provider.dart';

class RiderJobsPage extends StatefulWidget {
  final int riderId;
  final int initialTabIndex;

  const RiderJobsPage({
    Key? key,
    required this.riderId,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  _RiderJobsPageState createState() => _RiderJobsPageState();
}

// ignore_for_file: unused_field, unused_element

class _RiderJobsPageState extends State<RiderJobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  late RiderControllerSocket _orderController;
  double _thisSubprice(Order order) {
    return order.items.fold(0.0, (sum, item) => sum + item.subtotal);
  }
  // ราคา original_total_price

  // Helpers to include selected option prices in per-item total
  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  double _optionsExtraPerUnit(OrderItem item) {
    if (item.selectedOptions.isEmpty) return 0.0;
    return item.selectedOptions
        .map((o) => _asDouble((o as Map?)?['extraPrice']))
        .fold(0.0, (a, b) => a + b);
  }

  double _itemTotalWithOptions(OrderItem item) {
    final extrasPerUnit = _optionsExtraPerUnit(item);
    // Total = (base per unit + extras per unit) * quantity
    return (item.sellPrice + extrasPerUnit) * item.quantity;
  }

  // Order-level totals: base price and option extras
  double _orderBasePrice(Order order) {
    if (order.basePrice != null) return order.basePrice!.toDouble();
    return order.items.fold(
      0.0,
      (sum, item) => sum + ((item.basePrice ?? item.sellPrice) * item.quantity),
    );
  }

  double _orderOptionsExtras(Order order) {
    return order.items.fold(
      0.0,
      (sum, item) => sum + (_optionsExtraPerUnit(item) * item.quantity),
    );
  }

  // Green theme colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundGreen = Color(0xFFE8F5E8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _orderController = RiderControllerSocket();
    _initializeRider();
  }

  Future<void> _initializeRider() async {
    try {
      print('🚀 [Init] เริ่ม _initializeRider()');
      print('➡️ [Init] Rider widget.riderId = ${widget.riderId}');

      final status = await RiderStatusService.getCurrentStatus();
      print('📊 [Init] Current rider status = $status');

      if (status != RiderStatus.approved) {
        _showApprovalRequiredDialog();
        return;
      }

      await _getCurrentLocation();

      // ✅ connect socket + register_rider
      await _orderController.initializeSocket(riderId: widget.riderId);

      // ดึง orders ล่าสุด
      await _fetchOrders();

      // ติดตาม real-time update
      _setupRiderOrdersWatcher();

      print('🎉 [Init] Rider initialization completed successfully');
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _setupRiderOrdersWatcher() {
    // Watch rider's assigned orders for real-time updates
    final myOrders = _orderController.orders
        .where((order) => order.riderId == widget.riderId)
        .toList();

    for (var order in myOrders) {
      _orderController.watchOrder(order.orderId);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('บริการตำแหน่งไม่เปิด');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('ไม่อนุญาตใช้ตำแหน่ง');
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      _showErrorSnackBar('ไม่สามารถรับตำแหน่งได้: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchOrders() async {
    await _orderController.fetchOrdersByRider(riderId: widget.riderId);
  }

  Future<void> _updateOrderStatus(Order order, String status) async {
    _showLoadingDialog();
    try {
      final result = await _orderController.updateOrderStatus(
        order.orderId,
        status,
      );
      Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessSnackBar('อัปเดตสำเร็จ!');
        await _fetchOrders();
      } else {
        _showErrorSnackBar('อัปเดตไม่สำเร็จ');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: lightGreen)),
    );
  }

  void _showApprovalRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ยังไม่ได้รับอนุมัติ'),
        content: const Text('กรุณาตรวจสอบสถานะการอนุมัติ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: lightGreen),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _orderController,
      child: Scaffold(
        backgroundColor: backgroundGreen,
        appBar: AppBar(
          title: const Text(
            'งานส่งอาหาร',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'งานใหม่', icon: Icon(Icons.new_releases)),
              Tab(text: 'งานของฉัน', icon: Icon(Icons.assignment)),
              Tab(text: 'ประวัติ', icon: Icon(Icons.history)),
            ],
          ),
          actions: [
            Consumer<RiderControllerSocket>(
              builder: (context, controller, _) {
                return IconButton(
                  onPressed: () async {
                    await _getCurrentLocation();
                    await _fetchOrders();
                  },
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                );
              },
            ),
          ],
        ),
        body: Consumer<RiderControllerSocket>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.orders.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: lightGreen),
              );
            }

            if (controller.error != null) {
              return _buildErrorWidget(controller);
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableOrdersTab(controller),
                _buildMyOrdersTab(controller),
                _buildHistoryTab(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(RiderControllerSocket controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('เกิดข้อผิดพลาด', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              controller.clearError();
              await _fetchOrders();
            },
            style: ElevatedButton.styleFrom(backgroundColor: lightGreen),
            child: const Text('ลองใหม่', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersTab(RiderControllerSocket controller) {
    final availableOrders = controller.orders
        .where(
          (order) =>
              order.riderId == null &&
              [
                'waiting',
                // 'confirmed',
                // 'accepted',
                // 'preparing',
                // 'ready_for_pickup',
              ].contains(order.status),
        )
        .toList();

    if (availableOrders.isEmpty) {
      return _buildEmptyState('ไม่มีงานใหม่', Icons.inbox);
    }

    return RefreshIndicator(
      color: lightGreen,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableOrders.length,
        itemBuilder: (context, index) =>
            _buildAvailableOrderCard(availableOrders[index]),
      ),
    );
  }

  Widget _buildMyOrdersTab(RiderControllerSocket controller) {
    final myOrders = controller.orders
        .where(
          (order) =>
              order.riderId == widget.riderId &&
              [
                'rider_assigned',
                'confirmed',
                'preparing',
                'ready_for_pickup',
                'going_to_shop',
                'arrived_at_shop',
                'picked_up',
                'delivering',
                'arrived_at_customer',
              ].contains(order.status),
        )
        .toList();

    if (myOrders.isEmpty) {
      return _buildEmptyState('ไม่มีงานที่รับไว้', Icons.assignment_outlined);
    }

    return RefreshIndicator(
      color: lightGreen,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myOrders.length,
        itemBuilder: (context, index) {
          final order = myOrders[index];
          // Watch each order for real-time updates
          controller.watchOrder(order.orderId);
          return _buildMyOrderCard(order);
        },
      ),
    );
  }

  Widget _buildHistoryTab(RiderControllerSocket controller) {
    final historyOrders = controller.orders
        .where(
          (order) =>
              order.riderId == widget.riderId &&
              ['completed', 'cancelled'].contains(order.status),
        )
        .toList();

    if (historyOrders.isEmpty) {
      return _buildEmptyState('ไม่มีประวัติ', Icons.history);
    }

    return RefreshIndicator(
      color: lightGreen,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyOrders.length,
        itemBuilder: (context, index) =>
            _buildHistoryCard(historyOrders[index]),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrderCard(Order order) {
    final distanceKm = order.distanceKm ?? 0.0;
    final earning = (order.deliveryFee);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.shopName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lightGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightGreen),
                  ),
                  child: Text(
                    _getCombinedStatusText(order),
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Earning & Distance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lightGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: lightGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '฿$earning',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.route, size: 16, color: primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} กม.',
                        style: const TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (order.bonus > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: lightGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.orange,
                          size: 18,
                        ),

                        const SizedBox(width: 8),
                        Text(
                          'เครดิตช่วยจ่าย ฿${order.bonus.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.address,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items summary
            if (order.items.isNotEmpty) ...[
              Text(
                'รายการ: ${order.items.length} เมนู  จ่ายให้ร้าน ฿${order.originalTotalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showAcceptDialog(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'รับงาน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrderCard(Order order) {
    final distanceKm = order.distanceKm ?? 0.0;
    final earning = (order.deliveryFee);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with order ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shopName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      Text(
                        'Order #${order.orderId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 8,
                //     vertical: 4,
                //   ),
                //   decoration: BoxDecoration(
                //     color: lightGreen.withOpacity(0.2),
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: lightGreen),
                //   ),
                //   child: Text(
                //     _getCombinedStatusText(order),
                //     style: const TextStyle(
                //       color: primaryGreen,
                //       fontSize: 12,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: lightGreen),
                  ),
                  child: Text(
                    '฿$earning',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                if (order.bonus > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      'เครดิตช่วยจ่าย ฿${order.bonus.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: lightGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightGreen),
              ),
              child: Text(
                _getCombinedStatusText(order),
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Restaurant info section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Updated color styling for restaurant section
                color: Colors.deepOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepOrange.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        color: Colors.deepOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ร้าน: ${order.shopName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        color: Colors.deepOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Builder(
                        builder: (_) {
                          final shopPhone = order.marketLocation?['phone']
                              ?.toString();
                          return Text(
                            shopPhone == null || shopPhone.isEmpty
                                ? 'ไม่มีเบอร์ร้าน'
                                : shopPhone,
                            style: const TextStyle(fontSize: 13),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Builder(
                          builder: (_) {
                            final shopAddress = order.marketLocation?['address']
                                ?.toString();
                            return Text(
                              shopAddress == null || shopAddress.isEmpty
                                  ? 'ไม่พบที่อยู่ร้าน'
                                  : shopAddress,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${distanceKm.toStringAsFixed(1)} กม.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Customer info section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        order.clientName != null
                            ? 'ลูกค้า: ${order.clientName}'
                            : 'ลูกค้า: ไม่ระบุ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // if (order.customerLocation?['name'] != null)
                      //   Text(
                      //     order.customerLocation!['name'],
                      //     style: const TextStyle(fontWeight: FontWeight.w500),
                      //   ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.blue, size: 14),
                      const SizedBox(width: 6),
                      if (order.customerLocation?['phone'] != null)
                        Text(
                          order.customerLocation!['phone'],
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.address,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${distanceKm.toStringAsFixed(1)} กม.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Delivery info
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.deliveryType,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payment,
                          color: Colors.purple,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.paymentMethod,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items with detailed options
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        color: primaryGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'รายการอาหารที่สั่ง:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${order.items.length} รายการ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => _buildDetailedItemCard(item)),
                  const Divider(color: lightGreen, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ค่าอาหารจ่ายให้ร้าน: ฿${(order.originalTotalPrice).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'ค่าส่ง: ฿${order.deliveryFee.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (order.bonus > 0)
                            Text(
                              'เครดิตช่วยจ่าย: ฿${order.bonus.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      // Text(
                      //   'รวมที่ต้องรับจากลูกค้า: ฿${order.totalPrice.toStringAsFixed(0)}',
                      //   style: const TextStyle(
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 16,
                      //     color: primaryGreen,
                      //   ),
                      // ),
                    ],
                  ),
                  const Divider(color: lightGreen, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'รวมที่ต้องรับจากลูกค้า: ฿${order.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Note section if available
            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, color: Colors.orange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'หมายเหตุพิเศษ:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(order.note!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Action button
            _buildActionButton(order),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lightGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.foodName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: primaryGreen,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Base price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ราคาขาย: ฿${item.sellPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                'รวม: ฿${_itemTotalWithOptions(item).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),

          // Selected options if any
          if (item.selectedOptions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_circle, color: accentGreen, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'ตัวเลือกเพิ่มเติม:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.selectedOptions.map((option) {
                      final label = option['label']?.toString() ?? '';
                      final extraPrice =
                          option['extraPrice']?.toString() ?? '0';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '$label (+฿$extraPrice)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          // Additional notes for the item if any
          if (item.additionalNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note, color: Colors.grey[700], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'เพิ่มเติม:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    children: [
                      Text(
                        item.additionalNotes,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemWithOptions(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.foodName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'x${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '฿${_itemTotalWithOptions(item).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.selectedOptions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Wrap(
                spacing: 6,
                children: item.selectedOptions.map((option) {
                  final label = option['label'] ?? '';
                  final price = option['extraPrice'] ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+$label (+฿$price)',
                      style: const TextStyle(fontSize: 11, color: primaryGreen),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Order order) {
    final isCompleted = order.status == 'completed';
    final earning = isCompleted ? (order.deliveryFee) : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 6,
                //     vertical: 2,
                //   ),
                //   decoration: BoxDecoration(
                //     color: _getStatusColor(order.status).withOpacity(0.2),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: Text(
                //     _getCombinedStatusText(order),
                //     style: TextStyle(
                //       fontSize: 10,
                //       color: _getStatusColor(order.status),
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
                if (isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    '฿$earning',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lightGreen,
                    ),
                  ),
                  if (order.bonus > 0) ...[
                    Text(
                      'เครดิตช่วยจ่าย ฿${order.bonus.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Order order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // ตรวจสอบสถานะ ถ้าอยู่ในขั้นตอนจัดส่งแล้ว ให้ไปหน้า GoCustomer โดยตรง
          if (['delivering', 'arrived_at_customer'].contains(order.status)) {
            final result = await Navigator.pushNamed(
              context,
              '/goCustomer',
              arguments: {
                'orderId': order.orderId,
                'riderId': widget.riderId,
                'orderNumber': order.orderId.toString(),
                'restaurantName': order.shopName,
                'customerName':
                    order.customerLocation?['name'] ??
                    order.clientName ??
                    'ลูกค้า',
                'titleCustomerAddress': 'ส่งถึง',
                'customerAddress':
                    order.customerLocation?['address'] ??
                    order.address ??
                    'ไม่ระบุที่อยู่',
                'deliveryType': order.deliveryType,
                'note': order.note ?? 'เพิ่มเติม: -',
                'earn': order.deliveryFee,
                'payAtShop': order.originalTotalPrice,
                'bonus': 0.0,
                'totalReceived': order.deliveryFee + order.originalTotalPrice,
                'payType': order.paymentMethod,
                'distance':
                    '${order.distanceKm?.toStringAsFixed(1) ?? '0.0'} กม.',
                'totalPrice': order.totalPrice,
                'deliveryFee': order.deliveryFee,
                'orderItems': order.items
                    .map(
                      (item) => {
                        'orderNumber': order.orderId.toString(),
                        'foodName': item.foodName,
                        'quantity': item.quantity,
                        'selectedOptions': item.selectedOptions,
                        'subtotal': item.subtotal,
                        'additionalNotes':
                            item.additionalNotes, // เพิ่ม additionalNotes
                      },
                    )
                    .toList(),
              },
            );
            // จัดการ result จาก GoCustomer
            if (result != null && result is Map<String, dynamic>) {
              if (result['switchToTab'] != null) {
                _tabController.animateTo(result['switchToTab']);
              }
              if (result['refreshData'] == true) {
                await _orderController.fetchOrdersByRider(
                  riderId: widget.riderId,
                );
              }
            }
          } else {
            // ส่งไปหน้า GoRestaurant สำหรับสถานะอื่นๆ
            final result = await Navigator.pushNamed(
              context,
              '/goRestaurant',
              arguments: {'orderId': order.orderId, 'riderId': widget.riderId},
            );
            // จัดการ result จาก GoRestaurant
            if (result != null && result is Map<String, dynamic>) {
              if (result['switchToTab'] != null) {
                _tabController.animateTo(result['switchToTab']);
              }
              if (result['refreshData'] == true) {
                await _orderController.fetchOrdersByRider(
                  riderId: widget.riderId,
                );
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: lightGreen,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.visibility, color: Colors.white),
        label: const Text(
          'ดูรายละเอียดงาน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAcceptDialog(Order order) {
    final earning = (order.deliveryFee);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ยืนยันรับงาน',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ร้าน: ${order.shopName}'),
            // รายได้ และแสดงโบนัสถ้ามี
            Builder(
              builder: (_) {
                final bonus = order.bonus;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('รายได้: ฿${earning.toStringAsFixed(0)}'),
                    if (bonus > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'เครดิตช่วยจ่าย: ฿${bonus.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ],
                );
              },
            ),
            Text('ระยะทาง: ${(order.distanceKm ?? 0).toStringAsFixed(1)} กม.'),
            if (order.bonus > 0) ...[
              Text(
                'เหลือเครดิตที่ต้องใช้: ${order.riderRequiredGp.toStringAsFixed(0)} เครดิต',
                style: TextStyle(color: Colors.green[600]),
              ),
            ] else ...[
              Text(
                'เครดิตที่ต้องใช้: ${order.riderRequiredGp.toStringAsFixed(0)} เครดิต',
                style: TextStyle(color: Colors.green[600]),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'คุณต้องการรับงานนี้หรือไม่?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _orderController.assignRider(
                order.orderId,
                widget.riderId,
              );
              if (success) {
                _showSuccessSnackBar('รับงานสำเร็จ!');
                await _fetchOrders();
              } else {
                _showErrorSnackBar('ไม่สามารถรับงานได้');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: lightGreen),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return primaryGreen;
      case 'cancelled':
        return Colors.red;
      case 'rider_assigned':
        return lightGreen;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return 'ออเดอร์ใหม่';
      case 'confirmed':
        return 'ยืนยันแล้ว';
      case 'accepted':
        return 'รับออเดอร์';
      case 'rider_assigned':
        return 'รอยืนยัน';
      // case 'rider_assigned':
      //   return 'มีไรเดอร์';
      case 'preparing':
        return 'กำลังทำ';
      case 'ready_for_pickup':
        return 'พร้อมรับ';
      case 'going_to_shop':
        return 'กำลังไปที่ร้าน';
      case 'arrived_at_shop':
        return 'ถึงร้านแล้ว';
      case 'picked_up':
        return 'รับอาหารแล้ว';
      case 'delivering':
        return 'กำลังส่ง';
      case 'arrived_at_customer':
        return 'ถึงลูกค้าแล้ว';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  String _getShopStatusText(String? shopStatus) {
    if (shopStatus == null || shopStatus.isEmpty) return '';
    switch (shopStatus) {
      case 'preparing':
        return 'ร้านกำลังเตรียมอาหาร';
      case 'ready_for_pickup':
        return 'ร้านเตรียมเสร็จแล้ว';
      // case 'confirmed':
      //   return 'ร้านยืนยันออเดอร์';
      // case 'pending':
      //   return 'รอร้านยืนยัน';
      default:
        return shopStatus;
    }
  }

  String _getCombinedStatusText(Order order) {
    final orderStatusText = _getStatusText(order.status);
    final shopStatusText = _getShopStatusText(order.shopStatus);

    if (shopStatusText.isNotEmpty) {
      return '$orderStatusText • $shopStatusText';
    }
    return orderStatusText;
  }
}
