import 'package:hive_flutter/hive_flutter.dart';

enum InvoiceSaveStrategy { ask, auto }

class SettingsService {
  static const String _settingsBoxName = 'settings';
  static const String _keySaveStrategy = 'invoice_save_strategy';
  static const String _keyDefaultPath = 'default_save_path';

  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();

  Box get _box => Hive.box(_settingsBoxName);

  InvoiceSaveStrategy getInvoiceSaveStrategy() {
    final String? strategy = _box.get(_keySaveStrategy);
    if (strategy == 'auto') {
      return InvoiceSaveStrategy.auto;
    }
    return InvoiceSaveStrategy.ask;
  }

  Future<void> setInvoiceSaveStrategy(InvoiceSaveStrategy strategy) async {
    await _box.put(_keySaveStrategy, strategy == InvoiceSaveStrategy.auto ? 'auto' : 'ask');
  }

  String? getDefaultSavePath() {
    return _box.get(_keyDefaultPath);
  }

  Future<void> setDefaultSavePath(String path) async {
    await _box.put(_keyDefaultPath, path);
  }
}
