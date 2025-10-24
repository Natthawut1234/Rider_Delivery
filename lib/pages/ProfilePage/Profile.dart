import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/pages/ProfilePage/ProfileModel.dart';
import 'styles.dart';
import 'BottonEditProfile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileModel()..loadUserData(), // โหลดข้อมูลจริง
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _deleteConfirmController =
      TextEditingController();
  bool _needsRefresh =
      false; // ถ้าอัพเดตรูปหรือข้อมูลสำเร็จจะให้ Home รีเฟรชเมื่อกลับ

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _deleteConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileModel>();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_needsRefresh);
        return false; // เราควบคุมการ pop เอง
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'โปรไฟล์',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // แสดง loading indicator หากกำลังโหลดข้อมูล
                if (profile.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // การ์ดหลักรวม 5 ส่วน
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: buildGroupedCard(
                      children: [
                        // 1. Profile Header
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildProfileHeader(profile),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),

                        // 2. Rider Status (ใหม่)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildRiderStatusCard(profile),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),

                        // 3. Stats Card
                        // Padding(
                        //   padding: const EdgeInsets.all(20),
                        //   child: _buildStatsCard(profile),
                        // ),
                        // Divider(height: 1, color: Colors.grey[200]),

                        // 4. Personal Info
                        _buildPersonalInfoCard(profile),
                        Divider(height: 1, color: Colors.grey[200]),

                        // 5. Vehicle & Address Info (ใหม่)
                        _buildVehicleAddressCard(profile),
                        Divider(height: 1, color: Colors.grey[200]),

                        // 6. Menu Card
                        _buildMenuCard(profile),
                      ],
                    ),
                  ),
                ),

                // Danger Zone
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 20),
                    child: _buildDangerZone(profile),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Grouped Card Helper ----------------
  Widget buildGroupedCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ---------------- Profile Header ----------------
  Widget _buildProfileHeader(ProfileModel profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () => _showProfileImageViewer(profile),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: Colors.grey[300],
                child: profile.profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          profile.profileImage!,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/avatars/avatar-4.png',
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      )
                    : (profile.photoUrl?.isNotEmpty == true &&
                          profile.photoUrl!.startsWith('http'))
                    ? ClipOval(
                        child: Image.network(
                          profile.photoUrl!,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/avatars/avatar-4.png',
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 92,
                              height: 92,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Image.asset(
                        'assets/avatars/avatar-4.png',
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: () => _showImagePicker(profile),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.blueGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _statusBadge(profile.approvalStatusText),
                  const SizedBox(width: 8),
                  if (profile.isVerified)
                    const Icon(
                      Icons.verified,
                      color: Colors.lightBlue,
                      size: 20,
                    ),
                ],
              ),
              if (profile.rejectionReason?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          profile.rejectionReason!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (profile.submittedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  "ส่งเอกสารเมื่อ: ${profile.formatDate(profile.submittedAt)}",
                  style: AppTextStyles.subtitle,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text) {
    Color bg;
    switch (text) {
      case 'ได้รับการอนุมัติ':
        bg = Colors.green;
        break;
      case 'ถูกปฏิเสธ':
        bg = Colors.red;
        break;
      case 'รอการอนุมัติ':
        bg = Colors.orange;
        break;
      default:
        bg = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: bg.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Rider Status Card (separate) ----------------
  Widget _buildRiderStatusCard(ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สถานะไรเดอร์', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    profile.approvalStatusText,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            // Row(
            //   children: [
            //     const Text('พร้อม', style: TextStyle(fontSize: 12)),
            //     Switch(
            //       value: profile.available,
            //       onChanged: (val) => profile.toggleAvailable(val),
            //       activeColor: Colors.white,
            //       activeTrackColor: Colors.green,
            //     ),
            //   ],
            // ),
            IconButton(
              tooltip: 'รีเฟรช',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => profile.refresh(),
            ),
          ],
        ),
        if (profile.approvalStatus == 'pending')
          const Text(
            'กำลังรอตรวจสอบเอกสาร โปรดรอการอนุมัติ',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
      ],
    );
  }

  // ---------------- Stats Card ----------------
  // Widget _buildStatsCard(ProfileModel profile) {
  //   return Row(
  //     children: [
  //       _statItem(
  //         "รายได้",
  //         "฿${profile.earnings.toStringAsFixed(2)}",
  //         Icons.account_balance_wallet,
  //         AppColors.greenGradient,
  //       ),
  //       _statItem(
  //         "งานสำเร็จ",
  //         "${profile.completed}",
  //         Icons.check_circle,
  //         AppColors.blueGradient,
  //       ),
  //       _statItem(
  //         "เรตติ้ง",
  //         profile.rating > 0 ? profile.rating.toString() : "ยังไม่มี",
  //         Icons.star,
  //         AppColors.orangeGradient,
  //       ),
  //     ],
  //   );
  // }

  Widget _statItem(
    String label,
    String value,
    IconData icon,
    Gradient gradient,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ---------------- Personal Info Card ----------------
  Widget _buildPersonalInfoCard(ProfileModel profile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.phone_outlined,
            title: profile.phone.isNotEmpty ? profile.phone : 'ไม่ระบุเบอร์โทร',
            onEdit: () =>
                ProfileEditDialogs.showEditPhoneDialog(context, profile),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.email_outlined,
            title: profile.email.isNotEmpty ? profile.email : 'ไม่ระบุอีเมล',
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.cake_outlined,
            title:
                'วันเกิด: ${profile.birthdate != null ? profile.formatDate(profile.birthdate) : 'ไม่ระบุวันเกิด'}',
            onEdit: () =>
                ProfileEditDialogs.showEditBirthdateDialog(context, profile),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.person_outline,
            title: 'เพศ: ${profile.genderText}',
            trailing: profile.gender == null
                ? TextButton(
                    onPressed: () => ProfileEditDialogs.showSetGenderDialog(
                      context,
                      profile,
                    ),
                    child: const Text(
                      'ระบุเพศ',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    VoidCallback? onEdit,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[500]),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ---------------- Vehicle & Address Card (ใหม่) ----------------
  Widget _buildVehicleAddressCard(ProfileModel profile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ข้อมูลรถ
          if (profile.vehicleBrandModel.isNotEmpty) ...[
            _buildInfoItem(
              icon: Icons.motorcycle_outlined,
              title: 'รถ: ${profile.vehicleBrandModel}',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.palette_outlined,
              title: 'สี: ${profile.vehicleColor}',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.confirmation_number_outlined,
              title: 'ป้าย: ${profile.plateNumber}',
            ),
            if (profile.fullAddress != 'ไม่ระบุที่อยู่')
              const SizedBox(height: 16),
          ],

          // ที่อยู่
          if (profile.fullAddress != 'ไม่ระบุที่อยู่')
            _buildInfoItem(
              icon: Icons.home_outlined,
              title: 'ที่อยู่: ${profile.fullAddress}',
            ),
        ],
      ),
    );
  }

  // ---------------- Menu Card ----------------
  Widget _buildMenuCard(ProfileModel profile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.account_balance_outlined,
            title:
                'พร้อมเพย์: ${profile.promptpay.isNotEmpty ? profile.promptpay : 'ยังไม่ได้ตั้งค่า'}',
            onEdit: () =>
                ProfileEditDialogs.showEditPromptPayDialog(context, profile),
          ),
          // const SizedBox(height: 16),
          // _buildInfoItem(
          //   icon: Icons.lock_outlined,
          //   title: 'เปลี่ยนรหัสผ่าน',
          //   onEdit: () => _showChangePasswordDialog(profile),
          // ),
          const SizedBox(height: 16),
           // 🟢 ปุ่มคำร้องเรียนแทน “ติดต่อแอดมิน”
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/complaint_form');
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 245, 84, 9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color.fromARGB(255, 245, 84, 9), width: 1.2),
            ),
            child: Row(
              children: const [
                Icon(Icons.report_problem_outlined,
                    color: Color.fromARGB(255, 245, 84, 9), size: 22),
                SizedBox(width: 12),
                Text(
                  'คำร้องเรียน / แจ้งปัญหา',
                  style: TextStyle(
                    color: Color.fromARGB(255, 245, 84, 9),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  // ---------------- Danger Zone ----------------
  Widget _buildDangerZone(ProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => _showLogoutConfirm(profile),
              icon: const Icon(Icons.logout_outlined),
              label: const Text(
                "ออกจากระบบ",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          // TextButton.icon(
          //   onPressed: () => _showDeleteAccountConfirm(profile),
          //   icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 18),
          //   label: Text(
          //     "ลบบัญชี",
          //     style: TextStyle(
          //       color: Colors.red[300],
          //       fontSize: 14,
          //       fontWeight: FontWeight.w400,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // ---------------- Profile Image Viewer ----------------
  void _showProfileImageViewer(ProfileModel profile) {
    // ตรวจสอบว่ามีรูปภาพหรือไม่
    Widget imageWidget;

    if (profile.profileImage != null) {
      // รูปภาพจากไฟล์ local
      imageWidget = Image.file(
        profile.profileImage!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImageViewer();
        },
      );
    } else if (profile.photoUrl?.isNotEmpty == true &&
        profile.photoUrl!.startsWith('http')) {
      // รูปภาพจาก network
      imageWidget = Image.network(
        profile.photoUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImageViewer();
        },
      );
    } else {
      // รูปภาพ default
      imageWidget = _buildDefaultImageViewer();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Background สีดำ
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black87,
                ),
              ),

              // รูปภาพตรงกลาง
              Center(
                child: GestureDetector(
                  onTap: () {}, // ป้องกันการปิดเมื่อกดที่รูป
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: imageWidget,
                  ),
                ),
              ),

              // ปุ่มปิด
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // ข้อความแนะนำด้านล่าง
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'กดที่ไหนก็ได้เพื่อปิด',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultImageViewer() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset('assets/avatars/avatar-4.png', fit: BoxFit.cover),
    );
  }

  // ---------------- Image Picker ----------------
  Future<void> _showImagePicker(ProfileModel profile) async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("เลือกรูปจากเครื่อง"),
            onTap: () async {
              Navigator.pop(ctx);
              final pickedFile = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                _showImageConfirmationDialog(File(pickedFile.path), profile);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("ถ่ายรูปใหม่"),
            onTap: () async {
              Navigator.pop(ctx);
              final pickedFile = await picker.pickImage(
                source: ImageSource.camera,
              );
              if (pickedFile != null) {
                _showImageConfirmationDialog(File(pickedFile.path), profile);
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------- Image Confirmation Dialog ----------------
  Future<void> _showImageConfirmationDialog(
    File imageFile,
    ProfileModel profile,
  ) async {
    // เก็บ context ของหน้า page (ปลอดภัยหลังปิด dialog แล้ว)
    final pageContext = context;
    showDialog(
      context: pageContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.photo_camera,
                color: Theme.of(pageContext).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'ยืนยันการอัพโหลดรูปภาพ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'คุณต้องการใช้รูปภาพนี้เป็นรูปโปรไฟล์หรือไม่?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(
                  dialogContext,
                ).pop(); // ปิด confirmation dialog ก่อน

                // Show loading dialog with unique identifier
                late BuildContext loadingDialogContext;
                bool loadingClosed = false;
                showDialog(
                  context: pageContext,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    loadingDialogContext = dialogContext; // เก็บ context ไว้
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('กำลังอัพโหลดรูปภาพ...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );

                try {
                  // Upload image
                  print('🚀 Starting image upload...');
                  final success = await profile.updateProfileImage(imageFile);
                  print('📤 Upload completed with result: $success');

                  // ปิด loading dialog ด้วย context ที่เก็บไว้ (ต้องปิดก่อนแสดง SnackBar หรือ pop หน้า)
                  if (!loadingClosed &&
                      mounted &&
                      Navigator.canPop(loadingDialogContext)) {
                    Navigator.of(loadingDialogContext).pop();
                    loadingClosed = true;
                    print('✅ Loading dialog closed');
                  }

                  // Show result message
                  if (mounted) {
                    ScaffoldMessenger.of(pageContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'อัพโหลดรูปภาพสำเร็จ'
                              : 'ไม่สามารถอัพโหลดรูปภาพได้',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    // หากสำเร็จ ให้รีเฟรชข้อมูลภายในหน้า และตั้ง flag ให้ Home รีเฟรชเมื่อกด back
                    if (success) {
                      print('🔄 Refreshing profile data...');
                      await profile.refresh(); // รีเฟรชข้อมูลในโปรไฟล์

                      if (mounted) {
                        setState(() {
                          _needsRefresh =
                              true; // ให้ผลลัพธ์ true เมื่อผู้ใช้กดปุ่ม back ของเครื่อง
                        });
                        print(
                          '✅ Upload success – waiting for user back, _needsRefresh=true',
                        );
                      }
                    }
                  }
                } catch (e) {
                  print('❌ Upload error: $e');

                  // ปิด loading dialog ในกรณีเกิด error
                  if (!loadingClosed &&
                      mounted &&
                      Navigator.canPop(loadingDialogContext)) {
                    Navigator.of(loadingDialogContext).pop();
                    loadingClosed = true;
                    print('✅ Loading dialog closed (error case)');
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(pageContext).showSnackBar(
                      SnackBar(
                        content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(pageContext).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  // ---------------- Dialog Helper Functions ----------------

  ButtonStyle _popupButtonStyle(Gradient gradient) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ).copyWith(
      backgroundColor: MaterialStateProperty.all(Colors.transparent),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
    );
  }

  Widget _popupHeader(IconData icon, String title, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.appBarTitle),
        ],
      ),
    );
  }

  // (Local phone/promptpay dialogs removed in favor of ProfileEditDialogs utility.)

  // ---------------- Change Password Dialog ----------------
  void _showChangePasswordDialog(ProfileModel profile) {
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? matchMessage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            void checkMatch() {
              if (newPass.text.isEmpty || confirmPass.text.isEmpty) {
                setState(() => matchMessage = null);
                return;
              }
              if (newPass.text == confirmPass.text) {
                setState(() => matchMessage = "✅ รหัสผ่านตรงกัน");
              } else {
                setState(() => matchMessage = "❌ รหัสผ่านไม่ตรงกัน");
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              title: _popupHeader(
                Icons.lock,
                "เปลี่ยนรหัสผ่าน",
                AppColors.purpleGradient,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPass,
                    obscureText: obscureNew,
                    onChanged: (_) => checkMatch(),
                    decoration: InputDecoration(
                      labelText: "รหัสผ่านใหม่",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => obscureNew = !obscureNew);
                        },
                      ),
                    ),
                  ),
                  TextField(
                    controller: confirmPass,
                    obscureText: obscureConfirm,
                    onChanged: (_) => checkMatch(),
                    decoration: InputDecoration(
                      labelText: "ยืนยันรหัสผ่าน",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => obscureConfirm = !obscureConfirm);
                        },
                      ),
                    ),
                  ),
                  if (matchMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      matchMessage!,
                      style: TextStyle(
                        color: matchMessage!.contains("✅")
                            ? Colors.green
                            : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ยกเลิก", style: AppTextStyles.subtitle),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: _popupButtonStyle(AppColors.purpleGradient),
                    onPressed: () async {
                      if (newPass.text.isEmpty ||
                          confirmPass.text.isEmpty ||
                          newPass.text != confirmPass.text) {
                        return;
                      }

                      // เพิ่ม currentPassword (mock)
                      final success = await profile.changePassword(
                        'current_password', // TODO: ขอรหัสผ่านปัจจุบันจากผู้ใช้
                        newPass.text,
                        confirmPass.text,
                      );

                      if (success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ เปลี่ยนรหัสผ่านสำเร็จ"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("❌ เปลี่ยนรหัสผ่านไม่สำเร็จ"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text("บันทึก"),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- Logout Dialog ----------------
  void _showLogoutConfirm(ProfileModel profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        title: _popupHeader(Icons.logout, "ออกจากระบบ", AppColors.redGradient),
        content: const Text(
          "คุณแน่ใจหรือไม่ที่จะออกจากระบบ?",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ยกเลิก", style: AppTextStyles.subtitle),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.redGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: _popupButtonStyle(AppColors.redGradient),
              onPressed: () async {
                // เรียก logout function
                await profile.logout();
                Navigator.pop(ctx);
                // นำทางไปหน้า welcome และล้าง navigation stack ทั้งหมด
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/wellcome',
                    (route) => false, // ลบ navigation stack ทั้งหมด
                  );
                }
              },
              child: const Text("ยืนยัน"),
            ),
          ),
        ],
      ),
    );
  }
}
