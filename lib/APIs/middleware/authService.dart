// login , register , identify user
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../baseAPI_URL/baseURL.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Login แบบ manual (email + password)
  Future<Map<String, dynamic>> loginRider(String email, String password) async {
    try {
      final url = Uri.parse('${BaseAPI_URL.baseURL}/login');
      print('🌐 Trying to connect to: $url'); // Debug URL

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📡 Response status: ${response.statusCode}'); // Debug response

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // บันทึกข้อมูลลง SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_rider', jsonEncode(data['user']));

        // บันทึก refresh token ถ้ามี
        if (data['refresh_token'] != null) {
          await prefs.setString('refresh_token', data['refresh_token']);
        }

        // บันทึกเวลาที่ login
        await prefs.setString('login_time', DateTime.now().toIso8601String());

        // บันทึกสถานะการยืนยันตัวตน
        if (data['rider_status'] != null) {
          await prefs.setString(
            'rider_status',
            jsonEncode(data['rider_status']),
          );
        }

        return {
          'success': true,
          'data': data,
          'user': data['user'],
          'rider_status': data['rider_status'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Login failed: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  // ตรวจสอบและ refresh token หากจำเป็น
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final refreshToken = prefs.getString('refresh_token');

      if (token == null) return false;

      // ตรวจสอบว่า token ใกล้หมดอายุหรือไม่ (เหลือ 24 ชั่วโมง)
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final expiry = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeLeft = expiry - now;

      // ถ้าเหลือเวลาน้อยกว่า 24 ชั่วโมง หรือ token หมดอายุแล้ว
      if (timeLeft < 86400) {
        // ถ้าไม่มี refresh token ให้ logout
        if (refreshToken == null) {
          await logout();
          return false;
        }

        // เรียก API refresh token
        final refreshResult = await _callRefreshTokenAPI(refreshToken);

        if (refreshResult['success']) {
          // บันทึก token ใหม่
          await prefs.setString('token', refreshResult['token']);
          print('Token refreshed successfully');
          return true;
        } else {
          // ถ้า refresh ไม่สำเร็จ ให้ logout
          await logout();
          print('Refresh token failed: ${refreshResult['message']}');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Refresh token error: $e');
      // ถ้ามี error ให้ logout เพื่อความปลอดภัย
      await logout();
      return false;
    }
  }

  // เรียก API refresh token
  Future<Map<String, dynamic>> _callRefreshTokenAPI(String refreshToken) async {
    try {
      final url = Uri.parse('${BaseAPI_URL.baseURL}/refresh-token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['token'],
          'message': data['message'] ?? 'Token refreshed successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              data['error'] ?? 'Refresh token failed: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการ refresh token: $e',
      };
    }
  }

  // Logout และล้างข้อมูล
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_rider');
    await prefs.remove('rider_status');
    await prefs.remove('login_time');
    await prefs.remove('submission_date');
    await prefs.remove('approval_message');
  }

  // ตรวจสอบสถานะ token และ refresh อัตโนมัติถ้าจำเป็น
  Future<bool> ensureValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return false;

      // ตรวจสอบว่า token ยังใช้ได้อยู่หรือไม่
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final expiry = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // ถ้า token หมดอายุหรือใกล้หมดอายุ (เหลือ 5 นาที)
      if (expiry <= now + 300) {
        // 300 seconds = 5 minutes
        return await refreshToken();
      }

      return true;
    } catch (e) {
      print('ensureValidToken error: $e');
      return false;
    }
  }

  // ดึงข้อมูลโปรไฟล์จาก API (ตัวอย่าง method ที่ใช้ token)
  Future<Map<String, dynamic>> getRiderProfile() async {
    try {
      // ตรวจสอบและ refresh token ก่อนเรียก API
      final hasValidToken = await ensureValidToken();
      if (!hasValidToken) {
        return {'success': false, 'message': 'Token ไม่ถูกต้องหรือหมดอายุ'};
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${BaseAPI_URL.baseURL}/profile');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              data['error'] ??
              'Failed to get profile: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการดึงข้อมูล: $e'};
    }
  }

  // login
}
