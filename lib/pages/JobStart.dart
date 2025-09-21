// Fixed JobStart.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import '../APIs/Orders/models/Order_items.dart';

class JobStartPage extends StatefulWidget {
  final int riderId;

  const JobStartPage({
    super.key,
    required this.riderId,
  });

  @override
  State<JobStartPage> createState() => _JobStartPageState();
}

class _JobStartPageState extends State<JobStartPage> {
  late RiderControllerSocket _controller;
  double _todayEarnings = 0.0;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<RiderControllerSocket>(context, listen: false);
    
    // Delay initialization to avoid disposal issues
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
      print('🚀 Starting rider initialization for rider ${widget.riderId}');
      
      // First try to connect socket
      await _controller.initializeSocket(riderId: widget.riderId);
      
      if (!mounted) return;
      
      // Then fetch orders
      await _controller.fetchOrdersByRider(riderId: widget.riderId);
      
      if (!mounted) return;
      
      // Calculate today's earnings
      _calculateTodayEarnings();
      
      print('✅ Rider initialization completed successfully');
      
    } catch (e) {
      print('❌ Rider initialization failed: $e');
      if (mounted) {
        // Show error to user but don't prevent them from using the app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เชื่อมต่อไม่สำเร็จ: จะลองใหม่อัตโนมัติ'),
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

  void _calculateTodayEarnings() {
    final today = DateTime.now();
    final completedOrdersToday = _controller.orders.where((order) {
      return order.isCompleted && 
             order.updatedAt.year == today.year &&
             order.updatedAt.month == today.month &&
             order.updatedAt.day == today.day;
    });

    double totalEarnings = 0.0;
    for (var order in completedOrdersToday) {
      // Calculate rider earning (assume rider gets 80% of delivery fee)
      totalEarnings += (order.deliveryFee * 0.8);
    }
    
    setState(() {
      _todayEarnings = totalEarnings;
    });
  }

  String _getPaymentTypeText(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return 'เงินสด';
      case 'transfer':
      case 'online':
        return 'เงินโอน';
      case 'credit_card':
        return 'บัตรเครดิต';
      default:
        return paymentMethod;
    }
  }

  Color _getPaymentTypeColor(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'transfer':
      case 'online':
        return Colors.blue;
      case 'credit_card':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getPickupTitle(Order order) {
    if (order.distanceKm != null) {
      return 'ไปร้าน ${order.distanceKm!.toStringAsFixed(2)} กม.';
    }
    return 'ไปร้าน';
  }

  double _calculateRiderEarning(Order order) {
    // Assume rider gets 80% of delivery fee
    return order.deliveryFee * 0.8;
  }

  double _calculateBonus(Order order) {
    // Bonus calculation based on distance or other conditions
    if (order.distanceKm != null && order.distanceKm! > 2.0) {
      return 5.0; // Bonus for long distance
    }
    return 0.0;
  }

  Future<void> _acceptJob(Order order) async {
    if (!mounted) return;
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update order status to rider_assigned
      bool success = await _controller.updateOrderStatus(
        order.orderId,
        'rider_assigned',
        additionalData: {'rider_id': widget.riderId},
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success && mounted) {
        // Navigate to GoRestaurant page with order data
        Navigator.pushNamed(
          context,
          '/GoRestaurant',
          arguments: {
            'order': order,
            'riderId': widget.riderId,
          },
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถรับงานได้: ${_controller.error ?? 'เกิดข้อผิดพลาด'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
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

  Future<void> _refreshData() async {
    if (!mounted) return;
    await _controller.fetchOrdersByRider(riderId: widget.riderId);
    _calculateTodayEarnings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  // Safely dispose and navigate back
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Consumer<RiderControllerSocket>(
        builder: (context, controller, child) {
          // Show loading while initializing
          if (_isInitializing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังเตรียมระบบ...'),
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
                  Text('กำลังโหลดงาน...'),
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
                    child: Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                    ),
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

          // Filter orders available for pickup
          final availableOrders = controller.orders.where((order) {
            return order.status == 'ready_for_pickup' || 
                   order.status == 'accepted' ||
                   order.status == 'preparing' ||
                   order.status == 'confirmed';
          }).toList();

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Earnings summary
                    Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.green, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รายได้วันนี้',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '฿${_todayEarnings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Socket connection status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: controller.isSocketConnected ? Colors.green : Colors.red,
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
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                                elevation: 2,
                              ),
                              onPressed: () {
                                // Safely close and navigate back
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.power_settings_new,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF6F5F5), thickness: 6),
                    const SizedBox(height: 16),

                    // Available jobs count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'งานที่มีให้: ${availableOrders.length} งาน',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Job list
                    if (availableOrders.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.work_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'ไม่มีงานในขณะนี้',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'ดึงลงเพื่อรีเฟรช หรือรอสักครู่...',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    else
                      ...availableOrders.map((order) {
                        final riderEarning = _calculateRiderEarning(order);
                        final bonus = _calculateBonus(order);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Payment type and shop pay
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getPaymentTypeColor(order.paymentMethod)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getPaymentTypeText(order.paymentMethod),
                                          style: TextStyle(
                                            color: _getPaymentTypeColor(order.paymentMethod),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'จ่ายให้ร้าน ฿${order.totalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Earnings
                                  Row(
                                    children: [
                                      const Text(
                                        'รายรับ ',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '฿${riderEarning.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        '  +  ',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        'โบนัส ',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '฿${bonus.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Pickup location
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.green,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getPickupTitle(order),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              order.shopName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Dropoff location
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ที่อยู่ลูกค้า',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              order.address,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Order items summary
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'รายการสินค้า: ${order.items.length} รายการ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Accept job button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => _acceptJob(order),
                                      child: const Text(
                                        'รับงานนี้',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the controller here as it might be used elsewhere
    print('📱 JobStartPage disposed');
    super.dispose();
  }
}