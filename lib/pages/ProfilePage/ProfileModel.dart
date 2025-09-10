import 'dart:io';
import 'package:flutter/foundation.dart';

class ProfileModel extends ChangeNotifier {
  bool available = true;

  String name = 'สมชาย ขับดี';
  String phone = '081-234-5678';
  String email = 'rider@example.com';
  String vehicle = 'มอเตอร์ไซค์ Honda Click 150';
  String plate = 'ข้อมูลที่ลงทะเบียน';
  String license = 'ใบขับขี่: หมายเลข ABC123456';
  double rating = 4.8;
  int completed = 1250;
  double earnings = 45230.50;

  String bankAccount = "";

  File? profileImage; // ✅ เก็บไฟล์รูปโปรไฟล์จากกล้อง/แกลเลอรี

  // ✅ toggle สถานะว่าง/ไม่ว่าง
  void toggleAvailable(bool val) {
    available = val;
    notifyListeners();
  }

  // ✅ อัปเดตเบอร์โทร
  void updatePhone(String newPhone) {
    phone = newPhone;
    notifyListeners();
  }

  // ✅ อัปเดตบัญชีธนาคาร/พร้อมเพย์
  void updateBankAccount(String account) {
    bankAccount = account;
    notifyListeners();
  }

  // ✅ เปลี่ยนรหัสผ่าน (mock)
  bool changePassword(String newPass, String confirmPass) {
    if (newPass.isEmpty || confirmPass.isEmpty) return false;
    if (newPass != confirmPass) return false;
    return true; // mock ว่าสำเร็จ
  }

  // ✅ ลบบัญชี (ต้องพิมพ์ DELETE)
  bool deleteAccount(String confirmText) {
    return confirmText.trim().toUpperCase() == "DELETE";
  }

  // ✅ Logout
  void logout() {
    // TODO: ต่อ API เพื่อล้าง token หรือ session ได้
  }

  // ✅ อัปเดตรูปโปรไฟล์
  void updateProfileImage(File file) {
    profileImage = file;
    notifyListeners();
  }
}
