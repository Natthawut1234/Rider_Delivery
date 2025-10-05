import 'package:flutter/material.dart';
import 'package:rider_delivery/pages/ProfilePage/ProfileModel.dart';
import 'styles.dart';
import 'package:promptpay_qrcode_generate/promptpay_qrcode_generate.dart';

/// Utility class รวม Dialog สำหรับแก้ไขข้อมูลโปรไฟล์
class ProfileEditDialogs {
  static ButtonStyle _popupButtonStyle(Gradient gradient) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ).copyWith(
      foregroundColor: MaterialStateProperty.all(Colors.white),
      overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.08)),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  static Widget _popupHeader(IconData icon, String title, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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

  // -------- Phone --------
  static void showEditPhoneDialog(BuildContext context, ProfileModel profile) {
    final controller = TextEditingController(text: profile.phone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        title: _popupHeader(
          Icons.phone_android,
          'แก้ไขเบอร์โทร',
          AppColors.greenGradient,
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'เบอร์ใหม่'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: AppTextStyles.subtitle),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.greenGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: _popupButtonStyle(AppColors.greenGradient),
              onPressed: () async {
                final ok = await profile.updatePhone(controller.text);
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ แก้ไขเบอร์เรียบร้อย')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ แก้ไขเบอร์ไม่สำเร็จ'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('บันทึก'),
            ),
          ),
        ],
      ),
    );
  }

  // -------- Birthdate --------
  static void showEditBirthdateDialog(
    BuildContext context,
    ProfileModel profile,
  ) async {
    DateTime initialDate = profile.birthdate ?? DateTime(1995, 1, 1);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 15, now.month, now.day), // อายุ >= 15
      helpText: 'เลือกวันเกิด',
    );
    if (picked != null) {
      final ok = await profile.updateBirthdate(picked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? '✅ บันทึกวันเกิดแล้ว' : '❌ บันทึกวันเกิดไม่สำเร็จ',
          ),
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    }
  }

  // -------- Gender (one-time set) --------
  static void showSetGenderDialog(BuildContext context, ProfileModel profile) {
    if (profile.gender != null) return; // ถ้ามีแล้วไม่ทำอะไร
    int? tempGender; // 0 / 1
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          title: _popupHeader(Icons.person, 'ระบุเพศ', AppColors.blueGradient),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(
                value: 0,
                groupValue: tempGender,
                onChanged: (v) => setState(() => tempGender = v),
                title: const Text('ชาย'),
              ),
              RadioListTile<int>(
                value: 1,
                groupValue: tempGender,
                onChanged: (v) => setState(() => tempGender = v),
                title: const Text('หญิง'),
              ),
              const SizedBox(height: 8),
              const Text(
                'สามารถตั้งค่าได้ครั้งเดียว กรุณาตรวจสอบก่อนยืนยัน',
                style: TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.blueGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: _popupButtonStyle(AppColors.blueGradient),
                onPressed: tempGender == null
                    ? null
                    : () async {
                        final ok = await profile.setGenderIfUnset(tempGender!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? '✅ บันทึกเพศเรียบร้อย'
                                  : 'ไม่สามารถแก้ไขเพศได้',
                            ),
                            backgroundColor: ok ? null : Colors.red,
                          ),
                        );
                      },
                child: const Text('ยืนยัน'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- PromptPay --------
  static void showEditPromptPayDialog(
    BuildContext context,
    ProfileModel profile,
  ) {
    final controller = TextEditingController(text: profile.promptpay);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          title: _popupHeader(
            Icons.account_balance,
            'แก้ไขพร้อมเพย์',
            AppColors.purpleGradient,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'เบอร์/เลขบัตรประชาชน',
                      hintText: '0812345678 หรือ 1234567890123',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'กรุณากรอกพร้อมเพย์';
                      if (v.trim().length < 9) return 'รูปแบบไม่ถูกต้อง';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 16),
                if (controller.text.length == 10 ||
                    controller.text.length == 13) ...[
                  Text(
                    'ตัวอย่างคิวอาร์โค้ด',
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: AppColors.blueGradient,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: QRCodeGenerate(
                        promptPayId: controller.text,
                        width: 200,
                        height: 200,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: _popupButtonStyle(AppColors.purpleGradient),
                onPressed: () async {
                  if (formKey.currentState?.validate() == true) {
                    final ok = await profile.updatePromptPay(
                      controller.text.trim(),
                    );
                    if (ok) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ บันทึกพร้อมเพย์แล้ว')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ บันทึกพร้อมเพย์ไม่สำเร็จ'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('บันทึก'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
