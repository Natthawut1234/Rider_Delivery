// Helper function เพื่อ debug SharedPreferences
// ใส่ในไฟล์ที่ต้องการ debug เช่น Home.dart หรือ JobStart.dart

import 'package:shared_preferences/shared_preferences.dart';

Future<void> debugSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  Set<String> keys = prefs.getKeys();

  print('🔍 === DEBUG SHARED PREFERENCES ===');
  for (String key in keys) {
    dynamic value = prefs.get(key);
    print('📋 $key: $value (${value.runtimeType})');
  }
  print('🔍 === END DEBUG ===');
}

// เรียกใช้ใน initState หรือที่ต้องการ debug:
// await debugSharedPreferences();
