import 'package:hive_flutter/hive_flutter.dart';
import 'package:annex_sales_order/features/user/data/models/user_model.dart';

class UserLocalDataSource {
  static const String _boxName = 'userBox';
  static const String _userKey = 'currentUser';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<UserModel>(_boxName);
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      final box = Hive.box<UserModel>(_boxName);
      await box.put(_userKey, user);
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  UserModel? getUser() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final box = Hive.box<UserModel>(_boxName);
      return box.get(_userKey);
    } catch (e) {
      // Return null on error to prevent crash
      return null;
    }
  }

  bool isUserRegistered() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      final box = Hive.box<UserModel>(_boxName);
      return box.containsKey(_userKey);
    } catch (e) {
      // Return false on error to prevent crash
      return false;
    }
  }
}
