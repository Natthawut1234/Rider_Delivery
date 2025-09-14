import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';

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
  static Future<void> setStatusFromAPI(Map<String, dynamic> apiResponse) async {
    final prefs = await SharedPreferences.getInstance();

    print('🔄 setStatusFromAPI called with: $apiResponse');

    // ตรวจสอบรูปแบบข้อมูลที่ต่างกัน
    String? approvalStatus;

    // รูปแบบ 1: status field โดยตรง
    if (apiResponse['status'] != null) {
      approvalStatus = apiResponse['status'];
    }
    // รูปแบบ 2: approval_status field
    else if (apiResponse['approval_status'] != null) {
      approvalStatus = apiResponse['approval_status'];
    }
    // รูปแบบ 3: ข้อมูลจาก rider_profiles
    else if (apiResponse['rider_profiles'] != null &&
        apiResponse['rider_profiles'].isNotEmpty) {
      approvalStatus = apiResponse['rider_profiles'][0]['approval_status'];
    }
    // รูปแบบ 4: has_submitted + approval_status
    else if (apiResponse['has_submitted'] == true &&
        apiResponse['approval_status'] != null) {
      approvalStatus = apiResponse['approval_status'];
    }

    print('📝 Detected status: $approvalStatus');

    if (approvalStatus != null) {
      if (approvalStatus == 'pending') {
        await prefs.setString(_statusKey, RiderStatus.pending.toString());
        await prefs.setString(
          _approvalMessageKey,
          'กำลังตรวจสอบเอกสารของคุณ กรุณารอการอนุมัติ',
        );
        print('✅ Status set to PENDING');
      } else if (approvalStatus == 'approved') {
        await prefs.setString(_statusKey, RiderStatus.approved.toString());
        await prefs.setString(
          _approvalMessageKey,
          '🎉 ยินดีด้วย! เอกสารของคุณได้รับการอนุมัติแล้ว\nคุณสามารถเริ่มรับงานได้แล้ว',
        );
        print('✅ Status set to APPROVED');
      } else if (approvalStatus == 'rejected') {
        await prefs.setString(_statusKey, RiderStatus.rejected.toString());
        await prefs.setString(
          _approvalMessageKey,
          apiResponse['rejection_reason'] ??
              'เอกสารของคุณถูกปฏิเสธ กรุณาติดต่อทีมงานเพื่อแก้ไข',
        );
        print('✅ Status set to REJECTED');
      }

      // บันทึกวันที่ส่งเอกสาร
      if (apiResponse['submitted_at'] != null) {
        await prefs.setString(_submissionDateKey, apiResponse['submitted_at']);
      }
    } else {
      // ยังไม่ส่งเอกสาร
      await prefs.setString(_statusKey, RiderStatus.incomplete.toString());
      await prefs.setString(
        _approvalMessageKey,
        'กรุณายืนยันตัวตนเพื่อเริ่มใช้งาน',
      );
      print('✅ Status set to INCOMPLETE');
    }
  }

  // ได้รับการอนุมัติ
  static Future<void> setApproved(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, RiderStatus.approved.toString());
    await prefs.setString(_approvalMessageKey, message);
  }

  // รอการอนุมัติ
  static Future<void> setPending(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, RiderStatus.pending.toString());
    await prefs.setString(_approvalMessageKey, message);
    await prefs.setString(_submissionDateKey, DateTime.now().toIso8601String());
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

    print('📊 getCurrentStatus: stored value = $statusString');

    if (statusString == null) {
      print('📊 No status stored, returning incomplete');
      return RiderStatus.incomplete;
    }

    // ตรวจสอบว่าเป็น JSON object หรือไม่ (กรณีที่เก็บข้อมูลผิดรูปแบบ)
    if (statusString.startsWith('{')) {
      print('📊 Found JSON status data, migrating to new format');

      // ลบข้อมูลเก่าและให้ checkStatusFromServer ทำงานใหม่
      await clearStatus();
      return RiderStatus.incomplete;
    }

    // แยกชื่อ enum จาก string
    String enumValue = statusString;
    if (statusString.contains('.')) {
      enumValue = statusString.split('.').last;
    }

    switch (enumValue) {
      case 'pending':
        print('📊 Status: PENDING');
        return RiderStatus.pending;
      case 'approved':
        print('📊 Status: APPROVED');
        return RiderStatus.approved;
      case 'rejected':
        print('📊 Status: REJECTED');
        return RiderStatus.rejected;
      case 'incomplete':
        print('📊 Status: INCOMPLETE');
        return RiderStatus.incomplete;
      default:
        print('📊 Unknown status: $statusString, returning incomplete');
        return RiderStatus.incomplete;
    }
  }

  // ดึงข้อความสถานะ
  static Future<String> getStatusMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_approvalMessageKey) ?? 'ไม่มีข้อมูลสถานะ';
  }

  // ตรวจสอบสถานะจากเซิร์ฟเวอร์
  static Future<void> checkStatusFromServer() async {
    try {
      final authService = AuthService();

      // ลองเรียก approval status API ก่อน
      final result = await authService.checkApprovalStatus();

      if (result['success']) {
        final data = result['data'];
        await setStatusFromAPI(data);
        print('✅ Status updated from approval API: ${data['status']}');
        return;
      } else {
        print(
          '❌ Approval API failed, trying profile API: ${result['message']}',
        );

        // ถ้า approval API ไม่ทำงาน ให้ลองใช้ profile API
        final profileResult = await authService.getRiderProfile();

        if (profileResult['success'] && profileResult['data'] != null) {
          final profileData = profileResult['data'];

          // ดึงสถานะจาก profile data
          if (profileData['rider_profiles'] != null &&
              profileData['rider_profiles'].isNotEmpty) {
            final riderProfile = profileData['rider_profiles'][0];
            await setStatusFromAPI(riderProfile);
            print(
              '✅ Status updated from profile API: ${riderProfile['approval_status']}',
            );
          } else {
            // ไม่มี rider_profiles หมายความว่ายังไม่ส่งเอกสาร
            await setStatusFromAPI({});
            print('✅ No rider profile found, set to incomplete');
          }
        } else {
          print('❌ Both APIs failed, keeping current status');
        }
      }
    } catch (e) {
      print('❌ Error checking status from server: $e');

      // ลองใช้ profile API เป็น fallback
      try {
        final authService = AuthService();
        final profileResult = await authService.getRiderProfile();

        if (profileResult['success'] && profileResult['data'] != null) {
          final profileData = profileResult['data'];

          if (profileData['rider_profiles'] != null &&
              profileData['rider_profiles'].isNotEmpty) {
            final riderProfile = profileData['rider_profiles'][0];
            await setStatusFromAPI(riderProfile);
            print(
              '✅ Fallback: Status updated from profile API: ${riderProfile['approval_status']}',
            );
          } else {
            await setStatusFromAPI({});
            print('✅ Fallback: No rider profile found, set to incomplete');
          }
        }
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
      }
    }
  }

  // เคลียร์ข้อมูลสถานะ
  static Future<void> clearStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statusKey);
    await prefs.remove(_submissionDateKey);
    await prefs.remove(_approvalMessageKey);
  }

  // บันทึกข้อมูลที่ส่งแล้ว
  static Future<void> setDocumentSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, RiderStatus.pending.toString());
    await prefs.setString(
      _approvalMessageKey,
      'ส่งเอกสารเรียบร้อยแล้ว รอการตรวจสอบจากทีมงาน',
    );
    await prefs.setString(_submissionDateKey, DateTime.now().toIso8601String());
  }

  // รีเซ็ตสถานะสำหรับการส่งเอกสารใหม่ (ใช้เมื่อถูกปฏิเสธ)
  static Future<void> resetForResubmission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, RiderStatus.incomplete.toString());
    await prefs.setString(
      _approvalMessageKey,
      'กรุณายืนยันตัวตนเพื่อเริ่มใช้งาน',
    );
    await prefs.remove(_submissionDateKey); // ลบวันที่ส่งเดิม
    print('🔄 Status reset for resubmission');
  }

  // เช็คว่าส่งเอกสารแล้วหรือยัง
  static Future<bool> isDocumentSubmitted() async {
    final status = await getCurrentStatus();
    return status != RiderStatus.incomplete;
  }

  // ดึงวันที่ส่งเอกสาร
  static Future<String?> getSubmissionDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_submissionDateKey);
  }

  // สำหรับการทดสอบ - ตั้งสถานะโดยตรง
  static Future<void> setTestStatus(RiderStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, status.toString());

    String message;
    switch (status) {
      case RiderStatus.pending:
        message = 'กำลังตรวจสอบเอกสารของคุณ กรุณารอการอนุมัติ';
        break;
      case RiderStatus.approved:
        message =
            '🎉 ยินดีด้วย! เอกสารของคุณได้รับการอนุมัติแล้ว\nคุณสามารถเริ่มรับงานได้แล้ว';
        break;
      case RiderStatus.rejected:
        message = 'เอกสารของคุณถูกปฏิเสธ กรุณาติดต่อทีมงานเพื่อแก้ไข';
        break;
      default:
        message = 'กรุณายืนยันตัวตนเพื่อเริ่มใช้งาน';
    }

    await prefs.setString(_approvalMessageKey, message);
    print('🧪 Test status set to: $status');
  }

  // เพิ่มฟังก์ชันดีบัก - แสดงข้อมูลทั้งหมดใน SharedPreferences
  static Future<void> debugPrintStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_statusKey);
    final message = prefs.getString(_approvalMessageKey);
    final submissionDate = prefs.getString(_submissionDateKey);

    print('🔍 DEBUG - Stored data:');
    print('   Status: $status');
    print('   Message: $message');
    print('   Submission Date: $submissionDate');
  }
}
