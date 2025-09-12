import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.rightSlide,
        title: 'เข้าสู่ระบบไม่สำเร็จ',
        desc: 'กรุณากรอกอีเมลและรหัสผ่าน',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // เรียก API จริง
      final result = await AuthService().loginRider(email, password);

      if (!result['success']) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'เข้าสู่ระบบไม่สำเร็จ',
          desc: result['message'] ?? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
          btnOkOnPress: () {},
        ).show();
        return;
      }

      // ดึงข้อมูลจาก API response
      final userData = result['user'];
      final riderStatusData = result['rider_status'];

      // บันทึกสถานะไรเดอร์จาก API
      if (riderStatusData != null) {
        await RiderStatusService.setStatusFromAPI(riderStatusData);
      }

      // ตรวจสอบสถานะเอกสารหลัง login สำเร็จ
      final riderStatus = await RiderStatusService.getCurrentStatus();

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'เข้าสู่ระบบสำเร็จ',
        desc: 'ยินดีต้อนรับ ${userData['display_name'] ?? 'ไรเดอร์'}',
        btnOkOnPress: () {
          // กรณีที่ 1: ส่งเอกสารแล้ว -> ไปหน้า Home
          if (riderStatus == RiderStatus.pending ||
              riderStatus == RiderStatus.approved ||
              riderStatus == RiderStatus.rejected) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          // กรณีที่ 2: ยังไม่ส่งเอกสาร -> ไปหน้ายืนยันตัวตน
          else {
            Navigator.pushReplacementNamed(context, '/riderIdentity');
          }
        },
        btnOkColor: Colors.green,
      ).show();
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'เกิดข้อผิดพลาด',
        desc: 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        btnOkOnPress: () {},
      ).show();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF34C759),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ลงชื่อเข้าใช้',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // logo / header
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Image(
                  image: AssetImage('assets/logo/image-rider.png'),
                  width: 90,
                  height: 90,
                ),
              ),
              // child: const Center(
              //   child: Icon(
              //     Icons.delivery_dining,
              //     size: 46,
              //     color: Color(0xFF34C759),
              //   ),
              // ),
            ),
            const SizedBox(height: 16),
            const Text(
              'เข้าสู่ระบบสำหรับไรเดอร์',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              _emailController,
              'อีเมล',
              keyboardType: TextInputType.emailAddress,
            ),
            _buildTextField(_passwordController, 'รหัสผ่าน', obscureText: true),
            // Row(
            //   children: [
            //     Checkbox(
            //       value: _remember,
            //       onChanged: (v) => setState(() => _remember = v ?? true),
            //     ),
            //     const SizedBox(width: 4),
            //     const Text('จดจำฉัน'),
            //     const Spacer(),
            //     TextButton(
            //       onPressed: () {
            //         Navigator.pushNamed(context, '/forgotPassword');
            //       },
            //       child: const Text(
            //         'ลืมรหัสผ่าน?',
            //         style: TextStyle(color: Color(0xFF34C759)),
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ยังไม่มีบัญชี?'),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(color: Color(0xFF34C759)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'หมายเหตุ: ใช้อีเมลหรือเบอร์ที่ลงทะเบียนกับระบบไรเดอร์',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
