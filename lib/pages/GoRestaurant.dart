import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import 'package:rider_delivery/APIs/Orders/models/Order_items.dart';

class GoRestaurant extends StatefulWidget {
  const GoRestaurant({super.key});

  @override
  _GoRestaurantState createState() => _GoRestaurantState();
}

class _GoRestaurantState extends State<GoRestaurant> {
  int? orderId;
  int? riderId;
  Order? currentOrder;
  RiderControllerSocket? _orderController;
  bool arrivedAtRestaurant = false;
  bool confirmedArrival = false;
  bool _isLoading = true;
  double get itemsSubtotal {
    return orderItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (orderId == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        orderId = args['orderId'];
        riderId = args['riderId'];
        print(
          'GoRestaurant: Received orderId: $orderId, riderId: $riderId',
        ); // Debug
        _initializeData();
      } else {
        print('GoRestaurant: No arguments received'); // Debug
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeData() {
    _orderController = Provider.of<RiderControllerSocket>(
      context,
      listen: false,
    );
    print('GoRestaurant: Controller initialized'); // Debug
    _loadOrderData();
  }

  void _loadOrderData() async {
    if (orderId == null || _orderController == null) {
      print('GoRestaurant: orderId or controller is null'); // Debug
      setState(() => _isLoading = false);
      return;
    }

    print(
      'GoRestaurant: Looking for order $orderId in ${_orderController!.orders.length} orders',
    ); // Debug

    // Print all available orders for debugging
    for (var order in _orderController!.orders) {
      print(
        'Available order: ${order.orderId} - Status: ${order.status} - Rider: ${order.riderId}',
      );
    }

    // หาข้อมูลออเดอร์จาก controller
    Order? order;
    try {
      order = _orderController!.orders
          .where((o) => o.orderId == orderId)
          .firstOrNull;
    } catch (e) {
      print('Error finding order: $e'); // Debug
    }

    // ถ้าไม่พบในรายการ ลองดึงข้อมูลใหม่
    if (order == null) {
      print(
        'GoRestaurant: Order not found in current list, fetching fresh data...',
      ); // Debug
      try {
        await _orderController!.fetchOrdersByRider(riderId: riderId!);
        // ลองหาใหม่หลังจากดึงข้อมูล
        order = _orderController!.orders
            .where((o) => o.orderId == orderId)
            .firstOrNull;
      } catch (e) {
        print('Error fetching orders: $e'); // Debug
      }
    }

    setState(() {
      currentOrder = order;
      _isLoading = false;
    });

    if (order != null) {
      print('GoRestaurant: Order found - ${order.shopName}'); // Debug
      // เริ่ม watch order สำหรับการอัปเดตแบบ real-time
      _orderController!.watchOrder(orderId!);
    } else {
      print('GoRestaurant: Order still not found after fetch'); // Debug
    }
  }

  // ฟังก์ชันช่วยอ่านข้อมูลปลอดภัย
  String get restaurantName => currentOrder?.shopName ?? 'ร้านอาหาร';
  String get restaurantAddress =>
      currentOrder?.marketLocation?['address'] ?? 'ไม่ระบุที่อยู่';
  String get customerName =>
      currentOrder?.customerLocation?['name'] ?? 'ลูกค้า';
  String get customerPhone => currentOrder?.customerLocation?['phone'] ?? '';
  String get customerAddress => currentOrder?.address ?? 'ไม่ระบุที่อยู่';
  String get paymentMethod => currentOrder?.paymentMethod ?? 'เงินสด';
  String get deliveryType => currentOrder?.deliveryType ?? 'ส่งถึงที่';
  double get totalPrice => currentOrder?.totalPrice ?? 0.0;
  double get deliveryFee => currentOrder?.deliveryFee ?? 0.0;
  int get shopPayAmount => (totalPrice - deliveryFee).toInt();
  String get note => currentOrder?.note ?? '';
  double get distance => currentOrder?.distanceKm ?? 0.0;
  List<OrderItem> get orderItems => currentOrder?.items ?? [];

  void _showConfirmationDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String status) async {
    if (currentOrder == null) return;

    final success = await _orderController!.updateOrderStatus(
      currentOrder!.orderId,
      status,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปเดตสถานะสำเร็จ')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToCustomer() {
    Navigator.pushNamed(
      context,
      '/goCustomer',
      arguments: {'orderId': orderId, 'riderId': riderId},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (currentOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดงาน')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('ไม่พบข้อมูลออเดอร์ #${orderId ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                'Rider ID: ${riderId ?? 'N/A'}',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      _loadOrderData(); // ลองโหลดซ้ำ
                    },
                    child: const Text('ลองใหม่'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('กลับ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<RiderControllerSocket>(
      builder: (context, controller, _) {
        // อัปเดตข้อมูลออเดอร์ปัจจุบันจาก controller (ปลอดภัยกว่า)
        final updatedOrder = controller.orders
            .where((o) => o.orderId == orderId)
            .firstOrNull;

        if (updatedOrder != null) {
          currentOrder = updatedOrder;
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text('รายละเอียดงาน #${currentOrder!.orderId}'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () {
                  _showConfirmationDialog(
                    'แจ้งร้านปิด',
                    'คุณต้องการแจ้งว่าร้านปิดใช่หรือไม่?',
                    () => _updateOrderStatus('shop_closed'),
                  );
                },
                child: const Text(
                  'แจ้งร้านปิด',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // สถานะปัจจุบัน
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: arrivedAtRestaurant
                        ? (confirmedArrival
                              ? Colors.orange[100]
                              : Colors.blue[100])
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: arrivedAtRestaurant
                          ? (confirmedArrival ? Colors.orange : Colors.blue)
                          : Colors.green,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        arrivedAtRestaurant
                            ? (confirmedArrival
                                  ? Icons.restaurant_menu
                                  : Icons.location_on)
                            : Icons.directions,
                        color: arrivedAtRestaurant
                            ? (confirmedArrival ? Colors.orange : Colors.blue)
                            : Colors.green,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              arrivedAtRestaurant
                                  ? (confirmedArrival
                                        ? 'รอรับอาหารจากร้าน'
                                        : 'มาถึงร้านแล้ว')
                                  : 'กำลังเดินทางไปร้าน',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ออเดอร์ #${currentOrder!.orderId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ข้อมูลร้านอาหาร
                _buildInfoCard(
                  title: 'ร้านอาหาร',
                  icon: Icons.restaurant,
                  color: Colors.green,
                  children: [
                    _buildInfoRow('ชื่อร้าน', restaurantName),
                    _buildInfoRow('ที่อยู่', restaurantAddress),
                    _buildInfoRow(
                      'ระยะทาง',
                      '${distance.toStringAsFixed(1)} กม.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ข้อมูลลูกค้า
                _buildInfoCard(
                  title: 'ข้อมูลลูกค้า',
                  icon: Icons.person,
                  color: Colors.blue,
                  children: [
                    _buildInfoRow('ชื่อ', customerName),
                    if (customerPhone.isNotEmpty)
                      _buildInfoRow('เบอร์โทร', customerPhone),
                    _buildInfoRow('ที่อยู่', customerAddress),
                    _buildInfoRow('การชำระเงิน', paymentMethod),
                    _buildInfoRow('ประเภทการส่ง', deliveryType),
                  ],
                ),

                const SizedBox(height: 16),

                // รายการอาหาร
                _buildInfoCard(
                  title: 'รายการอาหาร (${orderItems.length} รายการ)',
                  icon: Icons.restaurant_menu,
                  color: Colors.orange,
                  children: [
                    ...orderItems.map((item) => _buildItemRow(item)).toList(),
                    const Divider(),
                    _buildInfoRow(
                      'ค่าอาหาร',
                      '${(totalPrice - deliveryFee).toStringAsFixed(0)} บาท',
                    ),
                    _buildInfoRow(
                      'รายได้',
                      '${deliveryFee.toStringAsFixed(0)} บาท',
                      isTotal: true,
                    ),
                    _buildInfoRow(
                      'รวมที่ต้องจ่าย',
                      '${(itemsSubtotal).toStringAsFixed(0)} บาท',
                      isTotal: true,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // หมายเหตุ
                if (note.isNotEmpty)
                  _buildInfoCard(
                    title: 'หมายเหตุ',
                    icon: Icons.note,
                    color: Colors.purple,
                    children: [
                      Text(note, style: const TextStyle(fontSize: 14)),
                    ],
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (arrivedAtRestaurant) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'จ่ายให้ร้าน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '$shopPayAmount บาท',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!arrivedAtRestaurant) {
                          _showConfirmationDialog(
                            'ยืนยันการเดินทาง',
                            'คุณต้องการเดินทางไปยังร้านอาหารใช่หรือไม่?',
                            () {
                              setState(() => arrivedAtRestaurant = true);
                              _updateOrderStatus('going_to_shop');
                            },
                          );
                        } else if (!confirmedArrival) {
                          _showConfirmationDialog(
                            'ยืนยันถึงร้าน',
                            'คุณได้มาถึงร้านอาหารแล้วใช่หรือไม่?',
                            () {
                              setState(() => confirmedArrival = true);
                              _updateOrderStatus('arrived_at_shop');
                            },
                          );
                        } else {
                          _showConfirmationDialog(
                            'ยืนยันรับอาหาร',
                            'คุณได้รับอาหารเรียบร้อยแล้วใช่หรือไม่?',
                            () {
                              _updateOrderStatus('picked_up');
                              _goToCustomer();
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        confirmedArrival
                            ? 'ยืนยันรับอาหาร'
                            : (arrivedAtRestaurant
                                  ? 'ยืนยันถึงร้าน'
                                  : 'เดินทางไปร้าน'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'x${item.quantity}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (item.selectedOptions.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.selectedOptions
                  .map(
                    (option) =>
                        '${option['label']} (+${option['extraPrice']} บาท)',
                  )
                  .join(', '),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            '${item.subtotal.toStringAsFixed(0)} บาท',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

// Extension สำหรับ firstOrNull (ถ้าไม่มีใน Dart version ของคุณ)
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
