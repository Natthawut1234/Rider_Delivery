import 'package:flutter/material.dart';

class RiderReviewPage extends StatelessWidget {
  const RiderReviewPage({Key? key}) : super(key: key);

  // ตัวอย่างข้อมูลรีวิวสมมุติ
  final List<Map<String, dynamic>> reviews = const [
    {
      'customerName': 'Adisak',
      'rating': 5,
      'reviewText': 'บริการดีมากครับ ส่งของรวดเร็วทันใจ!',
      'date': '2024-08-15',
    },
    {
      'customerName': 'Boonchoo',
      'rating': 4,
      'reviewText': 'สภาพกล่องสินค้าดีมากครับ ไรเดอร์พูดจาสุภาพ',
      'date': '2024-08-14',
    },
    {
      'customerName': 'Chanon',
      'rating': 1,
      'reviewText': 'หาที่อยู่ไม่เจอ โทรศัพท์ไปก็ไม่รับสายเลยครับ',
      'date': '2024-08-13',
    },
    {
      'customerName': 'Darika',
      'rating': 5,
      'reviewText': 'ประทับใจมาก ส่งเร็วและของสดใหม่',
      'date': '2024-08-12',
    },
    {
      'customerName': 'Ekachai',
      'rating': 2,
      'reviewText': 'ดีครับ แต่อยากให้แจ้งก่อนถึงหน้าบ้าน',
      'date': '2024-08-11',
    },
  ];

  // คำนวณค่าเฉลี่ยคะแนน
  double get averageRating {
    if (reviews.isEmpty) return 0.0;
    double total = 0;
    for (var review in reviews) {
      total += review['rating'] as int;
    }
    return total / reviews.length;
  }

  // คำนวณจำนวนรีวิวแต่ละดาว
  Map<int, int> get ratingDistribution {
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      int rating = review['rating'] as int;
      distribution[rating] = distribution[rating]! + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'รีวิวจากลูกค้า',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
      ),
      body: Column(
        children: [
          // ส่วนแสดงสรุปคะแนน
          _buildRatingSummary(),

          // ส่วนแสดงรายการรีวิว
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewCard(review);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับแสดงสรุปคะแนน
  Widget _buildRatingSummary() {
    final distribution = ratingDistribution;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ค่าเฉลี่ยคะแนนใหญ่
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  // ดาวแสดงค่าเฉลี่ย
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: () {
                      final double rounded =
                          (averageRating * 2).round() / 2.0; // ปัดเป็น 0.5
                      return List.generate(5, (index) {
                        final pos = index + 1;
                        IconData icon;
                        if (rounded >= pos) {
                          icon = Icons.star;
                        } else if (rounded >= pos - 0.5) {
                          icon = Icons.star_half;
                        } else {
                          icon = Icons.star_border;
                        }
                        return Icon(icon, color: Colors.amber, size: 20);
                      });
                    }(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reviews.length} รีวิว',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // แท่งกราฟแสดงการกระจายคะแนน
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    int count = distribution[star]!;
                    double percentage = reviews.isEmpty
                        ? 0
                        : count / reviews.length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star'),
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: percentage,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget สำหรับแสดงรีวิวแต่ละรายการ
  Widget _buildReviewCard(Map<String, dynamic> review) {
    Color ratingColor = _getRatingColor(review['rating'] as int);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวของรีวิว
            Row(
              children: [
                // Avatar ของลูกค้า
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  radius: 20,
                  child: Text(
                    (review['customerName'] as String)[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ชื่อและวันที่
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customerName'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        review['date'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // คะแนนดาว
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ratingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: ratingColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${review['rating']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ratingColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ข้อความรีวิว
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Text(
                review['reviewText'] as String,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับกำหนดสีตามคะแนน
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
