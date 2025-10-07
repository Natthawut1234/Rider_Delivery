import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';

class GoCustomer extends StatefulWidget {
  const GoCustomer({super.key});

  @override
  State<GoCustomer> createState() => _GoCustomerState();
}

class _GoCustomerState extends State<GoCustomer> {
  bool _photoConfirmed =
      false; // becomes true after DeliveryConfirm returns true
  RiderControllerSocket? _orderController;
  int? orderId;
  int? riderId;

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

  Future<void> _updateOrderStatus(String status) async {
    if (orderId == null || _orderController == null) return;

    try {
      final result = await _orderController!.updateOrderStatus(
        orderId!,
        status,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('อัปเดตสถานะสำเร็จ')));
      } else {
        final errorMessage = result['error'] ?? 'เกิดข้อผิดพลาด';
        final hint = result['hint'] ?? '';

        String displayMessage = errorMessage;
        if (hint.isNotEmpty) {
          displayMessage = hint;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetailsDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
      data['orderItems'] ?? [],
    );
    final orderNumber =
        data['orderNumber'] ??
        ((data['orderItems'] is List && (data['orderItems'] as List).isNotEmpty)
            ? (data['orderItems'][0]['orderNumber'] ?? '-')
            : '-');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // header (Fixed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'ดูรายละเอียดการสั่งซื้อ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // restaurant (Fixed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          data['restaurantName'] ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'หมายเลขออเดอร์: $orderNumber',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              // Scrollable content (รายการอาหาร + footer)
              Flexible(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // รายการอาหาร
                      ...items.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['foodName']?.toString() ?? '-',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if ((item['selectedOptions'] != null &&
                                            (item['selectedOptions'] as List)
                                                .isNotEmpty)) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.green.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.add_circle_outline,
                                                      color: Colors.green[700],
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'ตัวเลือกเพิ่มเติม:',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.green[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: (item['selectedOptions'] as List).map((
                                                    opt,
                                                  ) {
                                                    final map =
                                                        opt
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >;
                                                    final label =
                                                        map['label']
                                                            ?.toString() ??
                                                        '';
                                                    final extraPrice =
                                                        map['extraPrice']
                                                            ?.toString() ??
                                                        '0';
                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.green
                                                              .withOpacity(0.4),
                                                          width: 1,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.green
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            blurRadius: 2,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  1,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        '$label (+฿$extraPrice)',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.green[800],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        // เพิ่มการแสดงข้อมูลเพิ่มเติมของเมนู
                                        if (item['additionalNotes'] != null &&
                                            item['additionalNotes']
                                                .toString()
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.note_alt_outlined,
                                                      color: Colors.orange[700],
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'หมายเหตุเพิ่มเติม:',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.orange[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  item['additionalNotes']
                                                      .toString()
                                                      .trim(),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.orange[800],
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'x${item['quantity']?.toString() ?? '1'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '${(item['subtotal'] ?? 0).toString()} บาท',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      // footer (summary)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ค่าอาหาร',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${((data['totalPrice']?.toDouble() ?? 0.0) - (data['deliveryFee']?.toDouble() ?? 0.0)).toStringAsFixed(0)} บาท',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ค่าส่ง (รายได้)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '${(data['deliveryFee']?.toDouble() ?? 0.0).toStringAsFixed(0)} บาท',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            // if ((data['bonus']?.toDouble() ?? 0.0) > 0) ...[
                            //   const SizedBox(height: 8),
                            //   Row(
                            //     mainAxisAlignment:
                            //         MainAxisAlignment.spaceBetween,
                            //     children: [
                            //       const Text(
                            //         'โบนัส',
                            //         style: TextStyle(
                            //           fontSize: 16,
                            //           color: Colors.orange,
                            //         ),
                            //       ),
                            //       Text(
                            //         '+ ${(data['bonus']?.toDouble() ?? 0.0).toStringAsFixed(0)} บาท',
                            //         style: const TextStyle(
                            //           fontSize: 16,
                            //           color: Colors.orange,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'รวมทั้งหมด',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${(data['totalPrice']?.toDouble() ?? 0.0).toStringAsFixed(0)} บาท',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
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
                                  '${(data['payAtShop']?.toDouble() ?? 0.0).toStringAsFixed(0)} บาท',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDeliveryConfirm() async {
    // ให้ผู้ขับกดยืนยันว่ามาถึงที่หมายก่อนจะไปหน้าถ่ายรูปยืนยันการส่ง
    final arrived = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 28),
            const SizedBox(height: 8),
            const Text('ยืนยันการถึงจุดจัดส่ง'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'คุณถึงจุดจัดส่งแล้ว?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            isDefaultAction: false,
            child: const Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(context).pop(true);
              // อัพเดทสถานะเป็น arrived_at_customer
              await _updateOrderStatus('arrived_at_customer');
            },
            isDefaultAction: true,
            child: const Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );

    // หากกดยืนยัน ให้ไปหน้าถ่ายรูปยืนยันการส่ง และอัปเดตสถานะเมื่อได้ผลลัพธ์เป็น true
    if (arrived == true) {
      final result = await Navigator.pushNamed(context, '/deliveryConfirm');
      if (result == true) {
        setState(() => _photoConfirmed = true);
      }
    }
  }

  void _confirmDeliveryFinal(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(height: 8),
            const Text('ยืนยันการจัดส่งและรับเงิน'),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'คุณต้องการยืนยันการจัดส่งและรับเงินจากลูกค้าหรือไม่?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: false,
            child: const Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              // อัพเดทสถานะเป็น completed
              await _updateOrderStatus('completed');
              // Navigate to completion screen with order data
              Navigator.pushReplacementNamed(
                context,
                '/deliveryCompleted',
                arguments: data,
              );
            },
            isDefaultAction: true,
            child: const Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      // Order Status
      case 'waiting':
        return 'รอไรเดอร์รับ';
      case 'rider_assigned':
        return 'รับงานแล้ว(รอร้านยืนยัน)';
      case 'confirmed':
        return 'ร้านยืนยันออเดอร์';
      case 'going_to_shop':
        return 'ไรเดอร์กำลังไปร้าน';
      case 'arrived_at_shop':
        return 'ไรเดอร์มาถึงร้านแล้ว';
      case 'picked_up':
        return 'ไรเดอร์รับแล้ว';
      case 'delivering':
        return 'กำลังจัดส่ง';
      case 'arrived_at_customer':
        return 'ไรเดอร์มาถึงลูกค้าแล้ว';
      case 'completed':
        return 'จัดส่งเสร็จสิ้น';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
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

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final data = args ?? {};

    // รับข้อมูล orderId และ riderId
    orderId = data['orderId'];
    riderId = data['riderId'];

    // final payType = data['payType'] ?? '-';
    final restaurantName = data['restaurantName'] ?? '-';
    final customerName = data['customerName'] ?? '-';
    final titleCustomerAddress = data['titleCustomerAddress'] ?? '-';
    final customerAddress = data['customerAddress'] ?? '-';
    final deliveryType = data['deliveryType'] ?? '-';
    final note = data['note'] ?? 'เพิ่มเติม: -';
    final totalPrice = data['totalPrice']?.toDouble() ?? 0.0;

    return WillPopScope(
      onWillPop: () async {
        // รีเฟรชข้อมูลก่อนกลับ
        if (_orderController != null && orderId != null) {
          await _orderController!.fetchOrdersByRider(riderId: riderId!);
        }
        // ส่ง result กลับไปยัง JobStart เพื่อเปลี่ยน tab
        Navigator.pop(context, {
          'switchToTab': 1, // เปลี่ยนไป tab "งานของฉัน" (My Orders)
          'refreshData': true,
        });
        return false; // ป้องกันการ pop ปกติ
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 0,
          leadingWidth: 140,
          toolbarHeight: 40,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20, right: 8),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'ยกเลิกออเดอร์',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // actions: [
          //   Container(
          //     margin: const EdgeInsets.only(right: 16),
          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //     decoration: BoxDecoration(
          //       color: Colors.white.withOpacity(0.2),
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: Colors.white),
          //     ),
          //     child: Consumer<RiderControllerSocket>(
          //       builder: (context, controller, _) {
          //         final currentOrder = controller.orders
          //             .where((o) => o.orderId == orderId)
          //             .firstOrNull;

          //         String statusText = _getStatusText(
          //           currentOrder?.status ?? '',
          //         );
          //         String shopStatusText = _getShopStatusText(
          //           currentOrder?.shopStatus,
          //         );

          //         if (shopStatusText.isNotEmpty) {
          //           statusText = '$statusText • $shopStatusText';
          //         }

          //         return Text(
          //           statusText,
          //           style: const TextStyle(
          //             color: Colors.white,
          //             fontSize: 12,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         );
          //       },
          //     ),
          //   ),
          // ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(12),
            child: SizedBox(height: 12),
          ),
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Section
              Container(
                color: const Color(0xFF4CAF50),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '1. ไปร้าน',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            restaurantName,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 2, color: Colors.white30),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '2. ส่งให้ลูกค้า',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            customerName,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Status display section ที่ด้านล่าง
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(6),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.green[700],
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<RiderControllerSocket>(
                        builder: (context, controller, _) {
                          final currentOrder = controller.orders
                              .where((o) => o.orderId == orderId)
                              .firstOrNull;

                          String statusText = _getStatusText(
                            currentOrder?.status ?? '',
                          );
                          String shopStatusText = _getShopStatusText(
                            currentOrder?.shopStatus,
                          );

                          if (shopStatusText.isNotEmpty) {
                            statusText = '$statusText • $shopStatusText';
                          }

                          return Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ร้านอาหาร',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              restaurantName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.facebook,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ลูกค้า',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/chat'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[300],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.message,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // รายละเอียดปุ่ม
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _showOrderDetailsDialog(context, data),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[700]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Go to customer section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'เดินทางไปที่จุดจัดส่ง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleCustomerAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                customerAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deliveryType,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'เพิ่มเติม: ' +
                                  (note.isNotEmpty
                                      ? note
                                      : 'ไม่มีหมายเหตุเพิ่มเติม'),
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Map is only shown before the delivery photo is confirmed
                    if (!_photoConfirmed)
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('Map Placeholder')),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              if (!_photoConfirmed)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'คำแนะนำ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'คุณจะไปถึงลูกค้าประมาณ 5 นาที',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 120), // space for bottom button
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'รับเงินจากลูกค้า',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    // แสดงยอดรวมที่คำนวณจากข้อมูลที่ส่งมา
                    Text(
                      '฿${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_photoConfirmed) {
                        await _openDeliveryConfirm();
                      } else {
                        _confirmDeliveryFinal(data);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      !_photoConfirmed
                          ? 'ยืนยันถึงจุดจัดส่ง'
                          : 'ยืนยันการจัดส่งและรับเงิน',
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
      ), // ปิด WillPopScope
    );
  }
}

// Extension for firstOrNull (if not available in your Dart version)
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
