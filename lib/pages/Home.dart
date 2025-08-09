import 'package:flutter/material.dart';
import 'JobStart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Profile & Greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(
                      'assets/avatars/avatar-4.png',
                    ), // Replace with your asset
                  ),
                  const SizedBox(width: 16),
                  // Greeting and name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'สวัสดี',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'จอห์น วิค',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Icon(Icons.chevron_right, color: Colors.grey, size: 28),
                ],
              ),
            ),
            // Earnings Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              // child: Card(
              //   shadowColor: Colors.grey.withOpacity(0.9),
              //   elevation: 5, // เพิ่มความสูงของเงา
              //   surfaceTintColor: Colors.transparent, // ป้องกันสี overlay
              //   color: Colors.white,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3), // สีเงา
                      blurRadius: 12, // ความฟุ้งของเงา
                      spreadRadius: 4, // การกระจายของเงา
                      offset: Offset(0, 4), // ย้ายเงา (0,0) = รอบด้าน
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(
                              Icons.attach_money,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '\$852',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'รายได้วันนี้',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Today's tips
                          Column(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$50',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'ทิปวันนี้',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          // Today's jobs
                          Column(
                            children: [
                              Icon(
                                Icons.pedal_bike,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '25 งาน',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'งานวันนี้',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          // Rating
                          Column(
                            children: [
                              Icon(Icons.star, color: Colors.orange, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                '4.5',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'ดูรีวิวทั้งหมด',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Start Work Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JobStartPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'เริ่มรับงาน',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
