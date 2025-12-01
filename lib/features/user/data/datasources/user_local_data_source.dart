import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class UserLocalDataSource {
  static const String _boxName = 'userBox';
  static const String _userKey = 'currentUser';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<UserModel>(_boxName);
    }
  }

  Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(_boxName);
    await box.put(_userKey, user);
  }

  UserModel? getUser() {
    final box = Hive.box<UserModel>(_boxName);
    return box.get(_userKey);
  }

  bool isUserRegistered() {
    final box = Hive.box<UserModel>(_boxName);
    return box.containsKey(_userKey);
  }
}
