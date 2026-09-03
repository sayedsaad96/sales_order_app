# Offline Data and Storage Architecture Review
**Flutter Sales Order Application (`annex_sales_order`)**
**Inspector**: `teamwork_preview_explorer_r2_1`
**Audit Date**: September 3, 2026
**Scope**: Local Hive Database, Storage Lifecycles, TypeAdapters & Serialization Safety, Offline Reliability, Backup/Restore & Data Synchronization

---

## Executive Summary

An exhaustive architectural audit of local storage and data persistence was conducted across the Flutter Sales Order Application. The application is designed as an **offline-first local database application**, relying primarily on Hive boxes for persistence of user credentials, sales orders, yarn orders, fabric/CM orders, quotations, return orders, customer profiles, tax invoice requests, and settings. Remote data interactions are restricted to:
1. Periodic background checks via Workmanager checking remote Google Sheets CSV files for PDF catalog updates.
2. In-app remote CSV synchronization for price lists, bank accounts, and company documents.
3. Version update checks against remote configurations.
4. Manual JSON backup and restore via `FilePicker`.

The investigation uncovered **15 distinct issues** across Hive box lifecycles, serialization schemas, data integrity mutations, and synchronization/recovery mechanisms. Among these, **4 are Critical**, **7 are Major**, and **4 are Minor / Improvement Suggestions**.

### Severity Distribution
| Severity | Count | Primary Impact Areas |
|---|:---:|---|
| **Critical** | 4 | Destructive non-transactional backup restore, positional index corruption (`putAt`/`deleteAt`), unhandled Hive box opening race conditions, global init failure swallow |
| **Major** | 7 | Concurrent isolate Hive access, zero compaction across database, memory bloat from image storage, silent deserialization error swallow, length-only stale analytics cache, broken route on restore, return order S/N collisions |
| **Minor / Suggestion** | 4 | Missing box disposal, non-atomic CSV writes, missing offline cache & timeout for bank accounts, inconsistent TypeID/FieldID gaps |

---

## 1. Hive Box Lifecycle Management

### Issue 1.1 [Critical]: Synchronous `Hive.box()` Call Without Box Opening in `SettingsService`
- **File**: `lib/core/services/settings_service.dart`
- **Lines**: 18-26, 33-34
- **Offending Code**:
```dart
class SettingsService {
  static const String _settingsBoxName = 'settings';
  ...
  Box get _box => Hive.box(_settingsBoxName);

  InvoiceSaveStrategy getInvoiceSaveStrategy() {
    final String? strategy = _box.get(_keySaveStrategy);
...
  String? getDefaultSavePath() {
    return _box.get(_keyDefaultPath);
  }
```
- **Failure Mode / Reproduction**:
  `SettingsService` is a singleton with synchronous getters (`getInvoiceSaveStrategy()`, `getDefaultSavePath()`) that directly access `_box => Hive.box('settings')`. However, `SettingsService` has **no `init()` method** and **never opens the `'settings'` box**. In `lib/main.dart:68-78`, all local data sources are initialized with `await ...init()`, but `'settings'` is omitted entirely.
  The app accidentally relies on `ThemeProvider` in `lib/core/providers/theme_provider.dart:17` calling `Hive.openBox('settings')` inside an unawaited constructor callback (`_loadTheme()`).
  If any component calls `SettingsService().getInvoiceSaveStrategy()` before `ThemeProvider` finishes opening the box (e.g. during initialization, on splash, or in headless testing), Hive throws:
  `HiveError: Box not found. Did you forget to call Hive.openBox()?`
- **Concrete Remediation**:
  1. Add an explicit asynchronous `Future<void> init()` method to `SettingsService`:
     ```dart
     Future<void> init() async {
       if (!Hive.isBoxOpen(_settingsBoxName)) {
         await Hive.openBox(_settingsBoxName);
       }
     }
     ```
  2. Await `SettingsService().init()` in `lib/main.dart` alongside other data sources before `runApp()`.
  3. Ensure `_box` getter safely checks `Hive.isBoxOpen(_settingsBoxName)`.

---

### Issue 1.2 [Critical]: Global Initialization Failure Swallowed in `main.dart` Leading to Unhandled Crashes
- **File**: `lib/main.dart`
- **Lines**: 47-85
- **Offending Code**:
```dart
try {
  await Hive.initFlutter();

  // Register all adapters first
  Hive.registerAdapter(UserModelAdapter());
  ...
  // Initialize Data Sources
  final userDataSource = UserLocalDataSource();
  await userDataSource.init();
  await InvoiceLocalDataSource().init();
  ...
} catch (e, stack) {
  debugPrint('Initialization Error: $e\n$stack');
  // Consider showing a fallback UI here if critical init fails
}

runApp(
  MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
    child: const SalesOrderApp(isRegistered: true),
  ),
);
```
- **Failure Mode / Reproduction**:
  If Hive initialization encounters any failure (such as locked box files from another process, corrupt box index headers, full disk, or permission errors), the `catch` block catches the exception, logs to `debugPrint`, and **proceeds directly to `runApp()`**.
  `SplashScreen` then mounts and queries `UserLocalDataSource.isUserRegistered()`. Because the box failed to open, `isUserRegistered()` returns `false`, causing the app to transition the user to `RegistrationPage`. When the user enters their credentials and taps "Register", `UserLocalDataSource.saveUser()` calls `Hive.box<UserModel>('userBox')`, triggering an uncaught `HiveError: Box not found` crash.
- **Concrete Remediation**:
  Track initialization status explicitly. If critical initialization fails, mount an `InitializationErrorApp` displaying a user-friendly recovery screen allowing the user to retry initialization, clear cache, or restore from a backup file:
  ```dart
  bool initSuccess = false;
  String? initError;
  try {
    await Hive.initFlutter();
    ...
    initSuccess = true;
  } catch (e, s) {
    initError = e.toString();
  }

  runApp(
    initSuccess
      ? const MainApp()
      : DatabaseRecoveryApp(error: initError),
  );
  ```

---

### Issue 1.3 [Major]: Multi-Isolate Concurrent Access Without File Locking in `UpdateNotificationService`
- **File**: `lib/core/services/update_notification_service.dart`
- **Lines**: 11-27, 89-95, 139-140
- **Offending Code**:
```dart
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == UpdateNotificationService.taskKey) {
        final service = UpdateNotificationService();
        await service.prepareBackground();
        await service.checkForUpdates();
      }
    ...
  });
}
...
Future<void> prepareBackground() async {
  if (!Hive.isBoxOpen(metadataBoxName)) {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    await Hive.openBox(metadataBoxName);
  }
}
```
- **Failure Mode / Reproduction**:
  `callbackDispatcher()` is executed by `workmanager` inside a background Dart VM isolate (or separate process on Android).
  At the same time, the main UI isolate in `main.dart:80` runs `UpdateNotificationService().init()`, which calls `await prepareBackground()`, opening the box `'pdf_metadata'` in the main isolate.
  Hive is an in-memory embedded database designed for single-isolate/single-process access. When the background isolate executes `Hive.init(dir.path)` and `Hive.openBox('pdf_metadata')`, two isolated runtimes attempt to access and write to the same `.hive` binary file simultaneously. This produces lock conflicts (`HiveError: Another box is already open with the same name`) or causes file corruption if writes occur concurrently. Furthermore, the background isolate never calls `box.close()`.
- **Concrete Remediation**:
  1. Do not use Hive for background periodic tasks spawned across separate isolates unless using a dedicated isolate-safe storage mechanism (such as SQLite via `sqflite`/`drift` or `shared_preferences`).
  2. If using Hive in `callbackDispatcher()`, ensure the box is opened, written, and immediately closed before `executeTask` returns:
     ```dart
     final box = await Hive.openBox(metadataBoxName);
     try {
       await service.checkForUpdates(box);
     } finally {
       await box.close();
     }
     ```

---

### Issue 1.4 [Major]: Complete Absence of Hive Box Compaction Across the Entire Application
- **File**: Entire repository (`lib/**`)
- **Offending Code**:
  Zero invocations of `box.compact()` or `Hive.compactBox()`.
- **Failure Mode / Reproduction**:
  Hive uses an append-only log format. Whenever an order, customer, quotation, or settings value is updated or deleted:
  - `box.put(key, updatedValue)` appends the new value to the end of the file.
  - `invoice.delete()` appends a tombstone record.
  Old records remain in the file on disk as dead bytes. Over months of standard sales operations (editing orders, updating quantities, deleting draft invoices), the Hive files grow monotonically. Without compaction, disk usage inflates unnecessarily, and cold-start box loading times degrade.
- **Concrete Remediation**:
  1. Introduce an automated compaction policy in each data source upon box initialization, or invoke `box.compact()` periodically / during app startup when dead entry ratios exceed a threshold:
     ```dart
     Future<void> init() async {
       if (!Hive.isBoxOpen(_boxName)) {
         final box = await Hive.openBox<SalesOrder>(_boxName);
         await box.compact();
       }
     }
     ```
  2. Expose a manual "Clean Database / Compact" action inside `BackupPage`.

---

### Issue 1.5 [Major]: Unchecked Synchronous `Hive.box()` Calls in Local Data Sources
- **Files**:
  - `lib/features/return_order/data/datasources/return_order_local_data_source.dart:14, 23, 34`
  - `lib/features/sales_order/data/datasources/fabrics_cm_invoice_local_data_source.dart:14, 24, 41`
  - `lib/features/sales_order/data/datasources/quotation_local_data_source.dart:14, 24`
  - `lib/features/sales_order/data/datasources/invoice_local_data_source.dart:20`
  - `lib/features/user/data/datasources/user_local_data_source.dart:16`
- **Offending Code**:
  ```dart
  // Example from return_order_local_data_source.dart:
  List<ReturnOrder> getReturnOrders() {
    final box = Hive.box<ReturnOrder>(boxName);
    return box.values.toList().cast<ReturnOrder>();
  }
  ```
- **Failure Mode / Reproduction**:
  In `ReturnOrderLocalDataSource.getReturnOrders()`, `Hive.box<ReturnOrder>(boxName)` is called directly without checking `Hive.isBoxOpen(boxName)`. If `getReturnOrders()` is invoked before `init()` completes or if `init()` threw an error, this call immediately crashes the UI with `HiveError: Box not found`.
  While other data sources defensively return `[]` when `!isBoxOpen()`, `ReturnOrderLocalDataSource` contains zero guards.
- **Concrete Remediation**:
  Enforce a centralized private getter or helper method across all data sources that validates open state:
  ```dart
  Box<ReturnOrder> get _box {
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('Box $boxName is not open. Call init() before accessing.');
    }
    return Hive.box<ReturnOrder>(boxName);
  }
  ```

---

### Issue 1.6 [Minor / Suggestion]: Missing Box Disposal and Unclosed Resources on Shutdown
- **Files**: All data sources (`lib/features/**/data/datasources/*.dart`)
- **Offending Code**: Zero implementations of `dispose()` or `close()` across all 9 local data source classes.
- **Failure Mode**:
  While the OS closes file descriptors upon process termination, unclosed boxes during hot reload, unit tests, and user logout scenarios leave active in-memory listeners and uncommitted writes.
- **Concrete Remediation**:
  Provide a uniform `Future<void> close()` on data sources or a top-level `DatabaseService.closeAll()` to cleanly flush buffers and release listeners.

---

## 2. Serialization Safety, Schema Evolution & TypeAdapters

### Issue 2.1 [Critical]: Strict Non-Nullable Type-Cast Deserialization Crashes in Generated Adapters
- **Files**:
  - `lib/features/sales_order/data/models/sales_order.g.dart:22, 25, 27, 31, 93, 94, 96`
  - `lib/features/sales_order/data/models/yarn_sales_order.g.dart:22, 27`
  - `lib/features/sales_order/data/models/fabrics_cm_sales_order.g.dart:84`
- **Offending Code**:
```dart
// sales_order.g.dart:
SalesOrder read(BinaryReader reader) {
  ...
  return SalesOrder(
    sn: fields[0] as String?,
    branch: fields[1] as String?,
    orderTypes: (fields[2] as List).cast<String>(), // Line 22: Throws if null!
    customerName: fields[3] as String?,
    region: fields[4] as String?,
    deliveryIncluded: fields[5] as bool,            // Line 25: Throws if null!
    deliveryDate: fields[6] as DateTime?,
    orderDate: fields[7] as DateTime,               // Line 27: Throws if null!
    ...
    items: (fields[11] as List).cast<SalesOrderItem>(), // Line 31: Throws if null!
  );
}

// fabrics_cm_sales_order.g.dart:
FabricsCmLineItem read(BinaryReader reader) {
  ...
  return FabricsCmLineItem(
    quantity: fields[0] as double, // Line 84: Throws if stored as int or null!
  ...
```
- **Failure Mode / Reproduction**:
  1. In `sales_order.g.dart`, fields 2 (`orderTypes`), 5 (`deliveryIncluded`), 7 (`orderDate`), and 11 (`items`) were declared without `@HiveField(..., defaultValue: ...)` annotations in `sales_order.dart`. Consequently, the generated adapter outputs hard casts: `(fields[2] as List).cast<String>()` and `fields[5] as bool`. If an older database record or a corrupted record has `null` for any of these fields, Dart throws:
     `TypeError: type 'Null' is not a subtype of type 'bool' in type cast`
  2. In `FabricsCmLineItemAdapter`, `quantity: fields[0] as double`. In Dart runtime typing, an integer is **not** a subtype of double. If a whole number `10` was written without explicit float preservation, `10 as double` throws:
     `TypeError: type 'int' is not a subtype of type 'double' in type cast`
- **Concrete Remediation**:
  Annotate all non-nullable fields with `@HiveField(x, defaultValue: ...)`:
  ```dart
  @HiveField(2, defaultValue: <String>[])
  List<String> orderTypes;

  @HiveField(5, defaultValue: false)
  bool deliveryIncluded;

  @HiveField(11, defaultValue: <SalesOrderItem>[])
  List<SalesOrderItem> items;
  ```
  And re-run `dart run build_runner build --delete-conflicting-outputs`.

---

### Issue 2.2 [Major]: Severe In-Memory Heap Bloat from Storing Raw `Uint8List` Image Blobs in Hive
- **File**: `lib/features/tax_invoice/data/models/tax_invoice_request.dart`
- **Lines**: 30, 46, 62, 78, 105, 137
- **Offending Code**:
```dart
@HiveType(typeId: 16)
class TaxInvoiceRequest extends HiveObject {
  ...
  @HiveField(11)
  final Uint8List? taxCardImage;
```
- **Failure Mode / Reproduction**:
  Modern mobile cameras capture photos between 3MB and 12MB. When an image is picked in `TaxInvoiceRequestScreen`, the raw image bytes are stored directly inside `TaxInvoiceRequest.taxCardImage`.
  Because Hive is a memory-mapped database that maintains all box values resident in the Dart VM heap, opening `tax_invoice_requests` loads all full-resolution tax card images into RAM simultaneously. With only 15–20 requests, memory consumption surges by 100MB–200MB, triggering out-of-memory (OOM) app crashes on low-end Android and iOS devices.
  Additionally, in `BackupService.createBackup()` (`lib/core/services/backup_service.dart:103`), `toJson()` encodes this byte array to Base64, inflating size by 33% and causing memory spikes and JSON string encoding failures.
- **Concrete Remediation**:
  Never store raw binary images in Hive boxes. Store the image as a local file on the device filesystem and store only the relative file path string in the Hive box:
  ```dart
  @HiveField(11)
  final String? taxCardImagePath;
  ```

---

### Issue 2.3 [Major]: Silent Error Swallowing on Corrupted Deserialization Hides Entire Invoice Stores
- **Files**:
  - `lib/features/sales_order/data/datasources/invoice_local_data_source.dart:31-40`
  - `lib/features/sales_order/data/datasources/yarn_invoice_local_data_source.dart:36-44`
  - `lib/features/user/data/datasources/user_local_data_source.dart:23-32`
- **Offending Code**:
```dart
List<SalesOrder> getAllInvoices() {
  try {
    if (!Hive.isBoxOpen(_boxName)) return [];
    final box = Hive.box<SalesOrder>(_boxName);
    return box.values.toList();
  } catch (e) {
    // Return empty list on error to prevent crash
    return [];
  }
}
```
- **Failure Mode / Reproduction**:
  `box.values.toList()` reads every record from disk into memory. If even **one single record** in the box has a corrupt field or serialization mismatch (e.g. Issue 2.1), `box.values` throws an exception during iteration.
  The `catch (e)` block catches the error and returns `[]`.
  The user navigates to "Saved Invoices" and sees an empty list. The user believes all their orders have been deleted, while in reality, valid records still exist on disk but cannot be displayed because of one malformed record. No error is reported to the user or sent to telemetry.
- **Concrete Remediation**:
  Read records individually using keys to isolate and skip/quarantine damaged records:
  ```dart
  List<SalesOrder> getAllInvoices() {
    if (!Hive.isBoxOpen(_boxName)) return [];
    final box = Hive.box<SalesOrder>(_boxName);
    final List<SalesOrder> valid = [];
    for (final key in box.keys) {
      try {
        final order = box.get(key);
        if (order != null) valid.add(order);
      } catch (recordError) {
        debugPrint('Corrupted record at key $key: $recordError');
        // Quarantine or log damaged record without discarding valid ones
      }
    }
    return valid;
  }
  ```

---

### Issue 2.4 [Minor]: Inconsistent Field ID Numbering and Missing Field Gaps
- **Files**:
  - `lib/features/sales_order/data/models/yarn_sales_order.dart:25-42`
  - `lib/features/sales_order/data/models/fabrics_cm_sales_order.dart:84-98`
  - `lib/main.dart:51-65`
- **Offending Code**:
```dart
// yarn_sales_order.dart:
@HiveField(8)  String? editQuantity;
@HiveField(18) String? contactName;
@HiveField(19, defaultValue: false) bool specifiedQuantity;
@HiveField(11) String? paymentMethod;
// Note: Fields 9 and 10 are completely skipped!
```
- **Failure Mode**:
  Field IDs 9 and 10 were omitted, while 18 and 19 were inserted before 11–17. In `FabricsCmLineItem`, fields 2..6 were deleted. In `main.dart`, registered TypeIDs skip 13 and 14. While Hive permits non-contiguous IDs, undocumented ID gaps cause future contributors to reuse abandoned IDs, risking catastrophic binary deserialization errors against legacy user databases.
- **Concrete Remediation**:
  Maintain a clear schema changelog comment in model definitions documenting retired field IDs and explicitly marking them as reserved:
  ```dart
  // RESERVED / RETIRED HIVE FIELD IDS: 9, 10
  ```

---

## 3. Data Integrity, Positional Mutations & Concurrency

### Issue 3.1 [Critical]: Silent Data Corruption and Unintended Overwrites via Positional Index Mutations (`putAt` and `deleteAt`)
- **Files**:
  - `lib/features/customer_list/data/datasources/customer_local_data_source.dart:46-75`
  - `lib/features/customer_list/presentation/pages/customer_list_page.dart:409-455`
  - `lib/features/customer_list/presentation/pages/add_edit_customer_page.dart:88-92`
  - `lib/features/tax_invoice/data/datasources/tax_invoice_local_data_source.dart:50-70`
  - `lib/features/tax_invoice/presentation/screens/saved_tax_invoices_screen.dart:53-97`
  - `lib/features/tax_invoice/presentation/screens/tax_invoice_request_screen.dart:139, 145`
  - `lib/features/authorization/data/datasources/authorization_local_data_source.dart:51-60`
  - `lib/features/authorization/presentation/screens/authorization_screen.dart:71, 277`
  - `lib/features/sales_order/data/datasources/fabrics_cm_invoice_local_data_source.dart:40-43`
- **Offending Code**:
```dart
// customer_local_data_source.dart:
Future<void> updateCustomer(int index, Customer customer) async {
  try {
    if (index >= 0 && index < _box.length) {
      await _box.putAt(index, customer);
    }
  ...
Future<void> deleteCustomer(int index) async {
  try {
    if (index >= 0 && index < _box.length) {
      await _box.deleteAt(index);
    }
  ...

// saved_tax_invoices_screen.dart:
final requests = box.values.toList().reversed.toList();
...
itemBuilder: (context, index) {
  final request = requests[index];
  final actualIndex = box.length - 1 - index;
  ...
  onPressed: () => _confirmDelete(context, actualIndex),
```
- **Failure Mode / Reproduction**:
  Hive boxes are key-value maps. When keys are auto-incrementing integers, deleting an item leaves gaps in keys. `putAt(index)` and `deleteAt(index)` access Hive's continuous internal array of entries by position `0..length-1`, **not by key**.
  1. Suppose customers exist at positions: Index 0 = "Customer A", Index 1 = "Customer B", Index 2 = "Customer C".
  2. User opens "Customer C" for editing (`index: 2`).
  3. Meanwhile, "Customer A" is deleted. The box length becomes 2 ("Customer B" is at index 0, "Customer C" is at index 1).
  4. The user completes edits on "Customer C" and taps Save. `AddEditCustomerPage` invokes `_dataSource.updateCustomer(2, updatedCustomer)`. Because `index 2 >= box.length`, the update silently fails with no error.
  5. If "Customer B" was opened at index 1, and "Customer A" was deleted, saving "Customer B" executes `_box.putAt(1, updatedB)`, which **OVERWRITES Customer C**!
  6. In `SavedTaxInvoicesScreen:53`, the reversing math `box.length - 1 - index` breaks as soon as entries are deleted while viewing the list.
  All these models extend `HiveObject`, which provides built-in `.save()`, `.delete()`, and `.key`. Bypassing `HiveObject` methods in favor of positional `putAt`/`deleteAt` is a catastrophic anti-pattern that silently overwrites user records.
- **Concrete Remediation**:
  1. Remove `updateCustomer(int index, ...)` and `deleteCustomer(int index)`.
  2. Use `customer.save()` and `customer.delete()`, or key-based mutations:
     ```dart
     Future<void> updateCustomer(dynamic key, Customer customer) async {
       await _box.put(key, customer);
     }
     Future<void> deleteCustomer(dynamic key) async {
       await _box.delete(key);
     }
     ```
  3. In `AddEditCustomerPage`, pass `customer.key` instead of `int index`.

---

### Issue 3.2 [Major]: S/N Collision and Birthday Paradox Risk in Return Orders
- **File**: `lib/features/return_order/presentation/pages/return_order_page.dart`
- **Lines**: 410-412
- **Offending Code**:
```dart
sn: _currentSn ?? 'RET-${DateTime.now().millisecondsSinceEpoch % 10000}',
```
- **Failure Mode / Reproduction**:
  Return order serial numbers are generated using `millisecondsSinceEpoch % 10000`, producing an integer between 0 and 9999 (only 10,000 possibilities). Furthermore, `ReturnOrderLocalDataSource` has no uniqueness validation (`isSnExists` does not exist).
  Under the Birthday Paradox, the collision probability reaches 50% after generating only 118 return orders. When collisions occur, duplicate S/Ns corrupt accounting records, confuse warehouse staff, and cause filename collisions during PDF export.
- **Concrete Remediation**:
  1. Implement `isSnExists` in `ReturnOrderLocalDataSource`.
  2. Use high-entropy unique identifiers, such as formatted timestamps with monotonic sequences (`RET-YYYYMMDD-XXXX`) or UUID v4.

---

### Issue 3.3 [Major]: Blocking Main-Thread I/O and Full Box Scans for S/N Generation
- **Files**:
  - `lib/features/sales_order/presentation/pages/sales_order_page.dart:36-56`
  - `lib/features/sales_order/presentation/providers/fabrics_cm_order_provider.dart:146-168`
  - `lib/features/sales_order/presentation/providers/quotation_provider.dart:49-71`
- **Offending Code**:
```dart
String _generateUniqueSn() {
  final box = InvoiceLocalDataSource().getAllInvoices();
  final existingSns = box.map((e) => e.sn ?? '').toSet();

  final List<int> available = [];
  for (int i = 10; i <= 9999; i++) {
    final sn = 'SO-$i';
    if (!existingSns.contains(sn)) {
      available.add(i);
    }
  }
  ...
```
- **Failure Mode / Reproduction**:
  Every time a user creates or resets a sales order, quotation, or fabrics order, `_generateUniqueSn()` synchronously loads all invoices into memory, constructs a string set, runs a `for` loop allocating a 10,000-element integer array, and picks a random entry.
  As the database accumulates orders, this full-scan operation on the UI isolate freezes the interface and causes visible stutter.
- **Concrete Remediation**:
  Store a single monotonic counter in `settings` box (e.g. `last_sales_order_sn: 1042`) and increment it atomically when generating an S/N: `SO-${counter + 1}`.

---

## 4. Offline-First Reliability, Backup & Synchronization

### Issue 4.1 [Critical]: Destructive Non-Transactional Backup Restore Permanently Wipes Existing Database on Parse Failures
- **File**: `lib/core/services/backup_service.dart`
- **Lines**: 186-288
- **Offending Code**:
```dart
// 1. User
if (backupData.containsKey('user')) {
  final userBox = await _openBox<UserModel>(_userBoxName);
  await userBox.clear();
  await userBox.put('currentUser', UserModel.fromJson(backupData['user']));
}

// 2. Invoices
if (backupData.containsKey('invoices')) {
  final box = await _openBox<SalesOrder>(_invoiceBoxName);
  await box.clear();
  final List<dynamic> list = backupData['invoices'];
  await box.addAll(list.map((e) => SalesOrder.fromJson(e)).toList());
  debugPrint('Restored ${list.length} invoices');
}

// 3. Yarn Invoices
if (backupData.containsKey('yarn_invoices')) {
  final box = await _openBox<YarnSalesOrder>(_yarnInvoiceBoxName);
  await box.clear();
  final List<dynamic> list = backupData['yarn_invoices'];
  await box.addAll(list.map((e) => YarnSalesOrder.fromJson(e)).toList());
...
```
- **Failure Mode / Reproduction**:
  `restoreBackup()` sequentially iterates through 10 Hive boxes. For each box, it calls `await box.clear()` **before** validating or deserializing all items.
  If an error occurs while parsing a subsequent box (e.g., an invalid JSON field, null pointer, or schema format change in `fabrics_cm_orders` or `tax_invoice_requests`):
  - Invoices, yarn orders, and user profile have ALREADY been deleted and partially repopulated.
  - The failing box is WIPED and remains empty.
  - Remaining boxes are untouched.
  - Execution jumps to `catch (e) { onError('فشل استعادة النسخة الاحتياطية: $e'); }`.
  **There is no transaction and no rollback mechanism.** The user's original data is permanently erased and lost.
- **Concrete Remediation**:
  1. **Phase 1 (Validation)**: Parse and deserialize ALL JSON objects into memory first before modifying any Hive box. If any object fails deserialization, abort immediately without touching the database.
  2. **Phase 2 (Pre-restore Snapshot)**: Create a temporary backup of all current boxes prior to restoration.
  3. **Phase 3 (Atomic Staging / Swap)**: Populate new temporary boxes or commit all clears and puts only after full validation succeeds.

---

### Issue 4.2 [Major]: Custom Key Destruction During Backup Restore
- **File**: `lib/core/services/backup_service.dart`
- **Lines**: 200, 210, 221, 230, 241, 249, 261, 272
- **Offending Code**:
```dart
await box.addAll(list.map((e) => YarnSalesOrder.fromJson(e)).toList());
```
- **Failure Mode**:
  `YarnInvoiceLocalDataSource:32` generates custom string keys:
  `'${customerName}_${order.sn}_${timestamp}'`.
  When `restoreBackup()` calls `box.addAll(...)`, Hive ignores existing keys and assigns new sequential auto-incrementing integer keys (`0, 1, 2...`). Any logic or external referencing that relies on the original key format is permanently broken.
- **Concrete Remediation**:
  Store key-value pairs in the backup JSON (`backupData['yarn_invoices'] = {for (var e in box.toMap()) ...}`) and restore using `await box.putAll(map)`.

---

### Issue 4.3 [Major]: Unhandled Navigator Route Crash Upon Completing Backup Restore
- **File**: `lib/features/settings/presentation/pages/backup_page.dart`
- **Line**: 78
- **Offending Code**:
```dart
Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
```
- **Failure Mode / Reproduction**:
  In `lib/main.dart:107-126`, `MaterialApp` is defined with `home: const SplashScreen()`. It does **not** declare named routes (`routes` or `onGenerateRoute`).
  When a user restores a backup on `BackupPage`, a dialog appears: "تم استعادة البيانات بنجاح. يرجى إعادة تشغيل التطبيق."
  When the user taps "حسنًا", line 78 executes `pushNamedAndRemoveUntil('/', ...)`. Flutter immediately throws a fatal exception:
  `FlutterError: Could not find a generator for route RouteSettings("/", null) in the _WidgetsAppState`
- **Concrete Remediation**:
  Define named routes in `MaterialApp` (`routes: {'/': (context) => const SplashScreen()}`) or navigate using `MaterialPageRoute`:
  ```dart
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SplashScreen()),
    (route) => false,
  );
  ```

---

### Issue 4.4 [Major]: Flawed Length-Only Cache Invalidation in `AnalysisService`
- **File**: `lib/features/analysis/data/analysis_service.dart`
- **Lines**: 185-193
- **Offending Code**:
```dart
final currentStateKey =
    '${salesBox.length}-${yarnBox.length}-${fabricBox.length}-${returnsBox.length}';

if (!forceRefresh &&
    _cache.containsKey(cacheKey) &&
    _lastCounts[cacheKey] == currentStateKey) {
  return _cache[cacheKey]!;
}
```
- **Failure Mode / Reproduction**:
  The analytics engine computes revenues, order volumes, customer breakdowns, and representative statistics. It caches the calculated `AnalysisMetrics` in memory using `currentStateKey`, which is formulated solely from box lengths: `${salesBox.length}-${yarnBox.length}-${fabricBox.length}-${returnsBox.length}`.
  If an existing invoice is edited (e.g. total value changes from 5,000 EGP to 50,000 EGP, items added/removed, representative reassigned), or if one order is deleted and another is created:
  `box.length` remains completely unchanged.
  `currentStateKey` matches the cache!
  `AnalysisService.getMetrics()` serves the stale cached metrics. The dashboard charts, KPIs, and customer tables continue to display inaccurate historical metrics until the user manually triggers a forced refresh.
- **Concrete Remediation**:
  Maintain a monotonic database revision timestamp or version number in `settings` box, incremented on every order insert/update/delete, and use that revision as the cache invalidation key.

---

### Issue 4.5 [Minor]: Non-Atomic Remote CSV Cache Writes
- **Files**:
  - `lib/features/sales_order/presentation/pages/price_list_page.dart:55`
  - `lib/features/about/presentation/pages/about_page.dart:56`
- **Offending Code**:
```dart
final decodedBody = utf8.decode(response.bodyBytes);
await cacheFile.writeAsString(decodedBody); // Cache it
_parseAndLoad(decodedBody);
```
- **Failure Mode**:
  `price_list_page.dart` and `about_page.dart` fetch CSV spreadsheets from Google Sheets. When caching, they write directly to `price_list_cache.csv` using `writeAsString`. If the application process is killed, paused, or crashes during the write, the file is corrupted. (Contrast this with `DocumentRepository:128`, which correctly writes to a `.tmp` file and performs an atomic rename).
- **Concrete Remediation**:
  Adopt atomic writing pattern: write to `${cacheFile.path}.tmp` and rename to `cacheFile.path` upon completion.

---

### Issue 4.6 [Minor]: Complete Absence of Offline Caching and Missing HTTP Timeout in `BankAccountsPage`
- **File**: `lib/features/about/presentation/pages/bank_accounts_page.dart`
- **Lines**: 55-58
- **Offending Code**:
```dart
Future<void> _fetchBankAccounts() async {
  try {
    final response = await http.get(Uri.parse(_sheetUrl));
    if (response.statusCode == 200) {
...
```
- **Failure Mode**:
  1. `_fetchBankAccounts()` does not specify a `.timeout()`. If the user is on a slow or unresponsive mobile connection, the HTTP request hangs indefinitely, trapping the user in a perpetual loading spinner.
  2. Unlike `PriceListPage` and `AboutPage`, `BankAccountsPage` has **zero offline caching**. When the user launches the app in the field without an internet connection, bank account data cannot be viewed at all.
- **Concrete Remediation**:
  Add `.timeout(const Duration(seconds: 10))` and implement local CSV disk caching identical to `AboutPage`.

---

## Prioritized Remediation Roadmap

```
┌────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: IMMEDIATE STABILITY & DATA CORRUPTION SHIELD (P0)                    │
├────────────────────────────────────────────────────────────────────────────────┤
│ 1. Fix Customer, Tax Invoice, and Authorization positional index operations    │
│    -> Replace putAt(index) & deleteAt(index) with HiveObject key-based methods │
│ 2. Fix non-transactional BackupService.restoreBackup()                         │
│    -> Pre-validate all JSON payloads before clearing boxes                     │
│ 3. Fix SettingsService synchronous Hive.box() access                           │
│    -> Add init() and await before runApp in main.dart                          │
│ 4. Fix backup_page.dart navigation crash on restore completion                 │
│    -> Replace pushNamedAndRemoveUntil('/') with MaterialPageRoute              │
└────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: SERIALIZATION SAFETY & MEMORY OPTIMIZATION (P1)                       │
├────────────────────────────────────────────────────────────────────────────────┤
│ 5. Add defaultValue annotations to all non-nullable model fields               │
│    -> Re-run build_runner to protect against null type-cast crashes            │
│ 6. Migrate taxCardImage from Uint8List to local file paths                     │
│    -> Eliminate 100MB+ heap spikes and OOM crashes                             │
│ 7. Fix silent error swallow in getAllInvoices() & getAllCustomers()            │
│    -> Iterate keys individually to preserve valid records on single failure    │
│ 8. Fix Workmanager multi-isolate concurrent Hive access                        │
│    -> Open and close box inside callbackDispatcher task scope                  │
└────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: CACHING & OFFLINE-FIRST HARDENING (P2)                                │
├────────────────────────────────────────────────────────────────────────────────┤
│ 9. Fix AnalysisService length-only cache invalidation                          │
│    -> Use database mutation version/timestamp counter                          │
│ 10. Implement periodic box compaction across all data sources                  │
│ 11. Add atomic file writes (.tmp -> rename) in PriceListPage & AboutPage       │
│ 12. Add offline cache and HTTP timeout to BankAccountsPage                     │
│ 13. Replace random S/N generators with monotonic sequential counters           │
└────────────────────────────────────────────────────────────────────────────────┘
```
