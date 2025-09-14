// ตัวอย่างการใช้งาน Google Login ใน Rider App
import '../middleware/authService.dart';

class GoogleLoginExample {
  final AuthService _authService = AuthService();

  // ตัวอย่างการ login ด้วย Google
  Future<void> exampleGoogleLogin(String idToken) async {
    final result = await _authService.loginWithGoogle(idToken);

    if (result['success']) {
      print('✅ Google Login สำเร็จ');
      print('User: ${result['user']}');
      print('Rider Status: ${result['rider_status']}');

      final riderStatus = result['rider_status'];

      // ตรวจสอบสถานะเอกสาร
      if (riderStatus != null && riderStatus['has_submitted'] == true) {
        // มีการส่งเอกสารแล้ว - ไปหน้า Home
        print('📄 ส่งเอกสารแล้ว -> ไปหน้า Home');

        // ตรวจสอบสถานะการอนุมัติ
        final approvalStatus = riderStatus['approval_status'];
        switch (approvalStatus) {
          case 'pending':
            print('⏳ สถานะ: รอการอนุมัติ');
            break;
          case 'approved':
            print('✅ สถานะ: อนุมัติแล้ว');
            break;
          case 'rejected':
            print('❌ สถานะ: ถูกปฏิเสธ');
            break;
        }
      } else {
        // ยังไม่ส่งเอกสาร - ไปหน้ายืนยันตัวตน
        print('📝 ยังไม่ส่งเอกสาร -> ไปหน้ายืนยันตัวตน');
      }
    } else {
      print('❌ Google Login ไม่สำเร็จ: ${result['message']}');
    }
  }
}

/* 
วิธีการทำงานของ Google Login:

1. ผู้ใช้กด "Login with Google" ใน Wellcome.dart
2. ระบบแสดงหน้า Google Sign-In
3. ผู้ใช้เลือกบัญชี Google และอนุญาต
4. ได้ idToken จาก Google
5. ส่ง idToken ไปยัง API /login-google
6. Backend ตรวจสอบ idToken กับ Google
7. ถ้าถูกต้อง:
   - สร้างหรืออัปเดตข้อมูลผู้ใช้
   - ตรวจสอบสถานะการยืนยันตัวตน
   - ส่งกลับ JWT token และข้อมูลผู้ใช้
8. Frontend ตรวจสอบสถานะ:
   - ถ้าส่งเอกสารแล้ว -> ไปหน้า Home
   - ถ้ายังไม่ส่ง -> ไปหน้ายืนยันตัวตน

API Endpoint ที่ใช้:
- POST /rider/login-google
- Body: {"tokenId": "google_id_token"}
- Response: {
    "message": "เข้าสู่ระบบด้วย Google สำเร็จ",
    "token": "jwt_token",
    "user": {...},
    "rider_status": {
      "has_submitted": true/false,
      "approval_status": "pending/approved/rejected",
      "submitted_at": "..."
    }
  }

ความปลอดภัย:
- idToken ถูกตรวจสอบกับ Google API
- JWT token มีอายุ 7 วัน
- ข้อมูลผู้ใช้ถูกเก็บใน SharedPreferences
- มีระบบ refresh token อัตโนมัติ
*/
