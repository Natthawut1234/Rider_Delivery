import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';
import 'package:http_parser/http_parser.dart';

class ShopClosedAPI {
  /// POST /rider/shop-closed
  static Future<Map<String, dynamic>> reportShopClosed({
    required int orderId,
    required int marketId,
    required String reason,
    String? note,
    List<File>? images,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final baseUrl = BaseAPI_URL.baseURL;
      final uri = Uri.parse("$baseUrl/shop-closed");

      print("🛰️ [ShopClosedAPI] --- START ---");
      print("📍 Endpoint: $uri");
      print("🔑 Token: ${token != null ? '✅ มี token' : '❌ ไม่มี token'}");

      final request = http.MultipartRequest("POST", uri);

      // Header
      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
      }
      request.headers["Accept"] = "application/json";

      // Fields
      request.fields["order_id"] = orderId.toString();
      request.fields["market_id"] = marketId.toString();
      request.fields["reason"] = reason;
      if (note != null && note.isNotEmpty) {
        request.fields["note"] = note;
      }

      print("🧾 Fields:");
      request.fields.forEach((k, v) => print("   $k = $v"));

      // Files
      if (images != null && images.isNotEmpty) {
        print("📸 แนบรูปภาพทั้งหมด ${images.length} รูป");
        for (var img in images) {
          print("   📷 ${img.path}");

          // ตรวจนามสกุลไฟล์เพื่อกำหนด MIME type ให้ถูกต้อง
          final lowerPath = img.path.toLowerCase();
          final mimeType = lowerPath.endsWith('.png')
              ? MediaType('image', 'png')
              : lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')
              ? MediaType('image', 'jpeg')
              : MediaType('image', 'jpeg'); // fallback

          request.files.add(
            await http.MultipartFile.fromPath(
              'images', // ✅ ตรงกับ backend
              img.path,
              contentType: mimeType, // ✅ สำคัญมาก
            ),
          );
        }
      } else {
        print("🖼️ ไม่มีรูปแนบไป");
      }

      print("🚀 กำลังส่งคำขอไปยังเซิร์ฟเวอร์...");
      final response = await request.send();

      final responseBody = await response.stream.bytesToString();
      print("📡 Status Code: ${response.statusCode}");
      print("📨 Response Body:");
      print(responseBody);

      final decoded = json.decode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ สำเร็จ: ${decoded["message"]}");
        print("🧩 Data: ${decoded["data"]}");
        print("🛰️ [ShopClosedAPI] --- END ---");
        return {
          "success": true,
          "message": decoded["message"] ?? "แจ้งร้านปิดเรียบร้อยแล้ว ✅",
          "data": decoded["data"],
        };
      } else {
        print("⚠️ ไม่สำเร็จ: ${decoded["error"] ?? 'unknown error'}");
        print("🛰️ [ShopClosedAPI] --- END ---");
        return {
          "success": false,
          "error": decoded["error"] ?? "ไม่สามารถแจ้งร้านปิดได้",
          "status": response.statusCode,
        };
      }
    } catch (e, stack) {
      print("❌ [ShopClosedAPI] เกิดข้อผิดพลาด:");
      print("   Error: $e");
      print("   StackTrace: $stack");
      print("🛰️ [ShopClosedAPI] --- END (ERROR) ---");
      return {"success": false, "error": e.toString()};
    }
  }
}
