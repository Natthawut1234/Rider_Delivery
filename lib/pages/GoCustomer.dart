import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/ChatSocket/ChatControllerSK.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import 'package:rider_delivery/APIs/Orders/models/Order_items.dart';
import 'package:rider_delivery/APIs/middleware/topupGP.dart';
import 'package:rider_delivery/pages/Chats/models/ChatMessage.dart';
import 'package:rider_delivery/pages/DeliveryCompleted.dart';
import 'package:rider_delivery/pages/DeliveryConfirm.dart';
import 'package:rider_delivery/pages/maps/map_button_widget.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/pages/utils/navigation_guard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';

class GoCustomer extends StatefulWidget {
  const GoCustomer({super.key});

  @override
  State<GoCustomer> createState() => _GoCustomerState();
}

class _GoCustomerState extends State<GoCustomer> {
  bool _photoConfirmed = false;
  RiderControllerSocket? _orderController;
  int? orderId;
  int? riderId;
  File? _deliveryPhoto; // เก็บรูปการจัดส่ง
  String? _promptPayId;
  String? _qrData;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        orderId = args['orderId'];
        riderId = args['riderId'];

        // ✅ ดึง socket controller
        _orderController = Provider.of<RiderControllerSocket>(
          context,
          listen: false,
        );

        // ✅ ถ้ายังไม่ดึงข้อมูล ให้ดึงจาก backend
        await _orderController!.fetchOrdersByRider(riderId: riderId!);

        // ✅ เริ่ม watch order นี้แบบ real-time
        _orderController!.watchOrder(orderId!);

        // ✅ อัปเดตสถานะในหน้า
        setState(() {});
      }
    });
  }

  String generatePromptPayQR(String promptPayId, double amount) {
    // ตรวจสอบ PromptPay ID
    String idType;
    String targetId;

    if (RegExp(r'^\d{13}$').hasMatch(promptPayId)) {
      idType = "02"; // บัตรประชาชน
      targetId = promptPayId;
    } else if (RegExp(r'^0\d{9}$').hasMatch(promptPayId)) {
      idType = "01"; // เบอร์โทร
      // ✅ ตัด 0 หน้า แล้วเติม 66
      targetId = "66${promptPayId.substring(1)}";
    } else {
      throw ArgumentError("❌ PromptPay ID ไม่ถูกต้อง");
    }

    // AID ของ PromptPay
    const appId = "A000000677010111";

    // ✅ Tag 00 = Application ID
    final tag00 = "00${appId.length.toString().padLeft(2, '0')}$appId";

    // ✅ Tag 01 = Account Info (idType + targetId)
    final accountInfo = "$idType$targetId";
    final tag01 =
        "01${accountInfo.length.toString().padLeft(2, '0')}$accountInfo";

    // ✅ Tag 29 = Merchant Account Information
    final merchantAccountInfo = tag00 + tag01;
    final merchantLength = merchantAccountInfo.length.toString().padLeft(
      2,
      '0',
    );

    // ✅ Payload หลัก
    String payload =
        "000201" // Payload Format Indicator
        "010212" // Point of Initiation Method (Dynamic QR with amount)
        "29$merchantLength$merchantAccountInfo" // Merchant Account Info
        "5303764" // Currency Code (764 = THB)
        "5802TH"; // Country Code

    // ✅ เพิ่มยอดเงิน (ต้องมี 2 ทศนิยม)
    if (amount > 0) {
      final amt = amount.toStringAsFixed(2);
      payload += "54${amt.length.toString().padLeft(2, '0')}$amt";
    }

    // ✅ คำนวณ CRC16 (CCITT-FFFF)
    final crc = _calculateCRC16(payload + "6304");
    payload += "6304$crc";

    print('✅ PromptPay QR Payload: $payload');
    return payload;
  }

  String _calculateCRC16(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  Future<void> _loadPromptPayID() async {
    final promptPayInfo = await TopupGP().fetchPromptPayInfo();

    if (promptPayInfo != null && promptPayInfo.isNotEmpty) {
      print('✅ หมายเลขพร้อมเพย์ของไรเดอร์: $promptPayInfo');

      // ตรวจสอบว่ายอดไม่เป็นศูนย์
      final double amount = _totalPrice > 0 ? _totalPrice : 0.01;

      final qrData = generatePromptPayQR(promptPayInfo, amount);
      print("✅ PromptPay QR payload: $qrData");

      setState(() {
        _promptPayId = promptPayInfo;
        _qrData = qrData;
      });
    } else {
      print('⚠️ ไม่พบหมายเลขพร้อมเพย์ของไรเดอร์');
    }
  }

  Future<void> _restoreActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final storedOrderId = prefs.getInt('active_order_id');
    final storedRiderId = prefs.getInt('active_rider_id');
    if (storedOrderId != null && storedRiderId != null) {
      print('🔁 โหลดงานค้าง orderId=$storedOrderId riderId=$storedRiderId');
      setState(() {
        orderId = storedOrderId;
        riderId = storedRiderId;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _orderController = Provider.of<RiderControllerSocket>(
          context,
          listen: false,
        );
        await _orderController!.fetchOrdersByRider(riderId: storedRiderId);
      });
    }
  }

  Future<void> _saveActiveOrderToLocal() async {
    if (orderId == null || riderId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_order_id', orderId!);
    await prefs.setInt('active_rider_id', riderId!);
    print('💾 บันทึกงานค้าง orderId=$orderId riderId=$riderId');
  }

  void _initializeController() {
    _orderController = Provider.of<RiderControllerSocket>(
      context,
      listen: false,
    );
  }

  Future<void> _updateOrderStatus(String status, {File? photo}) async {
    if (orderId == null || _orderController == null) return;

    try {
      final result = await _orderController!.updateOrderStatus(
        orderId!,
        status,
        photo: photo,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('อัปเดตสถานะสำเร็จ')));
      } else {
        final errorMessage = result['error'] ?? 'เกิดข้อผิดพลาด';
        final hint = result['hint'] ?? '';
        String displayMessage = hint.isNotEmpty ? hint : errorMessage;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.orange,
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
        insetPadding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.zero,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.95,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF4CAF50), const Color(0xFF45a049)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'รายละเอียดออเดอร์',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'เลขที่: $orderNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.storefront,
                        color: Colors.orange[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['restaurantName'] ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ร้านอาหาร',
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

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Colors.grey[50],
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'รายการอาหาร (${items.length} รายการ)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item['foodName']?.toString() ?? '-',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF4CAF50,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'x${item['quantity']?.toString() ?? '1'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4CAF50),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '฿${(item['subtotal'] ?? 0).toString()}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (item['selectedOptions'] != null &&
                                    (item['selectedOptions'] as List)
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.15),
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
                                              color: Colors.green[600],
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'ตัวเลือกเพิ่มเติม',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: (item['selectedOptions'] as List)
                                              .map((opt) {
                                                final map =
                                                    opt as Map<String, dynamic>;
                                                final label =
                                                    map['label']?.toString() ??
                                                    '';
                                                final extraPrice =
                                                    map['extraPrice']
                                                        ?.toString() ??
                                                    '0';
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.green
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        label,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.green[800],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' +฿$extraPrice',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .orange[700],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              })
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                if (item['additionalNotes'] != null &&
                                    item['additionalNotes']
                                        .toString()
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.15),
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
                                              color: Colors.orange[600],
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'หมายเหตุ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[700],
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
                                            fontSize: 12,
                                            color: Colors.orange[800],
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[50]!, Colors.grey[100]!],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '฿${((data['totalPrice']?.toDouble() ?? 0.0) - (data['deliveryFee']?.toDouble() ?? 0.0)).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ค่าจัดส่ง (รายได้)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                Text(
                                  '฿${(data['deliveryFee']?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, thickness: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ยอดรวมทั้งหมด',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  '฿${(data['totalPrice']?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, thickness: 1.5),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'จ่ายให้ร้าน',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    '฿${(data['payAtShop']?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
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
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'คุณถึงจุดจัดส่งแล้ว?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              await _updateOrderStatus('arrived_at_customer');
              Navigator.of(context).pop(true);
            },
            isDefaultAction: true,
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (arrived == true && orderId != null && _orderController != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryConfirmPage(
            orderId: orderId!,
            orderController: _orderController!,
          ),
        ),
      );

      if (result != null && result is File && mounted) {
        setState(() {
          _deliveryPhoto = result;
          _photoConfirmed = true;
        });
      }
    }
  }

  void _confirmDeliveryFinal(Map<String, dynamic> data) async {
    if (_deliveryPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาถ่ายรูปหลักฐานการส่งก่อนยืนยันจัดส่ง'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ แสดง dialog ยืนยันก่อนอัปโหลดจริง
    showDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(height: 8),
            Text('ยืนยันการจัดส่งและรับเงิน'),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(dialogContext); // ปิด dialog

              // ✅ อัปเดตสถานะจริง แค่ครั้งเดียว พร้อมรูป
              await _updateOrderStatus('completed', photo: _deliveryPhoto);

              // ✅ ล้างงานค้าง
              final prefs = await SharedPreferences.getInstance();
              prefs.remove('active_order_id');
              prefs.remove('active_rider_id');
              print('🧹 ล้างงานค้างหลังจัดส่งเสร็จ');

              if (!mounted) return;

              // ✅ แสดงหน้าสำเร็จเต็มจอ 3 วิ
              showGeneralDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(0.6),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, __, ___) {
                  return Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 150,
                          ),
                          SizedBox(height: 30),
                          Text(
                            'จัดส่งสำเร็จ!',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'ขอบคุณที่ให้บริการกับลูกค้า 💚',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );

              // ✅ หน่วง 3 วิ แล้วไปหน้า DeliveryCompletedPage
              await Future.delayed(const Duration(seconds: 3));
              if (!mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const DeliveryCompletedPage(),
                  settings: RouteSettings(
                    arguments: {'orderId': orderId, ...data},
                  ),
                ),
                ModalRoute.withName('/home'), // ✅ กลับไปหน้า home
              );
            },
            isDefaultAction: true,
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
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
      default:
        return shopStatus;
    }
  }

  String? _getCurrentStatus() {
    if (_orderController == null || orderId == null) return null;

    final currentOrder = IterableExtension(
      _orderController!.orders.where((o) => o.orderId == orderId),
    ).firstOrNull;

    return currentOrder?.status;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // ✅ เปิด dialer ภายนอกโดยตรง
      )) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('❌ Error launching dialer: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถโทรออกได้ในอุปกรณ์นี้')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final data = args ?? {};

    orderId = data['orderId'];
    riderId = data['riderId'];
    _totalPrice = data['totalPrice']?.toDouble() ?? 0.0;
    if (_promptPayId == null && _totalPrice > 0) {
      _loadPromptPayID();
    }

    final restaurantName = data['restaurantName'] ?? '-';
    final customerName = data['customerName'] ?? '-';
    final titleCustomerAddress = data['titleCustomerAddress'] ?? '-';
    final customerAddress = data['customerAddress'] ?? '-';
    final deliveryType = data['deliveryType'] ?? '-';
    final double customerLat = (data['customerLat'] ?? 0.0).toDouble();
    final double customerLng = (data['customerLng'] ?? 0.0).toDouble();
    final note = data['note'] ?? 'เพิ่มเติม: -';
    final totalPrice = data['totalPrice']?.toDouble() ?? 0.0;
    final currentOrder = _orderController?.orders
        .where((o) => o.orderId == orderId)
        .cast<Order?>()
        .firstWhere((o) => true, orElse: () => null);

    final String ResPhone =
        data['restaurantPhone'] ??
        currentOrder?.customerLocation!['phone'] ??
        '';
    final String CusPhone =
        data['customerPhone'] ?? currentOrder?.marketLocation!['phone'] ?? '';

    print('ResPhone : ${ResPhone}');
    print('CusPhone : ${CusPhone}');

    print('latitude: ${customerLat}');
    print('longitude: ${customerLng}');

    return WillPopScope(
      onWillPop: () async {
        final currentStatus = _getCurrentStatus();

        // เรียกใช้ NavigationGuard
        final canPop = await NavigationGuard.showBackWarningDialog(
          context,
          currentStatus,
        );

        if (canPop) {
          if (_orderController != null && orderId != null) {
            await _orderController!.fetchOrdersByRider(riderId: riderId!);
          }
          Navigator.pop(context, {'switchToTab': 1, 'refreshData': true});
          return false;
        }

        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 0,
          leadingWidth: 140,
          toolbarHeight: 40,
          // leading: Padding(
          //   padding: const EdgeInsets.only(left: 20, right: 8),
          //   child: TextButton(
          //     onPressed: () async {
          //       final currentStatus = _getCurrentStatus();
          //       final canPop = await NavigationGuard.showBackWarningDialog(
          //         context,
          //         currentStatus,
          //       );

          //       if (canPop && mounted) {
          //         if (_orderController != null && orderId != null) {
          //           await _orderController!.fetchOrdersByRider(
          //             riderId: riderId!,
          //           );
          //         }
          //         Navigator.pop(context, {
          //           'switchToTab': 1,
          //           'refreshData': true,
          //         });
          //       }
          //     },
          //     style: TextButton.styleFrom(
          //       backgroundColor: const Color(0xFFE0E0E0),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 12,
          //         vertical: 8,
          //       ),
          //     ),
          //     child: const Text(
          //       'ยกเลิกออเดอร์',
          //       style: TextStyle(
          //         color: Colors.black87,
          //         fontSize: 13,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ),
          // ),
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
                              color: Colors.green[900],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            restaurantName,
                            style: TextStyle(
                              color: Colors.green[900],
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
                          final currentOrder = IterableExtension(
                            controller.orders.where(
                              (o) => o.orderId == orderId,
                            ),
                          ).firstOrNull;

                          final argStatus = data['status'] ?? '';
                          final argShopStatus = data['shopStatus'] ?? '';

                          String statusText = _getStatusText(
                            currentOrder?.status ?? argStatus,
                          );
                          String shopStatusText = _getShopStatusText(
                            currentOrder?.shopStatus ?? argShopStatus,
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
                          // decoration: const BoxDecoration(
                          //   color: Colors.blue,
                          //   shape: BoxShape.circle,
                          // ),
                          // child: const Icon(
                          //   Icons.facebook,
                          //   color: Colors.white,
                          //   size: 20,
                          // ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _makePhoneCall(ResPhone),
                          child: Container(
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

                        // 🟢 ปุ่มข้อความ (ย้ายมาด้านซ้ายแทนโทร)
                        GestureDetector(
                          onTap: () async {
                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token');

                              int? tokenRiderId;
                              int? userId;

                              if (token != null && token.isNotEmpty) {
                                final parts = token.split('.');
                                if (parts.length == 3) {
                                  final payload = parts[1];
                                  final normalized = base64.normalize(payload);
                                  final decoded = utf8.decode(
                                    base64Url.decode(normalized),
                                  );
                                  final Map<String, dynamic> data = jsonDecode(
                                    decoded,
                                  );

                                  tokenRiderId = data['rider_id'];
                                  userId = data['user_id'];

                                  print(
                                    '🔑 JWT decode: rider_id=$tokenRiderId, user_id=$userId',
                                  );
                                } else {
                                  print("⚠️ Invalid JWT format");
                                }
                              }

                              final chat = context.read<RiderChatController>();

                              if (chat.riderId == null &&
                                  tokenRiderId != null) {
                                chat.riderId = tokenRiderId;
                              }

                              await chat.initializeRiderInfoIfNeeded();
                              await chat.connectToChat();
                              await chat.loadChatRooms();

                              // ✅ หา room ของ order ปัจจุบัน
                              final room = chat.chatRooms
                                  .where(
                                    (r) =>
                                        (r.orderId?.toString() ?? '') ==
                                        (orderId?.toString() ?? ''),
                                  )
                                  .cast<ChatRoom?>()
                                  .firstWhere((r) => true, orElse: () => null);

                              final customerPhone =
                                  data['customerPhone'] ?? '-';
                              final customerName = data['customerName'] ?? '-';

                              if (room != null && room.roomId != null) {
                                chat.openChatWithCustomer(
                                  context: context,
                                  roomId: room.roomId!,
                                  orderId: orderId!,
                                  customerName:
                                      room.customerName ?? customerName,
                                  customerPhoto: currentOrder
                                      ?.customerLocation!['photo_url'],
                                  customerPhone:
                                      room.customerPhone ?? customerPhone,
                                );
                              } else {
                                final newRoomId = await chat
                                    .createChatRoomForOrder(
                                      orderId: orderId!,
                                      customerId: userId!,
                                      customerName: customerName,
                                      customerPhoto: null,
                                    );

                                if (newRoomId != null) {
                                  chat.openChatWithCustomer(
                                    context: context,
                                    roomId: newRoomId,
                                    orderId: orderId!,
                                    customerName: customerName,

                                    customerPhoto: null,
                                    customerPhone: customerPhone,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'ไม่สามารถเปิดห้องแชทได้ในขณะนี้',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              print('❌ Error opening chat: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('เปิดแชทไม่สำเร็จ: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
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

                        const SizedBox(width: 8),

                        // 📞 ปุ่มโทร (เพิ่ม onTap)
                        GestureDetector(
                          onTap: () => _makePhoneCall(CusPhone),
                          child: Container(
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
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
                              'เพิ่มเติม: ' + (note.isNotEmpty ? note : '-'),
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_deliveryPhoto != null)
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.9),
                              builder: (context) => GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.8,
                                      maxScale: 3.0,
                                      child: Image.file(
                                        _deliveryPhoto!,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            width: MediaQuery.of(context).size.width * 0.85,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _deliveryPhoto!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (_deliveryPhoto == null && !_photoConfirmed)
                      MapNavigationButton(
                        latitude: customerLat,
                        longitude: customerLng,
                        locationName: customerName,
                        address: customerAddress,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
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
                // 🔻 ส่วนสถานะและปุ่มยืนยัน (เหมือนเดิม)
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'รับเงินจากลูกค้า',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
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
                // ✅ เงื่อนไขแสดง QR พร้อมเพย์ เฉพาะตอนสถานะ = arrived_at_customer
                if (_getCurrentStatus() == 'arrived_at_customer') ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      // แสดง QR เต็มหน้าจอ
                      showDialog(
                        context: context,
                        barrierColor: Colors.black87,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(20),
                          child: Stack(
                            children: [
                              // ปุ่มปิด
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              // เนื้อหา QR
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // QR Code Container
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue[600]!,
                                            Colors.blue[400]!,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.5),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            // Logo PromptPay
                                            Image.network(
                                              'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/PromptPay-logo.png/800px-PromptPay-logo.png',
                                              height: 40,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.payment,
                                                    color: Color(0xFF1E4899),
                                                    size: 40,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'สแกนเพื่อชำระเงิน',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E4899),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            // QR Code
                                            if (_qrData != null)
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF1E4899,
                                                    ),
                                                    width: 3,
                                                  ),
                                                ),
                                                child: QrImageView(
                                                  data: _qrData!,
                                                  version: QrVersions.auto,
                                                  size: 280,
                                                  backgroundColor: Colors.white,
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  40,
                                                ),
                                                child: Column(
                                                  children: [
                                                    const Icon(
                                                      Icons.error_outline,
                                                      size: 60,
                                                      color: Colors.red,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      '⚠️ ไม่พบหมายเลขพร้อมเพย์',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(height: 20),
                                            // ข้อมูลเงิน
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blue[600]!,
                                                    Colors.blue[400]!,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'ยอดชำระทั้งหมด',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '฿${_totalPrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // คำแนะนำ
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: Colors.blue[700],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'เปิดแอพธนาคารเพื่อสแกน QR Code',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E4899), Color(0xFF2D5AB8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E4899).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // QR Preview
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _qrData != null
                                ? QrImageView(
                                    data: _qrData!,
                                    version: QrVersions.auto,
                                    size: 60,
                                  )
                                : const Icon(
                                    Icons.qr_code_2,
                                    size: 60,
                                    color: Color(0xFF1E4899),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // ข้อความ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Logo PromptPay
                                    Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/PromptPay-logo.png/800px-PromptPay-logo.png',
                                      height: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.payment,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'พร้อมเพย์',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'แตะเพื่อสแกน QR Code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '฿${_totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ลูกศร
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
