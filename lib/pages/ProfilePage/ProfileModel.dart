import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../APIs/middleware/authService.dart';
import '../../APIs/middleware/authServiceEditProfile.dart';

class ProfileModel extends ChangeNotifier {
  bool available = true;
  bool _isLoading = false;

  // ข้อมูลผู้ใช้พื้นฐาน
  int? userId;
  String name = '';
  String phone = '';
  String promptpay = '';
  String email = '';
  DateTime? birthdate;
  int? gender; // 0=ชาย, 1=หญิง
  String? photoUrl;
  bool isVerified = false;
  DateTime? createdAt;

  // สถานะไรเดอร์
  String approvalStatus =
      'incomplete'; // pending, approved, rejected, incomplete
  DateTime? submittedAt;
  DateTime? approvedAt;
  String? rejectionReason;

  // ข้อมูลรถและเอกสาร
  String vehicleType = '';
  String vehicleBrandModel = '';
  String vehicleColor = '';
  String vehicleRegistrationNumber = '';
  String vehicleRegistrationProvince = '';

  // ที่อยู่
  String? houseNumber;
  String? street;
  String? subdistrict;
  String? district;
  String? province;
  String? postalCode;

  // ข้อมูลเพิ่มเติม (mock data สำหรับสถิติ)
  double rating = 0.0;
  int completed = 0;
  double earnings = 0.0;

  File? profileImage; // รูปโปรไฟล์ที่เลือกใหม่

  // Getters
  bool get isLoading => _isLoading;

  String get fullName => name.isNotEmpty ? name : 'ไม่ระบุชื่อ';

  String get vehicleFullInfo {
    if (vehicleBrandModel.isEmpty) return 'ยังไม่ได้ลงทะเบียนรถ';
    return '$vehicleBrandModel ($vehicleColor)';
  }

  String get verificationStatus {
    return isVerified ? 'ยืนยันแล้ว' : 'ยังไม่ยืนยัน';
  }

  String get approvalStatusText {
    switch (approvalStatus.toLowerCase()) {
      case 'approved':
        return 'ได้รับการอนุมัติ';
      case 'rejected':
        return 'ถูกปฏิเสธ';
      case 'pending':
        return 'รอการอนุมัติ';
      default:
        return 'ยังไม่ได้ส่งเอกสาร';
    }
  }

  String get genderText {
    if (gender == null) return 'ไม่ระบุ';
    return gender == 0 ? 'ชาย' : 'หญิง';
  }

  String get plateNumber {
    return vehicleRegistrationNumber.isNotEmpty
        ? vehicleRegistrationNumber
        : 'ไม่ระบุป้ายทะเบียน';
  }

  String get fullAddress {
    List<String> addressParts = [];

    if (houseNumber?.isNotEmpty == true)
      addressParts.add('บ้านเลขที่ $houseNumber');
    if (street?.isNotEmpty == true) addressParts.add(street!);
    if (subdistrict?.isNotEmpty == true) addressParts.add('ตำบล$subdistrict');
    if (district?.isNotEmpty == true) addressParts.add('อำเภอ$district');
    if (province?.isNotEmpty == true) addressParts.add('จังหวัด$province');
    if (postalCode?.isNotEmpty == true) addressParts.add(postalCode!);

    return addressParts.isNotEmpty ? addressParts.join(' ') : 'ไม่ระบุที่อยู่';
  }

  ImageProvider get currentProfileImage {
    if (profileImage != null) {
      return FileImage(profileImage!);
    } else if (photoUrl?.isNotEmpty == true && photoUrl!.startsWith('http')) {
      return NetworkImage(photoUrl!);
    } else {
      return const AssetImage('assets/avatars/avatar-4.png');
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'ไม่ระบุ';
    return '${date.day}/${date.month}/${date.year + 543}'; // แปลงเป็น พ.ศ.
  }

  // โหลดข้อมูลจาก SharedPreferences และ API
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userRiderString = prefs.getString('user_rider');

      // โหลดจาก SharedPreferences ก่อน
      if (userRiderString != null) {
        final userData = jsonDecode(userRiderString);
        _updateFromUserData(userData);
      }

      // เรียก API เพื่อข้อมูลล่าสุด
      final authService = AuthService();
      final result = await authService.getRiderProfile();

      if (result['success'] && result['data'] != null) {
        final profileData = result['data'];

        // อัพเดตข้อมูลจาก API
        _updateFromProfileData(profileData);

        // บันทึกข้อมูลใหม่ลง SharedPreferences
        if (profileData['user_info'] != null) {
          await prefs.setString(
            'user_rider',
            jsonEncode(profileData['user_info']),
          );
        }
      }

      // โหลดข้อมูลเพิ่มเติม (mock data สำหรับการพัฒนา)
      _loadMockStats();
    } catch (e) {
      print('❌ Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateFromUserData(Map<String, dynamic> userData) {
    userId = userData['user_id'];
    name = userData['display_name'] ?? userData['name'] ?? '';
    email = userData['email'] ?? '';
    phone = userData['phone'] ?? '';
    promptpay = userData['promptpay'] ?? '';
    photoUrl = userData['photo_url'];
    isVerified = userData['is_verified'] ?? false;

    if (userData['birthdate'] != null) {
      birthdate = DateTime.tryParse(userData['birthdate']);
    }

    gender = userData['gender'];

    if (userData['created_at'] != null) {
      createdAt = DateTime.tryParse(userData['created_at']);
    }
  }

  void _updateFromProfileData(Map<String, dynamic> profileData) {
    // ข้อมูลผู้ใช้
    if (profileData['user_info'] != null) {
      _updateFromUserData(profileData['user_info']);
    }

    // สถานะไรเดอร์
    if (profileData['rider_status'] != null) {
      final riderStatus = profileData['rider_status'];
      approvalStatus = riderStatus['approval_status'] ?? 'incomplete';

      if (riderStatus['submitted_at'] != null) {
        submittedAt = DateTime.tryParse(riderStatus['submitted_at']);
      }

      if (riderStatus['approved_at'] != null) {
        approvedAt = DateTime.tryParse(riderStatus['approved_at']);
      }

      rejectionReason = riderStatus['rejection_reason'];
    }

    // ข้อมูลรถ
    if (profileData['vehicle_info'] != null) {
      final vehicleInfo = profileData['vehicle_info'];
      vehicleType = vehicleInfo['vehicle_type'] ?? '';
      vehicleBrandModel = vehicleInfo['vehicle_brand_model'] ?? '';
      vehicleColor = vehicleInfo['vehicle_color'] ?? '';
      vehicleRegistrationNumber =
          vehicleInfo['vehicle_registration_number'] ?? '';
      vehicleRegistrationProvince =
          vehicleInfo['vehicle_registration_province'] ?? '';
    }

    // ที่อยู่
    if (profileData['address'] != null) {
      final address = profileData['address'];
      houseNumber = address['house_number'];
      street = address['street'];
      subdistrict = address['subdistrict'];
      district = address['district'];
      province = address['province'];
      postalCode = address['postal_code'];
    }
  }

  void _loadMockStats() {
    // ข้อมูล mock สำหรับสถิติ (จะต้องเชื่อมต่อกับ API จริงในอนาคต)
    switch (approvalStatus) {
      case 'approved':
        rating = 4.8;
        completed = 1250;
        earnings = 45230.50;
        break;
      case 'pending':
        rating = 0.0;
        completed = 0;
        earnings = 0.0;
        break;
      default:
        rating = 0.0;
        completed = 0;
        earnings = 0.0;
    }
  }

  // Method เก่าที่ใช้ mock data (เก็บไว้เพื่อ backward compatibility)
  void loadMockData() {
    loadUserData(); // เรียกใช้ method ใหม่แทน
  }

  // ✅ toggle สถานะว่าง/ไม่ว่าง
  void toggleAvailable(bool val) {
    available = val;
    notifyListeners();
  }

  // ✅ อัปเดตเบอร์โทร
  Future<bool> updatePhone(String newPhone) async {
    final value = newPhone.trim();
    if (value.length < 9) return false;
    final previous = phone;
    phone = value; // optimistic
    notifyListeners();
    try {
      final service = AuthServiceEditProfile();
      final res = await service.updateRiderPhone(value);
      if (res['success'] == true) return true;
      phone = previous; // rollback
      notifyListeners();
      return false;
    } catch (e) {
      phone = previous;
      notifyListeners();
      return false;
    }
  }

  // ✅ อัปเดตพร้อมเพย์
  Future<bool> updatePromptPay(String account) async {
    final value = account.trim();
    if (value.isEmpty || value.length < 9) return false;
    final previous = promptpay;
    promptpay = value; // optimistic
    notifyListeners();
    try {
      final service = AuthServiceEditProfile();
      final res = await service.updateRiderPromptPay(value);
      if (res['success'] == true) return true;
      promptpay = previous; // rollback
      notifyListeners();
      return false;
    } catch (e) {
      promptpay = previous;
      notifyListeners();
      return false;
    }
  }

  // ✅ เปลี่ยนรหัสผ่าน
  Future<bool> changePassword(
    String currentPass,
    String newPass,
    String confirmPass,
  ) async {
    if (newPass.isEmpty || confirmPass.isEmpty || currentPass.isEmpty) {
      return false;
    }
    if (newPass != confirmPass) {
      return false;
    }
    if (newPass.length < 6) {
      return false;
    }

    // TODO: เรียก API เปลี่ยนรหัสผ่าน
    try {
      // final authService = AuthService();
      // final result = await authService.changePassword(currentPass, newPass);
      // return result['success'] ?? false;

      // Mock สำเร็จ
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error changing password: $e');
      return false;
    }
  }

  // ✅ ลบบัญชี
  Future<bool> deleteAccount(String confirmText) async {
    if (confirmText.trim().toUpperCase() != "DELETE") {
      return false;
    }

    try {
      // TODO: เรียก API ลบบัญชี
      // final authService = AuthService();
      // final result = await authService.deleteAccount();
      // return result['success'] ?? false;

      // Mock สำเร็จ
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error deleting account: $e');
      return false;
    }
  }

  // ✅ ออกจากระบบ
  Future<void> logout() async {
    try {
      final authService = AuthService();
      await authService.logout();

      // เคลียร์ข้อมูลใน model
      _clearAllData();
      notifyListeners();
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  void _clearAllData() {
    available = true;
    userId = null;
    name = '';
    phone = '';
    email = '';
    birthdate = null;
    gender = null;
    photoUrl = null;
    isVerified = false;
    createdAt = null;
    approvalStatus = 'incomplete';
    submittedAt = null;
    approvedAt = null;
    rejectionReason = null;
    vehicleType = '';
    vehicleBrandModel = '';
    vehicleColor = '';
    vehicleRegistrationNumber = '';
    vehicleRegistrationProvince = '';
    houseNumber = null;
    street = null;
    subdistrict = null;
    district = null;
    province = null;
    postalCode = null;
    rating = 0.0;
    completed = 0;
    earnings = 0.0;
    promptpay = '';
    profileImage = null;
  }

  // ✅ อัปเดตรูปโปรไฟล์ + อัพโหลด API
  Future<bool> updateProfileImage(File file) async {
    final previous = profileImage;
    final previousUrl = photoUrl;

    profileImage = file; // optimistic preview
    notifyListeners();

    try {
      final service = AuthServiceEditProfile();
      final res = await service.updateRiderPhoto(file);

      if (res['success'] == true) {
        // อัพเดต photoUrl ด้วยข้อมูลใหม่จาก server
        if (res['photo_url'] != null) {
          photoUrl = res['photo_url'];
          print('✅ Updated photo URL: $photoUrl');
        }

        // รีเฟรชข้อมูลจาก server เพื่อให้แน่ใจว่าได้ข้อมูลล่าสุด
        await refresh();

        return true;
      }

      // Rollback on failure
      profileImage = previous;
      photoUrl = previousUrl;
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ Error updating profile image: $e');
      profileImage = previous;
      photoUrl = previousUrl;
      notifyListeners();
      return false;
    }
  }

  // ✅ ตั้งค่าเพศ (ครั้งเดียว) + API
  Future<bool> setGenderIfUnset(int g) async {
    if (gender != null) return false;
    if (g != 0 && g != 1) return false;
    try {
      final service = AuthServiceEditProfile();
      final res = await service.updateRiderGender(g.toString());
      if (res['success'] == true) {
        gender = g;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ✅ อัพเดตวันเกิด (แก้ไขได้) + API
  Future<bool> updateBirthdate(DateTime date) async {
    final previous = birthdate;
    birthdate = date; // optimistic
    notifyListeners();
    final formatted =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final service = AuthServiceEditProfile();
      final res = await service.updateRiderBirthdate(formatted);
      if (res['success'] == true) return true;
      birthdate = previous; // rollback
      notifyListeners();
      return false;
    } catch (e) {
      birthdate = previous;
      notifyListeners();
      return false;
    }
  }

  // ✅ รีเฟรชข้อมูล
  Future<void> refresh() async {
    print('🔄 ProfileModel: Starting refresh...');
    await loadUserData();
    print('✅ ProfileModel: Refresh completed, photo URL: $photoUrl');
  }
}
