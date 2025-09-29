import 'dart:io';

// API baseURL สำหรับแต่ละแพลตฟอร์ม
class BaseAPI_URL {
  static String get baseURL {
    // 🔧 สำหรับการ debug - เปลี่ยนได้ตามต้องการ
    // return androidEmulatorURL;  // สำหรับ Android Emulator
    // return localhostURL;        // สำหรับ iOS Simulator
    // return localNetworkURL;     // สำหรับเครื่องจริง

    if (Platform.isAndroid) {
      // Android Emulator ใช้ 10.0.2.2 แทน localhost
      return androidEmulatorURL;
    } else if (Platform.isIOS) {
      // iOS Simulator สามารถใช้ localhost ได้
      return localhostURL;
    } else if (Platform.isAndroid) {
      // ใช้สำหรับเครื่อง Android จริง
      return localNetworkURL;
    } else {
      // Web หรือ Desktop ใช้ localhost
      return localhostURL;
    }
  }

  // URL ตัวเลือกต่างๆ
  static const String localhostURL = 'http://10.173.108.73:4000/rider';
  static const String androidEmulatorURL = 'http://10.173.108.73:4000/rider';
  // แทนที่ด้วย IP จริงของเครื่อง
  static const String localNetworkURL = 'http://10.173.108.73:4000/rider';
  //Socket URL
  static const String SocketURL = 'http://10.173.108.73:4000/riders/socket';

  static const String HostSocketURL = 'http://10.173.108.73:4000';
}
// 'http://10.0.2.2:4000/rider';