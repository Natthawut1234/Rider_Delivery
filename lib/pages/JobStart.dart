import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import 'package:rider_delivery/APIs/Orders/models/Order_items.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';
import 'package:provider/provider.dart';

class RiderJobsPage extends StatefulWidget {
  final int riderId;
  
  const RiderJobsPage({Key? key, required this.riderId}) : super(key: key);

  @override
  _RiderJobsPageState createState() => _RiderJobsPageState();
}

class _RiderJobsPageState extends State<RiderJobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  late RiderControllerSocket _orderController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _orderController = RiderControllerSocket();
    _initializeRider();
  }

  Future<void> _initializeRider() async {
    try {
      // Check rider approval status first
      final status = await RiderStatusService.getCurrentStatus();
      if (status != RiderStatus.approved) {
        _showApprovalRequiredDialog();
        return;
      }

      // Get current location
      await _getCurrentLocation();
      
      // Initialize socket connection
      await _orderController.initializeSocket(riderId: widget.riderId);
      
      // Fetch available orders
      await _fetchOrders();
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเริ่มต้น: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('บริการตำแหน่งไม่เปิดใช้งาน');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('ไม่ได้รับอนุญาตให้ใช้ตำแหน่ง');
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('📍 Current location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    } catch (e) {
      print('❌ Location error: $e');
      _showErrorSnackBar('ไม่สามารถรับตำแหน่งปัจจุบันได้: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _fetchOrders() async {
    if (_currentPosition != null) {
      await _orderController.fetchOrdersByRider(riderId: widget.riderId);
    }
  }

  Future<void> _acceptOrder(Order order) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _orderController.updateOrderStatus(
        order.orderId,
        'rider_assigned',
        additionalData: {'rider_id': widget.riderId},
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        _showSuccessSnackBar('รับงานสำเร็จ!');
        await _fetchOrders(); // Refresh orders
      } else {
        _showErrorSnackBar('ไม่สามารถรับงานได้: ${_orderController.error}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _updateOrderStatus(Order order, String status) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _orderController.updateOrderStatus(
        order.orderId,
        status,
      );

      Navigator.of(context).pop();

      if (success) {
        _showSuccessSnackBar('อัปเดตสถานะสำเร็จ!');
        await _fetchOrders();
      } else {
        _showErrorSnackBar('ไม่สามารถอัปเดตสถานะได้: ${_orderController.error}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showApprovalRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ยังไม่ได้รับการอนุมัติ'),
        content: const Text(
          'คุณต้องได้รับการอนุมัติจากทีมงานก่อนจึงจะสามารถรับงานได้\nกรุณาตรวจสอบสถานะการอนุมัติ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
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
        appBar: AppBar(
          title: const Text('งานส่งอาหาร'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
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
                return Stack(
                  children: [
                    IconButton(
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
                    ),
                    if (controller.isSocketConnected)
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.green,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<RiderControllerSocket>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.orders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        controller.clearError();
                        await _fetchOrders();
                      },
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              );
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

  Widget _buildAvailableOrdersTab(RiderControllerSocket controller) {
    // Orders that are available for riders to pick up
    final availableOrders = controller.orders
        .where((order) => 
            order.riderId == null && 
            ['confirmed', 'accepted', 'preparing', 'ready_for_pickup'].contains(order.status))
        .toList();

    if (availableOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ไม่มีงานใหม่ในขณะนี้',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'ลากลงเพื่อรีเฟรช',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _getCurrentLocation();
        await _fetchOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableOrders.length,
        itemBuilder: (context, index) {
          final order = availableOrders[index];
          return _buildAvailableOrderCard(order);
        },
      ),
    );
  }

  Widget _buildMyOrdersTab(RiderControllerSocket controller) {
    // Orders assigned to this rider
    final myOrders = controller.orders
        .where((order) => 
            order.riderId == widget.riderId && 
            !['completed', 'cancelled'].contains(order.status))
        .toList();

    if (myOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'คุณไม่มีงานที่กำลังดำเนินการ',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myOrders.length,
        itemBuilder: (context, index) {
          final order = myOrders[index];
          return _buildMyOrderCard(order);
        },
      ),
    );
  }

  Widget _buildHistoryTab(RiderControllerSocket controller) {
    // Completed and cancelled orders
    final historyOrders = controller.orders
        .where((order) => 
            order.riderId == widget.riderId && 
            ['completed', 'cancelled'].contains(order.status))
        .toList();

    if (historyOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ยังไม่มีประวัติการส่ง',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyOrders.length,
        itemBuilder: (context, index) {
          final order = historyOrders[index];
          return _buildHistoryOrderCard(order);
        },
      ),
    );
  }

  Widget _buildAvailableOrderCard(Order order) {
    // Calculate distance if current position is available
    double? distanceToShop;
    double? distanceToCustomer;
    
    if (_currentPosition != null && 
        order.marketLocation?['latitude'] != null && 
        order.marketLocation?['longitude'] != null) {
      distanceToShop = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        double.parse(order.marketLocation!['latitude'].toString()),
        double.parse(order.marketLocation!['longitude'].toString()),
      ) / 1000; // Convert to km
      
      if (order.customerLocation?['latitude'] != null && 
          order.customerLocation?['longitude'] != null) {
        distanceToCustomer = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          double.parse(order.customerLocation!['latitude'].toString()),
          double.parse(order.customerLocation!['longitude'].toString()),
        ) / 1000; // Convert to km
      }
    }

    // Calculate estimated earnings (80% of delivery fee)
    final estimatedEarning = (order.deliveryFee * 0.8).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.shopName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusText,
                    style: TextStyle(
                      color: order.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Earning and distance info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, 
                                color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'รายได้: ฿$estimatedEarning',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (distanceToShop != null)
                          Row(
                            children: [
                              const Icon(Icons.store, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                'ห่างจากร้าน: ${distanceToShop.toStringAsFixed(1)} กม.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        if (distanceToCustomer != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'ห่างจากลูกค้า: ${distanceToCustomer.toStringAsFixed(1)} กม.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Order details
            _buildOrderDetailsSection(order),
            const SizedBox(height: 16),

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showAcceptOrderDialog(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'รับงาน',
                  style: TextStyle(
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.shopName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusText,
                    style: TextStyle(
                      color: order.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Order details
            _buildOrderDetailsSection(order),
            const SizedBox(height: 16),

            // Action buttons based on status
            _buildStatusActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryOrderCard(Order order) {
    final isCompleted = order.status == 'completed';
    final earnings = isCompleted ? (order.deliveryFee * 0.8).round() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.shopName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.statusText,
                        style: TextStyle(
                          color: order.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 4),
                      Text(
                        '฿$earnings',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              'วันที่: ${_formatDate(order.createdAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              'ที่อยู่: ${order.address}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.address,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Payment method
        Row(
          children: [
            const Icon(Icons.payment, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Text(
              'ชำระเงิน: ${order.paymentMethod}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Order items
        if (order.items.isNotEmpty) ...[
          const Text(
            'รายการอาหาร:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ...order.items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Text(
              '• ${item.foodName} x${item.quantity}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          )),
          if (order.items.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'และอีก ${order.items.length - 3} รายการ',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],

        const SizedBox(height: 8),

        // Total price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ยอดรวม:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '฿${order.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusActionButtons(Order order) {
    switch (order.status) {
      case 'rider_assigned':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order, 'going_to_shop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('เริ่มเดินทางไปร้าน'),
              ),
            ),
          ],
        );

      case 'going_to_shop':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order, 'arrived_at_shop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ถึงร้านแล้ว'),
              ),
            ),
          ],
        );

      case 'arrived_at_shop':
      case 'ready_for_pickup':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order, 'picked_up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('รับอาหารแล้ว'),
              ),
            ),
          ],
        );

      case 'picked_up':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order, 'delivering'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('เริ่มจัดส่ง'),
              ),
            ),
          ],
        );

      case 'delivering':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order, 'arrived_at_customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ถึงลูกค้าแล้ว'),
              ),
            ),
          ],
        );

      case 'arrived_at_customer':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order, 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ส่งเสร็จแล้ว'),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _showAcceptOrderDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันรับงาน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ร้าน: ${order.shopName}'),
            const SizedBox(height: 8),
            Text('รายได้: ฿${(order.deliveryFee * 0.8).round()}'),
            const SizedBox(height: 8),
            Text('ที่อยู่จัดส่ง: ${order.address}'),
            const SizedBox(height: 16),
            const Text(
              'คุณต้องการรับงานนี้หรือไม่?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _acceptOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยันรับงาน'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Additional models needed for the UI
extension OrderExtensions on Order {
  // Market location data from API
  Map<String, dynamic>? get marketLocation {
    // This would come from the API response
    // For now, returning null - should be populated from API
    return null;
  }
  
  // Customer location data from API  
  Map<String, dynamic>? get customerLocation {
    // This would come from the API response
    // For now, returning null - should be populated from API
    return null;
  }
}