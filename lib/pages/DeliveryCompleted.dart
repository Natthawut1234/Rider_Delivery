import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';

class DeliveryCompletedPage extends StatefulWidget {
  const DeliveryCompletedPage({super.key});

  @override
  State<DeliveryCompletedPage> createState() => _DeliveryCompletedPageState();
}

class _DeliveryCompletedPageState extends State<DeliveryCompletedPage> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  RiderControllerSocket? _orderController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (orderData == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          orderData = args;
          isLoading = false;
        });
        _orderController = Provider.of<RiderControllerSocket>(
          context,
          listen: false,
        );
        _loadOrderDetails(args['orderId'], args['riderId']);
      }
    }
  }

  Future<void> _loadOrderDetails(int? orderId, int? riderId) async {
    if (orderId == null || riderId == null || _orderController == null) return;
    try {
      await _orderController!.fetchOrdersByRider(riderId: riderId);
      final order = _orderController!.orders
          .where((o) => o.orderId == orderId)
          .firstOrNull;
      if (order != null && mounted) {
        setState(() {
          orderData = {
            ...orderData!,
            'deliveryFee': order.deliveryFee,
            'originalTotalPrice': order.originalTotalPrice,
            'totalPrice': order.totalPrice,
            'bonus': order.bonus,
            'riderRequiredGp': order.riderRequiredGp,
          };
        });
      }
    } catch (e) {
      print('Error loading order details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || orderData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );
    }

    final orderId = orderData!['orderId'] ?? 0;
    final deliveryFee = (orderData!['deliveryFee'] ?? 0.0).toDouble();
    final originalTotalPrice =
        (orderData!['originalTotalPrice'] ?? orderData!['payAtShop'] ?? 0.0)
            .toDouble();
    final totalPrice = (orderData!['totalPrice'] ?? 0.0).toDouble();
    final bonus = (orderData!['bonus'] ?? 0.0).toDouble();
    final riderRequiredGp = (orderData!['riderRequiredGp'] ?? 0.0).toDouble();
    final customerName = orderData!['customerName'] ?? 'ลูกค้า';
    final restaurantName = orderData!['restaurantName'] ?? 'ร้านอาหาร';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        title: Text(
          'จัดส่งเสร็จสิ้น',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success Icon Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 80,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'จัดส่งสำเร็จ!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Order #$orderId',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Order Summary Section
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant & Customer Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: Colors.orange,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ร้านอาหาร',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      restaurantName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 24),
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ลูกค้า',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      customerName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Financial Summary
                  Text(
                    'สรุปรายได้',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  // ข้อมูลการชำระเงิน (จ่ายให้ร้าน + รับจากลูกค้า)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payments,
                                color: Colors.purple,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ข้อมูลการชำระเงิน',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _buildFinancialRow(
                            icon: Icons.restaurant_menu,
                            iconColor: Colors.orange,
                            label: 'จ่ายให้ร้าน',
                            amount: originalTotalPrice,
                            amountColor: Colors.orange,
                          ),
                          SizedBox(height: 8),
                          _buildFinancialRow(
                            icon: Icons.attach_money,
                            iconColor: Colors.blue,
                            label: 'รับจากลูกค้า',
                            amount: totalPrice,
                            amountColor: Colors.blue,
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 6),

                  // 💰 รายได้ของคุณ
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'รายได้ของคุณ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          // _buildFinancialRow(
                          //   icon: Icons.local_shipping,
                          //   iconColor: Color(0xFF4CAF50),
                          //   label: 'ค่าจัดส่ง',
                          //   amount: deliveryFee,
                          //   amountColor: Color(0xFF4CAF50),
                          // ),
                          // SizedBox(height: 8),
                          _buildFinancialRow(
                            icon: Icons.delivery_dining_sharp,
                            iconColor: Color(0xFF4CAF50),
                            label: 'รายได้รวม',
                            amount: deliveryFee,
                            amountColor: Color(0xFF4CAF50),
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 💳 ค่าใช้จ่าย (แสดงเฉพาะเมื่อมีเครดิตช่วยจ่าย)
                  if (bonus > 0 || riderRequiredGp > 0) ...[
                    SizedBox(height: 6),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'ค่าใช้จ่าย',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            if (riderRequiredGp > 0) ...[
                              _buildFinancialRow(
                                icon: Icons.payments,
                                iconColor: Colors.grey[600]!,
                                label: 'เครดิตที่ต้องจ่าย',
                                amount: riderRequiredGp + bonus,
                                amountColor: Colors.black87,
                              ),
                            ],
                            if (bonus > 0) ...[
                              SizedBox(height: 8),
                              _buildFinancialRow(
                                icon: Icons.savings,
                                iconColor: Colors.orange,
                                label: 'เครดิตช่วยจ่าย',
                                amount: bonus,
                                amountColor: Colors.orange,
                                isDeduction: true,
                              ),
                            ],
                            if (riderRequiredGp > 0) ...[
                              SizedBox(height: 12),
                              Divider(height: 8),
                              SizedBox(height: 8),
                              _buildFinancialRow(
                                icon: Icons.remove_circle_outline,
                                iconColor: Colors.red,
                                label: 'เครดิตที่หักจริง',
                                amount: riderRequiredGp,
                                amountColor: Colors.red,
                                isHighlight: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 📊 สรุป
                  // if (bonus > 0) ...[
                  //   SizedBox(height: 16),
                  //   Card(
                  //     elevation: 2,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     child: Container(
                  //       padding: EdgeInsets.all(16),
                  //       decoration: BoxDecoration(
                  //         color: Colors.blue.withOpacity(0.05),
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Row(
                  //             children: [
                  //               Icon(
                  //                 Icons.savings,
                  //                 color: Colors.blue,
                  //                 size: 20,
                  //               ),
                  //               SizedBox(width: 8),
                  //               Text(
                  //                 'สรุป',
                  //                 style: TextStyle(
                  //                   fontSize: 16,
                  //                   fontWeight: FontWeight.bold,
                  //                   color: Colors.blue,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //           SizedBox(height: 12),
                  //           _buildFinancialRow(
                  //             icon: Icons.trending_up,
                  //             iconColor: Color(0xFF4CAF50),
                  //             label: 'รายได้สุทธิ',
                  //             amount: deliveryFee,
                  //             amountColor: Color(0xFF4CAF50),
                  //           ),
                  //           SizedBox(height: 8),
                  //           _buildFinancialRow(
                  //             icon: Icons.account_balance_wallet,
                  //             iconColor: Colors.blue,
                  //             label: 'ประหยัดได้',
                  //             amount: bonus,
                  //             amountColor: Colors.blue,
                  //             isHighlight: true,
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ],
                  SizedBox(height: 20),

                  // Quick Summary Card - แสดงรายได้สุทธิเสมอ
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4CAF50).withOpacity(0.1),
                          Color(0xFF81C784).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF4CAF50).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รายได้สุทธิของคุณ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '฿${deliveryFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            if (bonus > 0) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ประหยัดเครดิต ฿${bonus.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.monetization_on,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  // Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'กลับหน้าหลัก',
                        style: TextStyle(
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
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double amount,
    required Color amountColor,
    bool isHighlight = false,
    bool isTotal = false,
    bool isDeduction = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 8 : 4),
      decoration: isHighlight
          ? BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Padding(
        padding: isHighlight ? EdgeInsets.all(8) : EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: isTotal ? 18 : 16),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isTotal || isHighlight ? 15 : 14,
                  fontWeight: isTotal || isHighlight
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: isTotal || isHighlight
                      ? Colors.black87
                      : Colors.grey[700],
                ),
              ),
            ),
            Text(
              '${isDeduction ? '-' : ''}฿${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isTotal || isHighlight ? 18 : 16,
                fontWeight: isTotal || isHighlight
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
