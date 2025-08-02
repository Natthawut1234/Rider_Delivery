import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _pendingImage; // <--- เพิ่มตัวแปรนี้

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || _pendingImage != null) {
      setState(() {
        _messages.add({'text': text, 'isRider': true, 'image': _pendingImage});
        _pendingImage = null; // ล้างรูปหลังส่ง
      });
      _controller.clear();
      // mock ตอบกลับ
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add({
            'text': 'ขอบคุณค่ะ รอรับอาหารนะคะ',
            'isRider': false,
            'image': null,
          });
        });
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _pendingImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isRider = message['isRider'];
    final alignment = isRider ? Alignment.centerRight : Alignment.centerLeft;
    final color = isRider ? Colors.green[300] : Colors.grey[300];
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isRider
          ? const Radius.circular(12)
          : const Radius.circular(0),
      bottomRight: isRider
          ? const Radius.circular(0)
          : const Radius.circular(12),
    );

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisAlignment: isRider
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isRider)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('assets/avatars/avatar-1.png'),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
              minWidth: 48,
            ),
            child: IntrinsicWidth(
              child: Container(
                alignment: isRider
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: EdgeInsets.only(
                  left: isRider ? 40 : 2,
                  right: isRider ? 2 : 40,
                  top: 4,
                  bottom: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: borderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message['image'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          message['image'],
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if ((message['text'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(message['text'], softWrap: true),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isRider) const SizedBox(width: 8), // ลดช่องว่างให้ชิดขวา
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แชทกับลูกค้า'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final reversedIndex = _messages.length - 1 - index;
                return _buildMessage(_messages[reversedIndex]);
              },
            ),
          ),
          // แถบส่งข้อความ + ปุ่มกล้อง
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end, // เพิ่มบรรทัดนี้
                children: [
                  // ปุ่มเลือกรูป/ถ่ายภาพ
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.photo_camera,
                            color: Colors.green,
                          ),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo, color: Colors.green),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_pendingImage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _pendingImage!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _pendingImage = null;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'พิมพ์ข้อความ...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
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
}
