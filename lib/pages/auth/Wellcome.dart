import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:delivery/APIs/middleware/authService.dart';
// import 'package:delivery/pages/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class wellcomePage extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '564286121421-d7t8lmnj4ojnvr0etfrr2kge3pj1ijic.apps.googleusercontent.com', // ✅ ใช้ Web client ID
  );

  Future<void> _handleLogin(BuildContext context) async {
    try {
      print("Start Google SignIn");

      // ✅ บังคับให้แสดงตัวเลือกบัญชีทุกครั้ง
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

      // final success = await AuthService().loginWithGoogle(auth.idToken!);
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      final user = jsonDecode(userStr!); // ✅ ปลอดภัยเพราะเราเก็บ json แล้ว
      // print("loginWithGoogle result: $success");

      // if (success) {
      //   await AwesomeDialog(
      //     context: context,
      //     dialogType: DialogType.success,
      //     animType: AnimType.scale,
      //     title: 'เข้าสู่ระบบสำเร็จ',
      //     desc: 'ยินดีต้อนรับ ${user['display_name']}',
      //     btnOkOnPress: () {},
      //     btnOkColor: Colors.green,
      //   ).show();
      //   Navigator.pushReplacementNamed(context, '/main');
      // } else {
      //   AwesomeDialog(
      //     context: context,
      //     dialogType: DialogType.error,
      //     animType: AnimType.rightSlide,
      //     title: 'เข้าสู่ระบบไม่สำเร็จ',
      //     desc: 'กรุณาตรวจสอบอินเทอร์เน็ต หรือบัญชีผู้ใช้ของคุณ',
      //     btnOkOnPress: () {},
      //   ).show();
      // }
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
    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง
          SizedBox.expand(
            child: Image.asset(
              'assets/png/login-background.png',
              fit: BoxFit.cover,
            ),
          ),
          // ชั้นสีทับเพื่อให้อ่านง่าย
          Container(color: Colors.black.withOpacity(0.3)),
          // เนื้อหา
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: RichText(
                      text: const TextSpan(
                        text: 'การสั่งอาหารจะเป็นเรื่องง่ายดาย\nเพราะ',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: 'เราใส่ใจ',
                            style: TextStyle(
                              color: Color(0xFF34C759),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' เพื่อคุณทุกคน กับ\nCSC FOOD',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Column(
                  children: [
                    Text(
                      'CSC FOOD',
                      style: GoogleFonts.prompt(
                        fontSize: 40,
                        color: const Color(0xFF34C759),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'WELCOME',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/login',
                          ); // เปลี่ยนเป็น pushNamed เพื่อให้ pop กลับได้
                          // TODO: เพิ่มหน้าจอ login ถ้ามี
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const LoginPage(),
                          //   ),
                          // );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF34C759),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/register',
                          ); // เปลี่ยนเป็น pushNamed เพื่อให้ pop กลับได้
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ลงทะเบียน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _handleLogin(context);
                        },
                        icon: SvgPicture.asset(
                          'assets/svg/google.svg',
                          width: 24,
                          height: 24,
                        ),
                        label: const Text('Google'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // return Scaffold(
    //   body: Center(
    //     child: ElevatedButton(
    //       onPressed: () => _handleLogin(context),
    //       child: Text("Login with Google"),
    //     ),
    //   ),
    // );
  }
}
