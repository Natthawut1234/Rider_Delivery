import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';
import '../../APIs/middleware/topupGP.dart';
import '../../services/Income_and_JobHistoryService.dart';
import '../../APIs/Models/Income_and_JobHistory_model.dart';
import '../../services/ReviewsService.dart';
import 'package:intl/intl.dart';
import '../JobStart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RiderStatus _riderStatus = RiderStatus.incomplete;
  String _statusMessage = '';
  bool _isInitialLoading = true; // Loading หลักสำหรับครั้งแรก
  int? _riderId;
  
  // ข้อมูลผู้ใช้
  String _userName = 'ผู้ใช้';
  String _userProfileImage = 'assets/avatars/avatar-4.png';

  // ข้อมูลเครดิต
  double _currentCredit = 0.0;

  // ข้อมูลรายได้และงานวันนี้
  double _todayIncome = 0.0;
  int _todayJobCount = 0;

  // ข้อมูลรีวิวและคะแนน
  double _averageRating = 0.0;
  int _reviewsCount = 0;

  // ฟิลด์ที่ต้องตรวจสอบความสมบูรณ์
  String? _phone;
  int? _gender;
  String? _promptpay;
  DateTime? _birthdate;

  // Helper: ตรวจสอบว่า response จาก API เป็น auth error
  bool _isAuthError(Map<String, dynamic>? result) {
    if (result == null) return false;
    final code = result['statusCode'];
    final msg = (result['message'] ?? '').toString();
    if (result['authError'] == true) return true;
    if (code == 401 || code == 403) return true;
    if (msg.contains('Token') ||
        msg.contains('หมดอายุ') ||
        msg.contains('ไม่ถูกต้อง')) return true;
    return false;
  }

  // เพิ่ม query parameter เพื่อบังคับให้ Image.network โหลดไฟล์ใหม่
  String _appendCacheBuster(String url) {
    try {
      final uri = Uri.parse(url);
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final newQueryParams = Map<String, String>.from(uri.queryParameters);
      newQueryParams['v'] = ts;
      final newUri = uri.replace(queryParameters: newQueryParams);
      return newUri.toString();
    } catch (_) {
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAllData();
  }

  // รวมการโหลดข้อมูลทั้งหมดไว้ที่เดียว
  Future<void> _initializeAllData() async {
    print('🚀 Starting initialization...');
    setState(() {
      _isInitialLoading = true;
    });

    try {
      // โหลดข้อมูลจาก SharedPreferences ก่อน (แสดงผลเร็ว)
      await _loadCachedUserData();

      // โหลดข้อมูลทั้งหมดแบบ parallel พร้อม timeout
      final results = await Future.wait([
        _checkRiderStatus().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Timeout: _checkRiderStatus');
          },
        ),
        _loadGPBalance().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Timeout: _loadGPBalance');
          },
        ),
        _loadTodayIncome().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Timeout: _loadTodayIncome');
          },
        ),
        _loadTodayJobCount().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Timeout: _loadTodayJobCount');
          },
        ),
        _loadRatingData().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Timeout: _loadRatingData');
          },
        ),
        _refreshProfileData().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Timeout: _refreshProfileData');
          },
        ),
      ]).timeout(
        Duration(seconds: 15), // Timeout สำหรับทั้งหมด
        onTimeout: () {
          print('⏰ Overall timeout - proceeding anyway');
          return [];
        },
      );

      print('✅ All data loaded successfully');
    } catch (e) {
      print('❌ Error during initialization: $e');
      // แม้จะ error ก็ให้แสดงหน้าได้ตามปกติ
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
      print('✅ Initialization completed');
    }
  }

  // โหลดข้อมูลจาก cache เพื่อแสดงผลเร็ว
  Future<void> _loadCachedUserData() async {
    try {
      print('📦 Loading cached user data...');
      final prefs = await SharedPreferences.getInstance();
      final userRiderString = prefs.getString('user_rider');

      if (userRiderString != null) {
        final userData = jsonDecode(userRiderString);
        
        if (mounted) {
          setState(() {
            _userName = userData['display_name'] ?? userData['name'] ?? 'ผู้ใช้';
            _phone = userData['phone'];
            _gender = userData['gender'];
            _promptpay = userData['promptpay'];
            
            // เก็บ rider_id
            final riderId = userData['rider_id'];
            if (riderId != null && riderId != 0) {
              _riderId = riderId;
              prefs.setInt('cached_rider_id', riderId);
            } else {
              final cachedRiderId = prefs.getInt('cached_rider_id');
              if (cachedRiderId != null && cachedRiderId != 0) {
                _riderId = cachedRiderId;
              }
            }

            // แปลง birthdate
            if (userData['birthdate'] != null && userData['birthdate'] is String) {
              _birthdate = DateTime.tryParse(userData['birthdate']);
            } else if (userData['birthdate'] is DateTime) {
              _birthdate = userData['birthdate'];
            }

            // โหลดรูปโปรไฟล์
            if (userData['photo_url'] != null &&
                userData['photo_url'].toString().isNotEmpty &&
                userData['photo_url'] != 'null') {
              _userProfileImage = _appendCacheBuster(userData['photo_url']);
            }
          });
        }
        print('✅ Cached user data loaded');
      }
    } catch (e) {
      print('❌ Error loading cached user data: $e');
    }
  }

  // ฟังก์ชันดึงยอดเครดิต GP จาก API
  Future<void> _loadGPBalance() async {
    try {
      final topupAPI = TopupGP();
      final result = await topupAPI.getGPBalance();

      if (result['success']) {
        if (mounted) {
          setState(() {
            final gpBalanceStr = result['data']['gp_balance'].toString();
            _currentCredit = double.parse(gpBalanceStr);
          });
        }
        print('✅ Credit loaded: ฿$_currentCredit');
      } else {
        print('❌ Failed to load credit: ${result['message']}');
        if (_isAuthError(result)) {
          await _handleAuthError('เครดิต');
        }
      }
    } catch (e) {
      print('❌ Error loading credit: $e');
    }
  }

  // ฟังก์ชันดึงรายได้วันนี้จาก API
  Future<void> _loadTodayIncome() async {
    try {
      final service = JobHistoryService();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await service.fetchJobHistoryByDate(dateStr);

      if (result['success']) {
        final jobHistoryResponse = JobHistoryResponse.fromJson(result['data']);
        final jobs = jobHistoryResponse.data.jobHistory;
        final completedJobs = jobs.where((job) => job.isCompleted).toList();
        final todayIncome = completedJobs.fold(0.0, (sum, job) => sum + job.totalEarnings);

        if (mounted) {
          setState(() {
            _todayIncome = todayIncome;
          });
        }
        print('✅ Today income loaded: ฿$_todayIncome');
      } else {
        print('❌ Failed to load today income: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error loading today income: $e');
    }
  }

  // ฟังก์ชันดึงจำนวนงานวันนี้จาก API
  Future<void> _loadTodayJobCount() async {
    try {
      final service = JobHistoryService();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await service.fetchJobHistoryByDate(dateStr);

      if (result['success']) {
        final jobHistoryResponse = JobHistoryResponse.fromJson(result['data']);
        final jobs = jobHistoryResponse.data.jobHistory;

        if (mounted) {
          setState(() {
            _todayJobCount = jobs.length;
          });
        }
        print('✅ Today job count loaded: $_todayJobCount jobs');
      } else {
        print('❌ Failed to load today job count: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error loading today job count: $e');
    }
  }

  // โหลดข้อมูลคะแนนรีวิว
  Future<void> _loadRatingData() async {
    try {
      print('📊 Loading rating data...');
      final result = await ReviewsService().fetchRiderReviews(limit: 100);

      if (result['success']) {
        final data = result['data'];
        final riderSummary = data['rider_summary'];

        if (riderSummary != null && mounted) {
          setState(() {
            _averageRating = double.tryParse(riderSummary['rating_avg']?.toString() ?? '0') ?? 0.0;
            _reviewsCount = riderSummary['reviews_count'] ?? 0;
          });
          print('✅ Rating data loaded: $_averageRating ($_reviewsCount reviews)');
        } else {
          print('ℹ️ No rating summary available');
        }
      } else {
        print('❌ Failed to load rating data: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error loading rating data: $e');
      // Set default values on error
      if (mounted) {
        setState(() {
          _averageRating = 0.0;
          _reviewsCount = 0;
        });
      }
    }
  }

  // Method สำหรับ refresh ข้อมูล user
  Future<void> _refreshUserData() async {
    print('🔄 Starting user data refresh...');

    await Future.wait([
      _refreshProfileData(),
      _loadGPBalance(),
      _loadTodayIncome(),
      _loadTodayJobCount(),
      _loadRatingData(),
      _checkRiderStatus(),
    ]);
  }

  // แยก method สำหรับรีเฟรชข้อมูลโปรไฟล์
  Future<void> _refreshProfileData() async {
    try {
      print('🔄 Refreshing profile data from API...');
      final authService = AuthService();
      final result = await authService.getRiderProfile();

      if (result['success'] && result['data'] != null) {
        final profileData = result['data'];
        final ui = profileData['user_info'] ?? profileData;

        print('✅ Profile data received from API');

        if (mounted) {
          setState(() {
            _userName = ui['display_name'] ?? ui['name'] ?? 'ผู้ใช้';
            _phone = ui['phone'];
            _gender = ui['gender'];
            _promptpay = ui['promptpay'];

            if (ui['birthdate'] != null && ui['birthdate'] is String) {
              _birthdate = DateTime.tryParse(ui['birthdate']);
            } else if (ui['birthdate'] is DateTime) {
              _birthdate = ui['birthdate'];
            }

            String? photoUrl = ui['photo_url'];
            if (photoUrl != null &&
                photoUrl.toString().isNotEmpty &&
                photoUrl != 'null' &&
                photoUrl.startsWith('http')) {
              _userProfileImage = _appendCacheBuster(photoUrl);
            } else {
              _userProfileImage = 'assets/avatars/avatar-4.png';
            }
          });
        }

        // อัพเดต SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (profileData['user_info'] != null) {
          await prefs.setString('user_rider', jsonEncode(profileData['user_info']));
          print('💾 SharedPreferences updated');
        }
      } else {
        print('❌ Failed to get profile data: ${result['message']}');
        if (_isAuthError(result)) {
          await _handleAuthError('โปรไฟล์');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error refreshing user data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // จัดการ Auth Error
  Future<void> _handleAuthError(String source) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เซสชันหมดอายุ ($source) กรุณาเข้าสู่ระบบใหม่'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
    await _performLogout();
  }

  // Method สำหรับ logout เมื่อ token หมดอายุ
  Future<void> _performLogout() async {
    try {
      print('🚪 Starting logout process...');
      final authService = AuthService();
      await authService.logout();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushNamedAndRemoveUntil('/wellcome', (route) => false);
      }
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  bool _isProfileInfoMissing() {
    if (_riderStatus != RiderStatus.approved) return false;
    final missingPhone = _phone == null || _phone!.trim().isEmpty;
    final missingGender = _gender == null;
    final missingPromptpay = _promptpay == null || _promptpay!.trim().isEmpty;
    final missingBirthdate = _birthdate == null;

    return missingPhone || missingGender || missingPromptpay || missingBirthdate;
  }

  void _showIncompleteProfileDialog() {
    final List<String> missing = [];
    if (_phone == null || _phone!.trim().isEmpty) missing.add('เบอร์โทรศัพท์');
    if (_gender == null) missing.add('เพศ');
    if (_promptpay == null || _promptpay!.trim().isEmpty) missing.add('หมายเลขพร้อมเพย์');
    if (_birthdate == null) missing.add('วันเกิด');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ข้อมูลยังไม่ครบ', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรุณากรอกข้อมูลต่อไปนี้ให้ครบก่อนเริ่มรับงาน:'),
            const SizedBox(height: 12),
            ...missing.map((m) => Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(m, style: const TextStyle(fontSize: 14))),
              ],
            )),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    print('🔄 Checking rider status...');

    final prefs = await SharedPreferences.getInstance();
    final currentStatus = prefs.getString('rider_status');
    if (currentStatus != null && currentStatus.startsWith('{')) {
      print('🧹 Cleaning old JSON format status data');
      await RiderStatusService.clearStatus();
    }

    await RiderStatusService.checkStatusFromServer();
    await _testAPICall();

    final status = await RiderStatusService.getCurrentStatus();
    final message = await RiderStatusService.getStatusMessage();

    if (mounted) {
      setState(() {
        _riderStatus = status;
        _statusMessage = message;
      });
    }

    print('✅ Status updated: $status');
  }

  Future<void> _testAPICall() async {
    try {
      final authService = AuthService();
      final result = await authService.getRiderProfile();

      if (result['success']) {
        print('✅ API call successful');
        final profileData = result['data'];
        if (profileData != null && mounted) {
          final ui = profileData['user_info'] ?? profileData;
          setState(() {
            _phone = ui['phone'] ?? _phone;
            _gender = ui['gender'] ?? _gender;
            _promptpay = ui['promptpay'] ?? _promptpay;
            if (ui['birthdate'] != null && ui['birthdate'] is String) {
              _birthdate = DateTime.tryParse(ui['birthdate']) ?? _birthdate;
            } else if (ui['birthdate'] is DateTime) {
              _birthdate = ui['birthdate'];
            }
          });
        }
      } else {
        print('❌ API call failed: ${result['message']}');
        if (_isAuthError(result)) {
          await _handleAuthError('ตรวจสอบ');
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                ),
                if (_riderStatus != RiderStatus.approved) ...[
                  const SizedBox(height: 4),
                  Text(
                    _statusMessage,
                    style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
                  ),
                ],
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
              onTap: () => Navigator.pushNamed(context, '/riderIdentity'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: textColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ยืนยันตัวตน',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_riderStatus == RiderStatus.rejected)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/riderIdentity'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: textColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ส่งเอกสารใหม่',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
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
    // แสดง Loading Screen ครั้งแรกจนกว่าข้อมูลจะโหลดเสร็จ (สูงสุด 15 วินาที)
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      strokeWidth: 4,
                    ),
                  ),
                  Icon(
                    Icons.delivery_dining,
                    size: 30,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'กำลังโหลดข้อมูล...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณารอสักครู่',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshUserData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Profile & Greeting
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await _refreshUserData();
                              final shouldRefresh = await Navigator.pushNamed(context, '/profile');
                              if (shouldRefresh == true) {
                                await _refreshUserData();
                              }
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey[300],
                                  child: ClipOval(
                                    child: _userProfileImage.startsWith('http')
                                        ? Image.network(
                                            _userProfileImage,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.grey[300],
                                                ),
                                                child: const CircularProgressIndicator(strokeWidth: 2),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('สวัสดี', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _userName,
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey, size: 28),
                              ],
                            ),
                          ),
                        ),

                        // Rider Status Card
                        _buildStatusCard(),

                        // Earnings Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Column(
                                children: [
                                  // รายได้วันนี้
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => Navigator.pushNamed(context, '/income'),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor: Colors.green[100],
                                              child: Icon(Icons.attach_money, color: Colors.green[700], size: 26),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '฿${_todayIncome.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          color: Colors.green[800],
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: _loadTodayIncome,
                                                        child: Icon(Icons.refresh, color: Colors.green[600], size: 18),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('รายได้วันนี้', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.chevron_right, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  Divider(),

                                  // เครดิตรับงาน
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () async {
                                        await Navigator.pushNamed(context, '/myCredit');
                                        _loadGPBalance();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor: Colors.blue[100],
                                              child: Icon(
                                                Icons.account_balance_wallet_outlined,
                                                color: Colors.blue[700],
                                                size: 26,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '฿${_currentCredit.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          color: Colors.blue[800],
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: _loadGPBalance,
                                                        child: Icon(Icons.refresh, color: Colors.blue[600], size: 18),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('เครดิตรับงาน', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.chevron_right, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      // งานวันนี้
                                      Column(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => Navigator.pushNamed(context, '/jobs'),
                                            child: Column(
                                              children: [
                                                Icon(Icons.pedal_bike, color: Colors.red, size: 24),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '$_todayJobCount งาน',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: _loadTodayJobCount,
                                                      child: Icon(Icons.refresh, color: Colors.red[600], size: 14),
                                                    ),
                                                  ],
                                                ),
                                                Text('งานวันนี้', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // คะแนนรีวิว
                                      Column(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => Navigator.pushNamed(context, '/riderReview'),
                                            child: Column(
                                              children: [
                                                Icon(Icons.star, color: Colors.orange, size: 24),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _averageRating > 0
                                                          ? _averageRating.toStringAsFixed(1)
                                                          : 'ไม่มี',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: _loadRatingData,
                                                      child: Icon(Icons.refresh, color: Colors.orange[600], size: 14),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  _reviewsCount > 0
                                                      ? 'ดูรีวิว $_reviewsCount รายการ'
                                                      : 'ยังไม่มีรีวิว',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey),
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

                        // ข้อมูลสถานะระบบ
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
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
                              _buildStatusInfoRow('สถานะปัจจุบัน', _riderStatus.toString().split('.').last),
                              const SizedBox(height: 8),
                              _buildStatusInfoRow('ข้อความ', _statusMessage),
                              if (_userName != 'ผู้ใช้')
                                Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    _buildStatusInfoRow('ชื่อผู้ใช้', _userName),
                                  ],
                                ),
                              FutureBuilder<String?>(
                                future: RiderStatusService.getSubmissionDate(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    final date = DateTime.parse(snapshot.data!);
                                    final formattedDate =
                                        '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                                    return Column(
                                      children: [
                                        const SizedBox(height: 8),
                                        _buildStatusInfoRow('วันที่ส่งเอกสาร', formattedDate),
                                      ],
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                              const SizedBox(height: 12),
                              // SizedBox(
                              //   width: double.infinity,
                              //   child: ElevatedButton.icon(
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Colors.blue[600],
                              //       foregroundColor: Colors.white,
                              //       padding: const EdgeInsets.symmetric(vertical: 12),
                              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              //     ),
                              //     icon: Icon(Icons.refresh, size: 18),
                              //     label: Text('รีเฟรชสถานะ'),
                              //     onPressed: () async {
                              //       await _checkRiderStatus();
                              //       await _refreshUserData();
                              //     },
                              //   ),
                              // ),
                              // SizedBox(
                              //   width: double.infinity,
                              //   child: ElevatedButton.icon(
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Colors.red[600],
                              //       foregroundColor: Colors.white,
                              //       padding: const EdgeInsets.symmetric(vertical: 12),
                              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              //     ),
                              //     icon: Icon(Icons.chat_bubble, size: 18),
                              //     label: Text('แชท'),
                              //     onPressed: () => Navigator.pushNamed(context, '/chat-lists'),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _riderStatus == RiderStatus.approved
                          ? () {
                              if (_isProfileInfoMissing()) {
                                _showIncompleteProfileDialog();
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RiderJobsPage(riderId: _riderId ?? 0,),
                                  ),
                                );
                              }
                            }
                          : _riderStatus == RiderStatus.incomplete
                          ? () => Navigator.pushNamed(context, '/riderIdentity')
                          : _riderStatus == RiderStatus.rejected
                          ? () => Navigator.pushNamed(context, '/riderIdentity')
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_getDisabledMessage()),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                      child: Text(
                        _getButtonText(),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}