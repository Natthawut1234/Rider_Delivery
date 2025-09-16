import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ImageSaver {
  /// ฟังก์ชันบันทึกภาพไปยัง Gallery
  static Future<void> saveImage(Uint8List bytes, {String? name}) async {
    try {
      final result = await ImageGallerySaver.saveImage(
        bytes,
        name: name ?? "qr_code_${DateTime.now().millisecondsSinceEpoch}",
        quality: 100,
      );

      if (result["isSuccess"] == true) {
        Fluttertoast.showToast(msg: "✅ บันทึกรูปเรียบร้อยแล้ว");
      } else {
        Fluttertoast.showToast(msg: "❌ บันทึกรูปไม่สำเร็จ");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาด: $e");
    }
  }
}
