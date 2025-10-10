import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NavigationGuard {
  // ตรวจสอบว่าควรอนุญาตให้ย้อนหน้าหรือไม่
  static bool canGoBack(String? currentStatus) {
    if (currentStatus == null) return true;

    // Status ที่ไม่ควรให้ย้อนหน้า
    const restrictedStatuses = [
      'going_to_shop', // กำลังไปร้าน
      'arrived_at_shop', // ถึงร้านแล้ว
      'picked_up', // รับอาหารแล้ว
      'delivering', // กำลังส่ง
      'arrived_at_customer', // ถึงลูกค้าแล้ว
    ];

    return !restrictedStatuses.contains(currentStatus);
  }

  // 🧩 เพิ่ม method นี้เข้าไปใน NavigationGuard
  static Future<bool> showBackWarningDialog(
    BuildContext context,
    String? currentStatus,
  ) async {
    // 1️⃣ ถ้าสามารถกลับได้เลย → อนุญาต
    if (canGoBack(currentStatus)) {
      return true;
    }

    // 2️⃣ ถ้าควรแสดง Warning → แสดง dialog ถามก่อน
    if (shouldShowWarning(currentStatus)) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
              SizedBox(width: 6),
              Text('แจ้งเตือน'),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              getWarningMessage(currentStatus),
              style: const TextStyle(fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              isDefaultAction: false,
              child: const Text('ยกเลิก'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              isDefaultAction: true,
              child: const Text('ย้อนกลับ'),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    // 3️⃣ ถ้าอยู่ในสถานะที่ห้ามย้อนกลับ → แสดง SnackBar แจ้งเตือน
    final message = getBlockMessage(currentStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    return false;
  }

  // ตรวจสอบว่าควรแสดง warning ก่อนย้อนหน้าหรือไม่
  static bool shouldShowWarning(String? currentStatus) {
    if (currentStatus == null) return false;

    const warningStatuses = [
      'rider_assigned', // รับงานแล้ว (รอร้านยืนยัน)
      'confirmed', // ร้านยืนยันออเดอร์
    ];

    return warningStatuses.contains(currentStatus);
  }

  // ข้อความแจ้งเตือนตาม status
  static String getWarningMessage(String? currentStatus) {
    switch (currentStatus) {
      case 'rider_assigned':
      case 'confirmed':
        return 'คุณได้รับงานนี้แล้ว\nหากย้อนกลับจะต้องทำงานนี้ให้เสร็จ\nต้องการย้อนกลับหรือไม่?';
      case 'going_to_shop':
        return 'คุณกำลังเดินทางไปร้าน\nไม่สามารถยกเลิกงานได้';
      case 'arrived_at_shop':
        return 'คุณมาถึงร้านแล้ว\nกรุณารับอาหารให้เสร็จสิ้น';
      case 'picked_up':
        return 'คุณรับอาหารแล้ว\nกรุณานำไปส่งลูกค้าให้เสร็จสิ้น';
      case 'delivering':
        return 'คุณกำลังจัดส่งอาหาร\nกรุณาส่งให้ลูกค้าให้เสร็จสิ้น';
      case 'arrived_at_customer':
        return 'คุณมาถึงลูกค้าแล้ว\nกรุณายืนยันการส่งให้เสร็จสิ้น';
      default:
        return 'คุณแน่ใจว่าต้องการย้อนกลับ?';
    }
  }

  // ข้อความบน SnackBar
  static String getBlockMessage(String? currentStatus) {
    switch (currentStatus) {
      case 'going_to_shop':
        return 'ไม่สามารถย้อนกลับได้ กำลังเดินทางไปร้าน';
      case 'arrived_at_shop':
        return 'ไม่สามารถย้อนกลับได้ กรุณารับอาหารให้เสร็จสิ้น';
      case 'picked_up':
        return 'ไม่สามารถย้อนกลับได้ กรุณานำอาหารไปส่งลูกค้า';
      case 'delivering':
        return 'ไม่สามารถย้อนกลับได้ กำลังจัดส่งอาหาร';
      case 'arrived_at_customer':
        return 'ไม่สามารถย้อนกลับได้ กรุณายืนยันการส่งให้เสร็จสิ้น';
      default:
        return 'ไม่สามารถย้อนกลับได้ในขณะนี้';
    }
  }
}
