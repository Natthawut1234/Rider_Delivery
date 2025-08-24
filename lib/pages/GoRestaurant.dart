import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class GoRestaurant extends StatefulWidget {
  @override
  _GoRestaurantState createState() => _GoRestaurantState();
}

class _GoRestaurantState extends State<GoRestaurant> {
  bool arrivedAtRestaurant = false;
  bool confirmedArrival = false;

  Map<String, dynamic>? _selectedJob;
  List<dynamic>? _jobsList;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _selectedJob == null) {
      _selectedJob = args['job'] as Map<String, dynamic>?;
      _jobsList = args['jobs'] as List<dynamic>?;
      // ถ้าต้องการ เตรียม orderItems จาก _selectedJob ที่ส่งมา
      if (_selectedJob != null && _selectedJob!['orderItems'] is List) {
        final items = _selectedJob!['orderItems'] as List;
        // แปลงเป็น List<Map<String, dynamic>>
        orderItems = items.map((e) {
          if (e is Map<String, dynamic>) return e;
          return Map<String, dynamic>.from(e as Map);
        }).toList();
      }
      setState(() {});
    }
  }

  // ตัวอย่างรายการอาหาร (ค่าเริ่มต้น ถ้าไม่ได้ส่งมาจากหน้าเรียก)
  List<Map<String, dynamic>> orderItems = [
    {
      'orderNumber': '000001', // หมายเลขออเดอร์
      'name': 'ข้าวผัดกระเพราไก่',
      'option': 'พิเศษ, ไข่ดาว, ไม่ใส่พริก',
      'description': 'ขอน้ำปลาพริกแยก',
      'quantity': 'x2',
    },
    {
      'orderNumber': '000002', // หมายเลขออเดอร์
      'name': 'ส้มตำไทย',
      'option': 'ไม่ใส่ถั่ว, เผ็ดน้อย',
      'description': '',
      'quantity': 'x1',
    },
    {'name': 'น้ำเปล่า', 'option': 'เย็น', 'description': '', 'quantity': 'x3'},
  ];

  // ช่วยอ่านค่าแบบปลอดภัยจาก _selectedJob
  // ชื่อร้าน
  String get payType => _selectedJob?['payType'] as String? ?? '-';
  String get restaurantName =>
      _selectedJob?['restaurantName'] as String? ?? '-';
  // ที่อยู่ร้าน
  String get restaurantAddress =>
      _selectedJob?['restaurantAddress'] as String? ??
      '999 ซอยอาชัย ถนนแดง เชียงเครือ เมืองสกลนคร สกลนคร';
  // ชื่อผู้รับ
  String get customerName => _selectedJob?['customerName'] as String? ?? 'สมุย';
  // ชื่อที่อยู่ผู้รับ
  String get titleCustomerAddress =>
      _selectedJob?['titleCustomerAddress'] as String? ?? '-';
  // ที่อยู่ผู้รับ
  String get customerAddress =>
      _selectedJob?['customerAddress'] as String? ??
      '999 ซอยอาชัย ถนนแดง เชียงเครือ เมืองสกลนคร สกลนคร';
  // จำนวนเงินที่ต้องจ่าย
  int get shopPayAmount => _selectedJob?['shopPayAmount'] is int
      ? _selectedJob!['shopPayAmount'] as int
      : (_selectedJob?['shopPayAmount'] is String
            ? int.tryParse(_selectedJob!['shopPayAmount'].toString()) ?? 0
            : 0);
  // หมายเหตุ
  String get note1 =>
      _selectedJob?['note1'] as String? ?? 'แขวน/วางไว้จุดที่ระบุ';
  // หมายเหตุเพิ่มเติม
  String get note2 =>
      _selectedJob?['note2'] as String? ?? 'เพิ่มเติม: วางบนหลังคา';
  // หมายเลขออเดอร์
  String get orderNumberDisplay {
    if (_selectedJob != null && _selectedJob!['orderNumber'] != null)
      return _selectedJob!['orderNumber'].toString();
    if (orderItems.isNotEmpty && orderItems.first.containsKey('orderNumber'))
      return orderItems.first['orderNumber'].toString();
    return '';
  }

  // รายรับ
  int get earn {
    if (_selectedJob != null && _selectedJob!['earn'] is int) {
      return _selectedJob!['earn'] as int;
    }
    return 0;
  }

  // โบนัส
  int get bonus {
    if (_selectedJob != null && _selectedJob!['bonus'] is int) {
      return _selectedJob!['bonus'] as int;
    }
    return 0;
  }

  void _showOrderDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // หัวข้อ dialog พื้นหลังสีเขียว
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ข้อมูลร้านอาหาร
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
                          restaurantName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'หมายเลขออเดอร์: $orderNumberDisplay',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              // รายการอาหาร
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(0),
                  shrinkWrap: true,
                  children: orderItems.map((item) {
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  item['option'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item['quantity'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ส่วนล่าง - ราคารวม
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'จ่ายให้ร้าน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '\$${shopPayAmount.toString()}',
                      style: TextStyle(
                        fontSize: 20,
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
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bike, color: Colors.green, size: 28),
            SizedBox(height: 8),
            Text('ยืนยันการเดินทาง'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'คุณต้องการเดินทางไปยังร้านอาหารใช่หรือไม่?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: false,
            child: Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                arrivedAtRestaurant = true;
              });
            },
            isDefaultAction: true,
            child: Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showConfirmArrivalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant, color: Colors.green, size: 28),
            SizedBox(height: 6),
            Text('ยืนยันถึงร้านอาหาร'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'คุณได้มาถึงร้านอาหารแล้วใช่หรือไม่?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: false,
            child: Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                confirmedArrival = true;
              });
            },
            isDefaultAction: true,
            child: Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showConfirmPickupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(height: 6),
            Text('ยืนยันรับอาหาร'),
          ],
        ), // หรือเปลี่ยนเป็นหัวข้อที่คุณต้องการ
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'โปรดตรวจสอบรายการอาหาร\nคุณได้รับอาหารเรียบร้อยแล้วใช่หรือไม่?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: false,
            child: Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              // ส่งข้อมูลทั้งหมดที่หน้า GoRestaurant รับมา ไปยัง GoCustomer
              final Map<String, dynamic> argsToCustomer = {
                // ถ้ามี _selectedJob ให้ใช้ค่านั้นเป็นแหล่งข้อมูลหลัก
                'payType': _selectedJob?['payType'] ?? '-',
                'restaurantName':
                    _selectedJob?['restaurantName'] ?? 'ร้าน ผญ.โซ้',
                'restaurantAddress': _selectedJob?['restaurantAddress'] ?? '-',
                'customerName': _selectedJob?['customerName'] ?? 'สมุย',
                'titleCustomerAddress':
                    _selectedJob?['titleCustomerAddress'] ?? 'หอ',
                'customerAddress':
                    _selectedJob?['customerAddress'] ??
                    '999 ซอยอาชัย ถนนแดง เชียงเครือ เมืองสกลนคร สกลนคร',
                'payAtShop':
                    _selectedJob?['shopPayAmount'] ??
                    _selectedJob?['payAtShop'] ??
                    0,
                'note1': _selectedJob?['note1'] ?? note1,
                'note2': _selectedJob?['note2'] ?? note2,
                'orderItems': orderItems,
                'orderNumber':
                    _selectedJob?['orderNumber'] ??
                    (orderItems.isNotEmpty
                        ? orderItems.first['orderNumber']
                        : null),
                // ถ้าต้องการส่งข้อมูลเพิ่มเติม เช่น earn/bonus/jobsList/index
                'earn': _selectedJob?['earn'] ?? 0,
                'bonus': _selectedJob?['bonus'] ?? 0,
                'jobsList': _jobsList,
              };

              Navigator.pushNamed(
                context,
                '/goCustomer',
                arguments: argsToCustomer,
              );
            },
            isDefaultAction: true,
            child: Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        leadingWidth: 140,
        toolbarHeight: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, right: 8),
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFE0E0E0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'ยกเลิกออเดอร์',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                side: BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: Size(0, 36),
              ),
              child: Text(
                'แจ้งร้านปิด',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(12),
          child: SizedBox(height: 12),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Section
            Container(
              color: Color(0xFF4CAF50),
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          arrivedAtRestaurant
                              ? (confirmedArrival
                                    ? '1. รับอาหาร'
                                    : '1. ถึงร้านอาหาร')
                              : '1. ไปร้าน',
                          style: TextStyle(
                            color: arrivedAtRestaurant
                                ? Colors.green[900]
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          restaurantName,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
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
                          'สมุย',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Contact Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant, color: Colors.grey[600], size: 20),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ร้านอาหาร',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            restaurantName, // ใช้จาก argument
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.facebook,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey[600], size: 20),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ลูกค้า',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            customerName, // ใช้จาก argument
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        // ปุ่มแชท
                        onTap: () {
                          Navigator.pushNamed(context, '/chat');
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
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

            SizedBox(height: 16),
            // หลัง Container รายการอาหาร (ก่อนแผนที่/คำแนะนำ)
            if (arrivedAtRestaurant && !confirmedArrival)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _showOrderDetailsDialog(context),
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
                      SizedBox(width: 8),
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
            SizedBox(height: 16),

            // รายการอาหาร (แสดงเฉพาะถ้ายังไม่อยู่หน้าปุ่ม "ยืนยันถึงร้านอาหาร")
            if (!(arrivedAtRestaurant && !confirmedArrival))
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // หมายเลขออเดอร์
                    Text(
                      'หมายเลขออเดอร์: ${orderItems.isNotEmpty ? orderItems.first['orderNumber'] : ''}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'รายการอาหาร',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${orderItems.length} รายการ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...orderItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OrderItem(
                          name: item['name'],
                          option: item['option'],
                          description: item['description'],
                          quantity: item['quantity'],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // แสดงแผนที่ เฉพาะเมื่อยังไม่ถึงร้าน หรือยังไม่ยืนยันถึงร้าน
            if (!confirmedArrival)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ไปร้านอาหาร',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurantName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          restaurantAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),
                        // Map placeholder
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green[100]!,
                                      Colors.blue[50]!,
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 50,
                                top: 40,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 30,
                                top: 20,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'หอพักบ้านสมุย ม.เกษตรศาสตร์',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
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
                  SizedBox(height: 16),
                ],
              ),

            // Recommendation Section
            if (!confirmedArrival)
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คำแนะนำ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      arrivedAtRestaurant
                          ? 'คุณถึงร้านอาหารแล้ว'
                          : 'คุณจะไปถึงร้านประมาณ 7 นาที',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Price and Action Section (ยังอยู่ในเนื้อหน้า สำหรับสถานะ 1-2 เท่านั้น)
            // ย้ายปุ่มไปไว้ bottomNavigationBar แทน เพื่อให้สอดคล้องกับหน้า GoCustomer
            // if (false && !confirmedArrival)
            //   SafeArea(
            //     child: Container(
            //       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            //       decoration: BoxDecoration(
            //         color: Colors.white,
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.black12,
            //             blurRadius: 8,
            //             offset: Offset(0, -2),
            //           ),
            //         ],
            //         border: Border(
            //           top: BorderSide(color: Colors.grey.shade200),
            //         ),
            //       ),
            //       child: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //             children: const [
            //               Text(
            //                 'จ่ายให้ร้าน',
            //                 style: TextStyle(
            //                   fontSize: 20,
            //                   fontWeight: FontWeight.bold,
            //                   color: Colors.blue,
            //                 ),
            //               ),
            //               Text(
            //                 '\$50',
            //                 style: TextStyle(
            //                   fontSize: 24,
            //                   fontWeight: FontWeight.bold,
            //                   color: Colors.blue,
            //                 ),
            //               ),
            //             ],
            //           ),
            //           SizedBox(height: 12),
            //           SizedBox(
            //             width: double.infinity,
            //             height: 50,
            //             child: ElevatedButton(
            //               onPressed: () {
            //                 if (!arrivedAtRestaurant) {
            //                   _showConfirmationDialog(context);
            //                 } else if (!confirmedArrival) {
            //                   _showConfirmArrivalDialog(context);
            //                 } else {
            //                   _showConfirmPickupDialog(context);
            //                 }
            //               },
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: Color(0xFF4CAF50),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(25),
            //                 ),
            //                 elevation: 2,
            //               ),
            //               child: Text(
            //                 confirmedArrival
            //                     ? 'ยืนยันรับอาหาร'
            //                     : (arrivedAtRestaurant
            //                           ? 'ยืนยันถึงร้านอาหาร'
            //                           : 'เดินทางไปร้านอาหาร'),
            //                 style: TextStyle(
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.bold,
            //                   color: Colors.white,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // SizedBox(height: 32),
          ],
        ),
      ),

      // แถบล่าง (Bottom bar) ให้เหมือนหน้า GoCustomer ใช้ทุกสถานะ
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // if (arrivedAtRestaurant) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'จ่ายให้ร้าน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    '\$${shopPayAmount.toString()}', // แสดงยอดจ่ายจริงจาก argument
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (!arrivedAtRestaurant) {
                      _showConfirmationDialog(context);
                    } else if (!confirmedArrival) {
                      _showConfirmArrivalDialog(context);
                    } else {
                      _showConfirmPickupDialog(context);
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
                    confirmedArrival
                        ? 'ยืนยันรับอาหาร'
                        : (arrivedAtRestaurant
                              ? 'ยืนยันถึงร้านอาหาร'
                              : 'เดินทางไปร้านอาหาร'),
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
  }
}

class OrderItem extends StatelessWidget {
  final String name;
  final String option;
  final String description;
  final String quantity;

  const OrderItem({
    Key? key,
    required this.name,
    required this.option,
    required this.description,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 2),
              Text(
                option,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              if (description.isNotEmpty) ...[
                SizedBox(height: 2),
                Text(
                  "เพิ่มเติม: " + description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
        Text(
          quantity,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}
