import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../baseAPI_URL/baseURL.dart';
import 'authService.dart';

// API ที่เขียน

// GET /rider/topup/:topup_id/status - ดูสถานะการเติมเงินรายการเดียว
// router.get('/topup/:topup_id/status', verifyRiderToken, getRiderTopUpStatus);
// exports.getRiderTopUpStatus = async (req, res) => {
//     const { topup_id } = req.params;
//     const user_id = req.user.user_id; // ดึง user_id จาก JWT token

//     try {
//         const result = await pool.query(
//             `SELECT
//                 topup_id,
//                 user_id,
//                 rider_id,
//                 amount,
//                 slip_url,
//                 status,
//                 rejection_reason,
//                 created_at,
//                 approved_at,
//                 updated_at
//              FROM rider_topups
//              WHERE topup_id = $1 AND user_id = $2`,
//             [topup_id, user_id]
//         );

//         if (result.rowCount === 0) {
//             return res.status(404).json({
//                 success: false,
//                 error: 'ไม่พบรายการเติมเงินที่ระบุหรือคุณไม่มีสิทธิ์เข้าถึง'
//             });
//         }

//         res.json({
//             success: true,
//             data: result.rows[0]
//         });
//     } catch (err) {
//         console.error('Error in getRiderTopUpStatus:', err);
//         res.status(500).json({
//             success: false,
//             error: 'เกิดข้อผิดพลาดในเซิร์ฟเวอร์'
//         });
//     }
// };

// เชื่อมต่อกับ API topup
class TopupGP {
  static final TopupGP _instance = TopupGP._internal();
  factory TopupGP() => _instance;
  TopupGP._internal();

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

  // GET /rider/gp-balance - ดูยอด GP คงเหลือ
  Future<Map<String, dynamic>> getGPBalance() async {
    try {
      // ตรวจสอบและ refresh token ก่อนเรียก API
      final authService = AuthService(); // สร้าง instance ของ AuthService
      final hasValidToken = await authService.ensureValidToken();
      if (!hasValidToken) {
        return {
          'success': false,
          'message': 'Token ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่',
        };
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${BaseAPI_URL.baseURL}/gp-balance');
      print('🌐 GP Balance API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'ดึงยอด GP คงเหลือสำเร็จ',
          'data': jsonResponse['data'],
        };
      } else {
        final jsonResponse = jsonDecode(response.body);
        // เพิ่ม flag สำหรับ auth error
        final status = response.statusCode;
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'ไม่สามารถดึงยอด GP ได้',
          'error': jsonResponse,
          'statusCode': status,
          'authError': status == 401 || status == 403,
        };
      }
    } catch (e) {
      print('❌ Error in getGPBalance: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  Future<String?> fetchPromptPayInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final url = Uri.parse('${BaseAPI_URL.localhostURL}/promptpay');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // ✅ เข้าถึงจาก data['data']['promptpay']
        return data['data']['promptpay']?.toString();
      }
    } catch (e) {
      print('❌ Error fetching PromptPay info: $e');
    }
    return null;
  }

  // POST/rider/topup - เติมเงิน GP
  Future<Map<String, dynamic>> topupGP({
    required double amount,
    File? slipFile,
    String? slipUrl,
  }) async {
    try {
      // ตรวจสอบและ refresh token ก่อนเรียก API
      final authService = AuthService(); // สร้าง instance ของ AuthService
      final hasValidToken = await authService.ensureValidToken();
      if (!hasValidToken) {
        return {
          'success': false,
          'message': 'Token ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่',
        };
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${BaseAPI_URL.baseURL}/topup');
      print('🌐Topup API URL: $url');

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // เพิ่มข้อมูล Form fields
      request.fields['amount'] = amount.toString();

      if (slipFile != null) {
        // ถ้ามีไฟล์สลิป ให้แนบไฟล์ไปกับ request
        final mimeType = _getMimeType(slipFile.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'slip',
            slipFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
        print('📁 Attaching slip file: ${slipFile.path}');
      } else if (slipUrl != null) {
        // ถ้ามี URL สลิป ให้เพิ่มลงใน request
        request.fields['slip_url'] = slipUrl;
        print('🔗 Using slip URL: $slipUrl');
      }

      print('📤 Sending request with amount: $amount');
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${responseData.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData.body);
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'ส่งคำขอเติมเงินสำเร็จ',
          'data': jsonResponse['data'],
        };
      } else {
        // Handle different error status codes
        final jsonResponse = jsonDecode(responseData.body);
        final status = response.statusCode;
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'เติมเงินไม่สำเร็จ',
          'error': jsonResponse,
          'statusCode': status,
          'authError': status == 401 || status == 403,
        };
      }
    } catch (e) {
      print('❌ Error in topupGP: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // GET /rider/topup-history - ดึงประวัติการเติมเงิน
  Future<Map<String, dynamic>> getTopupHistory() async {
    try {
      // ตรวจสอบและ refresh token
      final authService = AuthService();
      final hasValidToken = await authService.ensureValidToken();
      if (!hasValidToken) {
        return {
          'success': false,
          'message': 'Token ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่',
        };
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${BaseAPI_URL.baseURL}/topup-history');
      print('🌐 Topup History API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'ดึงประวัติสำเร็จ',
          'data': jsonResponse['data'],
        };
      } else {
        final jsonResponse = jsonDecode(response.body);
        final status = response.statusCode;
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'ไม่สามารถดึงประวัติได้',
          'error': jsonResponse,
          'statusCode': status,
          'authError': status == 401 || status == 403,
        };
      }
    } catch (e) {
      print('❌ Error in getTopupHistory: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }
}

// GET /rider/topup/:topup_id/status - ดูสถานะการเติมเงินรายการเดียว
Future<Map<String, dynamic>> getTopupStatus(String topupId) async {
  try {
    // ตรวจสอบและ refresh token ก่อนเรียก API
    final authService = AuthService(); // สร้าง instance ของ AuthService
    final hasValidToken = await authService.ensureValidToken();
    if (!hasValidToken) {
      return {
        'success': false,
        'message': 'Token ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่',
      };
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('${BaseAPI_URL.baseURL}/topup/$topupId/status');
    print('🌐 Topup Status API URL: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'ดึงสถานะการเติมเงินสำเร็จ',
        'data': jsonResponse['data'],
      };
    } else {
      final jsonResponse = jsonDecode(response.body);
      final status = response.statusCode;
      return {
        'success': false,
        'message': jsonResponse['error'] ?? 'ไม่สามารถดึงสถานะการเติมเงินได้',
        'error': jsonResponse,
        'statusCode': status,
        'authError': status == 401 || status == 403,
      };
    }
  } catch (e) {
    print('❌ Error in getTopupStatus: $e');
    return {
      'success': false,
      'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}',
      'error': e.toString(),
    };
  }
}

// ล้อเล่น ยังไม่ทำ
// POST /rider/deduct-service-fee - หักค่าบริการเมื่อรับงาน
// Future<Map<String, dynamic>> deductServiceFee({
//   required double amount,
//   required String orderId,
//   String? description,
// }) async {
//   try {
//     // ตรวจสอบและ refresh token ก่อนเรียก API
//     final authService = AuthService();
//     final hasValidToken = await authService.ensureValidToken();
//     if (!hasValidToken) {
//       return {
//         'success': false,
//         'message': 'Token ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่',
//       };
//     }

//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     final url = Uri.parse('${BaseAPI_URL.baseURL}/rider/deduct-service-fee');
//     print('🌐 Deduct Service Fee API URL: $url');

//     final response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'amount': amount,
//         'order_id': orderId,
//         'description': description ?? 'ค่าบริการการขนส่ง',
//       }),
//     );

//     print('📥 Response status: ${response.statusCode}');
//     print('📥 Response body: ${response.body}');

//     if (response.statusCode == 200) {
//       final jsonResponse = jsonDecode(response.body);
//       return {
//         'success': true,
//         'message': jsonResponse['message'] ?? 'หักค่าบริการสำเร็จ',
//         'data': jsonResponse['data'],
//       };
//     } else {
//       final jsonResponse = jsonDecode(response.body);
//       return {
//         'success': false,
//         'message': jsonResponse['error'] ?? 'ไม่สามารถหักค่าบริการได้',
//         'error': jsonResponse,
//         'statusCode': response.statusCode,
//       };
//     }
//   } catch (e) {
//     print('❌ Error in deductServiceFee: $e');
//     return {
//       'success': false,
//       'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}',
//       'error': e.toString(),
//     };
//   }
// }

// ล้อเล่น ไม่ทำ
// POST /rider/withdraw - ถอนเงิน
// Future<Map<String, dynamic>> withdrawCredit({
//   required double amount,
//   required String bankAccount,
//   required String bankName,
//   String? note,
// }) async {
//   try {
//     // ตรวจสอบและ refresh token ก่อนเรียก API
//     final authService = AuthService();
//     final hasValidToken = await authService.ensureValidToken();
//     if (!hasValidToken) {
//       return {
//         'success': false,
//         'message': 'Token ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่',
//       };
//     }

//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     final url = Uri.parse('${BaseAPI_URL.baseURL}/rider/withdraw');
//     print('🌐 Withdraw API URL: $url');

//     final response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'amount': amount,
//         'bank_account': bankAccount,
//         'bank_name': bankName,
//         'note': note,
//       }),
//     );

//     print('📥 Response status: ${response.statusCode}');
//     print('📥 Response body: ${response.body}');

//     if (response.statusCode == 200) {
//       final jsonResponse = jsonDecode(response.body);
//       return {
//         'success': true,
//         'message': jsonResponse['message'] ?? 'ส่งคำขอถอนเงินสำเร็จ',
//         'data': jsonResponse['data'],
//       };
//     } else {
//       final jsonResponse = jsonDecode(response.body);
//       return {
//         'success': false,
//         'message': jsonResponse['error'] ?? 'ไม่สามารถถอนเงินได้',
//         'error': jsonResponse,
//         'statusCode': response.statusCode,
//       };
//     }
//   } catch (e) {
//     print('❌ Error in withdrawCredit: $e');
//     return {
//       'success': false,
//       'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}',
//       'error': e.toString(),
//     };
//   }
// }
