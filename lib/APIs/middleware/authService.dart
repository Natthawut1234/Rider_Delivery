// login , register , identify user
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

        // บันทึก rider_id แยกต่างหาก เพื่อป้องกันการสูญหาย
        if (data['user'] != null && data['user']['rider_id'] != null) {
          await prefs.setInt('cached_rider_id', data['user']['rider_id']);
          print(
            '🔐 Manual Login: Cached rider_id = ${data['user']['rider_id']}',
          );
        }

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

  // Login โดย Google
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final url = Uri.parse('${BaseAPI_URL.baseURL}/google-login');
      print('🌐 Trying Google login to: $url'); // Debug URL

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tokenId': idToken}),
      );

      print(
        '📡 Google login response status: ${response.statusCode}',
      ); // Debug response

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // บันทึกข้อมูลลง SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_rider', jsonEncode(data['user']));

        // บันทึก rider_id แยกต่างหาก เพื่อป้องกันการสูญหาย
        if (data['user'] != null && data['user']['rider_id'] != null) {
          await prefs.setInt('cached_rider_id', data['user']['rider_id']);
          print(
            '🔐 Google Login: Cached rider_id = ${data['user']['rider_id']}',
          );
        }

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
          'message':
              data['error'] ?? 'Google login failed: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ Google: $e',
      };
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

  // ยืนยันตัวตนไรเดอร์ (ขั้นตอนที่ 2)
  Future<Map<String, dynamic>> submitIdentityVerification({
    required String idCardNumber,
    required String driverLicenseNumber,
    String vehicleType = 'motorcycle',
    required String vehicleBrandModel,
    required String vehicleColor,
    required String vehicleRegistrationNumber,
    required String vehicleRegistrationProvince,
    required Map<String, File> documents,
  }) async {
    try {
      // ตรวจสอบและ refresh token ก่อนเรียก API
      final hasValidToken = await ensureValidToken();
      if (!hasValidToken) {
        return {'success': false, 'message': 'Token ไม่ถูกต้องหรือหมดอายุ'};
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${BaseAPI_URL.baseURL}/identity-verification');
      print('🌐 Submitting identity verification to: $url');

      // สร้าง multipart request
      var request = http.MultipartRequest('POST', url);

      // เพิ่ม headers
      request.headers['Authorization'] = 'Bearer $token';

      // เพิ่มข้อมูลฟอร์ม
      request.fields['id_card_number'] = idCardNumber;
      request.fields['driving_license_number'] = driverLicenseNumber;
      request.fields['vehicle_type'] = vehicleType;
      request.fields['vehicle_brand_model'] = vehicleBrandModel;
      request.fields['vehicle_color'] = vehicleColor;
      request.fields['vehicle_registration_number'] = vehicleRegistrationNumber;
      request.fields['vehicle_registration_province'] =
          vehicleRegistrationProvince;

      // เพิ่มไฟล์เอกสาร - ตรวจสอบว่าไฟล์มีอยู่จริงก่อน
      int validFileCount = 0;
      for (var entry in documents.entries) {
        if (entry.value.existsSync()) {
          try {
            // ตรวจสอบ file extension และกำหนด content type
            String contentType = 'image/jpeg';
            String fileName = entry.value.path.split('/').last;

            if (fileName.toLowerCase().endsWith('.png')) {
              contentType = 'image/png';
            } else if (fileName.toLowerCase().endsWith('.jpg') ||
                fileName.toLowerCase().endsWith('.jpeg')) {
              contentType = 'image/jpeg';
            }

            // อ่านไฟล์และสร้าง multipart file
            final fileBytes = await entry.value.readAsBytes();
            var multipartFile = http.MultipartFile.fromBytes(
              entry.key,
              fileBytes,
              filename: '${entry.key}.jpg',
              contentType: MediaType.parse(contentType),
            );

            request.files.add(multipartFile);
            validFileCount++;
            print(
              '✅ Added file: ${entry.key} (${entry.value.path}) as $contentType',
            );
          } catch (e) {
            print('❌ Failed to add file ${entry.key}: $e');
          }
        } else {
          print('⚠️ File does not exist: ${entry.key} (${entry.value.path})');
        }
      }

      print(
        '📤 Sending $validFileCount files out of ${documents.length} requested',
      );

      // ตรวจสอบว่ามีไฟล์จำเป็นครบไหม
      final requiredFiles = [
        'id_card_selfie',
        'driving_license_photo',
        'vehicle_registration_photo',
      ];
      final missingFiles = <String>[];

      for (String requiredFile in requiredFiles) {
        if (!documents.containsKey(requiredFile) ||
            !documents[requiredFile]!.existsSync()) {
          missingFiles.add(requiredFile);
        }
      }

      if (missingFiles.isNotEmpty) {
        return {
          'success': false,
          'message': 'ไฟล์จำเป็นไม่ครบ: ${missingFiles.join(', ')}',
        };
      }

      // ส่ง request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Identity verification response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // อัพเดตสถานะในแอพ
        await prefs.setString(
          'submission_date',
          DateTime.now().toIso8601String(),
        );

        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'ส่งข้อมูลยืนยันตัวตนสำเร็จ',
        };
      } else {
        return {
          'success': false,
          'message':
              data['error'] ??
              'ส่งข้อมูลยืนยันตัวตนไม่สำเร็จ: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('❌ Submit identity verification error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการส่งข้อมูล: $e'};
    }
  }

  // ตรวจสอบสถานะการอนุมัติ
  Future<Map<String, dynamic>> checkApprovalStatus() async {
    try {
      // ตรวจสอบและ refresh token ก่อนเรียก API
      final hasValidToken = await ensureValidToken();
      if (!hasValidToken) {
        return {'success': false, 'message': 'Token ไม่ถูกต้องหรือหมดอายุ'};
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userRider = prefs.getString('user_rider');

      if (userRider == null) {
        return {'success': false, 'message': 'ไม่พบข้อมูลผู้ใช้'};
      }

      // final userData = jsonDecode(userRider);
      // final userId = userData['user_id'];

      final url = Uri.parse('${BaseAPI_URL.baseURL}/approval-status');
      print('🌐 Checking approval status at: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Approval status response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        // ยังไม่ส่งเอกสาร
        return {
          'success': true,
          'data': {
            'has_profile': false,
            'can_submit': true,
            'status': 'incomplete',
          },
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'ไม่สามารถตรวจสอบสถานะได้',
        };
      }
    } catch (e) {
      print('❌ Check approval status error: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการตรวจสอบสถานะ: $e',
      };
    }
  }

  // ลงทะเบียนไรเดอร์ (ขั้นตอนที่ 1) - เชื่อมต่อกับ API backend
  Future<Map<String, dynamic>> registerRiderAPI({
    required String displayName,
    required String email,
    required String password,
    required String phone,
    required String birthdate,
    required String gender,
    required String address,
    required String province,
    required String amphure,
    required String tambon,
    File? profilePhoto,
  }) async {
    try {
      final url = Uri.parse('${BaseAPI_URL.baseURL}/register');
      print('🌐 Registering rider at: $url');

      // สร้าง multipart request
      var request = http.MultipartRequest('POST', url);

      // เพิ่มข้อมูลฟอร์ม
      request.fields['display_name'] = displayName;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['phone'] = phone;
      request.fields['birthdate'] = birthdate;
      // แปลง gender เป็น integer สำหรับฐานข้อมูล (0=ชาย, 1=หญิง)
      request.fields['gender'] = gender == 'male' ? '0' : '1';
      request.fields['address'] = address;
      request.fields['province'] = province;
      request.fields['amphure'] = amphure;
      request.fields['tambon'] = tambon;

      // เพิ่มรูปโปรไฟล์ (ถ้ามี)
      if (profilePhoto != null && profilePhoto.existsSync()) {
        final mimeType = _getMimeType(profilePhoto.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_photo',
            profilePhoto.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
        print('📤 Adding profile photo: ${profilePhoto.path}');
      }

      print(
        '📤 Sending registration data with fields: ${request.fields.keys.toList()}',
      );

      // ส่ง request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Registration response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // บันทึกข้อมูลการลงทะเบียนสำเร็จ
        final prefs = await SharedPreferences.getInstance();

        // เก็บ user_id ไว้สำหรับขั้นตอนถัดไป
        if (data['user_id'] != null) {
          await prefs.setString(
            'registered_user_id',
            data['user_id'].toString(),
          );
        }

        return {
          'success': true,
          'message': data['message'] ?? 'ลงทะเบียนสำเร็จ',
          'user_id': data['user_id'],
          'next_step': data['next_step'] ?? 'identity_verification',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'เกิดข้อผิดพลาดในการลงทะเบียน',
        };
      }
    } catch (e) {
      print('❌ Register rider API error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'};
    }
  }

  // Helper function สำหรับ MIME type
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // default fallback
    }
  }
}
