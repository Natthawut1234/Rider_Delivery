import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({Key? key}) : super(key: key);

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  File? _image;
  bool _isSubmitting = false;

  Map<String, dynamic>? _currentRider;

  @override
  void initState() {
    super.initState();
    _loadCurrentRider();
  }

  /// ✅ โหลดข้อมูลผู้ใช้ที่ล็อกอินไว้จาก SharedPreferences
  Future<void> _loadCurrentRider() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_rider');
    if (userJson != null) {
      setState(() {
        _currentRider = jsonDecode(userJson);
      });
      debugPrint("👤 Rider loaded: $_currentRider");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submitComplaint() async {
    if (_currentRider == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเข้าสู่ระบบก่อน")));
      return;
    }

    final int userId = _currentRider?['user_id'] ?? 0;
    const String role = 'rider'; // 🟩 บทบาทตายตัวของไรเดอร์

    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse("${BaseAPI_URL.baseURL}/complaints");
      final request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userId.toString();
      request.fields['role'] = role;
      request.fields['subject'] = _subjectController.text.trim();
      request.fields['message'] = _messageController.text.trim();

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('evidence', _image!.path),
        );
      }

      debugPrint("📤 Sending complaint: ${request.fields}");

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final decoded = jsonDecode(resBody);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded["message"] ?? "ส่งคำร้องเรียนสำเร็จ"),
            backgroundColor: Colors.green,
          ),
        );
        _subjectController.clear();
        _messageController.clear();
        setState(() => _image = null);

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server Error: ${decoded["error"] ?? resBody}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error sending complaint: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาด: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("คำร้องเรียน / แจ้งปัญหา"),
        backgroundColor: const Color(0xFF34C759),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "หัวข้อคำร้องเรียน",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: "เช่น ลูกค้าปฏิเสธรับอาหาร / ระบบค้าง / แอปเด้ง",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "รายละเอียดเพิ่มเติม",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "อธิบายเหตุการณ์ที่เกิดขึ้น...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.file(_image!, fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, height: 200, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image, color: Color(0xFF34C759)),
              label: const Text(
                "แนบรูปหลักฐาน (ถ้ามี)",
                style: TextStyle(color: Color(0xFF34C759)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitComplaint,
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(
                _isSubmitting ? "กำลังส่ง..." : "ส่งคำร้องเรียน",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
