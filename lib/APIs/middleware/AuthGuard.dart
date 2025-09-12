import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authService.dart';

// เก็บ token , user info และตรวจสอบความถูกต้อง

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userRider = prefs.getString('user_rider');

    // ตรวจสอบว่ามีข้อมูลครบ
    if (token == null || userRider == null) {
      return false;
    }

    // ใช้ AuthService เพื่อตรวจสอบและ refresh token อัตโนมัติ
    final authService = AuthService();
    final hasValidToken = await authService.ensureValidToken();

    if (!hasValidToken) {
      // ถ้า token หมดอายุหรือไม่ถูกต้อง ให้ลบข้อมูลออก
      await _clearAuthData();
      return false;
    }

    return true;
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_rider');
    await prefs.remove('rider_status');
  }

  // Static method สำหรับตรวจสอบสถานะ authentication จากที่อื่น
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final expiry = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return expiry != null && expiry > now;
    } catch (e) {
      return false;
    }
  }

  // Static method สำหรับ logout
  static Future<void> logout() async {
    final authService = AuthService();
    await authService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !(snapshot.data ?? false)) {
          // ถ้าไม่ authenticated, token หมดอายุ หรือมี error ให้ไปที่หน้า welcome
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/wellcome',
              (route) => false, // ลบ navigation stack ทั้งหมด
            );
          });
          return const SizedBox.shrink();
        }

        // ถ้า authenticated และ token ยังไม่หมดอายุ ให้แสดง child widget
        return child;
      },
    );
  }
}
