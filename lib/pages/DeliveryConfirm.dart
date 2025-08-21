import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DeliveryConfirmPage extends StatefulWidget {
  const DeliveryConfirmPage({super.key});

  @override
  State<DeliveryConfirmPage> createState() => _DeliveryConfirmPageState();
}

class _DeliveryConfirmPageState extends State<DeliveryConfirmPage> {
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _submitted = false;

  Future<void> _takePhoto() async {
    final XFile? f = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (f != null) setState(() => _pickedImage = File(f.path));
  }

  Future<void> _pickFromGallery() async {
    final XFile? f = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (f != null) setState(() => _pickedImage = File(f.path));
  }

  void _submit() {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.white),
              SizedBox(width: 8),
              Text('กรุณาถ่ายรูปก่อนส่งยืนยัน'),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _submitted = true);
    // simulate upload and return
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                'ส่งรูปยืนยันเรียบร้อย',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ขอบคุณที่ยืนยันการจัดส่ง',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              // ElevatedButton(
              //   onPressed: () => Navigator.pop(context, true),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.green,
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 32,
              //       vertical: 12,
              //     ),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(30),
              //     ),
              //   ),
              //   child: const Text(
              //     'กลับหน้าหลัก',
              //     style: TextStyle(
              //       fontWeight: FontWeight.bold,
              //       fontSize: 16,
              //       color: Colors.white,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ถ่ายรูปยืนยันการจัดส่ง',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กรุณาถ่ายรูปเพื่อยืนยันการจัดส่ง โดยในภาพต้องมีรายละเอียดดังนี้:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '\u2022 อาหารที่จัดส่ง',
              style: TextStyle(color: Colors.black54),
            ),
            const Text(
              '\u2022 สภาพแวดล้อมของจุดจัดส่ง',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Center(
              child: _pickedImage == null
                  ? Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[100],
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/png/meem2.jpg',
                              width: 300,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 60,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'กดปุ่มด้านล่างเพื่อถ่ายรูป',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  // ? Container(
                  //     width: 250,
                  //     height: 250,
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(16),
                  //       color: Colors.grey[100],
                  //       border: Border.all(
                  //         color: Colors.green.shade200,
                  //         width: 2,
                  //       ),
                  //     ),
                  //     child: const Column(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Icon(
                  //           Icons.camera_alt_outlined,
                  //           size: 60,
                  //           color: Colors.grey,
                  //         ),
                  //         SizedBox(height: 8),
                  //         Text(
                  //           'กดปุ่มด้านล่างเพื่อถ่ายรูป',
                  //           style: TextStyle(color: Colors.grey, fontSize: 14),
                  //         ),
                  //       ],
                  //     ),
                  //   )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _pickedImage!,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'ถ่ายรูป',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      'เลือกจากแกลอรี่',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ยืนยันการจัดส่ง',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
