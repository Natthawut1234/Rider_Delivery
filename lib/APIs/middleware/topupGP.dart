import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../baseAPI_URL/baseURL.dart';
import 'authService.dart';

// API ที่เขียน

// GET /rider/gp-balance - ดูยอด GP คงเหลือ
// router.get('/gp-balance', verifyRiderToken, getRiderGPBalance);
// exports.getRiderGPBalance = async (req, res) => {
//     const user_id = req.user.user_id; // ดึง user_id จาก JWT token

//     try {
//         const result = await pool.query(
//             'SELECT rider_id, gp_balance FROM rider_profiles WHERE user_id = $1',
//             [user_id]
//         );

//         if (result.rows.length === 0) {
//             return res.status(404).json({
//                 success: false,
//                 error: 'ไม่พบข้อมูลผู้ใช้'
//             });
//         }

//         const { rider_id, gp_balance } = result.rows[0];

//         return res.status(200).json({
//             success: true,
//             data: {
//                 user_id,
//                 rider_id,
//                 gp_balance
//             }
//         });
//     } catch (error) {
//         console.error('Error fetching GP balance:', error);
//         return res.status(500).json({
//             success: false,
//             error: 'เกิดข้อผิดพลาดในการดึงข้อมูล GP คงเหลือ'
//         });
//     }
// };

// POST /rider/topup - เติมเงิน GP
// router.post('/topup', verifyRiderToken, upload.single('slip'), riderTopUp);
// exports.riderTopUp = async (req, res) => {
//     try {
//         console.log('=== Topup API Called ===');
//         console.log('req.user:', req.user);
//         console.log('req.body:', req.body);
//         console.log('req.file:', req.file);

//         const { amount, slip_url } = req.body;
//         const user_id = req.user.user_id; // ดึง user_id จาก JWT token

//         console.log('Extracted data:', { amount, slip_url, user_id });

//         // ตรวจสอบข้อมูลที่จำเป็น
//         if (!amount) {
//             console.log('Error: No amount provided');
//             return res.status(400).json({
//                 success: false,
//                 error: 'กรุณากรอกจำนวนเงินที่ต้องการเติม'
//             });
//         }

//         // ตรวจสอบจำนวนเงินที่เติม
//         if (amount <= 0) {
//             console.log('Error: Invalid amount:', amount);
//             return res.status(400).json({
//                 success: false,
//                 error: 'จำนวนเงินที่เติมต้องมากกว่า 0'
//             });
//         }

//         let finalSlipUrl = null;

//         // ตรวจสอบการอัปโหลดสลิป (เหมือน updateRiderPhoto)
//         if (req.file) {
//             console.log('File upload detected, uploading to Cloudinary...');
//             // อัปโหลดรูปสลิปไปยัง Cloudinary
//             const uploadResult = await uploadToCloudinary(req.file.buffer, 'rider-topup-slips');
//             finalSlipUrl = uploadResult.secure_url;
//             console.log('Upload successful:', finalSlipUrl);
//         } else if (slip_url) {
//             console.log('Using provided slip_url:', slip_url);
//             // รองรับการส่ง URL มาตรง ๆ (สำหรับ backward compatibility)
//             finalSlipUrl = slip_url;

//             // ตรวจสอบรูปแบบ URL
//             try {
//                 new URL(finalSlipUrl);
//             } catch (e) {
//                 console.log('Error: Invalid URL format');
//                 return res.status(400).json({
//                     success: false,
//                     error: 'รูปแบบ URL ไม่ถูกต้อง'
//                 });
//             }

//             // ตรวจสอบว่าเป็น URL ของ Cloudinary หรือไม่
//             if (!finalSlipUrl.includes('cloudinary.com') && !finalSlipUrl.includes('res.cloudinary.com')) {
//                 console.log('Error: Not a Cloudinary URL');
//                 return res.status(400).json({
//                     success: false,
//                     error: 'กรุณาใช้ URL รูปภาพจาก Cloudinary เท่านั้น'
//                 });
//             }
//         } else {
//             console.log('Error: No slip file or URL provided');
//             return res.status(400).json({
//                 success: false,
//                 error: 'กรุณาอัปโหลดสลิปการโอนเงินหรือส่ง slip_url'
//             });
//         }

//         console.log('Final slip URL:', finalSlipUrl);

//         // ตรวจสอบว่าไรเดอร์มีอยู่จริงหรือไม่ (ตรวจสอบจาก token ที่มีอยู่แล้ว)
//         console.log('Checking rider existence...');
//         const riderCheck = await pool.query(
//             'SELECT user_id FROM users WHERE user_id = $1 AND role = $2',
//             [user_id, 'rider']
//         );

//         console.log('Rider check result:', riderCheck.rows);

//         if (riderCheck.rowCount === 0) {
//             console.log('Error: Rider not found or not a rider');
//             return res.status(403).json({
//                 success: false,
//                 error: 'คุณไม่มีสิทธิ์เป็นไรเดอร์ในระบบ'
//             });
//         }

//         // บันทึกคำขอเติมเงิน พร้อม rider_id
//         console.log('Inserting topup record...');

//         // ดึง rider_id จาก rider_profiles
//         const riderResult = await pool.query(
//             `SELECT rider_id FROM rider_profiles WHERE user_id = $1`,
//             [user_id]
//         );

//         if (riderResult.rowCount === 0) {
//             return res.status(404).json({
//                 success: false,
//                 error: 'ไม่พบข้อมูลไรเดอร์ในระบบ'
//             });
//         }

//         const rider_id = riderResult.rows[0].rider_id;

//         const result = await pool.query(
//             `INSERT INTO rider_topups (user_id, rider_id, amount, slip_url, status)
//              VALUES ($1, $2, $3, $4, 'pending') RETURNING *`,
//             [user_id, rider_id, amount, finalSlipUrl]
//         );

//         console.log('Insert result:', result.rows);

//         res.json({
//             success: true,
//             message: 'ส่งคำขอเติมเงินสำเร็จ รอการอนุมัติจากแอดมิน',
//             data: {
//                 topup_id: result.rows[0].topup_id,
//                 user_id: result.rows[0].user_id,
//                 rider_id: result.rows[0].rider_id,
//                 amount: result.rows[0].amount,
//                 slip_url: result.rows[0].slip_url,
//                 status: result.rows[0].status,
//                 created_at: result.rows[0].created_at
//             }
//         });
//     } catch (error) {
//         console.error('=== Error in riderTopUp ===');
//         console.error('Error details:', error);
//         console.error('Error stack:', error.stack);

//         // จัดการ error ของ Cloudinary (เหมือน updateRiderPhoto)
//         if (error.message && error.message.includes('cloudinary')) {
//             return res.status(400).json({
//                 success: false,
//                 error: 'เกิดข้อผิดพลาดในการอัปโหลดสลิป กรุณาลองใหม่อีกครั้ง'
//             });
//         }

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
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'ไม่สามารถดึงยอด GP ได้',
          'error': jsonResponse,
          'statusCode': response.statusCode,
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
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'เติมเงินไม่สำเร็จ',
          'error': jsonResponse,
          'statusCode': response.statusCode,
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

  // GET /rider/topup/history - ดึงประวัติการเติมเงิน
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

      final url = Uri.parse('${BaseAPI_URL.baseURL}/rider/topup/history');
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
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'ไม่สามารถดึงประวัติได้',
          'error': jsonResponse,
          'statusCode': response.statusCode,
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
