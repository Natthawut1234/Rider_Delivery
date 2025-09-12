import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';
import '../JobStart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RiderStatus _riderStatus = RiderStatus.incomplete;
  String _statusMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRiderStatus();
  }

  Future<void> _checkRiderStatus() async {
    setState(() => _isLoading = true);

    // ตรวจสอบสถานะจากเซิร์ฟเวอร์
    await RiderStatusService.checkStatusFromServer();

    // ทดสอบการเรียก API โปรไฟล์ (จะ refresh token อัตโนมัติถ้าจำเป็น)
    await _testAPICall();

    // ดึงสถานะปัจจุบัน
    final status = await RiderStatusService.getCurrentStatus();
    final message = await RiderStatusService.getStatusMessage();

    setState(() {
      _riderStatus = status;
      _statusMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _testAPICall() async {
    try {
      final authService = AuthService();
      final result = await authService.getRiderProfile();

      if (result['success']) {
        print('✅ API call successful with auto token refresh');
        // ใช้ข้อมูลจาก result['data'] ได้ที่นี่
      } else {
        print('❌ API call failed: ${result['message']}');
      }
    } catch (e) {
      print('❌ API call error: $e');
    }
  }

  Widget _buildStatusCard() {
    Color cardColor;
    Color textColor;
    IconData icon;
    String title;

    switch (_riderStatus) {
      case RiderStatus.pending:
        cardColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        icon = Icons.hourglass_empty;
        title = 'รอการอนุมัติ';
        break;
      case RiderStatus.approved:
        cardColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        title = 'ได้รับการอนุมัติ';
        break;
      case RiderStatus.rejected:
        cardColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        title = 'ถูกปฏิเสธ';
        break;
      default:
        cardColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        icon = Icons.info;
        title = 'ยังไม่ยืนยันตัวตน';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: textColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_riderStatus == RiderStatus.pending)
            GestureDetector(
              onTap: _checkRiderStatus,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.refresh, color: textColor, size: 20),
              ),
            ),
          if (_riderStatus == RiderStatus.incomplete)
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/riderIdentity');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: textColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ยืนยันตัวตน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_riderStatus) {
      case RiderStatus.approved:
        return 'เริ่มรับงาน';
      case RiderStatus.pending:
        return 'รอการอนุมัติ';
      case RiderStatus.rejected:
        return 'ถูกปฏิเสธ';
      default:
        return 'ยืนยันตัวตนก่อน';
    }
  }

  String _getDisabledMessage() {
    switch (_riderStatus) {
      case RiderStatus.pending:
        return 'กรุณารอการอนุมัติจากทีมงาน เราจะแจ้งให้ทราบเร็วๆ นี้';
      case RiderStatus.rejected:
        return 'เอกสารของคุณถูกปฏิเสธ กรุณาติดต่อทีมงานเพื่อแก้ไข';
      default:
        return 'กรุณายืนยันตัวตนก่อนเริ่มรับงาน';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // แสดง dialog ยืนยันการออกจากแอพ
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ออกจากแอพ'),
            content: const Text('คุณต้องการออกจากแอพใช่หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('ออก'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop(); // ออกจากแอพ
        }

        return false; // ป้องกันการ pop ปกติ
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Profile & Greeting
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
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
                          children: [
                            Text(
                              'สวัสดี',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
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
              ),

              // Rider Status Card
              _buildStatusCard(),

              // Earnings Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
                        // สรุปรายได้แบบการ์ดย่อ
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pushNamed(context, '/income');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.green[100],
                                    child: Icon(
                                      Icons.attach_money,
                                      color: Colors.green[700],
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '\$852',
                                          style: TextStyle(
                                            color: Colors.green[800],
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'รายได้วันนี้',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Column(
                                  //   crossAxisAlignment: CrossAxisAlignment.end,
                                  //   children: [
                                  //     Text(
                                  //       '+12%',
                                  //       style: TextStyle(
                                  //         color: Colors.green[600],
                                  //         fontWeight: FontWeight.w600,
                                  //       ),
                                  //     ),
                                  //     const SizedBox(height: 4),
                                  //     Text(
                                  //       'เมื่อวาน',
                                  //       style: TextStyle(
                                  //         fontSize: 12,
                                  //         color: Colors.grey[500],
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Divider(),

                        // เครดิตรับงาน
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // เพิ่มการทำงานเมื่อกดถ้าต้องการ
                              Navigator.pushNamed(context, '/myCredit');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.blue[100],
                                    child: Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: Colors.blue[700],
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '\$420',
                                          style: TextStyle(
                                            color: Colors.blue[800],
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'เครดิตรับงาน',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Column(
                                  //   crossAxisAlignment: CrossAxisAlignment.end,
                                  //   children: [
                                  //     Text(
                                  //       'คงเหลือ',
                                  //       style: TextStyle(
                                  //         fontSize: 12,
                                  //         color: Colors.grey[500],
                                  //       ),
                                  //     ),
                                  //     const SizedBox(height: 4),
                                  //     Text(
                                  //       '\$420',
                                  //       style: TextStyle(
                                  //         fontSize: 14,
                                  //         color: Colors.blue[700],
                                  //         fontWeight: FontWeight.w600,
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
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
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.pushNamed(context, '/trip');
                                  },
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.monetization_on,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$50',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                ),
                              ],
                            ),
                            // Today's jobs
                            Column(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.pushNamed(context, '/jobs');
                                  },
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.pedal_bike,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '25 งาน',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                ),
                              ],
                            ),

                            // Rating
                            Column(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/riderReview',
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '4.5',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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

              // Debug Panel (แสดงเฉพาะในโหมดพัฒนา)
              if (_riderStatus != RiderStatus.incomplete) ...[
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Panel (สำหรับทดสอบ)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () async {
                                await RiderStatusService.setApproved(
                                  '🎉 ยินดีด้วย! เอกสารของคุณได้รับการอนุมัติแล้ว\nคุณสามารถเริ่มรับงานได้แล้ว',
                                );
                                _checkRiderStatus();
                              },
                              child: const Text(
                                'อนุมัติ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () async {
                                await RiderStatusService.setRejected(
                                  '❌ เอกสารของคุณไม่ผ่านการตรวจสอบ\nกรุณาติดต่อทีมงานเพื่อแก้ไข',
                                );
                                _checkRiderStatus();
                              },
                              child: const Text(
                                'ปฏิเสธ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () async {
                                await RiderStatusService.resetStatus();
                                _checkRiderStatus();
                              },
                              child: const Text(
                                'รีเซ็ต',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),
              // Start Work Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _riderStatus == RiderStatus.approved
                          ? Colors.green
                          : _riderStatus == RiderStatus.incomplete
                          ? Colors.blue
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _riderStatus == RiderStatus.approved
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const JobStartPage(),
                              ),
                            );
                          }
                        : _riderStatus == RiderStatus.incomplete
                        ? () {
                            // ไปหน้ายืนยันตัวตน
                            Navigator.pushNamed(context, '/riderIdentity');
                          }
                        : () {
                            // แสดงข้อความเมื่อยังไม่ได้รับอนุมัติ
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_getDisabledMessage()),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _getButtonText(),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ), // ปิด SafeArea Column
        ), // ปิด SafeArea
      ), // ปิด Scaffold
    ); // ปิด WillPopScope
  }
}
