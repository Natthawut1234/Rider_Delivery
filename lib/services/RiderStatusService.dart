import 'package:shared_preferences/shared_preferences.dart';

enum RiderStatus {
  pending, // รอการอนุมัติ
  approved, // อนุมัติแล้ว
  rejected, // ปฏิเสธ
  incomplete, // ข้อมูลไม่ครบ
}

class RiderStatusService {
  static const String _statusKey = 'rider_status';
  static const String _submissionDateKey = 'submission_date';
  static const String _approvalMessageKey = 'approval_message';

  // บันทึกสถานะจาก API response
  static Future<void> setStatusFromAPI(Map<String, dynamic> riderStatus) async {
    final prefs = await SharedPreferences.getInstance();

    if (riderStatus['has_submitted'] == true) {
      final approvalStatus = riderStatus['approval_status'];

      if (approvalStatus == 'pending') {
        await prefs.setString(_statusKey, RiderStatus.pending.toString());
        await prefs.setString(
          _approvalMessageKey,
          'กำลังตรวจสอบเอกสารของคุณ กรุณารอการอนุมัติ',
        );
      } else if (approvalStatus == 'approved') {
        await prefs.setString(_statusKey, RiderStatus.approved.toString());
        await prefs.setString(
          _approvalMessageKey,
          '🎉 ยินดีด้วย! เอกสารของคุณได้รับการอนุมัติแล้ว\nคุณสามารถเริ่มรับงานได้แล้ว',
        );
      } else if (approvalStatus == 'rejected') {
        await prefs.setString(_statusKey, RiderStatus.rejected.toString());
        await prefs.setString(
          _approvalMessageKey,
          'เอกสารของคุณถูกปฏิเสธ กรุณาติดต่อทีมงานเพื่อแก้ไข',
        );
      }

      // บันทึกวันที่ส่งเอกสาร
      if (riderStatus['submitted_at'] != null) {
        await prefs.setString(_submissionDateKey, riderStatus['submitted_at']);
      }
    } else {
      // ยังไม่ส่งเอกสาร
      await prefs.setString(_statusKey, RiderStatus.incomplete.toString());
      await prefs.setString(
        _approvalMessageKey,
        'ยังไม่ได้ส่งเอกสารยืนยันตัวตน',
      );
    }
  }

  // บันทึกสถานะการส่งเอกสาร
  static Future<void> setDocumentSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, RiderStatus.pending.toString());
    await prefs.setString(_submissionDateKey, DateTime.now().toIso8601String());
    await prefs.setString(
      _approvalMessageKey,
      'กำลังตรวจสอบเอกสารของคุณ กรุณารอการอนุมัติ',
    );
  }

  // ได้รับการอนุมัติ (จำลอง - ในความเป็นจริงจะมาจาก API)
  static Future<void> setApproved(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, RiderStatus.approved.toString());
    await prefs.setString(_approvalMessageKey, message);
  }

  // ถูกปฏิเสธ
  static Future<void> setRejected(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, RiderStatus.rejected.toString());
    await prefs.setString(_approvalMessageKey, message);
  }

  // ดึงสถานะปัจจุบัน
  static Future<RiderStatus> getCurrentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final statusString = prefs.getString(_statusKey);

    if (statusString == null) {
      return RiderStatus.incomplete;
    }

    switch (statusString) {
      case 'RiderStatus.pending':
        return RiderStatus.pending;
      case 'RiderStatus.approved':
        return RiderStatus.approved;
      case 'RiderStatus.rejected':
        return RiderStatus.rejected;
      default:
        return RiderStatus.incomplete;
    }
  }

  // ดึงข้อความสถานะ
  static Future<String> getStatusMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_approvalMessageKey) ??
        'ยังไม่ได้ส่งเอกสารยืนยันตัวตน';
  }

  // ดึงวันที่ส่งเอกสาร
  static Future<DateTime?> getSubmissionDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_submissionDateKey);

    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  // จำลองการตรวจสอบสถานะจากเซิร์ฟเวอร์
  static Future<void> checkStatusFromServer() async {
    // TODO: เรียก API เพื่อเช็คสถานะล่าสุดจากเซิร์ฟเวอร์
    // สำหรับตอนนี้ใช้การจำลองเก่า
    await Future.delayed(const Duration(seconds: 1));

    final status = await getCurrentStatus();
    final submissionDate = await getSubmissionDate();

    // จำลอง: หลังจากส่งเอกสาร 30 วินาที จะได้รับการอนุมัติ
    if (status == RiderStatus.pending && submissionDate != null) {
      final now = DateTime.now();
      final difference = now.difference(submissionDate).inSeconds;

      if (difference > 30) {
        // จำลอง 30 วินาที
        await setApproved(
          '🎉 ยินดีด้วย! เอกสารของคุณได้รับการอนุมัติแล้ว\nคุณสามารถเริ่มรับงานได้แล้ว',
        );
      }
    }
  }

  // เรียก API เพื่อเช็คสถานะล่าสุด (สำหรับอนาคต)
  static Future<void> refreshStatusFromAPI() async {
    // TODO: เรียก API GET /rider/approval-status/:user_id
    // และอัปเดตสถานะใหม่

    // ตัวอย่างการเรียก API (ยังไม่ได้ implement)
    /*
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userDataString = prefs.getString('user_rider');
      
      if (token != null && userDataString != null) {
        final userData = jsonDecode(userDataString);
        final userId = userData['user_id'];
        
        // เรียก API ตรวจสอบสถานะ
        final response = await http.get(
          Uri.parse('${BaseAPI_URL.baseURL}/approval-status/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await setStatusFromAPI(data['rider_status']);
        }
      }
    } catch (e) {
      print('Error refreshing status: $e');
    }
    */
  }

  // รีเซ็ตสถานะ (สำหรับทดสอบ)
  static Future<void> resetStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statusKey);
    await prefs.remove(_submissionDateKey);
    await prefs.remove(_approvalMessageKey);
  }
}
