import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:promptpay_qrcode_generate/promptpay_qrcode_generate.dart';
import 'package:rider_delivery/pages/ProfilePage/ProfileModel.dart';
import 'styles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileModel(),
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
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final profile = context.watch<ProfileModel>();

  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 223, 228, 223),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(
          children: [
            // รวม 4 การ์ดเป็นก้อนเดียว และขยับลงมา 24px
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 24), // ✅ ขยับลงมา 24px
                child: buildGroupedCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildProfileHeader(profile),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildStatsCard(profile),
                    ),
                    const Divider(height: 1),
                    _buildInfoCard(profile),
                    const Divider(height: 1),
                    _buildMenuCard(profile),
                  ],
                ),
              ),
            ),

            // Danger Zone แยกออกมา และเว้นระยะข้างบน
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 24), // ✅ ขยับลงมา
                child: _buildDangerZone(profile),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  // ---------------- Grouped Card Helper ----------------
  Widget buildGroupedCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ---------------- Profile Header ----------------
  Widget _buildProfileHeader(ProfileModel profile) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profile.profileImage != null
                  ? FileImage(profile.profileImage!)
                  : const AssetImage('assets/avatars/avatar-4.png')
                      as ImageProvider,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: () => _showImagePicker(profile),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.blue, size: 20),
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
              Text(profile.name, style: AppTextStyles.bodyLarge),
              const SizedBox(height: 6),
              Text(profile.vehicle, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 6),
              Text(
                profile.available ? "🟢 พร้อมรับงาน" : "🔴 ไม่พร้อม",
                style: profile.available
                    ? AppTextStyles.success
                    : AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        Switch(
          value: profile.available,
          activeColor: Colors.green,
          thumbColor: MaterialStateProperty.all(Colors.white),
          onChanged: (val) => profile.toggleAvailable(val),
        ),
      ],
    );
  }

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
              final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                profile.updateProfileImage(File(pickedFile.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("ถ่ายรูปใหม่"),
            onTap: () async {
              Navigator.pop(ctx);
              final pickedFile =
                  await picker.pickImage(source: ImageSource.camera);
              if (pickedFile != null) {
                profile.updateProfileImage(File(pickedFile.path));
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------- Stats Card ----------------
  Widget _buildStatsCard(ProfileModel profile) {
    return Row(
      children: [
        _statItem("รายได้", "฿${profile.earnings.toStringAsFixed(2)}",
            Icons.account_balance_wallet, AppColors.greenGradient),
        _statItem("งานสำเร็จ", "${profile.completed}", Icons.check_circle,
            AppColors.blueGradient),
        _statItem("เรตติ้ง", profile.rating.toString(), Icons.star,
            AppColors.orangeGradient),
      ],
    );
  }

  Widget _statItem(
      String label, String value, IconData icon, Gradient gradient) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(gradient: gradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.bodyLarge),
          Text(label, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }

  // ---------------- Info Card ----------------
  Widget _buildInfoCard(ProfileModel profile) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.phone),
          title: Text(profile.phone, style: AppTextStyles.bodyMedium),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditPhoneDialog(profile),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: Text(profile.email, style: AppTextStyles.bodyMedium),
        ),
        ListTile(
          leading: const Icon(Icons.motorcycle),
          title: Text(profile.plate, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  // ---------------- Menu Card ----------------
  Widget _buildMenuCard(ProfileModel profile) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.account_balance),
          title: const Text("บัญชีรับเงิน", style: AppTextStyles.bodyLarge),
          subtitle: Text(profile.bankAccount, style: AppTextStyles.bodyMedium),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showBankAccountDialog(profile),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text("เปลี่ยนรหัสผ่าน", style: AppTextStyles.bodyLarge),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showChangePasswordDialog(profile),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.support_agent),
          title: Text("ติดต่อแอดมิน", style: AppTextStyles.bodyLarge),
          subtitle: Text("โทร 089-123-4567\nEmail: admin@rider.com",
              style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  // ---------------- Danger Zone ----------------
  Widget _buildDangerZone(ProfileModel profile) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: AppDecorations.dangerButton,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            onPressed: () => _showLogoutConfirm(profile),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text("ออกจากระบบ",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
        TextButton.icon(
          onPressed: () => _showDeleteAccountConfirm(profile),
          icon: const Icon(Icons.delete, color: Color(0xFFD32F2F)),
          label: const Text("ลบบัญชี", style: AppTextStyles.danger),
        ),
      ],
    );
  }

  // ---------------- Popups ----------------

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

  void _showEditPhoneDialog(ProfileModel profile) {
    final phoneController = TextEditingController(text: profile.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        title: _popupHeader(
          Icons.phone_android,
          "แก้ไขเบอร์โทร",
          AppColors.greenGradient,
        ),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "เบอร์ใหม่"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ยกเลิก", style: AppTextStyles.subtitle),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.greenGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: _popupButtonStyle(AppColors.greenGradient),
              onPressed: () {
                if (phoneController.text.trim().length >= 9) {
                  profile.updatePhone(phoneController.text.trim());
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ แก้ไขเบอร์เรียบร้อย")),
                  );
                }
              },
              child: const Text("บันทึก"),
            ),
          ),
        ],
      ),
    );
  }

  void _showBankAccountDialog(ProfileModel profile) {
    final accountController = TextEditingController(text: profile.bankAccount);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              title: _popupHeader(
                Icons.account_balance,
                "แก้ไขบัญชีรับเงิน",
                AppColors.blueGradient,
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: accountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "หมายเลขพร้อมเพย์",
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    if (accountController.text.length == 10 ||
                        accountController.text.length == 13)
                      QRCodeGenerate(
                        promptPayId: accountController.text,
                        width: 220,
                        height: 220,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ยกเลิก", style: AppTextStyles.subtitle),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.blueGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: _popupButtonStyle(AppColors.blueGradient),
                    onPressed: () {
                      profile.updateBankAccount(accountController.text.trim());
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ บันทึกบัญชีรับเงินเรียบร้อย"),
                        ),
                      );
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
                    onPressed: () {
                      if (newPass.text.isEmpty ||
                          confirmPass.text.isEmpty ||
                          newPass.text != confirmPass.text) {
                        return;
                      }
                      if (profile.changePassword(
                        newPass.text,
                        confirmPass.text,
                      )) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ เปลี่ยนรหัสผ่านสำเร็จ"),
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
              onPressed: () {
                profile.logout();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("👋 ออกจากระบบเรียบร้อย")),
                );
              },
              child: const Text("ยืนยัน"),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirm(ProfileModel profile) {
    _deleteConfirmController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        title: _popupHeader(Icons.delete, "ลบบัญชี", AppColors.darkRedGradient),
        content: TextField(
          controller: _deleteConfirmController,
          decoration: const InputDecoration(
            labelText: "พิมพ์ DELETE เพื่อยืนยัน",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ยกเลิก", style: AppTextStyles.subtitle),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.darkRedGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: _popupButtonStyle(AppColors.darkRedGradient),
              onPressed: () {
                if (profile.deleteAccount(_deleteConfirmController.text)) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("🗑️ ลบบัญชีเรียบร้อย")),
                  );
                }
              },
              child: const Text("ลบ"),
            ),
          ),
        ],
      ),
    );
  }
}