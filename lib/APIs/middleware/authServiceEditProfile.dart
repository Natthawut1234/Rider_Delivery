// login , register , identify user
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../baseAPI_URL/baseURL.dart';

class AuthServiceEditProfile {
  static final AuthServiceEditProfile _instance =
      AuthServiceEditProfile._internal();
  factory AuthServiceEditProfile() => _instance;
  AuthServiceEditProfile._internal();

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

  // PUT /update-phone - อัพเดตเบอร์โทรศัพท์
  // router.put('/update-phone', verifyRiderToken, updateRiderPhone);
  Future<Map<String, dynamic>> updateRiderPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'No token found'};
    }

    final url = Uri.parse('${BaseAPI_URL.baseURL}/update-phone');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['error'] == null) {
        // อัพเดตข้อมูลใน SharedPreferences
        final userRider = prefs.getString('user_rider');
        if (userRider != null) {
          final userMap = json.decode(userRider);
          userMap['phone'] = phone;
          await prefs.setString('user_rider', json.encode(userMap));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Phone updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Update failed',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    }
  }

  // PUT /update-promptpay - อัพเดตหมายเลข PromptPay
  // router.put('/update-promptpay', verifyRiderToken, updateRiderPromptPay);
  Future<Map<String, dynamic>> updateRiderPromptPay(String promptpay) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'No token found'};
    }

    final url = Uri.parse('${BaseAPI_URL.baseURL}/update-promptpay');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'promptpay': promptpay}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['error'] == null) {
        // อัพเดตข้อมูลใน SharedPreferences
        final userRider = prefs.getString('user_rider');
        if (userRider != null) {
          final userMap = json.decode(userRider);
          userMap['promptpay'] = promptpay;
          await prefs.setString('user_rider', json.encode(userMap));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'PromptPay updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Update failed',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    }
  }

  // PUT /update-gender - อัพเดตเพศ
  // router.put('/update-gender', verifyRiderToken, updateRiderGender);
  Future<Map<String, dynamic>> updateRiderGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'No token found'};
    }

    final url = Uri.parse('${BaseAPI_URL.baseURL}/update-gender');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'gender': gender}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['error'] == null) {
        // อัพเดตข้อมูลใน SharedPreferences
        final userRider = prefs.getString('user_rider');
        if (userRider != null) {
          final userMap = json.decode(userRider);
          userMap['gender'] = gender;
          await prefs.setString('user_rider', json.encode(userMap));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Gender updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Update failed',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    }
  }

  // PUT /update-birthdate - อัพเดตวันเกิด
  // router.put('/update-birthdate', verifyRiderToken, updateRiderBirthdate);
  Future<Map<String, dynamic>> updateRiderBirthdate(String birthdate) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'No token found'};
    }

    final url = Uri.parse('${BaseAPI_URL.baseURL}/update-birthdate');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'birthdate': birthdate}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['error'] == null) {
        // อัพเดตข้อมูลใน SharedPreferences
        final userRider = prefs.getString('user_rider');
        if (userRider != null) {
          final userMap = json.decode(userRider);
          userMap['birthdate'] = birthdate;
          await prefs.setString('user_rider', json.encode(userMap));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Birthdate updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Update failed',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    }
  }

  // PUT /update-photo - อัพเดตรูปโปรไฟล์
  // router.put('/update-photo', verifyRiderToken, upload.single('photo'), updateRiderPhoto);
  Future<Map<String, dynamic>> updateRiderPhoto(File photoFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'No token found'};
    }

    final url = Uri.parse('${BaseAPI_URL.baseURL}/update-photo');
    final request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    // เพิ่มไฟล์รูปภาพ
    final mimeType = _getMimeType(photoFile.path);
    final mimeParts = mimeType.split('/');
    final multipartFile = await http.MultipartFile.fromPath(
      'photo',
      photoFile.path,
      contentType: MediaType(mimeParts[0], mimeParts[1]),
    );
    request.files.add(multipartFile);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📸 AuthService: Upload response: $data');

        if (data is Map && data['error'] == null) {
          // อัพเดตข้อมูลใน SharedPreferences
          final userRider = prefs.getString('user_rider');
          if (userRider != null) {
            final userMap = json.decode(userRider);
            if (data['photo_url'] != null) {
              userMap['photo_url'] = data['photo_url'];
              print(
                '💾 AuthService: Updated SharedPreferences with photo_url: ${data['photo_url']}',
              );
            }
            await prefs.setString('user_rider', json.encode(userMap));
          }
          return {
            'success': true,
            'message': data['message'] ?? 'Photo updated successfully',
            'photo_url': data['photo_url'],
          };
        } else {
          print('❌ AuthService: Upload failed with data: $data');
          return {
            'success': false,
            'message': data['error'] ?? data['message'] ?? 'Update failed',
          };
        }
      } else {
        print(
          '❌ AuthService: HTTP error ${response.statusCode}: ${response.body}',
        );
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
