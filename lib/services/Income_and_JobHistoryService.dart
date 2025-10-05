import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';

class JobHistoryService {
  // ดึง token จาก SharedPreferences
  static Future<Map<String, String>> _getHeaders() async {
    final authService = AuthService(); // สร้าง instance ของ AuthService
    final hasValidToken = await authService.ensureValidToken();
    if (!hasValidToken) {
      // หาก token ไม่ถูกต้องหรือหมดอายุ ให้ส่ง headers พื้นฐาน (หรือคุณอาจโยน error แทน)
      return {'Content-Type': 'application/json'};
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // เชื่อมต่อ API เพื่อดึงประวัติการทำงาน

  // GET /rider/job-history/all - ดูประวัติการทำงานของไรเดอร์ทั้งหมด
  Future<Map<String, dynamic>> fetchAllJobHistory() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${BaseAPI_URL.baseURL}/job-history/all');

    final response = await http.get(url, headers: headers);
    print('AllJobHistory URL: $url'); // Debug log
    print('AllJobHistory status: ${response.statusCode}');
    print('AllJobHistory response: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message': 'ดึงประวัติการทำงานทั้งหมดสำเร็จ',
        'data': data,
      };
    } else {
      final status = response.statusCode;
      return {
        'success': false,
        'message': 'Failed to fetch all job history',
        'statusCode': status,
        'authError': status == 401 || status == 403 || status == 404,
      };
    }
  }

  // GET /rider/job-history/bydate?date= - ดูประวัติการทำงานของไรเดอร์ในวันที่ระบุ (รูปแบบ YYYY-MM-DD)
  Future<Map<String, dynamic>> fetchJobHistoryByDate(String date) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '${BaseAPI_URL.baseURL}/job-history/bydate?date=$date',
    );

    final response = await http.get(url, headers: headers);
    print('JobHistoryByDate URL: $url'); // Debug log
    print('JobHistoryByDate status: ${response.statusCode}');
    print('JobHistoryByDate response: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message': 'ดึงประวัติการทำงานวันที่ $date สำเร็จ',
        'data': data,
      };
    } else {
      final status = response.statusCode;
      return {
        'success': false,
        'message': 'Failed to fetch job history by date',
        'statusCode': status,
        'authError': status == 401 || status == 403 || status == 404,
      };
    }
  }

  // GET /rider/job-history/by-month?month=10&year=2025 - ดูประวัติการทำงานของไรเดอร์ในเดือนที่เลือก
  Future<Map<String, dynamic>> fetchJobHistoryByMonth(
    int month,
    int year,
  ) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '${BaseAPI_URL.baseURL}/job-history/by-month?month=$month&year=$year',
    );

    final response = await http.get(url, headers: headers);
    print('JobHistoryByMonth URL: $url'); // Debug log
    print('JobHistoryByMonth status: ${response.statusCode}');
    print('JobHistoryByMonth response: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message': 'ดึงประวัติการทำงานเดือน $month/$year สำเร็จ',
        'data': data,
      };
    } else {
      final status = response.statusCode;
      return {
        'success': false,
        'message': 'Failed to fetch job history by month',
        'statusCode': status,
        'authError': status == 401 || status == 403 || status == 404,
      };
    }
  }

  // GET /rider/job-history/by-year?year=2025 - ดูประวัติการทำงานของไรเดอร์ในปีที่เลือก
  Future<Map<String, dynamic>> fetchJobHistoryByYear(int year) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '${BaseAPI_URL.baseURL}/job-history/by-year?year=$year',
    );

    final response = await http.get(url, headers: headers);
    print('JobHistoryByYear URL: $url'); // Debug log
    print('JobHistoryByYear status: ${response.statusCode}');
    print('JobHistoryByYear response: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message': 'ดึงประวัติการทำงานปี $year สำเร็จ',
        'data': data,
      };
    } else {
      final status = response.statusCode;
      return {
        'success': false,
        'message': 'Failed to fetch job history by year',
        'statusCode': status,
        'authError': status == 401 || status == 403 || status == 404,
      };
    }
  }

  // GET /rider/job-history/bydate-range - ดูประวัติการทำงานของไรเดอร์ในช่วงวันที่ระบุ
  Future<Map<String, dynamic>> fetchJobHistoryByDateRange(
    String startDate,
    String endDate,
  ) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '${BaseAPI_URL.baseURL}/job-history/bydate-range?start_date=$startDate&end_date=$endDate',
    );

    final response = await http.get(url, headers: headers);
    print('JobHistoryByDateRange URL: $url'); // Debug log
    print('JobHistoryByDateRange status: ${response.statusCode}');
    print('JobHistoryByDateRange response: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message': 'ดึงประวัติการทำงานช่วง $startDate ถึง $endDate สำเร็จ',
        'data': data,
      };
    } else {
      final status = response.statusCode;
      return {
        'success': false,
        'message': 'Failed to fetch job history by date range',
        'statusCode': status,
        'authError': status == 401 || status == 403 || status == 404,
      };
    }
  }
}
