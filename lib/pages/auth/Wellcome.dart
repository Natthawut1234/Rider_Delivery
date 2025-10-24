import 'package:rider_delivery/APIs/middleware/authService.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class wellcomePage extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '564286121421-d7t8lmnj4ojnvr0etfrr2kge3pj1ijic.apps.googleusercontent.com',
  );

  Future<void> _handleLogin(BuildContext context) async {
    try {
      print("Start Google SignIn");

      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();
      print("Google SignIn done");

      if (account == null) {
        print('User cancelled login');
        return;
      }

      final auth = await account.authentication;
      print("Got idToken: ${auth.idToken}");

      if (auth.idToken == null) {
        print('No ID token found');
        return;
      }

      final authService = AuthService();
      final result = await authService.loginWithGoogle(auth.idToken!);
      print("Google login result: ${result['success']}");

      if (result['success']) {
        final user = result['user'];
        final riderStatus = result['rider_status'];

        await AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: 'เข้าสู่ระบบสำเร็จ',
          desc: 'ยินดีต้อนรับ ${user['display_name']}',
          btnOkOnPress: () {},
          btnOkColor: Colors.green,
        ).show();

        if (context.mounted) {
          if (riderStatus != null && riderStatus['has_submitted'] == true) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/riderIdentity');
          }
        }
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'เข้าสู่ระบบไม่สำเร็จ',
          desc:
              result['message'] ??
              'กรุณาตรวจสอบอินเทอร์เน็ต หรือบัญชีผู้ใช้ของคุณ',
          btnOkOnPress: () {},
        ).show();
      }
    } catch (e, st) {
      print("Login error: $e");
      print(st);

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'เกิดข้อผิดพลาด',
        desc: 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่อีกครั้ง\n\n$e',
        btnOkOnPress: () {},
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง
          SizedBox.expand(
            child: Image.asset(
              'assets/png/login-background-3.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // เนื้อหา - ใช้ SingleChildScrollView
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: isSmallScreen ? 20 : 32),
                      
                      // Header Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เริ่มต้นการส่งออเดอร์',
                              style: GoogleFonts.prompt(
                                fontSize: isSmallScreen ? 24 : 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 10),
                            Text(
                              'สร้างรายได้ ยืดหยุ่น ตามสไตล์คุณ',
                              style: GoogleFonts.prompt(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 40),

                      // Logo Section
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.two_wheeler,
                          size: isSmallScreen ? 45 : 55,
                          color: const Color(0xFF34C759),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 14),
                      Text(
                        'CSC RIDER',
                        style: GoogleFonts.prompt(
                          fontSize: isSmallScreen ? 28 : 32,
                          color: const Color(0xFF34C759),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Text(
                        'พาร์ทเนอร์ไรเดอร์',
                        style: GoogleFonts.prompt(
                          fontSize: isSmallScreen ? 13 : 15,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 40),

                      // Benefits Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            _buildBenefitItem(
                              Icons.schedule,
                              'ทำงานเมื่อไหร่ก็ได้',
                              isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 10),
                            _buildBenefitItem(
                              Icons.attach_money,
                              'รายได้ดี มีโบนัส',
                              isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 10),
                            _buildBenefitItem(
                              Icons.support_agent,
                              'ซัพพอร์ท 24/7',
                              isSmallScreen,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Buttons Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          children: [
                            // Login Button
                            Container(
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
                                    color: const Color(0xFF34C759).withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, isSmallScreen ? 50 : 54),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'เข้าสู่ระบบ',
                                  style: GoogleFonts.prompt(
                                    fontSize: isSmallScreen ? 16 : 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 10 : 12),

                            // Register Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, isSmallScreen ? 50 : 54),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'สมัครเป็นไรเดอร์',
                                style: GoogleFonts.prompt(
                                  fontSize: isSmallScreen ? 16 : 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 14 : 16),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'หรือ',
                                    style: GoogleFonts.prompt(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isSmallScreen ? 14 : 16),

                            // Google Sign In Button
                            ElevatedButton.icon(
                              onPressed: () {
                                _handleLogin(context);
                              },
                              icon: SvgPicture.asset(
                                'assets/svg/google.svg',
                                width: 22,
                                height: 22,
                              ),
                              label: Text(
                                'เข้าสู่ระบบด้วย Google',
                                style: GoogleFonts.prompt(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, isSmallScreen ? 50 : 54),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 20 : 28),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: const Color(0xFF34C759).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF34C759),
            size: isSmallScreen ? 18 : 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.prompt(
            fontSize: isSmallScreen ? 13 : 14,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}