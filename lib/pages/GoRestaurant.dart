import 'package:flutter/material.dart';

class GoRestaurant extends StatefulWidget {
  @override
  _GoRestaurantState createState() => _GoRestaurantState();
}

class _GoRestaurantState extends State<GoRestaurant> {
  bool arrivedAtRestaurant = false;

  // ตัวอย่างรายการอาหาร
  final List<Map<String, dynamic>> orderItems = [
    {
      'name': 'ข้าวผัดกระเพราไก่',
      'option': 'พิเศษ, ไข่ดาว, ไม่ใส่พริก',
      'description': 'ขอน้ำปลาพริกแยก',
      'quantity': 'x2',
    },
    {
      'name': 'ส้มตำไทย',
      'option': 'ไม่ใส่ถั่ว, เผ็ดน้อย',
      'description': '',
      'quantity': 'x1',
    },
    {'name': 'น้ำเปล่า', 'option': 'เย็น', 'description': '', 'quantity': 'x3'},
  ];

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
                child: Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.grey[700], size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'ร้าน ผญ.โซ้',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                                  item['option'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item['quantity'],
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
                  children: const [
                    Text(
                      'จ่ายให้ร้าน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '\$50',
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
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.directions_bike, color: Colors.green),
            SizedBox(width: 8),
            Text('ยืนยันการเดินทาง'),
          ],
        ),
        content: Text('คุณต้องการเดินทางไปยังร้านอาหารใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                arrivedAtRestaurant = true;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('ยืนยัน'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          arrivedAtRestaurant ? '1. ถึงร้านอาหาร' : '1. ไปร้าน',
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
                          'ครัวตามใจ',
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
                            'ร้าน ผญ.โซ้',
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
                            'สมุย',
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

            // รายการอาหาร (แสดงเฉพาะเมื่อยังไม่กดไปร้าน)
            if (!arrivedAtRestaurant)
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
                          '3 รายการ',
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

            // ปุ่มดูรายละเอียด (แสดงเมื่อกดไปร้านแล้ว)
            if (arrivedAtRestaurant)
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
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    minimumSize: Size(double.infinity, 56),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 24),
            // Go to Restaurant Section
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
                    'ร้าน ผญ.โซ้',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '999 ซอยอาชัย ถนนแดง เชียงเครือ เมืองสกลนคร สกลนคร',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                              colors: [Colors.green[100]!, Colors.blue[50]!],
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
            // Recommendation Section
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
                    'คำแนะนำ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            // Price and Action Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'จ่ายให้ร้าน',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '\$50',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!arrivedAtRestaurant) {
                          _showConfirmationDialog(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        arrivedAtRestaurant
                            ? 'ยืนยันถึงร้านอาหาร'
                            : 'เดินทางไปร้านอาหาร',
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
            SizedBox(height: 32),
          ],
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
