import 'package:hive_flutter/hive_flutter.dart';
import '../models/tax_invoice_request.dart';
import 'package:flutter/foundation.dart';

class TaxInvoiceLocalDataSource {
  static const String boxName = 'tax_invoice_requests';
  static Box<TaxInvoiceRequest>? _boxInstance;

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _boxInstance = await Hive.openBox<TaxInvoiceRequest>(boxName);
    } else {
      _boxInstance = Hive.box<TaxInvoiceRequest>(boxName);
    }
  }

  Box<TaxInvoiceRequest> get _box {
    if (_boxInstance != null && _boxInstance!.isOpen) {
      return _boxInstance!;
    }
    if (Hive.isBoxOpen(boxName)) {
      _boxInstance = Hive.box<TaxInvoiceRequest>(boxName);
      return _boxInstance!;
    }
    throw HiveError('Tax Invoice box is not open. Call init() first.');
  }

  List<TaxInvoiceRequest> getAll() {
    return _box.values.toList();
  }

  ValueListenable<Box<TaxInvoiceRequest>> getListenable() {
    return _box.listenable();
  }

  Future<void> add(TaxInvoiceRequest request) async {
    try {
      await _box.add(request);
    } catch (e) {
      debugPrint('Error adding tax invoice request: $e');
      rethrow;
    }
  }

  Future<void> update(int index, TaxInvoiceRequest request) async {
    try {
      await _box.putAt(index, request);
    } catch (e) {
      debugPrint('Error updating tax invoice request: $e');
      rethrow;
    }
  }

  Future<void> delete(int index) async {
    try {
      if (index >= 0 && index < _box.length) {
        await _box.deleteAt(index);
      }
    } catch (e) {
      debugPrint('Error deleting tax invoice request: $e');
      rethrow;
    }
  }
}
