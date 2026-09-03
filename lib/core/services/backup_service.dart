import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../features/user/data/models/user_model.dart';
import '../../features/sales_order/data/models/sales_order.dart';
import '../../features/sales_order/data/models/yarn_sales_order.dart';
import '../../features/sales_order/data/models/quotation.dart';
import '../../features/sales_order/data/models/fabrics_cm_sales_order.dart';
import '../../features/return_order/data/models/return_order.dart';
import '../../features/customer_list/data/models/customer.dart';
import '../../features/authorization/data/models/authorized_person.dart';
import '../../features/tax_invoice/data/models/tax_invoice_request.dart';

class BackupService {
  // Box Names (Must match exactly what is used in LocalDataSources)
  static const String _userBoxName = 'userBox';
  static const String _invoiceBoxName = 'invoicesBox';
  static const String _yarnInvoiceBoxName = 'yarn_invoices';
  static const String _quotationBoxName = 'quotations';
  static const String _fabricsCmBoxName = 'fabrics_cm_orders';
  static const String _returnOrderBoxName = 'return_orders';
  static const String _settingsBoxName = 'settings';
  static const String _customersBoxName = 'customers';
  static const String _authorizedPersonsBoxName = 'authorized_persons';
  static const String _taxInvoiceBoxName = 'tax_invoice_requests';

  // Backup version for future compatibility
  static const int _backupVersion = 2;

  Future<void> createBackup({
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final Map<String, dynamic> backupData = {};

      // Add metadata
      backupData['_metadata'] = {
        'version': _backupVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'appName': 'Annex Sales Order',
      };

      // 1. User Data
      final userBox = await _openBox<UserModel>(_userBoxName);
      final currentUser = userBox.get('currentUser');
      if (currentUser != null) {
        backupData['user'] = currentUser.toJson();
      }

      // 2. Invoices (SalesOrder)
      final invoiceBox = await _openBox<SalesOrder>(_invoiceBoxName);
      backupData['invoices'] = invoiceBox.values
          .map((e) => e.toJson())
          .toList();

      // 3. Yarn Invoices
      final yarnBox = await _openBox<YarnSalesOrder>(_yarnInvoiceBoxName);
      backupData['yarn_invoices'] = yarnBox.values
          .map((e) => e.toJson())
          .toList();

      // 4. Quotations
      final quotationBox = await _openBox<Quotation>(_quotationBoxName);
      backupData['quotations'] = quotationBox.values
          .map((e) => e.toJson())
          .toList();

      // 5. Fabrics/CM Orders
      final fabricsBox = await _openBox<FabricsCmSalesOrder>(_fabricsCmBoxName);
      backupData['fabrics_cm_orders'] = fabricsBox.values
          .map((e) => e.toJson())
          .toList();

      // 6. Return Orders
      final returnBox = await _openBox<ReturnOrder>(_returnOrderBoxName);
      backupData['return_orders'] = returnBox.values
          .map((e) => e.toJson())
          .toList();

      // 7. Customers
      final customerBox = await _openBox<Customer>(_customersBoxName);
      backupData['customers'] = customerBox.values
          .map((e) => e.toJson())
          .toList();

      // 8. Authorized Persons
      final authBox = await _openBox<AuthorizedPerson>(
        _authorizedPersonsBoxName,
      );
      backupData['authorized_persons'] = authBox.values
          .map((e) => e.toJson())
          .toList();

      // 9. Tax Invoice Requests
      final taxBox = await _openBox<TaxInvoiceRequest>(_taxInvoiceBoxName);
      backupData['tax_invoice_requests'] = taxBox.values
          .map((e) => e.toJson())
          .toList();

      // 10. Settings
      final settingsBox = await _openBox(_settingsBoxName);
      final settingsMap = settingsBox.toMap().map(
        (key, value) => MapEntry(key.toString(), value),
      );
      backupData['settings'] = settingsMap;

      // Add data counts for verification
      backupData['_metadata']['counts'] = {
        'invoices': (backupData['invoices'] as List).length,
        'yarn_invoices': (backupData['yarn_invoices'] as List).length,
        'quotations': (backupData['quotations'] as List).length,
        'fabrics_cm_orders': (backupData['fabrics_cm_orders'] as List).length,
        'return_orders': (backupData['return_orders'] as List).length,
        'customers': (backupData['customers'] as List).length,
        'authorized_persons': (backupData['authorized_persons'] as List).length,
        'tax_invoice_requests':
            (backupData['tax_invoice_requests'] as List).length,
      };

      final jsonString = jsonEncode(backupData);
      final bytes = utf8.encode(jsonString);

      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'backup_annex_$timestamp.json';

      // Let user choose where to save the backup file
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(bytes),
      );

      if (savedPath != null) {
        // On some platforms, saveFile writes the bytes automatically.
        // On others, we need to write manually.
        final file = File(savedPath);
        if (!await file.exists() || await file.length() == 0) {
          await file.writeAsBytes(bytes);
        }
        onSuccess('تم حفظ النسخة الاحتياطية بنجاح في:\n$savedPath');
      } else {
        // User cancelled
        onError('تم إلغاء حفظ النسخة الاحتياطية');
      }
    } catch (e) {
      debugPrint('Backup Error: $e');
      onError('فشل إنشاء النسخة الاحتياطية: $e');
    }
  }

  Future<void> restoreBackup({
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        // Log backup info
        if (backupData.containsKey('_metadata')) {
          final metadata = backupData['_metadata'];
          debugPrint(
            'Restoring backup v${metadata['version']} created at ${metadata['createdAt']}',
          );
          if (metadata.containsKey('counts')) {
            debugPrint('Backup counts: ${metadata['counts']}');
          }
        }

        // Restore User
        if (backupData.containsKey('user')) {
          final userBox = await _openBox<UserModel>(_userBoxName);
          await userBox.clear();
          await userBox.put(
            'currentUser',
            UserModel.fromJson(backupData['user']),
          );
        }

        // Restore Invoices
        if (backupData.containsKey('invoices')) {
          final box = await _openBox<SalesOrder>(_invoiceBoxName);
          await box.clear();
          final List<dynamic> list = backupData['invoices'];
          await box.addAll(list.map((e) => SalesOrder.fromJson(e)).toList());
          debugPrint('Restored ${list.length} invoices');
        }

        // Restore Yarn Invoices
        if (backupData.containsKey('yarn_invoices')) {
          final box = await _openBox<YarnSalesOrder>(_yarnInvoiceBoxName);
          await box.clear();
          final List<dynamic> list = backupData['yarn_invoices'];
          await box.addAll(
            list.map((e) => YarnSalesOrder.fromJson(e)).toList(),
          );
          debugPrint('Restored ${list.length} yarn invoices');
        }

        // Restore Quotations
        if (backupData.containsKey('quotations')) {
          final box = await _openBox<Quotation>(_quotationBoxName);
          await box.clear();
          final List<dynamic> list = backupData['quotations'];
          await box.addAll(list.map((e) => Quotation.fromJson(e)).toList());
          debugPrint('Restored ${list.length} quotations');
        }

        // Restore Fabrics/CM
        if (backupData.containsKey('fabrics_cm_orders')) {
          final box = await _openBox<FabricsCmSalesOrder>(_fabricsCmBoxName);
          await box.clear();
          final List<dynamic> list = backupData['fabrics_cm_orders'];
          await box.addAll(
            list.map((e) => FabricsCmSalesOrder.fromJson(e)).toList(),
          );
          debugPrint('Restored ${list.length} fabrics/cm orders');
        }

        // Restore Return Orders
        if (backupData.containsKey('return_orders')) {
          final box = await _openBox<ReturnOrder>(_returnOrderBoxName);
          await box.clear();
          final List<dynamic> list = backupData['return_orders'];
          await box.addAll(list.map((e) => ReturnOrder.fromJson(e)).toList());
          debugPrint('Restored ${list.length} return orders');
        }

        // Restore Customers
        if (backupData.containsKey('customers')) {
          final box = await _openBox<Customer>(_customersBoxName);
          await box.clear();
          final List<dynamic> list = backupData['customers'];
          await box.addAll(list.map((e) => Customer.fromJson(e)).toList());
          debugPrint('Restored ${list.length} customers');
        }

        // Restore Authorized Persons
        if (backupData.containsKey('authorized_persons')) {
          final box = await _openBox<AuthorizedPerson>(
            _authorizedPersonsBoxName,
          );
          await box.clear();
          final List<dynamic> list = backupData['authorized_persons'];
          await box.addAll(
            list.map((e) => AuthorizedPerson.fromJson(e)).toList(),
          );
          debugPrint('Restored ${list.length} authorized persons');
        }

        // Restore Tax Invoice Requests
        if (backupData.containsKey('tax_invoice_requests')) {
          final box = await _openBox<TaxInvoiceRequest>(_taxInvoiceBoxName);
          await box.clear();
          final List<dynamic> list = backupData['tax_invoice_requests'];
          await box.addAll(
            list.map((e) => TaxInvoiceRequest.fromJson(e)).toList(),
          );
          debugPrint('Restored ${list.length} tax invoice requests');
        }

        // Restore Settings
        if (backupData.containsKey('settings')) {
          final box = await _openBox(_settingsBoxName);
          await box.clear();
          final Map<String, dynamic> settings = Map<String, dynamic>.from(
            backupData['settings'],
          );
          for (final entry in settings.entries) {
            await box.put(entry.key, entry.value);
          }
          debugPrint('Restored ${settings.length} settings');
        }

        onSuccess('تم استعادة البيانات بنجاح. يرجى إعادة تشغيل التطبيق.');
      } else {
        // User canceled
      }
    } catch (e) {
      debugPrint('Restore Error: $e');
      onError('فشل استعادة النسخة الاحتياطية: $e');
    }
  }

  Future<Box<T>> _openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    } else {
      return await Hive.openBox<T>(name);
    }
  }
}
