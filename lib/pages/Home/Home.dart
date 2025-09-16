import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';
import '../../APIs/middleware/topupGP.dart';
import '../JobStart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RiderStatus _riderStatus = RiderStatus.incomplete;
  String _statusMessage = '';
  bool _isLoading = true;

  // ข้อมูลผู้ใช้
  String _userName = 'ผู้ใช้';
  String _userProfileImage = 'assets/avatars/avatar-4.png';
  bool _isUserDataLoading = true;

  // ข้อมูลเครดิต
  double _currentCredit = 0.0;
  bool _isCreditLoading = true;

  // ฟิลด์ที่ต้องตรวจสอบความสมบูรณ์
  String? _phone;
  int? _gender; // 0/1
  String? _promptpay;
  DateTime? _birthdate; // เพิ่มฟิลด์ birthdate

  // เพิ่ม query parameter เพื่อบังคับให้ Image.network โหลดไฟล์ใหม่
  String _appendCacheBuster(String url) {
    try {
      final uri = Uri.parse(url);
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      // รวมพารามิเตอร์เดิมกับ timestamp
      final newQueryParams = Map<String, String>.from(uri.queryParameters);
      newQueryParams['v'] = ts; // คีย์ v สำหรับ versioning
      final newUri = uri.replace(queryParameters: newQueryParams);
      return newUri.toString();
    } catch (_) {
      // ถ้า parse ไม่ได้ ใช้วิธี manual
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGPBalance(); // โหลดยอดเครดิต
    _checkRiderStatus();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRiderString = prefs.getString('user_rider');

      // โหลดข้อมูลจาก SharedPreferences ก่อน (เพื่อแสดง UI เร็วขึ้น)
      if (userRiderString != null) {
        final userData = jsonDecode(userRiderString);
        setState(() {
          _userName = userData['display_name'] ?? userData['name'] ?? 'ผู้ใช้';
          _phone = userData['phone'];
          _gender = userData['gender'];
          _promptpay = userData['promptpay'];

          // แก้ไขการแปลง birthdate
          if (userData['birthdate'] != null &&
              userData['birthdate'] is String) {
            _birthdate = DateTime.tryParse(userData['birthdate']);
          } else if (userData['birthdate'] is DateTime) {
            _birthdate = userData['birthdate'];
          }

          // ถ้ามี photo_url ให้ใช้ ไม่งั้นใช้รูป default
          if (userData['photo_url'] != null &&
              userData['photo_url'].toString().isNotEmpty &&
              userData['photo_url'] != 'null') {
            _userProfileImage = _appendCacheBuster(userData['photo_url']);
          }
          _isUserDataLoading = false;
        });
      }

      // เรียก API เพื่อดึงข้อมูลล่าสุด (รวมถึงรูปโปรไฟล์) เสมอ
      print('🔄 Home: Refreshing profile data from API...');
      final authService = AuthService();
      final result = await authService.getRiderProfile();

      if (result['success'] && result['data'] != null) {
        final profileData = result['data'];

        final ui = profileData['user_info'] ?? profileData; // fallback
        setState(() {
          _userName = ui['display_name'] ?? ui['name'] ?? 'ผู้ใช้';
          _phone = ui['phone'];
          _gender = ui['gender'];
          _promptpay = ui['promptpay'];

          // แก้ไขการแปลง birthdate
          if (ui['birthdate'] != null && ui['birthdate'] is String) {
            _birthdate = DateTime.tryParse(ui['birthdate']);
          } else if (ui['birthdate'] is DateTime) {
            _birthdate = ui['birthdate'];
          }

          String? photoUrl = ui['photo_url'];
          print('📸 Home: Received photo URL from API: $photoUrl');
          if (photoUrl != null &&
              photoUrl.toString().isNotEmpty &&
              photoUrl != 'null' &&
              photoUrl.startsWith('http')) {
            _userProfileImage = _appendCacheBuster(photoUrl);
            print('✅ Home: Updated profile image to: $_userProfileImage');
          } else {
            _userProfileImage = 'assets/avatars/avatar-4.png';
            print('⚠️ Home: Using default avatar image');
          }
          _isUserDataLoading = false;
        });

        // บันทึกข้อมูลที่ได้จาก API ลง SharedPreferences เพื่อใช้ครั้งต่อไป
        if (profileData['user_info'] != null) {
          await prefs.setString(
            'user_rider',
            jsonEncode(profileData['user_info']),
          );
          print('💾 Home: Updated SharedPreferences with latest data');
        }
      } else {
        // ถ้าไม่สามารถดึงข้อมูลจาก API ได้ แต่ไม่ได้ logout ให้ใช้ข้อมูลเดิม
        print('❌ Home: Failed to refresh profile data: ${result['message']}');
        setState(() {
          _isUserDataLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _isUserDataLoading = false;
      });
    }
  }

  // ฟังก์ชันดึงยอดเครดิต GP จาก API
  Future<void> _loadGPBalance() async {
    setState(() {
      _isCreditLoading = true;
    });

    try {
      final topupAPI = TopupGP();
      final result = await topupAPI.getGPBalance();

      if (result['success']) {
        setState(() {
          // แปลง gp_balance จาก String เป็น double
          final gpBalanceStr = result['data']['gp_balance'].toString();
          _currentCredit = double.parse(gpBalanceStr);
          _isCreditLoading = false;
        });
        print('✅ Home: Credit loaded successfully: ฿$_currentCredit');
      } else {
        setState(() {
          _isCreditLoading = false;
        });
        print('❌ Home: Failed to load credit: ${result['message']}');

        // ถ้า token หมดอายุให้ logout อัตโนมัติ
        if (result['message']?.contains('Token') == true ||
            result['message']?.contains('หมดอายุ') == true ||
            result['message']?.contains('ไม่ถูกต้อง') == true) {
          print(
            '🔒 Home: Token expired in credit loading, performing auto logout...',
          );
          await _performLogout();
        }
      }
    } catch (e) {
      setState(() {
        _isCreditLoading = false;
      });
      print('❌ Home: Error loading credit: $e');
    }
  }

  // Method สำหรับ refresh ข้อมูล user
  Future<void> _refreshUserData() async {
    print('🔄 Home: Starting user data refresh...');
    setState(() {
      _isUserDataLoading = true;
    });

    // รีเฟรชทั้งข้อมูลโปรไฟล์และเครดิต
    await Future.wait([_refreshProfileData(), _loadGPBalance()]);
  }

  // แยก method สำหรับรีเฟรชข้อมูลโปรไฟล์
  Future<void> _refreshProfileData() async {
    try {
      final authService = AuthService();
      final result = await authService.getRiderProfile();

      if (result['success'] && result['data'] != null) {
        final profileData = result['data'];
        final ui = profileData['user_info'] ?? profileData;

        print('🔍 Home: Raw user data received: $ui');
        print(
          '🔍 Home: birthdate type: ${ui['birthdate']?.runtimeType}, value: ${ui['birthdate']}',
        );

        setState(() {
          _userName = ui['display_name'] ?? ui['name'] ?? 'ผู้ใช้';
          _phone = ui['phone'];
          _gender = ui['gender'];
          _promptpay = ui['promptpay'];

          // แก้ไขการแปลง birthdate
          if (ui['birthdate'] != null && ui['birthdate'] is String) {
            _birthdate = DateTime.tryParse(ui['birthdate']);
            print('🗓️ Home: Parsed birthdate from string: $_birthdate');
          } else if (ui['birthdate'] is DateTime) {
            _birthdate = ui['birthdate'];
            print('🗓️ Home: Using DateTime birthdate: $_birthdate');
          } else {
            print('⚠️ Home: birthdate is null or unknown type');
          }

          String? photoUrl = ui['photo_url'];
          print('📸 Home: Received photo URL: $photoUrl');
          if (photoUrl != null &&
              photoUrl.toString().isNotEmpty &&
              photoUrl != 'null' &&
              photoUrl.startsWith('http')) {
            _userProfileImage = _appendCacheBuster(photoUrl);
            print('✅ Home: Updated profile image to: $_userProfileImage');
          } else {
            _userProfileImage = 'assets/avatars/avatar-4.png';
            print('⚠️ Home: Using default avatar image');
          }

          _isUserDataLoading = false;
        });

        // อัพเดต SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (profileData['user_info'] != null) {
          await prefs.setString(
            'user_rider',
            jsonEncode(profileData['user_info']),
          );
          print('💾 Home: Updated SharedPreferences with new data');
        }
      } else {
        print('❌ Home: Failed to get profile data: ${result['message']}');
        setState(() {
          _isUserDataLoading = false;
        });

        // ถ้า token หมดอายุหรือไม่ถูกต้อง ให้ logout อัตโนมัติ
        if (result['message']?.contains('Token') == true ||
            result['message']?.contains('หมดอายุ') == true ||
            result['message']?.contains('ไม่ถูกต้อง') == true) {
          print('🔒 Home: Token expired, performing auto logout...');
          await _performLogout();
        }
      }
    } catch (e) {
      print('❌ Home: Error refreshing user data: $e');
      setState(() {
        _isUserDataLoading = false;
      });
    }
  }

  // Method สำหรับ logout เมื่อ token หมดอายุ
  Future<void> _performLogout() async {
    try {
      print('🚪 Home: Starting logout process...');

      // ใช้ AuthService ในการ logout
      final authService = AuthService();
      await authService.logout();

      // แสดงข้อความแจ้งเตือน
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        // รอให้แสดง snackbar ก่อนแล้วค่อย navigate
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate ไปหน้า welcome และลบ navigation stack ทั้งหมด
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/wellcome', (route) => false);
      }
    } catch (e) {
      print('❌ Home: Error during logout: $e');
    }
  }

  bool _isProfileInfoMissing() {
    if (_riderStatus != RiderStatus.approved)
      return false; // สนใจเฉพาะตอน approved
    final missingPhone = _phone == null || _phone!.trim().isEmpty;
    final missingGender = _gender == null; // ต้องมีค่า 0 หรือ 1
    final missingPromptpay = _promptpay == null || _promptpay!.trim().isEmpty;
    final missingBirthdate = _birthdate == null; // ต้องมีวันเกิด

    return missingPhone ||
        missingGender ||
        missingPromptpay ||
        missingBirthdate;
  }

  void _showIncompleteProfileDialog() {
    final List<String> missing = [];
    if (_phone == null || _phone!.trim().isEmpty) missing.add('เบอร์โทรศัพท์');
    if (_gender == null) missing.add('เพศ');
    if (_promptpay == null || _promptpay!.trim().isEmpty)
      missing.add('หมายเลขพร้อมเพย์');
    if (_birthdate == null) missing.add('วันเกิด');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ข้อมูลยังไม่ครบ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรุณากรอกข้อมูลต่อไปนี้ให้ครบก่อนเริ่มรับงาน:'),
            const SizedBox(height: 12),
            ...missing.map(
              (m) => Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(m, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ไปที่หน้าโปรไฟล์เพื่อเพิ่มหรือแก้ไขข้อมูล',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ปิด'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.person),
            label: const Text('ไปหน้าโปรไฟล์'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkRiderStatus() async {
    print('🔄 _checkRiderStatus called');
    setState(() => _isLoading = true);

    // ทำความสะอาดข้อมูลเก่าถ้าเป็น JSON format
    final prefs = await SharedPreferences.getInstance();
    final currentStatus = prefs.getString('rider_status');
    if (currentStatus != null && currentStatus.startsWith('{')) {
      print('🧹 Cleaning old JSON format status data');
      await RiderStatusService.clearStatus();
    }

    // ตรวจสอบสถานะจากเซิร์ฟเวอร์
    print('📡 Checking status from server...');
    await RiderStatusService.checkStatusFromServer();

    // ทดสอบการเรียก API โปรไฟล์ (จะ refresh token อัตโนมัติถ้าจำเป็น)
    await _testAPICall();

    // ดึงสถานะปัจจุบัน
    print('📋 Getting current status...');
    final status = await RiderStatusService.getCurrentStatus();
    final message = await RiderStatusService.getStatusMessage();

    print('📊 Final status: $status');
    print('💬 Final message: $message');

    setState(() {
      _riderStatus = status;
      _statusMessage = message;
      _isLoading = false;
    });

    print('✅ UI updated with status: $status');
  }

  Future<void> _testAPICall() async {
    try {
      final authService = AuthService();
      final result = await authService.getRiderProfile();

      if (result['success']) {
        print('✅ API call successful with auto token refresh');
        // อัปเดตข้อมูล user หากจำเป็น (ดึง field สำคัญมา)
        final profileData = result['data'];
        if (profileData != null) {
          final ui = profileData['user_info'] ?? profileData;
          setState(() {
            _phone = ui['phone'] ?? _phone;
            _gender = ui['gender'] ?? _gender;
            _promptpay = ui['promptpay'] ?? _promptpay;

            // แก้ไขการแปลง birthdate
            if (ui['birthdate'] != null && ui['birthdate'] is String) {
              _birthdate = DateTime.tryParse(ui['birthdate']) ?? _birthdate;
            } else if (ui['birthdate'] is DateTime) {
              _birthdate = ui['birthdate'];
            }
          });
        }
      } else {
        print('❌ API call failed: ${result['message']}');

        // ถ้า token หมดอายุให้ logout อัตโนมัติ
        if (result['message']?.contains('Token') == true ||
            result['message']?.contains('หมดอายุ') == true ||
            result['message']?.contains('ไม่ถูกต้อง') == true) {
          print('🔒 _testAPICall: Token expired, performing auto logout...');
          await _performLogout();
        }
      }
    } catch (e) {
      print('❌ API call error: $e');
    }
  }

  Widget _buildStatusCard() {
    Color cardColor;
    Color textColor;
    IconData icon;
    String title;

    switch (_riderStatus) {
      case RiderStatus.pending:
        cardColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        icon = Icons.hourglass_empty;
        title = 'รอการอนุมัติ';
        break;
      case RiderStatus.approved:
        cardColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        title = 'ได้รับการอนุมัติ';
        break;
      case RiderStatus.rejected:
        cardColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        title = 'ถูกปฏิเสธ';
        break;
      default:
        cardColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        icon = Icons.info;
        title = 'ยังไม่ยืนยันตัวตน';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: textColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_riderStatus == RiderStatus.pending)
            GestureDetector(
              onTap: _checkRiderStatus,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.refresh, color: textColor, size: 20),
              ),
            ),
          if (_riderStatus == RiderStatus.incomplete)
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/riderIdentity');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: textColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ยืนยันตัวตน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_riderStatus == RiderStatus.rejected)
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/riderIdentity');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: textColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ส่งเอกสารใหม่',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  //
  // สร้างแถวข้อมูลสถานะ
  Widget _buildStatusInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    switch (_riderStatus) {
      case RiderStatus.approved:
        return 'เริ่มรับงาน';
      case RiderStatus.pending:
        return 'รอการอนุมัติ';
      case RiderStatus.rejected:
        return 'ส่งเอกสารใหม่';
      default:
        return 'ยืนยันตัวตนก่อน';
    }
  }

  String _getDisabledMessage() {
    switch (_riderStatus) {
      case RiderStatus.pending:
        return 'กรุณารอการอนุมัติจากทีมงาน เราจะแจ้งให้ทราบเร็วๆ นี้';
      case RiderStatus.rejected:
        return 'เอกสารของคุณถูกปฏิเสธ คลิกเพื่อส่งเอกสารใหม่';
      default:
        return 'กรุณายืนยันตัวตนก่อนเริ่มรับงาน';
    }
  }

  @override
  Widget build(BuildContext context) {
    // เลื่อนลงเพื่อรีเฟรชข้อมูล
    return RefreshIndicator(
      onRefresh: _refreshUserData,
      child: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('ออกจากแอพ'),
              content: const Text('คุณต้องการออกจากแอพใช่หรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('ออก'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }

          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Make main content scrollable to avoid bottom overflow
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Profile & Greeting
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              // Refresh ข้อมูล user ก่อนไปหน้า profile
                              await _refreshUserData();

                              // Navigate และรอผลลัพธ์
                              final shouldRefresh = await Navigator.pushNamed(
                                context,
                                '/profile',
                              );

                              // หากกลับมาพร้อมสัญญาณให้รีเฟรช
                              if (shouldRefresh == true) {
                                await _refreshUserData();
                              }
                            },
                            onLongPress: () {
                              // Long press เพื่อ refresh ข้อมูลโดยไม่ไปหน้า profile
                              _refreshUserData();
                            },
                            child: Row(
                              children: [
                                _isUserDataLoading
                                    ? Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[300],
                                        ),
                                        child: CircularProgressIndicator(
                                          color: Colors.grey[400],
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey[300],
                                        child: ClipOval(
                                          child:
                                              _userProfileImage.startsWith(
                                                'http',
                                              )
                                              ? Image.network(
                                                  _userProfileImage,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null)
                                                          return child;
                                                        return Container(
                                                          width: 56,
                                                          height: 56,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Colors
                                                                    .grey[300],
                                                              ),
                                                          child:
                                                              const CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        print(
                                                          '❌ Error loading profile image: $error',
                                                        );
                                                        return Image.asset(
                                                          'assets/avatars/avatar-4.png',
                                                          width: 56,
                                                          height: 56,
                                                          fit: BoxFit.cover,
                                                        );
                                                      },
                                                )
                                              : Image.asset(
                                                  _userProfileImage,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'สวัสดี',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      _isUserDataLoading
                                          ? Container(
                                              height: 20,
                                              width: 100,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            )
                                          : Text(
                                              _userName,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Rider Status Card
                        _buildStatusCard(),

                        // Earnings Card
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3), // สีเงา
                                  blurRadius: 12, // ความฟุ้งของเงา
                                  spreadRadius: 4, // การกระจายของเงา
                                  offset: Offset(
                                    0,
                                    4,
                                  ), // ย้ายเงา (0,0) = รอบด้าน
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  // สรุปรายได้แบบการ์ดย่อ
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        Navigator.pushNamed(context, '/income');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor:
                                                  Colors.green[100],
                                              child: Icon(
                                                Icons.attach_money,
                                                color: Colors.green[700],
                                                size: 26,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '\$852',
                                                    style: TextStyle(
                                                      color: Colors.green[800],
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'รายได้วันนี้',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  Divider(),

                                  // เครดิตรับงาน
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () async {
                                        // ไปหน้าเครดิตและรีเฟรชเมื่อกลับมา
                                        await Navigator.pushNamed(
                                          context,
                                          '/myCredit',
                                        );
                                        // รีเฟรชยอดเครดิตเมื่อกลับมา
                                        _loadGPBalance();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor: Colors.blue[100],
                                              child: Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                                color: Colors.blue[700],
                                                size: 26,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _isCreditLoading
                                                      ? SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  Colors
                                                                      .blue[700]!,
                                                                ),
                                                          ),
                                                        )
                                                      : Row(
                                                          children: [
                                                            Text(
                                                              _currentCredit > 0
                                                                  ? '฿${_currentCredit.toStringAsFixed(2)}'
                                                                  : 'ไม่สามารถโหลดได้',
                                                              style: TextStyle(
                                                                color:
                                                                    _currentCredit >
                                                                        0
                                                                    ? Colors
                                                                          .blue[800]
                                                                    : Colors
                                                                          .red[600],
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            if (_currentCredit ==
                                                                0)
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                            if (_currentCredit ==
                                                                0)
                                                              GestureDetector(
                                                                onTap:
                                                                    _loadGPBalance,
                                                                child: Icon(
                                                                  Icons.refresh,
                                                                  color: Colors
                                                                      .blue[600],
                                                                  size: 18,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'เครดิตรับงาน',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      // Today's tips
                                      Column(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/trip',
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.monetization_on,
                                                  color: Colors.amber,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$50',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'ทิปวันนี้',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Today's jobs
                                      Column(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/jobs',
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.pedal_bike,
                                                  color: Colors.red,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '25 งาน',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'งานวันนี้',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Rating
                                      Column(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/riderReview',
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  color: Colors.orange,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '4.5',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'ดูรีวิวทั้งหมด',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ข้อมูลสถานะระบบ (แทนที่ Debug Panel)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ข้อมูลสถานะ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildStatusInfoRow(
                                'สถานะปัจจุบัน',
                                _riderStatus.toString().split('.').last,
                              ),
                              const SizedBox(height: 8),
                              _buildStatusInfoRow('ข้อความ', _statusMessage),
                              if (_userName != 'ผู้ใช้')
                                Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    _buildStatusInfoRow(
                                      'ชื่อผู้ใช้',
                                      _userName,
                                    ),
                                  ],
                                ),
                              // แสดงวันที่ส่งเอกสาร (ถ้ามี)
                              FutureBuilder<String?>(
                                future: RiderStatusService.getSubmissionDate(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    final date = DateTime.parse(snapshot.data!);
                                    final formattedDate =
                                        '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                                    return Column(
                                      children: [
                                        const SizedBox(height: 8),
                                        _buildStatusInfoRow(
                                          'วันที่ส่งเอกสาร',
                                          formattedDate,
                                        ),
                                      ],
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Icon(Icons.refresh, size: 18),
                                  label: Text('รีเฟรชสถานะ'),
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          await _checkRiderStatus();
                                          await _refreshUserData();
                                        },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Debug Panel (คอมเม้นท์ออกแล้ว - ใช้เมื่อต้องการทดสอบเท่านั้น)
                        /*
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Debug Panel (สำหรับทดสอบ)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange[600],
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await RiderStatusService.setTestStatus(
                                            RiderStatus.pending,
                                          );
                                          _checkRiderStatus();
                                        },
                                        child: const Text(
                                          'รอการอนุมัติ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[600],
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await RiderStatusService.setApproved(
                                            '🎉 ยินดีด้วย! เอกสารของคุณได้รับการอนุมัติแล้ว\nคุณสามารถเริ่มรับงานได้แล้ว',
                                          );
                                          _checkRiderStatus();
                                        },
                                        child: const Text(
                                          'อนุมัติ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[600],
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await RiderStatusService.setRejected(
                                            '❌ เอกสารของคุณไม่ผ่านการตรวจสอบ\nกรุณาติดต่อทีมงานเพื่อแก้ไข',
                                          );
                                          _checkRiderStatus();
                                        },
                                        child: const Text(
                                          'ปฏิเสธ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[600],
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await RiderStatusService.clearStatus();
                                          _checkRiderStatus();
                                        },
                                        child: const Text(
                                          'รีเซ็ต',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          */
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Bottom button area pinned and safe (prevents overflow)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _riderStatus == RiderStatus.approved
                              ? Colors.green
                              : _riderStatus == RiderStatus.incomplete
                              ? Colors.blue
                              : _riderStatus == RiderStatus.rejected
                              ? Colors.red
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _riderStatus == RiderStatus.approved
                            ? () {
                                // ตรวจสอบข้อมูลโปรไฟล์ก่อนเริ่มงาน
                                if (_isProfileInfoMissing()) {
                                  _showIncompleteProfileDialog();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const JobStartPage(),
                                    ),
                                  );
                                }
                              }
                            : _riderStatus == RiderStatus.incomplete
                            ? () {
                                Navigator.pushNamed(context, '/riderIdentity');
                              }
                            : _riderStatus == RiderStatus.rejected
                            ? () {
                                Navigator.pushNamed(context, '/riderIdentity');
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_getDisabledMessage()),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _getButtonText(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ), // ElevatedButton
                    ), // SizedBox
                  ), // SafeArea
                ), // Padding
              ], // children
            ), // Column
          ), // SafeArea
        ), // Scaffold
      ), // WillPopScope
    );
  }
}
