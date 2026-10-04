import 'package:shared_preferences/shared_preferences.dart';

class SettingsHelper {
  static const String _keyGarageName = 'garage_name';
  static const String _keyGarageAddress = 'garage_address';
  static const String _keyGaragePhone = 'garage_phone';
  static const String _keyGarageEmail = 'garage_email';

  static Future<String> getGarageName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGarageName) ?? 'GARA NOTE';
  }

  static Future<void> setGarageName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGarageName, name);
  }

  static Future<String> getGarageAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGarageAddress) ?? '';
  }

  static Future<void> setGarageAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGarageAddress, address);
  }

  static Future<String> getGaragePhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGaragePhone) ?? '';
  }

  static Future<void> setGaragePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGaragePhone, phone);
  }

  static Future<String> getGarageEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGarageEmail) ?? '';
  }

  static Future<void> setGarageEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGarageEmail, email);
  }

  static Future<Map<String, String>> getAllSettings() async {
    return {
      'name': await getGarageName(),
      'address': await getGarageAddress(),
      'phone': await getGaragePhone(),
      'email': await getGarageEmail(),
    };
  }
}
