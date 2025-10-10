import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';

class DeliveryCompletedPage extends StatefulWidget {
  const DeliveryCompletedPage({super.key});

  @override
  State<DeliveryCompletedPage> createState() => _DeliveryCompletedPageState();
}

class _DeliveryCompletedPageState extends State<DeliveryCompletedPage> {
  RiderControllerSocket? _orderController;
  bool _isLoading = true;
  Map<String, dynamic> _orderData = {};
  int? _orderId;
  int? _riderId;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _orderController = Provider.of<RiderControllerSocket>(
      context,
      listen: false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      // รับ orderId และ riderId
      _orderId = args?['orderId'];
      _riderId = args?['riderId'];
      
      if (_orderId != null && _riderId != null) {
        _fetchOrderDetails();
      } else {
        // ถ้าไม่มี orderId ให้ใช้ข้อมูลที่ส่งมาแบบเดิม
        setState(() {
          _orderData = args ?? {};
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchOrderDetails() async {
    if (_orderId == null || _riderId == null || _orderController == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // ดึงข้อมูลล่าสุดจาก API ก่อน (แบบไม่ trigger notifyListeners ระหว่าง build)
      await _orderController!.fetchOrdersByRider(riderId: _riderId!);
      
      // ดึงข้อมูล order จาก controller
      final orders = _orderController!.orders;
      final currentOrder = orders.firstWhere(
        (order) => order.orderId == _orderId,
        orElse: () => throw Exception('Order not found'),
      );

      // แปลงข้อมูลจาก Order model เป็น Map
      // คำนวณค่าต่างๆ
      final restaurantAddress = currentOrder.marketLocation?['address'] ?? 
                                currentOrder.marketLocation?['shop_address'] ?? '-';
      final customerAddress = currentOrder.address.isNotEmpty 
                             ? currentOrder.address 
                             : (currentOrder.customerLocation?['address'] ?? '-');
      final titleCustomerAddress = currentOrder.customerLocation?['title'] ?? 
                                   currentOrder.deliveryType;
      final distance = currentOrder.distanceKm != null 
                      ? '${currentOrder.distanceKm!.toStringAsFixed(1)} km' 
                      : (currentOrder.distanceInfo?['distance']?.toString() ?? '0 km');
      
      // คำนวณเงินที่ต้องจ่ายให้ร้าน = ราคารวม - ค่าจัดส่ง
      final payAtShop = currentOrder.totalPrice - currentOrder.deliveryFee;
      
      if (mounted) {
        setState(() {
          _orderData = {
            'orderId': currentOrder.orderId,
            'orderNumber': '${currentOrder.orderId}',
            'restaurantName': currentOrder.shopName,
            'restaurantAddress': restaurantAddress,
            'customerName': currentOrder.clientName ?? 'ลูกค้า',
            'customerAddress': customerAddress,
            'titleCustomerAddress': titleCustomerAddress,
            'distance': distance,
            'payType': currentOrder.paymentMethod == 'cash' ? 'เงินสด' : 
                       currentOrder.paymentMethod == 'promptpay' ? 'พร้อมเพย์' : 
                       currentOrder.paymentMethod,
            'totalPrice': currentOrder.totalPrice,
            'deliveryFee': currentOrder.deliveryFee,
            'payAtShop': payAtShop,
            'earn': currentOrder.deliveryFee, // ค่าจัดส่ง = รายได้
            'bonus': currentOrder.bonus, // โบนัสพิเศษ
            'totalReceived': currentOrder.totalPrice,
            'orderItems': currentOrder.items.map((item) => {
              'orderNumber': '${currentOrder.orderId}',
              'foodName': item.foodName,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
              'selectedOptions': item.selectedOptions,
              'additionalNotes': item.additionalNotes,
            }).toList(),
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching order details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      // ใช้ SchedulerBinding เพื่อแสดง SnackBar หลัง build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่สามารถโหลดข้อมูลออเดอร์: $e'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'กลับ',
                textColor: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          title: const Text(
            'งานเสร็จสมบูรณ์',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }

    final payType = _orderData['payType'] ?? 'เงินสด';
    final orderNumber = _orderData['orderNumber'] ??
        (_orderData['orderItems'] is List && (_orderData['orderItems'] as List).isNotEmpty
            ? _orderData['orderItems'][0]['orderNumber'] ?? '9999999-9999'
            : '-');
    final restaurantName = _orderData['restaurantName'] ?? '-';
    final customerName = _orderData['customerName'] ?? '-';
    final customerAddress = _orderData['customerAddress'] ?? '-';
    final double payAtShop =
        double.tryParse((_orderData['payAtShop'] ?? '0').toString()) ?? 0.0;
    final double earn =
        double.tryParse((_orderData['earn'] ?? '0').toString()) ?? 0.0;
    final double bonus =
        double.tryParse((_orderData['bonus'] ?? '0').toString()) ?? 0.0;

    double totalReceived =
        double.tryParse((_orderData['totalReceived'] ?? '').toString()) ?? -1;
    if (totalReceived < 0) {
      totalReceived = payAtShop + earn + bonus;
    }

    final double netIncome = totalReceived - payAtShop;
    final distance = _orderData['distance'] ?? '1.5 km';
    final restaurantAddress = _orderData['restaurantAddress'] ?? '-';

    double credit = 100; // ตัวอย่างเครดิต
    // คิดเปอร์เซ็นต์เครดิต 20% ของรายได้สุทธ์(netIncome)
    double creditPercent = netIncome * (20 / 100);
    double creditRemaining = credit - creditPercent;

    // จัดรูปแบบวันที่และเวลาปัจจุบัน (ใช้ format แบบง่าย ไม่ต้อง locale)
    final now = DateTime.now();
    final day = now.day;
    final month = _getThaiMonth(now.month);
    final year = now.year + 543; // แปลงเป็น พ.ศ.
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final currentDateTime = '$day $month $year, $hour:$minute น.';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'งานเสร็จสมบูรณ์',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Order Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentDateTime,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        'ADR-$orderNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Restaurant Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.store,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  restaurantName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(
                              restaurantAddress,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.place,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(
                              customerAddress,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ระยะทางทั้งหมด',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Income Details Title
                  const Text(
                    'รายละเอียดรายได้',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Income Details Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'จ่ายให้ร้าน',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                '฿${payAtShop.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ค่าจัดส่ง',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '฿${earn.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'เงินโบนัสพิเศษ',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '฿${bonus.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'รับเงินจากลูกค้า ($payType)',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '฿${totalReceived.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Colors.grey),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'หักภาษี 20% (เครดิตรับงาน)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                '฿${creditPercent.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'เครดิตรับงานคงเหลือ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                '฿${creditRemaining.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Colors.grey),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'รายได้สุทธิ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '฿${netIncome.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Screenshot Button
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E8),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 1,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('บันทึกหน้าจอ (ยังไม่ทำ)'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                        label: const Text(
                          'บันทึกหน้าจอ',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: _orderData,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'คุยกับลูกค้า',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'ปิด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Helper method สำหรับแปลงเดือนเป็นภาษาไทย
  String _getThaiMonth(int month) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return months[month];
  }
}