import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ImageSaver {
  /// ฟังก์ชันบันทึกภาพไปยัง Gallery
  static Future<void> saveImage(Uint8List bytes, {String? name}) async {
    try {
      await Gal.putImageBytes(
        bytes,
        name: name ?? "qr_code_${DateTime.now().millisecondsSinceEpoch}.png",
      );

      Fluttertoast.showToast(msg: "✅ บันทึกรูปเรียบร้อยแล้ว");
    } catch (e) {
      Fluttertoast.showToast(msg: "❌ บันทึกรูปไม่สำเร็จ: ${e.toString()}");
    }
  }
}
