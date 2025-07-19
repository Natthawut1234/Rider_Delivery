import 'package:flutter/material.dart';

class JobStartPage extends StatelessWidget {
  const JobStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ตัวอย่างข้อมูล 3 งาน
    final jobs = [
      {
        'payType': 'เงินสด',
        'payTypeColor': Colors.green,
        'shopPay': 'จ่ายให้ร้าน',
        'shopPayColor': Colors.blue,
        'shopPayAmount': '\$50',
        'earn': '\$22',
        'bonus': '\$5',
        'pickupTitle': 'ไปร้าน 0.25 กม.',
        'pickupDetail':
            'ร้าน ผญ.โซ้\n9/99 ซอยอาชัย ถนนแดง เชียงเครือ เมืองสกลนคร สกลนคร',
        'dropoffTitle': 'หอ',
        'dropoffDetail': '2/22 ซอยอาชัย ถนนแดง เชียงเครือ เมืองสกลนคร สกลนคร',
      },
      {
        'payType': 'เงินสด',
        'payTypeColor': Colors.green,
        'shopPay': 'จ่ายให้ร้าน',
        'shopPayColor': Colors.blue,
        'shopPayAmount': '\$40',
        'earn': '\$18',
        'bonus': '\$3',
        'pickupTitle': 'ไปคาเฟ่ 0.5 กม.',
        'pickupDetail': 'คาเฟ่บ้านสวน\n123/1 ถนนสุขใจ เมืองสกลนคร สกลนคร',
        'dropoffTitle': 'บ้านลูกค้า',
        'dropoffDetail': '88/8 ถนนสุขใจ เมืองสกลนคร สกลนคร',
      },
      {
        'payType': 'เงินสด',
        'payTypeColor': Colors.green,
        'shopPay': 'จ่ายให้ร้าน',
        'shopPayColor': Colors.blue,
        'shopPayAmount': '\$60',
        'earn': '\$25',
        'bonus': '\$7',
        'pickupTitle': 'ไปตลาด 1.2 กม.',
        'pickupDetail': 'ตลาดสดเทศบาล\n456/7 ถนนตลาด เมืองสกลนคร สกลนคร',
        'dropoffTitle': 'อพาร์ทเมนท์',
        'dropoffDetail': '12/34 ถนนตลาด เมืองสกลนคร สกลนคร',
      },
    ];

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
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // สรุปรายได้
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
                      const Text(
                        '\$852',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                        onPressed: () {},
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
              // ทำซ้ำ
              ...jobs.map(
                (job) => Padding(
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
                                  color: (job['payTypeColor'] as Color)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  job['payType'] as String,
                                  style: TextStyle(
                                    color: job['payTypeColor'] as Color,
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
                                  color: (job['shopPayColor'] as Color)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  job['shopPay']! as String,
                                  style: TextStyle(
                                    color: job['shopPayColor'] as Color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                job['shopPayAmount']! as String,
                                style: TextStyle(
                                  color: job['shopPayColor'] as Color,
                                  fontWeight: FontWeight.bold,
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
                                job['earn']! as String,
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
                                job['bonus']! as String,
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
                                width: 36, // กำหนดขนาดของวงกลม
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.green[100], // สีพื้นหลังของวงกลม
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
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
                                      job['pickupTitle']! as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      job['pickupDetail']! as String,
                                      style: const TextStyle(fontSize: 14),
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
                                width: 36, // กำหนดขนาดของวงกลม
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.red[100], // สีพื้นหลังของวงกลม
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
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
                                      '${job['dropoffTitle']}\n${job['dropoffDetail']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                              onPressed: () {
                                Navigator.pushNamed(context, '/GoRestaurant',);
                              },
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
