import 'package:hive_flutter/hive_flutter.dart';
import '../models/authorized_person.dart';
import 'package:flutter/foundation.dart';

class AuthorizationLocalDataSource {
  static const String boxName = 'authorized_persons';
  static Box<AuthorizedPerson>? _boxInstance;

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _boxInstance = await Hive.openBox<AuthorizedPerson>(boxName);
    } else {
      _boxInstance = Hive.box<AuthorizedPerson>(boxName);
    }
  }

  Box<AuthorizedPerson> get _box {
    if (_boxInstance != null && _boxInstance!.isOpen) {
      return _boxInstance!;
    }
    if (Hive.isBoxOpen(boxName)) {
      _boxInstance = Hive.box<AuthorizedPerson>(boxName);
      return _boxInstance!;
    }
    throw HiveError('Authorization box is not open. Call init() first.');
  }

  List<AuthorizedPerson> getAll() {
    return _box.values.toList();
  }

  ValueListenable<Box<AuthorizedPerson>> getListenable() {
    return _box.listenable();
  }

  Future<void> add(AuthorizedPerson person) async {
    try {
      // Check if already exists to avoid duplicates
      final exists = _box.values.any((p) => p.name == person.name && p.nationalId == person.nationalId);
      if (!exists) {
        await _box.add(person);
      }
    } catch (e) {
      debugPrint('Error adding authorized person: $e');
      rethrow;
    }
  }

  Future<void> delete(int index) async {
    try {
      if (index >= 0 && index < _box.length) {
        await _box.deleteAt(index);
      }
    } catch (e) {
      debugPrint('Error deleting authorized person: $e');
      rethrow;
    }
  }
}
