import 'package:hive_flutter/hive_flutter.dart';
import 'package:annex_sales_order/features/customer_list/data/models/customer.dart';
import 'package:flutter/foundation.dart';

class CustomerLocalDataSource {
  static const String boxName = 'customers';
  static Box<Customer>? _boxInstance;

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _boxInstance = await Hive.openBox<Customer>(boxName);
    } else {
      _boxInstance = Hive.box<Customer>(boxName);
    }
  }

  Box<Customer> get _box {
    if (_boxInstance != null && _boxInstance!.isOpen) {
      return _boxInstance!;
    }
    if (Hive.isBoxOpen(boxName)) {
      _boxInstance = Hive.box<Customer>(boxName);
      return _boxInstance!;
    }
    // This should not happen if init() was called properly, but as a fallback:
    throw HiveError('Customer box is not open. Call init() first.');
  }

  List<Customer> getAllCustomers() {
    return _box.values.toList();
  }

  ValueListenable<Box<Customer>> getListenable() {
    return _box.listenable();
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      await _box.add(customer);
    } catch (e) {
      debugPrint('Error adding customer: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(int index, Customer customer) async {
    try {
      if (index >= 0 && index < _box.length) {
        await _box.putAt(index, customer);
      }
    } catch (e) {
      debugPrint('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> updateCustomerKey(dynamic key, Customer customer) async {
    try {
      await _box.put(key, customer);
    } catch (e) {
      debugPrint('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(int index) async {
    try {
      if (index >= 0 && index < _box.length) {
        await _box.deleteAt(index);
      }
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      rethrow;
    }
  }
}
