// lib/APIs/Orders/OrdersSocket.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';

class RiderOrdersApi {
  final String baseUrl;
  final String? token; // Bearer token ของไรเดอร์

  // Timeout สำหรับการเชื่อมต่อ
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  RiderOrdersApi(this.baseUrl, {this.token});

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Helper สำหรับจัดการ HTTP Request พร้อม timeout และ error handling
  Future<http.Response> _makeRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      print('🌐 Making $method request to: $uri');

      final headers = _headers();

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(connectionTimeout);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(connectionTimeout);
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(connectionTimeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      return response;
    } on SocketException catch (e) {
      print('❌ Network error: $e');
      throw Exception(
        'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
      );
    } on HttpException catch (e) {
      print('❌ HTTP error: $e');
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
    } catch (e) {
      print('❌ Request error: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  /// ดึงงานหน้า “เลือกรับงาน”
  /// จะส่ง lat/lng หรือไม่ส่งก็ได้ (ถ้าส่งจะคำนวณระยะทาง/ค่าส่ง)
  Future<List<Map<String, dynamic>>> fetchJobs({
    required int riderId,
    double? lat,
    double? lng,
    int limit = 1000,
    int offset = 0,
  }) async {
    final qp = <String, String>{
      'rider_id': '$riderId',
      'limit': '$limit',
      'offset': '$offset',
      if (lat != null) 'rider_latitude': '$lat',
      if (lng != null) 'rider_longitude': '$lng',
    };

    try {
      final response = await _makeRequest(
        'GET',
        '${BaseAPI_URL.SocketURL}/orders',
        queryParams: qp,
      );

      if (response.statusCode != 200) {
        throw Exception('ไม่สามารถดึงข้อมูลงานได้: ${response.statusCode}');
      }

      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Fetch jobs error: $e');
      throw Exception('ไม่สามารถดึงข้อมูลงานได้: $e');
    }
  }

  /// กดรับงาน (กันชน) -> เซิร์ฟเวอร์จะ set status = rider_assigned
  Future<Map<String, dynamic>> acceptJob({
    required int orderId,
    required int riderId,
  }) async {
    try {
      final response = await _makeRequest(
        'POST',
        '${BaseAPI_URL.SocketURL}/assign_rider',
        body: {'order_id': orderId, 'rider_id': riderId},
      );

      if (response.statusCode != 200) {
        throw Exception('ไม่สามารถรับงานได้: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      print('❌ Accept job error: $e');
      throw Exception('ไม่สามารถรับงานได้: $e');
    }
  }

  /// อัปเดตสถานะตาม flow (ใช้เฉพาะไรเดอร์เจ้าของงาน)
  Future<void> updateStatus({
    required int orderId,
    required int riderId,
    required String status,
  }) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '${BaseAPI_URL.SocketURL}/rider_update_status',
        body: {'order_id': orderId, 'rider_id': riderId, 'status': status},
      );

      if (response.statusCode != 200) {
        throw Exception('ไม่สามารถอัปเดตสถานะได้: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Update status error: $e');
      throw Exception('ไม่สามารถอัปเดตสถานะได้: $e');
    }
  }

  // helper ขอพิกัดปัจจุบันอย่างปลอดภัย (อนุญาตสิทธิแล้ว)
  static Future<({double? lat, double? lng})> getCurrentLatLng() async {
    try {
      print('📍 Requesting current location...');
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // เพิ่ม timeout
      );
      print('✅ Location received: ${pos.latitude}, ${pos.longitude}');
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      print('❌ Location error: $e');
      return (lat: null, lng: null);
    }
  }

  // ตรวจสอบการเชื่อมต่อเซิร์ฟเวอร์
  Future<bool> checkConnection() async {
    try {
      print('🔍 Checking server connection...');
      final response = await _makeRequest(
        'GET',
        '${BaseAPI_URL.SocketURL}/ping',
      );

      final isConnected = response.statusCode == 200;
      print(isConnected ? '✅ Server connected' : '❌ Server not responding');
      return isConnected;
    } catch (e) {
      print('❌ Connection check failed: $e');
      print('🔄 Using mock data for development');
      return false; // Return false to trigger mock data mode
    }
  }
}

/// สถานะที่ระบบใช้ (สำหรับอ้างอิงฝั่ง UI)
class RiderOrderStatus {
  static const waiting = 'waiting';
  static const confirmed = 'confirmed';
  static const riderAssigned = 'rider_assigned';
  static const goingToShop = 'going_to_shop';
  static const arrivedAtShop = 'arrived_at_shop';
  static const pickedUp = 'picked_up';
  static const delivering = 'delivering';
  static const arrivedAtCustomer = 'arrived_at_customer';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const preparing = 'preparing';
  static const readyForPickup = 'ready_for_pickup';
}
