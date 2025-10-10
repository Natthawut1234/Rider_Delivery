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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          orderData = args;
          isLoading = false;
        });
        _orderController = Provider.of<RiderControllerSocket>(context, listen: false);
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
    final originalTotalPrice = (orderData!['originalTotalPrice'] ?? orderData!['payAtShop'] ?? 0.0).toDouble();
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF81C784),
                  ],
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
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
                              Icon(
                                Icons.person,
                                color: Colors.blue,
                                size: 24,
                              ),
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
                  SizedBox(height: 12),

                  // Earnings Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildFinancialRow(
                            icon: Icons.restaurant_menu,
                            iconColor: Colors.orange,
                            label: 'ค่าอาหาร (จ่ายให้ร้าน)',
                            amount: originalTotalPrice,
                            amountColor: Colors.orange,
                          ),
                          Divider(height: 24),
                          _buildFinancialRow(
                            icon: Icons.delivery_dining,
                            iconColor: Color(0xFF4CAF50),
                            label: 'ค่าจัดส่ง (รายได้)',
                            amount: deliveryFee,
                            amountColor: Color(0xFF4CAF50),
                            isHighlight: true,
                          ),
                          if (bonus > 0) ...[
                            Divider(height: 24),
                            _buildFinancialRow(
                              icon: Icons.card_giftcard,
                              iconColor: Colors.purple,
                              label: 'เครดิตช่วยจ่าย',
                              amount: bonus,
                              amountColor: Colors.purple,
                            ),
                          ],
                          if (riderRequiredGp > 0) ...[
                            Divider(height: 24),
                            _buildFinancialRow(
                              icon: Icons.remove_circle_outline,
                              iconColor: Colors.red,
                              label: 'เครดิตที่หัก',
                              amount: riderRequiredGp,
                              amountColor: Colors.red,
                              isDeduction: true,
                            ),
                          ],
                          Divider(height: 24, thickness: 2),
                          _buildFinancialRow(
                            icon: Icons.attach_money,
                            iconColor: Colors.blue,
                            label: 'รวมที่รับจากลูกค้า',
                            amount: totalPrice,
                            amountColor: Colors.blue,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Quick Summary Card
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
                              '฿${(deliveryFee + bonus).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
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
      padding: EdgeInsets.symmetric(vertical: isTotal ? 8 : 0),
      decoration: isHighlight
          ? BoxDecoration(
              color: Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Padding(
        padding: isHighlight ? EdgeInsets.all(12) : EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isTotal ? 24 : 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
            Text(
              '${isDeduction ? '-' : ''}฿${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isTotal ? 20 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
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