import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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

      final userData = result['user'];
      final riderStatusData = result['rider_status'];

      if (riderStatusData != null) {
        await RiderStatusService.setStatusFromAPI(riderStatusData);
      }

      final riderStatus = await RiderStatusService.getCurrentStatus();

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'เข้าสู่ระบบสำเร็จ',
        desc: 'ยินดีต้อนรับ ${userData['display_name'] ?? 'ไรเดอร์'}',
        btnOkOnPress: () {
          if (riderStatus == RiderStatus.pending ||
              riderStatus == RiderStatus.approved ||
              riderStatus == RiderStatus.rejected) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
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
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.prompt(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.prompt(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF34C759), size: 22),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF34C759),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'เข้าสู่ระบบ',
          style: GoogleFonts.prompt(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: isSmallScreen ? 16 : 24,
          ),
          child: Column(
            children: [
              SizedBox(height: isSmallScreen ? 8 : 16),

              // Logo
              Container(
                width: isSmallScreen ? 80 : 90,
                height: isSmallScreen ? 80 : 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/logo/image-rider.png',
                    width: isSmallScreen ? 75 : 85,
                    height: isSmallScreen ? 75 : 85,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Title
              Text(
                'ยินดีต้อนรับกลับมา',
                style: GoogleFonts.prompt(
                  fontSize: isSmallScreen ? 22 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Text(
                'เข้าสู่ระบบเพื่อเริ่มการส่งออเดอร์',
                style: GoogleFonts.prompt(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: Colors.grey.shade600,
                ),
              ),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Email Field
              _buildTextField(
                _emailController,
                'อีเมล',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              // Password Field
              _buildTextField(
                _passwordController,
                'รหัสผ่าน',
                Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),

              SizedBox(height: isSmallScreen ? 4 : 8),

              // Login Button
              Container(
                width: double.infinity,
                height: isSmallScreen ? 50 : 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF34C759),
                      Color(0xFF28A745),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34C759).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'เข้าสู่ระบบ',
                          style: GoogleFonts.prompt(
                            fontSize: isSmallScreen ? 16 : 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ยังไม่มีบัญชี? ',
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: Text(
                      'สมัครเลย',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        color: const Color(0xFF34C759),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ใช้อีเมลที่ลงทะเบียนกับระบบไรเดอร์',
                        style: GoogleFonts.prompt(
                          color: Colors.blue.shade900,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }
}