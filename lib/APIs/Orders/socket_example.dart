// lib/APIs/Orders/socket_example.dart
// ตัวอย่างการใช้งาน RiderOrdersApi

import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';

class SocketExample {
  static Future<void> demonstrateUsage() async {
    // สร้าง instance (ใส่ token จริงจากการล็อกอิน)
    final api = RiderOrdersApi(
      BaseAPI_URL.SocketURL,
      token: 'your_bearer_token_here', // ใส่ token จริง
    );

    try {
      // 1. ตรวจสอบการเชื่อมต่อก่อน
      print('🔍 กำลังตรวจสอบการเชื่อมต่อ...');
      final isConnected = await api.checkConnection();
      if (!isConnected) {
        print('❌ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
        return;
      }

      // 2. ดึงตำแหน่งปัจจุบัน
      print('📍 กำลังดึงตำแหน่งปัจจุบัน...');
      final location = await RiderOrdersApi.getCurrentLatLng();
      print('📍 ตำแหน่ง: lat=${location.lat}, lng=${location.lng}');

      // 3. ดึงงานที่มี
      print('📋 กำลังดึงรายการงาน...');
      final jobs = await api.fetchJobs(
        riderId: 123, // ใส่ rider ID จริง
        lat: location.lat,
        lng: location.lng,
        limit: 10,
      );
      print('✅ พบงาน ${jobs.length} งาน');

      // แสดงงานแรก
      if (jobs.isNotEmpty) {
        final firstJob = jobs.first;
        print('งานแรก: ${firstJob['id']} - ${firstJob['customer_name']}');

        // 4. ทดสอบรับงาน (ระวัง: จะรับงานจริง!)
        // final result = await api.acceptJob(
        //   orderId: firstJob['id'],
        //   riderId: 123,
        // );
        // print('✅ รับงานสำเร็จ: $result');

        // 5. ทดสอบอัปเดตสถานะ
        // await api.updateStatus(
        //   orderId: firstJob['id'],
        //   riderId: 123,
        //   status: RiderOrderStatus.goingToShop,
        // );
        // print('✅ อัปเดตสถานะสำเร็จ');
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาด: $e');
    }
  }
}
