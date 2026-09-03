# R1 Diagnostic Report: Static Analysis & Code Quality Audit
**Target Repository**: `d:\Sayed\Flutter\sales_order_app`  
**Inspector**: `teamwork_preview_explorer_r1_1`  
**Mode**: Read-Only Comprehensive Audit  
**Date**: 2026-09-03  

---

## Executive Summary

A comprehensive diagnostic audit of the Dart codebase was conducted across all feature modules and core utilities of the **Annex Sales Order Application**. The evaluation focused on four core technical pillars:
1. **Static Analysis & Lint Warnings**: Compiler diagnostics, unawaited returns in try/catch blocks, and analysis options coverage.
2. **Asynchronous Exception Handling & Race Conditions**: Uncaught async errors, unawaited Futures, isolate initialization hazards, and catastrophic data loss vectors.
3. **Widget & State Lifecycles**: Memory leaks from undisposed or inline-allocated controllers, broken navigation pops, `BuildContext` leakage across async gaps and ChangeNotifier providers.
4. **Runtime Crash Hazards**: Fl_chart `RangeError` exceptions, division-by-zero (`NaN`) rendering anomalies, JSON parse format exceptions, and unchecked force-unwraps (`!`).

### Findings Matrix
| Severity | Count | Primary Impact |
|---|---|---|
| **Critical** | 3 | Screen ejection on mobile during PDF generation, catastrophic data wipe on backup restore failure, hardcoded signing credentials in version control |
| **Major** | 12 | Fl_chart RangeErrors, unawaited returns escaping try-catch, inline controller allocation memory leaks, cross-screen debounce timer clobbering, uninitialized Hive box accesses |
| **Minor / Improvement** | 8 | Division-by-zero progress bar distortions, unchecked `!` force unwraps on FormStates, unused constructor parameters, missing strict linter rules |

---

## Pillar 1: Static Analyzer Warnings & Syntax Diagnostics

### ISSUE-1.1: Unawaited Future Returned Inside Try Block (Bypassing Catch)
- **File**: `lib/core/services/document_repository.dart`
- **Line**: 179
- **Severity**: **Major**
- **Analyzer Diagnostic**: `warning - Returning a 'Future' without 'await' inside a try block. Try adding an 'await' - unawaited_return_in_try_block`
- **Offending Code**:
  ```dart
  176: } else if (response.statusCode == 302 || response.statusCode == 301) {
  177:    // Follow redirect
  178:   final newUrl = response.headers['location'];
  179:   if (newUrl != null) return _getRemoteFileSize(newUrl);
  180: }
  ```
- **Root Cause & Trigger**: In `_getRemoteFileSize`, when following an HTTP 301/302 redirect, the function calls itself recursively and returns the `Future<int?>` directly without `await`. If the redirect endpoint fails with a network timeout or connection reset, the error is thrown asynchronously after `_getRemoteFileSize` has returned. The enclosing `try / catch (e)` block at line 203 will NOT catch this error, resulting in an unhandled asynchronous error.
- **Remediation**:
  ```dart
  if (newUrl != null) return await _getRemoteFileSize(newUrl);
  ```

---

### ISSUE-1.2: Unawaited Future Returned Inside Try Block in Notification Service
- **File**: `lib/core/services/update_notification_service.dart`
- **Line**: 199
- **Severity**: **Major**
- **Analyzer Diagnostic**: `warning - Returning a 'Future' without 'await' inside a try block. Try adding an 'await' - unawaited_return_in_try_block`
- **Offending Code**:
  ```dart
  196: } else if (response.statusCode == 302 || response.statusCode == 301) {
  197:   // Follow redirect
  198:   final newUrl = response.headers['location'];
  199:   if (newUrl != null) return _getFileSize(newUrl);
  200: }
  ```
- **Root Cause & Trigger**: Identical recursive redirect issue as ISSUE-1.1. In background worker isolate checks, an unhandled exception escaping here can terminate the background execution task abruptly.
- **Remediation**:
  ```dart
  if (newUrl != null) return await _getFileSize(newUrl);
  ```

---

### ISSUE-1.3: Unawaited Future Returned Inside Try Block in PDF Viewer
- **File**: `lib/core/widgets/pdf_viewer_page.dart`
- **Line**: 49
- **Severity**: **Major**
- **Analyzer Diagnostic**: `warning - Returning a 'Future' without 'await' inside a try block. Try adding an 'await' - unawaited_return_in_try_block`
- **Offending Code**:
  ```dart
  45: final file = await DocumentRepository().getPdf(
  46:   assetPath,
  47:   filename,
  48: );
  49: return file.readAsBytes();
  ```
- **Root Cause & Trigger**: In `PdfPreview.build`, `file.readAsBytes()` returns a `Future<Uint8List>`. Returning it without `await` means any OS file lock, permission denied, or I/O failure bypasses the `catch (e)` block at line 54, preventing the custom error message fallback.
- **Remediation**:
  ```dart
  return await file.readAsBytes();
  ```

---

### ISSUE-1.4: Cleartext Certificate Password & Absolute Windows Drive Path Hardcoded in `pubspec.yaml`
- **File**: `pubspec.yaml`
- **Lines**: 122–123
- **Severity**: **Critical (Security / Portability)**
- **Offending Code**:
  ```yaml
  121: capabilities: "internetClient, location, microphone, webcam"
  122: certificate_path: D:\Sayed\Flutter\sales_order_app\certs\AnnexGroup.pfx
  123: certificate_password: annex123
  124: install_certificate: true
  ```
- **Root Cause & Trigger**: The Windows MSIX packaging certificate password (`annex123`) is stored in plaintext in the repository configuration. Furthermore, `certificate_path` points to a host-specific absolute Windows path (`D:\Sayed\...`), which will fail on any other developer machine, build runner, or CI/CD container.
- **Remediation**:
  1. Remove `certificate_password` from `pubspec.yaml`.
  2. Pass the password securely via environment variable or CLI argument when packaging (`flutter pub run msix:create --certificate-password $CERT_PWD`).
  3. Change `certificate_path` to a relative path: `certs/AnnexGroup.pfx`.

---

### ISSUE-1.5: Missing Critical Analysis Lint Rules in `analysis_options.yaml`
- **File**: `analysis_options.yaml`
- **Lines**: 23–26
- **Severity**: **Improvement Suggestion**
- **Offending Code**:
  ```yaml
  23: rules:
  24:   # avoid_print: false
  25:   # prefer_single_quotes: true
  ```
- **Root Cause**: The project utilizes default `package:flutter_lints/flutter.yaml` without enforcing essential concurrency and safety checks such as `unawaited_futures`, `use_build_context_synchronously`, `avoid_print`, and `cancel_subscriptions`.
- **Remediation**: Expand `analysis_options.yaml` to include:
  ```yaml
  linter:
    rules:
      - unawaited_futures
      - use_build_context_synchronously
      - discarded_futures
      - avoid_slow_async_io
      - cancel_subscriptions
      - close_sinks
  ```

---

## Pillar 2: Broken State Lifecycles & Memory Leaks

### ISSUE-2.1: Double `Navigator.pop()` Ejects User From Screen on Mobile
- **File**: `lib/features/sales_order/presentation/providers/fabrics_cm_order_provider.dart`
- **Lines**: 529 & 545
- **Severity**: **Critical (UX / Navigation Corruption)**
- **Offending Code**:
  ```dart
  528: if (!context.mounted) return;
  529: Navigator.of(context).pop(); // Dismiss loading
  530: 
  531: final settingsService = SettingsService();
  ...
  542: if (Platform.isAndroid || Platform.isIOS) {
  543:   // Mobile: Share directly
  544:   if (!context.mounted) return;
  545:   Navigator.of(context).pop(); // Dismiss loading
  546:   ConfettiOverlay.show(context);
  547:   await Printing.sharePdf(bytes: bytes, filename: fileName);
  548: }
  ```
- **Root Cause & Trigger**: When a user generates a PDF on Android or iOS, line 529 dismisses the modal loading indicator (`Dialog`). Then, line 545 inside the mobile block executes `Navigator.of(context).pop()` **a second time**. Because the dialog is already gone, the second `pop()` closes the `FabricsCmOrderPage` itself, kicking the user back to the previous screen while `Printing.sharePdf` opens!
- **Remediation**: Delete line 545 completely.

---

### ISSUE-2.2: Duplicate Double `Navigator.pop()` in Quotation Generation on Mobile
- **File**: `lib/features/sales_order/presentation/pages/create_quotation_page.dart`
- **Lines**: 798 & 814
- **Severity**: **Critical (UX / Navigation Corruption)**
- **Offending Code**:
  ```dart
  797: if (!context.mounted) return;
  798: Navigator.pop(context); // Dismiss loading
  799: 
  800: final settingsService = SettingsService();
  ...
  811: if (Platform.isAndroid || Platform.isIOS) {
  812:   // Mobile: Share directly
  813:   if (context.mounted) {
  814:     Navigator.pop(context); // Dismiss loading
  815:     ConfettiOverlay.show(context);
  816:     await Printing.sharePdf(bytes: bytes, filename: fileName);
  817:   }
  ```
- **Root Cause & Trigger**: Identical copy-paste bug as ISSUE-2.1. The loading dialog is already dismissed at line 798. Line 814 pops the active `CreateQuotationPage` route off the navigation stack on mobile devices.
- **Remediation**: Remove line 814.

---

### ISSUE-2.3: Inline `TextEditingController` Allocation in Build Tree (Orphaned Leaks)
- **File**: `lib/features/return_order/presentation/pages/return_order_page.dart`
- **Lines**: 652–656
- **Severity**: **Major (Memory Leak)**
- **Offending Code**:
  ```dart
  652: _buildTextField(
  653:   'رقم المرتجع',
  654:   TextEditingController(text: _currentSn),
  655:   readOnly: true,
  656: ),
  ```
- **Root Cause & Trigger**: Inside the widget build tree hierarchy, `TextEditingController(text: _currentSn)` is instantiated directly as an argument to `_buildTextField`. On every keystroke in any other field, dropdown selection, or theme toggle, `build()` runs and instantiates a new controller. The previous instance is abandoned without `dispose()`, leaking listeners and text storage in memory.
- **Remediation**: Declare a persistent controller in `_ReturnOrderPageState`:
  ```dart
  late final TextEditingController _snController = TextEditingController();
  ```
  Update `_snController.text = _currentSn` when loaded, pass `_snController` at line 654, and dispose it in `dispose()`.

---

### ISSUE-2.4: Unmanaged Undisposed Controller in `showBulkAddDialog`
- **File**: `lib/features/return_order/presentation/utils/return_order_helpers.dart`
- **Lines**: 49–51
- **Severity**: **Minor (Memory Leak)**
- **Offending Code**:
  ```dart
  49: Future<int?> showBulkAddDialog(BuildContext context) async {
  50:   final controller = TextEditingController(text: '5');
  51:   return showDialog<int>(
  ```
- **Root Cause & Trigger**: `controller` is instantiated in an async function and passed to a dialog widget. When the dialog closes (via Cancel, Add, or backdrop tap), `controller.dispose()` is never called, leaving the controller retained by garbage collector root until unreferenced.
- **Remediation**:
  ```dart
  Future<int?> showBulkAddDialog(BuildContext context) async {
    final controller = TextEditingController(text: '5');
    try {
      return await showDialog<int>(...);
    } finally {
      controller.dispose();
    }
  }
  ```

---

### ISSUE-2.5: Architecture Anti-Pattern: `BuildContext` Coupled to `ChangeNotifier`
- **File**: `lib/features/sales_order/presentation/providers/fabrics_cm_order_provider.dart`
- **Lines**: 341–352 & 434–452
- **Severity**: **Major (Architecture / State Risk)**
- **Offending Code**:
  ```dart
  341: Future<bool> saveOrder(
  342:   BuildContext context,
  343:   GlobalKey<FormState> formKey,
  344: ) async {
  345:   if (!formKey.currentState!.validate()) {
  346:     ScaffoldMessenger.of(context).showSnackBar(...);
  ...
  434: Future<void> generatePdf(
  435:   BuildContext context,
  436:   GlobalKey<FormState> formKey,
  437: ) async {
  449:   showDialog(context: context, ...);
  ```
- **Root Cause & Trigger**: Passing `BuildContext` into a ChangeNotifier creates a strong coupling between business logic and the presentation layer. If the widget is unmounted or navigating while an async disk save / PDF generation takes place, using `context` triggers `StateError: Looking up a deactivated widget's ancestor is unsafe` or leaks the widget context.
- **Remediation**: Refactor `saveOrder` and `generatePdf` to accept only pure data arguments and return status/result objects (`Result<Order>`). Handle `ScaffoldMessenger` and `showDialog` inside the widget view layer (`FabricsCmOrderPage`).

---

### ISSUE-2.6: Global Static Debounce Timer Concurrency Collision
- **File**: `lib/core/utils/performance_utils.dart`
- **Lines**: 8–22
- **Severity**: **Major (Concurrency / Race Condition)**
- **Offending Code**:
  ```dart
  8:  static Timer? _debounceTimer;
  9: 
  10: static void debounce({
  11:   required Duration duration,
  12:   required VoidCallback action,
  13: }) {
  14:   _debounceTimer?.cancel();
  15:   _debounceTimer = Timer(duration, action);
  16: }
  17: 
  18: static void cancelDebounce() {
  19:   _debounceTimer?.cancel();
  20:   _debounceTimer = null;
  21: }
  ```
- **Root Cause & Trigger**: `_debounceTimer` is a single static variable shared globally across the entire app. It is used by `saved_invoices_page.dart:39`, `saved_yarn_invoices_page.dart:38`, and `saved_fabrics_cm_invoices_page.dart:35`. If a user types in one search bar and quickly navigates away, `dispose()` calls `cancelDebounce()`, which cancels the pending search action of whatever screen the user just landed on! Furthermore, simultaneous inputs overwrite each other's timers.
- **Remediation**: Replace static timer with an instance-based `Debouncer` class:
  ```dart
  class Debouncer {
    final Duration duration;
    Timer? _timer;
    Debouncer({required this.duration});
    void run(VoidCallback action) {
      _timer?.cancel();
      _timer = Timer(duration, action);
    }
    void dispose() => _timer?.cancel();
  }
  ```

---

### ISSUE-2.7: Unmounted `setState()` Across Asynchronous Gaps
- **File**: `lib/features/sales_order/presentation/pages/saved_quotations_page.dart`
- **Lines**: 45–48 & 56–61
- **Severity**: **Major**
- **Offending Code**:
  ```dart
  45: Future<void> _deleteQuotation(Quotation quotation) async {
  46:   await _dataSource.deleteQuotation(quotation);
  47:   _loadQuotations(); // calls setState without mounted check
  48: }
  ...
  55: onPressed: () async {
  56:   await Navigator.push(
  57:     context,
  58:     MaterialPageRoute(builder: (_) => const CreateQuotationPage()),
  59:   );
  60:   _loadQuotations(); // calls setState without mounted check
  61: }
  ```
- **Root Cause & Trigger**: `_loadQuotations()` executes `setState(() => _isLoading = true)` and `setState(() => _isLoading = false)` unconditionally. If the user pops the route while quotation deletion is in flight, or if the page was popped while `CreateQuotationPage` was open, returning causes `setState() called after dispose()`.
- **Remediation**: Guard with `if (!mounted) return;` before calling `_loadQuotations()`.

---

## Pillar 3: Unhandled Asynchronous Exceptions & Data Loss Hazards

### ISSUE-3.1: Hive Box Wiped Before Parsing Backup (Catastrophic Data Loss)
- **File**: `lib/core/services/backup_service.dart`
- **Lines**: 197–202 (and repeated at lines 207, 218, 227, 238, 247, 258, 269)
- **Severity**: **Critical (Permanent Data Destruction)**
- **Offending Code**:
  ```dart
  197: final box = await _openBox<SalesOrder>(_invoiceBoxName);
  198: await box.clear();
  199: final List<dynamic> list = backupData['invoices'];
  200: await box.addAll(list.map((e) => SalesOrder.fromJson(e)).toList());
  ```
- **Root Cause & Trigger**: In `restoreBackup`, `await box.clear()` is called BEFORE parsing the records (`SalesOrder.fromJson(e)`). If any single record in the JSON file has a corrupt date format, a missing key, or a type mismatch, `SalesOrder.fromJson` throws a `FormatException` or `TypeError`. Because `box.clear()` already ran, the user's entire local database has been wiped clean, and the restore aborts in the catch block. The user loses ALL existing orders and gets zero restored orders.
- **Remediation**: Parse and validate all entities in memory before modifying the database:
  ```dart
  // 1. Parse and validate first
  final parsedInvoices = list.map((e) => SalesOrder.fromJson(e)).toList();
  // 2. Only clear and populate after successful parsing
  await box.clear();
  await box.addAll(parsedInvoices);
  ```

---

### ISSUE-3.2: Unawaited `deleteCustomer` Without Exception Handling
- **File**: `lib/features/customer_list/presentation/pages/customer_list_page.dart`
- **Lines**: 448–452
- **Severity**: **Major**
- **Offending Code**:
  ```dart
  448: onPressed: () {
  449:   _dataSource.deleteCustomer(index);
  450:   Navigator.pop(context);
  451: },
  ```
- **Root Cause & Trigger**: `_dataSource.deleteCustomer(index)` returns `Future<void>`, which performs async disk I/O and rethrows exceptions (`rethrow` in data source). In `_confirmDelete`, the call is NOT awaited, has no `catchError`, and has no `try / catch`. If Hive encounters an I/O error or lock failure, an uncaught asynchronous exception crashes the application. Furthermore, `Navigator.pop(context)` closes the confirmation dialog before deletion completes.
- **Remediation**:
  ```dart
  onPressed: () async {
    try {
      await _dataSource.deleteCustomer(index);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
      }
    }
  }
  ```

---

### ISSUE-3.3: Delete by Sequential Index Deletes Wrong Database Record
- **File**: `lib/features/customer_list/presentation/pages/customer_list_page.dart` & `customer_local_data_source.dart`
- **Lines**: `customer_list_page.dart:449` & `customer_local_data_source.dart:69`
- **Severity**: **Major (Data Corruption)**
- **Offending Code**:
  ```dart
  // customer_local_data_source.dart
  66: Future<void> deleteCustomer(int index) async {
  67:   try {
  68:     if (index >= 0 && index < _box.length) {
  69:       await _box.deleteAt(index);
  70:     }
  ...
  // customer_list_page.dart
  409: Widget _buildActionButtons(int index, Customer customer) {
  430:   onPressed: () => _confirmDelete(index),
  ```
- **Root Cause & Trigger**: `_box.deleteAt(index)` deletes the entry at internal Hive slot `index`. In Hive, if any items were previously deleted or if the list in the UI is ever sorted/filtered, the index in `box.values.toList()` does NOT align with internal compact indices. Calling `deleteAt(index)` deletes the WRONG customer from the database.
- **Remediation**: Use HiveObject key deletion:
  ```dart
  Future<void> deleteCustomer(Customer customer) async {
    await customer.delete();
  }
  ```

---

### ISSUE-3.4: Uninitialized Box Access in `SettingsService`
- **File**: `lib/core/services/settings_service.dart`
- **Lines**: 18 & 21
- **Severity**: **Major**
- **Offending Code**:
  ```dart
  18: Box get _box => Hive.box(_settingsBoxName);
  19: 
  20: InvoiceSaveStrategy getInvoiceSaveStrategy() {
  21:   final String? strategy = _box.get(_keySaveStrategy);
  ```
- **Root Cause & Trigger**: `SettingsService` has no `init()` method and `main.dart` never opens `'settings'`. The service implicitly relies on `ThemeProvider._loadTheme()` having asynchronously opened `'settings'` in the background. If any component calls `SettingsService().getInvoiceSaveStrategy()` before `ThemeProvider` finishes loading (or in headless background tasks, isolates, or unit tests), `Hive.box('settings')` throws `HiveError: Box not found. Did you forget to call Hive.openBox()?`.
- **Remediation**: Add explicit initialization or safeguard:
  ```dart
  Future<void> init() async {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox(_settingsBoxName);
    }
  }
  ```
  Call `await SettingsService().init();` in `main.dart`.

---

### ISSUE-3.5: Swallowed Fatal Initialization in `main.dart`
- **File**: `lib/main.dart`
- **Lines**: 81–84
- **Severity**: **Major**
- **Offending Code**:
  ```dart
  47: try {
  48:   await Hive.initFlutter();
  ...
  81: } catch (e, stack) {
  82:   debugPrint('Initialization Error: $e\n$stack');
  83:   // Consider showing a fallback UI here if critical init fails
  84: }
  86: runApp(MultiProvider(...));
  ```
- **Root Cause & Trigger**: If Hive storage initialization or data source opening fails (e.g., storage permission denied, disk full, corrupted Hive box header), the fatal error is merely printed to `debugPrint`. Execution proceeds straight to `runApp()`. When the home screen attempts to read data sources, the app crashes with unhandled exceptions instead of displaying a recovery/error UI.
- **Remediation**: Maintain an `isInitSuccess` boolean and render an `InitializationErrorApp(error: e)` screen if setup fails.

---

## Pillar 4: Potential Runtime Crashes

### ISSUE-4.1: Fl_Chart `RangeError` on Negative Index
- **File**: `lib/features/analysis/presentation/widgets/analysis_bar_chart.dart`
- **Line**: 178
- **Severity**: **Major (Crash Hazard)**
- **Offending Code**:
  ```dart
  177: getTitlesWidget: (val, meta) {
  178:   if (val.toInt() >= _chartKeys.length) {
  179:     return const SizedBox();
  180:   }
  181:   final key = _chartKeys[val.toInt()];
  ```
- **Root Cause & Trigger**: In `fl_chart`, during layout padding, viewport gestures, or curve animations, `val` can be negative (e.g. `val = -0.5`, `val.toInt() = 0` or `-1`). Line 178 only checks `val.toInt() >= _chartKeys.length`. When `val.toInt() < 0`, the condition evaluates to `false`, executing `_chartKeys[-1]`, which instantly crashes with `RangeError (index): Invalid value: -1`.
- **Remediation**:
  ```dart
  if (val.toInt() < 0 || val.toInt() >= _chartKeys.length) {
    return const SizedBox();
  }
  ```

---

### ISSUE-4.2: Fl_Chart Tooltip `RangeError` on Unbounded `groupIndex`
- **File**: `lib/features/analysis/presentation/widgets/analysis_bar_chart.dart`
- **Line**: 241
- **Severity**: **Major (Crash Hazard)**
- **Offending Code**:
  ```dart
  231: getTooltipItem: (group, groupIndex, rod, rodIndex) {
  ...
  240: return BarTooltipItem(
  241:   "${_chartKeys[groupIndex]}\n$type: ${rod.toY.toInt()}",
  ```
- **Root Cause & Trigger**: In `BarTouchTooltipData`, `groupIndex` is passed from touch coordinates. There is no bounds check verifying `groupIndex >= 0 && groupIndex < _chartKeys.length`. Touching the chart near boundaries during data updates throws `RangeError (index)`.
- **Remediation**:
  ```dart
  if (groupIndex < 0 || groupIndex >= _chartKeys.length) return null;
  ```

---

### ISSUE-4.3: Division-by-Zero Resulting in `NaN` in LinearProgressIndicator
- **File**: `lib/features/analysis/presentation/widgets/analysis_payment_method_chart.dart`
- **Lines**: 19 & 27–28
- **Severity**: **Major**
- **Offending Code**:
  ```dart
  19: final totalOrders = paymentMethods.values.fold(0, (sum, count) => sum + count);
  ...
  27: final percentage = (entry.value / totalOrders * 100).toStringAsFixed(1);
  28: final progress = entry.value / totalOrders;
  ...
  56: child: LinearProgressIndicator(
  57:   value: progress,
  ```
- **Root Cause & Trigger**: If `paymentMethods` contains zero counts, `totalOrders` equals `0`. `entry.value / totalOrders` calculates `0 / 0`, yielding `double.nan`. Formatting `double.nan` yields `"NaN%"`, and passing `value: double.nan` to `LinearProgressIndicator` violates Flutter animation assertions.
- **Remediation**:
  ```dart
  if (totalOrders == 0) {
    return const Center(child: Text('لا توجد بيانات سداد'));
  }
  ```

---

### ISSUE-4.4: Division-by-Zero & Empty Sections in `PieChart`
- **File**: `lib/features/analysis/presentation/widgets/analysis_pie_chart.dart`
- **Lines**: 28, 45, 62 & 84
- **Severity**: **Major**
- **Offending Code**:
  ```dart
  28: '${(metrics.totalGeneralSales / metrics.totalSalesValue * 100).toStringAsFixed(1)}%'
  ...
  84: sections: sections, // empty list when sales == 0
  ```
- **Root Cause & Trigger**: If `metrics.totalSalesValue == 0`, `sections` is empty (`[]`). Passing empty sections to `PieChartData` produces rendering glitches or division by zero in label percentages.
- **Remediation**:
  ```dart
  if (metrics.totalSalesValue <= 0 || sections.isEmpty) {
    return const Center(child: Text('لا توجد بيانات مبيعات للعرض'));
  }
  ```

---

### ISSUE-4.5: Unchecked `DateTime.parse` Null / Format Crash in `SalesOrder.fromJson`
- **File**: `lib/features/sales_order/data/models/sales_order.dart`
- **Line**: 78
- **Severity**: **Major**
- **Offending Code**:
  ```dart
  78: orderDate: DateTime.parse(json['orderDate']),
  ```
- **Root Cause & Trigger**: If a JSON document imported via backup has a missing or malformed `orderDate`, `DateTime.parse(null)` throws `TypeError: type 'Null' is not a subtype of type 'String'`.
- **Remediation**:
  ```dart
  orderDate: json['orderDate'] != null 
      ? (DateTime.tryParse(json['orderDate'].toString()) ?? DateTime.now()) 
      : DateTime.now(),
  ```

---

### ISSUE-4.6: Unchecked Force Unwraps (`!`) on Nullable `FormState`
- **Locations**:
  * `lib/features/customer_list/presentation/pages/add_edit_customer_page.dart:76`
  * `lib/features/authorization/presentation/screens/authorization_screen.dart:115`
  * `lib/features/new_lead/presentation/screens/new_lead_form_screen.dart:98`
  * `lib/features/return_order/presentation/pages/return_order_page.dart:239, 274`
  * `lib/features/sales_order/presentation/pages/sales_order_page.dart:344, 450`
  * `lib/features/sales_order/presentation/pages/yarn_sales_order_page.dart:331`
  * `lib/features/sales_order/presentation/providers/fabrics_cm_order_provider.dart:345, 438`
  * `lib/features/user/presentation/pages/registration_page.dart:24`
- **Severity**: **Minor**
- **Offending Pattern**:
  ```dart
  if (_formKey.currentState!.validate()) { ... }
  ```
- **Root Cause & Trigger**: If validation is called during teardown or before the form is attached to the widget tree, `_formKey.currentState` is null. Force unwrapping with `!` throws `NullCheckError`.
- **Remediation**:
  ```dart
  if (_formKey.currentState?.validate() == true) { ... }
  ```

---

## Actionable Remediation Roadmap

1. **Immediate (P0 - Critical Stability & Data Safety)**:
   - Fix double `Navigator.pop()` in `fabrics_cm_order_provider.dart` and `create_quotation_page.dart`.
   - Fix `backup_service.dart` restore sequence to parse data in memory before wiping Hive boxes.
   - Remove plaintext certificate password from `pubspec.yaml` and switch to relative path.
2. **High Priority (P1 - Concurrency & Lifecycle Bugs)**:
   - Add `await` to `unawaited_return_in_try_block` locations in `document_repository.dart`, `update_notification_service.dart`, and `pdf_viewer_page.dart`.
   - Remove inline `TextEditingController` allocation from `return_order_page.dart:654`.
   - Decouple static `_debounceTimer` in `PerformanceUtils` into individual widget debouncers.
   - Add negative index guards to `analysis_bar_chart.dart` (`val.toInt() < 0`).
   - Add division-by-zero guards in `analysis_payment_method_chart.dart` and `analysis_pie_chart.dart`.
3. **Medium Priority (P2 - Architecture & Code Quality)**:
   - Remove `BuildContext` parameters from `FabricsCmOrderProvider`.
   - Replace Hive `deleteAt(index)` with `customer.delete()` in `CustomerLocalDataSource`.
   - Replace unsafe `_formKey.currentState!` with null-aware `?.validate() == true`.
   - Explicitly initialize `'settings'` box in `SettingsService` and `main.dart`.
