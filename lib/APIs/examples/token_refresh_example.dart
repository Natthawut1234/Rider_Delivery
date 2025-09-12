// ตัวอย่างการใช้งาน AuthService กับ Refresh Token
import '../middleware/authService.dart';

class TokenRefreshExample {
  final AuthService _authService = AuthService();

  // ตัวอย่างการ login
  Future<void> exampleLogin() async {
    final result = await _authService.loginRider(
      'rider@example.com',
      'password123',
    );

    if (result['success']) {
      print('✅ Login สำเร็จ');
      print('User: ${result['user']}');
      print('Rider Status: ${result['rider_status']}');
    } else {
      print('❌ Login ไม่สำเร็จ: ${result['message']}');
    }
  }

  // ตัวอย่างการเรียก API ที่ต้องใช้ token (จะ refresh อัตโนมัติ)
  Future<void> exampleAPICall() async {
    final result = await _authService.getRiderProfile();

    if (result['success']) {
      print('✅ ดึงข้อมูลโปรไฟล์สำเร็จ');
      print('Data: ${result['data']}');
    } else {
      print('❌ ดึงข้อมูลโปรไฟล์ไม่สำเร็จ: ${result['message']}');
    }
  }

  // ตัวอย่างการ refresh token แบบ manual
  Future<void> exampleManualRefresh() async {
    final success = await _authService.refreshToken();

    if (success) {
      print('✅ Refresh token สำเร็จ');
    } else {
      print('❌ Refresh token ไม่สำเร็จ - อาจต้อง login ใหม่');
    }
  }

  // ตัวอย่างการตรวจสอบและ refresh token อัตโนมัติ
  Future<void> exampleEnsureValidToken() async {
    final hasValidToken = await _authService.ensureValidToken();

    if (hasValidToken) {
      print('✅ Token ยังใช้ได้ (หรือ refresh สำเร็จ)');
      // ทำงานที่ต้องใช้ token ต่อได้
    } else {
      print('❌ Token หมดอายุและ refresh ไม่สำเร็จ - ต้อง login ใหม่');
      // redirect ไปหน้า login
    }
  }
}

/* 
วิธีการทำงานของระบบ Refresh Token:

1. เมื่อ Login สำเร็จ:
   - เก็บ access_token และ refresh_token
   - access_token หมดอายุใน 7 วัน
   - refresh_token ใช้สำหรับขอ access_token ใหม่

2. เมื่อเรียก API:
   - ระบบจะตรวจสอบ access_token อัตโนมัติ
   - ถ้าใกล้หมดอายุ (เหลือ 5 นาที) จะ refresh อัตโนมัติ
   - ถ้า refresh สำเร็จจะใช้ token ใหม่เรียก API
   - ถ้า refresh ไม่สำเร็จจะ logout และให้ login ใหม่

3. การใช้งานใน App:
   - ใช้ AuthGuard ครอบ protected pages
   - เรียก AuthService.ensureValidToken() ก่อนเรียก API
   - ระบบจะจัดการ token refresh อัตโนมัติ

4. ความปลอดภัย:
   - Token จะถูกลบออกหากมี error
   - Navigation จะไปหน้า welcome เมื่อไม่ authenticated
   - ป้องกันการ access หน้าที่ต้อง login โดยไม่ได้รับอนุญาต
*/
