import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rider_delivery/APIs/middleware/AuthGuard.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    print('SplashScreen loaded'); // 🐞 เพิ่ม log
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 2)); // splash time

    // ตรวจสอบ authentication ด้วย AuthGuard
    final isLoggedIn = await AuthGuard.isUserLoggedIn();

    if (isLoggedIn) {
      print('✅ User is logged in, checking rider status...');

      // แสดงข้อมูลก่อนตรวจสอบ
      await RiderStatusService.debugPrintStoredData();

      // ตรวจสอบสถานะจากเซิร์ฟเวอร์ก่อน
      try {
        await RiderStatusService.checkStatusFromServer();
        print('✅ Status checked from server successfully');
      } catch (e) {
        print('❌ Error checking status from server: $e');
      }

      // แสดงข้อมูลหลังตรวจสอบจากเซิร์ฟเวอร์
      await RiderStatusService.debugPrintStoredData();

      // ดึงสถานะหลังจากตรวจสอบจากเซิร์ฟเวอร์แล้ว
      final riderStatus = await RiderStatusService.getCurrentStatus();
      print('📊 Final rider status: $riderStatus');

      switch (riderStatus) {
        case RiderStatus.incomplete:
          // ยังไม่ยืนยันตัวตน -> ไปหน้ายืนยันตัวตน
          print('🔄 Redirecting to identity verification...');
          Navigator.pushReplacementNamed(context, '/riderIdentity');
          break;
        case RiderStatus.pending:
        case RiderStatus.approved:
        case RiderStatus.rejected:
          // ส่งเอกสารแล้ว -> ไปหน้า Home (แสดงสถานะต่างๆ)
          print('🏠 Redirecting to home...');
          Navigator.pushReplacementNamed(context, '/home');
          break;
      }
    } else {
      // ไม่ได้ login หรือ token หมดอายุ -> ไปหน้า welcome
      print('❌ User not logged in, redirecting to welcome...');
      Navigator.pushReplacementNamed(context, '/wellcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    const String motorbike = 'assets/svg/motorcycle.svg';

    return Scaffold(
      backgroundColor: const Color(0xFF34C759),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              motorbike,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 30),
            Text(
              'CSC FOOD',
              style: GoogleFonts.prompt(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'for you',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 200),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 10),
            const Text(
              'กำลังโหลด ...',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
