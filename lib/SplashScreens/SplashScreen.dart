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
      // ถ้า login แล้วให้ตรวจสอบสถานะไรเดอร์
      final riderStatus = await RiderStatusService.getCurrentStatus();

      if (riderStatus == RiderStatus.incomplete) {
        // ยังไม่ยืนยันตัวตน -> ไปหน้ายืนยันตัวตน
        Navigator.pushReplacementNamed(context, '/riderIdentity');
      } else {
        // ยืนยันตัวตนแล้ว -> ไปหน้า Home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // ไม่ได้ login หรือ token หมดอายุ -> ไปหน้า welcome
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
