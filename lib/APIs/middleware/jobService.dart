// // ล้อเล่น ยังไม่ทำ
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../baseAPI_URL/baseURL.dart';
// import 'authService.dart';
// import 'topupGP.dart';

// class JobService {
//   static final JobService _instance = JobService._internal();
//   factory JobService() => _instance;
//   JobService._internal();

//   // รับงานและหักค่าบริการ
//   Future<Map<String, dynamic>> acceptJob({
//     required String jobId,
//     required double serviceFee,
//     String? description,
//   }) async {
//     try {
//       // ตรวจสอบและ refresh token ก่อนเรียก API
//       final authService = AuthService();
//       final hasValidToken = await authService.ensureValidToken();
//       if (!hasValidToken) {
//         return {
//           'success': false,
//           'message': 'Token ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่',
//         };
//       }

//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');

//       // 1. เรียก API รับงาน
//       final acceptUrl = Uri.parse('${BaseAPI_URL.baseURL}/jobs/$jobId/accept');
//       print('🌐 Accept Job API URL: $acceptUrl');

//       final acceptResponse = await http.post(
//         acceptUrl,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('📥 Accept Job Response status: ${acceptResponse.statusCode}');
//       print('📥 Accept Job Response body: ${acceptResponse.body}');

//       if (acceptResponse.statusCode == 200) {
//         // 2. หากรับงานสำเร็จ ให้หักค่าบริการ
//         final deductResult = await deductServiceFee(
//           amount: serviceFee,
//           orderId: jobId,
//           description: description ?? 'ค่าบริการการขนส่ง - ออเดอร์ #$jobId',
//         );

//         if (deductResult['success']) {
//           return {
//             'success': true,
//             'message': 'รับงานและหักค่าบริการสำเร็จ',
//             'data': {
//               'job_data': jsonDecode(acceptResponse.body),
//               'deduct_data': deductResult['data'],
//             },
//           };
//         } else {
//           // หากหักค่าบริการไม่สำเร็จ อาจต้องยกเลิกงาน
//           return {
//             'success': false,
//             'message':
//                 'รับงานสำเร็จ แต่ไม่สามารถหักค่าบริการได้: ${deductResult['message']}',
//             'error': deductResult,
//           };
//         }
//       } else {
//         final jsonResponse = jsonDecode(acceptResponse.body);
//         return {
//           'success': false,
//           'message': jsonResponse['error'] ?? 'ไม่สามารถรับงานได้',
//           'error': jsonResponse,
//           'statusCode': acceptResponse.statusCode,
//         };
//       }
//     } catch (e) {
//       print('❌ Error in acceptJob: $e');
//       return {
//         'success': false,
//         'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}',
//         'error': e.toString(),
//       };
//     }
//   }

//   // ตรวจสอบยอดเครดิตว่าเพียงพอสำหรับรับงานหรือไม่
//   Future<Map<String, dynamic>> checkCreditBalance(double requiredAmount) async {
//     try {
//       final topupAPI = TopupGP();
//       final balanceResult = await topupAPI.getGPBalance();

//       if (balanceResult['success']) {
//         final currentBalance = double.parse(
//           balanceResult['data']['gp_balance'].toString(),
//         );

//         if (currentBalance >= requiredAmount) {
//           return {
//             'success': true,
//             'sufficient': true,
//             'current_balance': currentBalance,
//             'required_amount': requiredAmount,
//             'message': 'เครดิตเพียงพอ',
//           };
//         } else {
//           return {
//             'success': true,
//             'sufficient': false,
//             'current_balance': currentBalance,
//             'required_amount': requiredAmount,
//             'shortage': requiredAmount - currentBalance,
//             'message':
//                 'เครดิตไม่เพียงพอ ต้องเติมอีก ฿${(requiredAmount - currentBalance).toStringAsFixed(2)}',
//           };
//         }
//       } else {
//         return {
//           'success': false,
//           'message':
//               'ไม่สามารถตรวจสอบยอดเครดิตได้: ${balanceResult['message']}',
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'message': 'เกิดข้อผิดพลาดในการตรวจสอบเครดิต: ${e.toString()}',
//       };
//     }
//   }

//   // ดึงรายการงานที่ว่าง
//   Future<Map<String, dynamic>> getAvailableJobs() async {
//     try {
//       final authService = AuthService();
//       final hasValidToken = await authService.ensureValidToken();
//       if (!hasValidToken) {
//         return {
//           'success': false,
//           'message': 'Token ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่',
//         };
//       }

//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');

//       final url = Uri.parse('${BaseAPI_URL.baseURL}/jobs/available');
//       print('🌐 Available Jobs API URL: $url');

//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('📥 Response status: ${response.statusCode}');
//       print('📥 Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         return {
//           'success': true,
//           'message': 'ดึงรายการงานสำเร็จ',
//           'data': jsonResponse['data'],
//         };
//       } else {
//         final jsonResponse = jsonDecode(response.body);
//         return {
//           'success': false,
//           'message': jsonResponse['error'] ?? 'ไม่สามารถดึงรายการงานได้',
//           'error': jsonResponse,
//           'statusCode': response.statusCode,
//         };
//       }
//     } catch (e) {
//       print('❌ Error in getAvailableJobs: $e');
//       return {
//         'success': false,
//         'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}',
//         'error': e.toString(),
//       };
//     }
//   }
// }
