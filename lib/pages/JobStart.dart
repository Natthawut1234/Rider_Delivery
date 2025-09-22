// JobStartPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import '../APIs/Orders/models/Order_items.dart';

class JobStartPage extends StatefulWidget {
  final int riderId;

  const JobStartPage({super.key, required this.riderId});

  @override
  State<JobStartPage> createState() => _JobStartPageState();
}

class _JobStartPageState extends State<JobStartPage>
    with TickerProviderStateMixin {
  late RiderControllerSocket _controller;
  late TabController _tabController;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _controller = Provider.of<RiderControllerSocket>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeRider();
      }
    });
  }

  Future<void> _initializeRider() async {
    if (_isInitializing || !mounted) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      print(
        '🚀 Starting rider status initialization for rider ${widget.riderId}',
      );

      await _controller.initializeSocket(riderId: widget.riderId);

      if (!mounted) return;

      await _controller.fetchOrdersByRider(riderId: widget.riderId);

      print('✅ Rider status initialization completed successfully');
    } catch (e) {
      print('❌ Rider status initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เชื่อมต่อไม่สำเร็จ: $e'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    await _controller.fetchOrdersByRider(riderId: widget.riderId);
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return 'รอการยืนยัน';
      case 'confirmed':
      case 'accepted':
        return 'ร้านรับออเดอร์แล้ว';
      case 'rider_assigned':
        return 'คุณได้รับงานแล้ว';
      case 'going_to_shop':
        return 'กำลังไปร้าน';
      case 'arrived_at_shop':
        return 'ถึงร้านแล้ว';
      case 'preparing':
        return 'ร้านกำลังเตรียมอาหาร';
      case 'ready_for_pickup':
        return 'พร้อมให้รับ';
      case 'picked_up':
        return 'รับของแล้ว';
      case 'delivering':
        return 'กำลังจัดส่ง';
      case 'arrived_at_customer':
        return 'ถึงที่ลูกค้าแล้ว';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
      case 'preparing':
        return Colors.blue;
      case 'rider_assigned':
        return Colors.purple;
      case 'going_to_shop':
      case 'arrived_at_shop':
        return Colors.indigo;
      case 'ready_for_pickup':
      case 'picked_up':
        return Colors.teal;
      case 'delivering':
      case 'arrived_at_customer':
        return Colors.cyan;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with order ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ออเดอร์ #${order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Shop info
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (order.distanceKm != null)
                        Text(
                          'ระยะทาง ${order.distanceKm!.toStringAsFixed(1)} กม.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
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
            const SizedBox(height: 12),

            // Order details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'รายการสินค้า:',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text('${order.items.length} รายการ'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ยอดรวม:',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        '฿${order.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'รายได้คุณ:',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        '฿${(order.deliveryFee * 0.8).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons based on status
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    switch (order.status) {
      case 'rider_assigned':
        return _buildButton(
          'ไปร้าน',
          Colors.blue,
          () => _updateOrderStatus(order.orderId, 'going_to_shop'),
        );

      case 'going_to_shop':
        return _buildButton(
          'ถึงร้านแล้ว',
          Colors.indigo,
          () => _updateOrderStatus(order.orderId, 'arrived_at_shop'),
        );

      case 'arrived_at_shop':
      case 'preparing':
        return _buildButton(
          'รอร้านเตรียมของ...',
          Colors.grey,
          null,
          icon: Icons.access_time,
        );

      case 'ready_for_pickup':
        return _buildButton(
          'รับของแล้ว',
          Colors.teal,
          () => _updateOrderStatus(order.orderId, 'picked_up'),
        );

      case 'picked_up':
        return _buildButton(
          'เริ่มจัดส่ง',
          Colors.cyan,
          () => _updateOrderStatus(order.orderId, 'delivering'),
        );

      case 'delivering':
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                'ถึงที่ลูกค้า',
                Colors.orange,
                () => _updateOrderStatus(order.orderId, 'arrived_at_customer'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildButton(
                'จัดส่งเสร็จ',
                Colors.green,
                () => _updateOrderStatus(order.orderId, 'completed'),
              ),
            ),
          ],
        );

      case 'arrived_at_customer':
        return _buildButton(
          'จัดส่งเสร็จ',
          Colors.green,
          () => _updateOrderStatus(order.orderId, 'completed'),
        );

      case 'completed':
        return _buildButton(
          'เสร็จสิ้น',
          Colors.green,
          null,
          icon: Icons.check_circle,
        );

      case 'cancelled':
        return _buildButton('ยกเลิกแล้ว', Colors.red, null, icon: Icons.cancel);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildButton(
    String text,
    Color color,
    VoidCallback? onPressed, {
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: onPressed != null ? 2 : 0,
        ),
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 20)
            : const SizedBox(width: 20, height: 20),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    if (!mounted) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      bool success = await _controller.updateOrderStatus(
        orderId,
        newStatus,
        additionalData: {'rider_id': widget.riderId},
      );

      // Close loading
      if (mounted) Navigator.of(context).pop();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัพเดทสถานะเป็น ${_getStatusText(newStatus)} แล้ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถอัพเดทสถานะได้: ${_controller.error ?? 'เกิดข้อผิดพลาด'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Order> _getOrdersByStatus(String status) {
    switch (status) {
      case 'active':
        return _controller.orders.where((order) {
          return [
            'rider_assigned',
            'going_to_shop',
            'arrived_at_shop',
            'preparing',
            'ready_for_pickup',
            'picked_up',
            'delivering',
            'arrived_at_customer',
          ].contains(order.status);
        }).toList();

      case 'completed':
        return _controller.orders
            .where((order) => order.status == 'completed')
            .toList();

      case 'cancelled':
        return _controller.orders
            .where((order) => order.status == 'cancelled')
            .toList();

      case 'all':
      default:
        return _controller.orders;
    }
  }

  Widget _buildOrdersList(String status) {
    final orders = _getOrdersByStatus(status);

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'active'
                  ? Icons.work_off
                  : status == 'completed'
                  ? Icons.check_circle_outline
                  : status == 'cancelled'
                  ? Icons.cancel_outlined
                  : Icons.list_alt,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              status == 'active'
                  ? 'ไม่มีงานที่กำลังทำ'
                  : status == 'completed'
                  ? 'ยังไม่มีงานที่เสร็จ'
                  : status == 'cancelled'
                  ? 'ไม่มีงานที่ยกเลิก'
                  : 'ไม่มีออเดอร์',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text('ดึงลงเพื่อรีเฟรช', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text(
          'สถานะงาน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Consumer<RiderControllerSocket>(
            builder: (context, controller, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: controller.isSocketConnected
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.isSocketConnected ? 'ออนไลน์' : 'ออฟไลน์',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'รอรับ'), // ⬅️ ใหม่
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'กำลังทำ'),
            Tab(text: 'เสร็จแล้ว'),
            Tab(text: 'ยกเลิก'),
          ],
        ),
      ),
      body: Consumer<RiderControllerSocket>(
        builder: (context, controller, child) {
          if (_isInitializing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังโหลดสถานะงาน...'),
                ],
              ),
            );
          }

          if (controller.isLoading && controller.orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังโหลดข้อมูล...'),
                ],
              ),
            );
          }

          if (controller.error != null && controller.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(controller.error!, textAlign: TextAlign.center),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeRider,
                    child: Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList('waiting'),
                _buildOrdersList('all'),
                _buildOrdersList('active'),
                _buildOrdersList('completed'),
                _buildOrdersList('cancelled'),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    print('📱 JobStartPage disposed');
    super.dispose();
  }
}
