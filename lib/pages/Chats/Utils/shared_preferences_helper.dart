// utils/shared_preferences_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class SharedPreferencesHelper {
  static SharedPreferences? _instance;
  
  // Singleton pattern
  static Future<SharedPreferences> getInstance() async {
    _instance ??= await SharedPreferences.getInstance();
    return _instance!;
  }
  
  // Authentication
  static Future<void> setAuthToken(String token) async {
    final prefs = await getInstance();
    await prefs.setString(AppConstants.PREF_AUTH_TOKEN, token);
  }
  
  static Future<String?> getAuthToken() async {
    final prefs = await getInstance();
    return prefs.getString(AppConstants.PREF_AUTH_TOKEN);
  }
  
  static Future<void> removeAuthToken() async {
    final prefs = await getInstance();
    await prefs.remove(AppConstants.PREF_AUTH_TOKEN);
  }
  
  // User Information
  static Future<void> setUserId(int userId) async {
    final prefs = await getInstance();
    await prefs.setInt(AppConstants.PREF_USER_ID, userId);
  }
  
  static Future<int?> getUserId() async {
    final prefs = await getInstance();
    return prefs.getInt(AppConstants.PREF_USER_ID);
  }
  
  static Future<void> setRiderId(int riderId) async {
    final prefs = await getInstance();
    await prefs.setInt(AppConstants.PREF_RIDER_ID, riderId);
  }
  
  static Future<int?> getRiderId() async {
    final prefs = await getInstance();
    return prefs.getInt(AppConstants.PREF_RIDER_ID);
  }
  
  static Future<void> setUserName(String name) async {
    final prefs = await getInstance();
    await prefs.setString(AppConstants.PREF_USER_NAME, name);
  }
  
  static Future<String?> getUserName() async {
    final prefs = await getInstance();
    return prefs.getString(AppConstants.PREF_USER_NAME);
  }
  
  static Future<void> setRiderName(String name) async {
    final prefs = await getInstance();
    await prefs.setString(AppConstants.PREF_RIDER_NAME, name);
  }
  
  static Future<String?> getRiderName() async {
    final prefs = await getInstance();
    return prefs.getString(AppConstants.PREF_RIDER_NAME);
  }
  
  static Future<void> setUserPhoto(String photo) async {
    final prefs = await getInstance();
    await prefs.setString(AppConstants.PREF_USER_PHOTO, photo);
  }
  
  static Future<String?> getUserPhoto() async {
    final prefs = await getInstance();
    return prefs.getString(AppConstants.PREF_USER_PHOTO);
  }
  
  static Future<void> setRiderPhoto(String photo) async {
    final prefs = await getInstance();
    await prefs.setString(AppConstants.PREF_RIDER_PHOTO, photo);
  }
  
  static Future<String?> getRiderPhoto() async {
    final prefs = await getInstance();
    return prefs.getString(AppConstants.PREF_RIDER_PHOTO);
  }
  
  static Future<void> setUserType(String type) async {
    final prefs = await getInstance();
    await prefs.setString(AppConstants.PREF_USER_TYPE, type);
  }
  
  static Future<String?> getUserType() async {
    final prefs = await getInstance();
    return prefs.getString(AppConstants.PREF_USER_TYPE);
  }
  
  static Future<void> setIsLoggedIn(bool isLoggedIn) async {
    final prefs = await getInstance();
    await prefs.setBool(AppConstants.PREF_IS_LOGGED_IN, isLoggedIn);
  }
  
  static Future<bool> getIsLoggedIn() async {
    final prefs = await getInstance();
    return prefs.getBool(AppConstants.PREF_IS_LOGGED_IN) ?? false;
  }
  
  // Helper methods for rider info
  static Future<Map<String, dynamic?>> getRiderInfo() async {
    return {
      'user_id': await getUserId(),
      'rider_id': await getRiderId(),
      'name': await getRiderName(),
      'photo': await getRiderPhoto(),
      'auth_token': await getAuthToken(),
      'is_logged_in': await getIsLoggedIn(),
    };
  }
  
  static Future<void> saveRiderInfo({
    required int userId,
    required int riderId,
    required String name,
    String? photo,
    required String authToken,
  }) async {
    await setUserId(userId);
    await setRiderId(riderId);
    await setRiderName(name);
    if (photo != null) await setRiderPhoto(photo);
    await setAuthToken(authToken);
    await setUserType(AppConstants.USER_TYPE_RIDER);
    await setIsLoggedIn(true);
  }
  
  // Clear all data (logout)
  static Future<void> clearAll() async {
    final prefs = await getInstance();
    await prefs.clear();
  }
  
  // Clear only auth data (keep some user preferences)
  static Future<void> clearAuthData() async {
    final prefs = await getInstance();
    await prefs.remove(AppConstants.PREF_AUTH_TOKEN);
    await prefs.remove(AppConstants.PREF_USER_ID);
    await prefs.remove(AppConstants.PREF_RIDER_ID);
    await prefs.remove(AppConstants.PREF_USER_NAME);
    await prefs.remove(AppConstants.PREF_RIDER_NAME);
    await prefs.remove(AppConstants.PREF_USER_PHOTO);
    await prefs.remove(AppConstants.PREF_RIDER_PHOTO);
    await prefs.remove(AppConstants.PREF_USER_TYPE);
    await prefs.setBool(AppConstants.PREF_IS_LOGGED_IN, false);
  }
  
  // Generic methods
  static Future<void> setString(String key, String value) async {
    final prefs = await getInstance();
    await prefs.setString(key, value);
  }
  
  static Future<String?> getString(String key) async {
    final prefs = await getInstance();
    return prefs.getString(key);
  }
  
  static Future<void> setInt(String key, int value) async {
    final prefs = await getInstance();
    await prefs.setInt(key, value);
  }
  
  static Future<int?> getInt(String key) async {
    final prefs = await getInstance();
    return prefs.getInt(key);
  }
  
  static Future<void> setBool(String key, bool value) async {
    final prefs = await getInstance();
    await prefs.setBool(key, value);
  }
  
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }
  
  static Future<void> setDouble(String key, double value) async {
    final prefs = await getInstance();
    await prefs.setDouble(key, value);
  }
  
  static Future<double?> getDouble(String key) async {
    final prefs = await getInstance();
    return prefs.getDouble(key);
  }
  
  static Future<void> setStringList(String key, List<String> value) async {
    final prefs = await getInstance();
    await prefs.setStringList(key, value);
  }
  
  static Future<List<String>> getStringList(String key) async {
    final prefs = await getInstance();
    return prefs.getStringList(key) ?? [];
  }
  
  static Future<void> remove(String key) async {
    final prefs = await getInstance();
    await prefs.remove(key);
  }
  
  static Future<bool> containsKey(String key) async {
    final prefs = await getInstance();
    return prefs.containsKey(key);
  }
  
  // Debug methods
  static Future<void> printAllKeys() async {
    final prefs = await getInstance();
    final keys = prefs.getKeys();
    print('SharedPreferences keys: $keys');
    for (String key in keys) {
      final value = prefs.get(key);
      print('$key: $value');
    }
  }
}