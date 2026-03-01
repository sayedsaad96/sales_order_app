import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:annex_sales_order/features/sales_order/data/models/sales_order.dart';
import 'package:annex_sales_order/features/sales_order/pdf/pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:annex_sales_order/features/sales_order/data/datasources/invoice_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/saved_invoices_page.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import 'package:annex_sales_order/core/utils/responsive_constants.dart';
import 'package:annex_sales_order/features/sales_order/presentation/widgets/customer_info_section.dart';
import 'package:annex_sales_order/features/sales_order/presentation/widgets/sales_order_item_row.dart';
import 'package:annex_sales_order/features/sales_order/presentation/utils/sales_order_helpers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:annex_sales_order/core/services/settings_service.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';

class SalesOrderPage extends StatefulWidget {
  final SalesOrder? existingOrder;
  final VoidCallback? onMenuPressed;
  const SalesOrderPage({super.key, this.existingOrder, this.onMenuPressed});

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _snController = TextEditingController();

  String _generateUniqueSn() {
    final box = InvoiceLocalDataSource().getAllInvoices();
    final existingSns = box.map((e) => e.sn ?? '').toSet();

    final List<int> available = [];
    for (int i = 1; i <= 999; i++) {
      final sn = 'SO-${i.toString().padLeft(3, '0')}';
      if (!existingSns.contains(sn)) {
        available.add(i);
      }
    }

    if (available.isNotEmpty) {
      final randomIndex =
          (DateTime.now().microsecondsSinceEpoch % available.length);
      final chosen = available[randomIndex.toInt()];
      return 'SO-${chosen.toString().padLeft(3, '0')}';
    }

    return 'SO-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';
  }

  final _customerNameController = TextEditingController();
  final _regionController = TextEditingController();
  final _salesResponsibleController = TextEditingController();
  final _deliveryPlaceController = TextEditingController();
  final _notesController = TextEditingController();
  final List<OrderSection> _sections = [];
  final ValueNotifier<double> _totalValueNotifier = ValueNotifier(0.0);
  final ValueNotifier<int> _totalQuantityNotifier = ValueNotifier(0);

  String? _selectedBranch = "القاهرة";
  final Map<String, bool> _orderTypes = {'مستلزمات': true, 'جوما': false};
  bool _deliveryIncluded = true;
  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;

  String? _paymentMethod;
  bool _isEditing = false;
  bool _saveAsNew = false;

  @override
  void dispose() {
    _snController.dispose();
    _customerNameController.dispose();
    _regionController.dispose();
    _salesResponsibleController.dispose();
    _deliveryPlaceController.dispose();
    _notesController.dispose();
    _totalValueNotifier.dispose();
    _totalQuantityNotifier.dispose();
    for (var section in _sections) {
      section.categoryController.dispose();
      section.defaultUnitController.dispose();
    }
    // Clear SnackBars when leaving the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingOrder != null) {
      final order = widget.existingOrder!;
      _snController.text =
          order.sn ?? _generateUniqueSn(); // Preserve SN during edit

      _selectedBranch = order.branch;
      _customerNameController.text = order.customerName ?? '';
      _regionController.text = order.region ?? '';
      _salesResponsibleController.text = order.salesResponsible ?? '';
      _deliveryPlaceController.text = order.deliveryPlace ?? '';
      _notesController.text = order.notes ?? '';
      _paymentMethod = _mapPaymentMethod(order.paymentMethod);
      _deliveryIncluded = order.deliveryIncluded;
      _orderDate = order.orderDate;

      _deliveryDate = order.deliveryDate;
      _isEditing = true;

      // Reset order types
      _orderTypes.updateAll((key, value) => false);
      for (var type in order.orderTypes) {
        if (_orderTypes.containsKey(type)) {
          _orderTypes[type] = true;
        }
      }

      // Group items by category
      final groupedItems = <String, List<SalesOrderItem>>{};
      if (order.items.isNotEmpty) {
        for (var item in order.items) {
          final cat = item.category ?? order.category ?? '';
          groupedItems.putIfAbsent(cat, () => []).add(item);
        }
      }

      if (groupedItems.isEmpty) {
        _addSection();
      } else {
        groupedItems.forEach((cat, items) {
          final controllers = items
              .map(
                (i) => ItemControllers(
                  name: i.itemName,
                  quantity: i.quantity == 0 ? '' : i.quantity.toString(),
                  unit: i.unit,
                  price: i.price == 0 ? '' : i.price.toString(),
                ),
              )
              .toList();

          final defaultUnit = items.isNotEmpty ? items.first.unit : '';

          _sections.add(
            OrderSection(
              category: cat,
              defaultUnit: defaultUnit,
              items: items,
              itemControllers: controllers,
            ),
          );
        });
      }
    } else {
      _snController.text = _generateUniqueSn();
      _addSection();
    }
    _calculateTotal();
    _loadCurrentUser();
  }

  String? _mapPaymentMethod(String? method) {
    if (method == null) return null;
    final mapping = {
      'Cash': 'كاش مع المبيعات',
      'Bank transfer': 'تحويل بنكي',
      'Credit': 'اجل شهر',
      'Cheque': 'تحويل بنكي',
      'Other': 'كاش مع المبيعات',
    };
    return mapping[method] ?? method;
  }

  Future<void> _loadCurrentUser() async {
    if (widget.existingOrder == null) {
      try {
        final user = UserLocalDataSource().getUser();
        if (user != null && mounted) {
          setState(() {
            _salesResponsibleController.text = user.fullName;
          });
        }
      } catch (e) {
        // Silently fail - not critical for app functionality
        debugPrint('Failed to load user: $e');
      }
    }
  }

  void _resetForm() {
    setState(() {
      _snController.text = _generateUniqueSn();
      _customerNameController.clear();
      _regionController.clear();
      _deliveryPlaceController.clear();
      _notesController.clear();
      _selectedBranch = null;
      _paymentMethod = null;
      _deliveryIncluded = true;
      _orderDate = DateTime.now();
      _deliveryDate = null;

      // Reset order types
      _orderTypes.updateAll((key, value) => false);
      _orderTypes['مستلزمات'] = true;

      for (var section in _sections) {
        section.dispose();
      }
      _sections.clear();
      _addSection();

      // Re-populate sales responsible
      _loadCurrentUser();
      _calculateTotal();

      _isEditing = false;
      _saveAsNew = false;
    });
  }

  void _addSection() {
    _sections.add(
      OrderSection(
        items: [SalesOrderItem()],
        itemControllers: [ItemControllers()],
      ),
    );
  }

  void _removeSection(int index) {
    if (_sections.length > 1) {
      _sections[index].dispose();
      _sections.removeAt(index);
      if (mounted) {
        setState(() {});
        _calculateTotal();
      }
    }
  }

  void _addItem(int sectionIndex, {int count = 1}) {
    final section = _sections[sectionIndex];
    for (int i = 0; i < count; i++) {
      double? defaultPrice;
      if (section.items.isNotEmpty && section.items.first.price > 0) {
        defaultPrice = section.items.first.price;
      }
      section.items.add(
        SalesOrderItem(
          price: defaultPrice ?? 0,
          unit: section.defaultUnitController.text,
        ),
      );
      section.itemControllers.add(
        ItemControllers(
          price: (defaultPrice != null && defaultPrice > 0)
              ? defaultPrice.toString()
              : '',
          unit: section.defaultUnitController.text,
        ),
      );
    }
    // Trigger rebuild only after adding item
    if (mounted) {
      setState(() {});
    }
    // No need to calculate total here as new item has 0 quantity
  }

  void _removeItem(int sectionIndex, int itemIndex) {
    final section = _sections[sectionIndex];
    if (section.items.length > 1) {
      section.items.removeAt(itemIndex);
      section.itemControllers[itemIndex].dispose();
      section.itemControllers.removeAt(itemIndex);
      if (mounted) {
        setState(() {});
        _calculateTotal();
      }
    }
  }

  List<SalesOrderItem> get _allValidItems {
    final allItems = <SalesOrderItem>[];
    for (var section in _sections) {
      for (var item in section.items) {
        if (item.itemName.isNotEmpty || item.quantity > 0) {
          item.category = section.categoryController.text;
          item.unit = section.defaultUnitController.text;
          allItems.add(item);
        }
      }
    }
    return allItems;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      final sn = _snController.text;
      final isDuplicate = InvoiceLocalDataSource().isSnExists(
        sn,
        excludeKey: (_isEditing && !_saveAsNew)
            ? widget.existingOrder?.key
            : null,
      );

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رقم الفاتورة (S/N) موجود بالفعل، يرجى تغييره'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final validItems = _allValidItems;

      if (validItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل')),
        );
        return;
      }

      // Update existing order if editing and NOT saving as new
      SalesOrder order;
      if (_isEditing && !_saveAsNew && widget.existingOrder != null) {
        order = widget.existingOrder!;
        // Update fields
        order.sn = _snController.text;
        order.branch = _selectedBranch;
        order.orderTypes = _orderTypes.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
        order.customerName = _customerNameController.text;
        order.region = _regionController.text;
        order.deliveryIncluded = _deliveryIncluded;
        order.deliveryDate = _deliveryDate;
        order.orderDate = _orderDate;
        order.salesResponsible = _salesResponsibleController.text;
        order.paymentMethod = _paymentMethod;
        order.deliveryPlace = _deliveryPlaceController.text;
        order.notes = _notesController.text;
        order.items = validItems;
      } else {
        // Create NEW if not editing OR if "Save as New" is checked
        order = SalesOrder(orderDate: _orderDate);
        order.sn = _snController.text;
        order.branch = _selectedBranch;
        order.orderTypes = _orderTypes.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
        order.customerName = _customerNameController.text;
        order.region = _regionController.text;
        order.deliveryIncluded = _deliveryIncluded;
        order.deliveryDate = _deliveryDate;
        order.orderDate = _orderDate;
        order.salesResponsible = _salesResponsibleController.text;
        order.paymentMethod = _paymentMethod;
        order.deliveryPlace = _deliveryPlaceController.text;
        order.notes = _notesController.text;
        order.items = validItems;
      }

      await InvoiceLocalDataSource().saveInvoice(order);

      if (mounted) {
        AnalysisService.clearCache();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing && !_saveAsNew
                  ? 'تم تحديث الفاتورة بنجاح'
                  : 'تم حفظ الفاتورة بنجاح',
            ),
          ),
        );
      }
    }
  }

  void _calculateTotal() {
    double total = 0;
    int totalQty = 0;
    for (var section in _sections) {
      for (var item in section.items) {
        total += item.value;
        totalQty += item.quantity;
      }
    }
    _totalValueNotifier.value = total;
    _totalQuantityNotifier.value = totalQty;
  }

  // double get _totalValue => _sections.fold(
  //   0,
  //   (sum, section) => sum + section.items.fold(0, (s, item) => s + item.value),
  // );

  Future<void> _generatePdf() async {
    if (_formKey.currentState!.validate()) {
      final validItems = _allValidItems;

      if (validItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'جارٍ إعداد ملف PDF...',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 15),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      try {
        final sn = _snController.text;
        final isDuplicate = InvoiceLocalDataSource().isSnExists(
          sn,
          excludeKey: (_isEditing && !_saveAsNew)
              ? widget.existingOrder?.key
              : null,
        );

        if (isDuplicate) {
          if (mounted) Navigator.of(context).pop(); // Dismiss loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الفاتورة (S/N) موجود بالفعل، يرجى تغييره'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        SalesOrder order;

        // Auto-save logic
        if (_isEditing && !_saveAsNew && widget.existingOrder != null) {
          order = widget.existingOrder!;
          // Update fields
          order.sn = _snController.text;
          order.branch = _selectedBranch;
          order.orderTypes = _orderTypes.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();
          order.customerName = _customerNameController.text;
          order.region = _regionController.text;
          order.deliveryIncluded = _deliveryIncluded;
          order.deliveryDate = _deliveryDate;
          order.orderDate = _orderDate;
          order.salesResponsible = _salesResponsibleController.text;
          order.paymentMethod = _paymentMethod;
          order.deliveryPlace = _deliveryPlaceController.text;
          order.notes = _notesController.text;
          order.items = validItems;

          await InvoiceLocalDataSource().saveInvoice(order);
        } else {
          // Create NEW if not editing OR if "Save as New" is checked
          order = SalesOrder(
            sn: _snController.text,
            branch: _selectedBranch,
            orderTypes: _orderTypes.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList(),
            customerName: _customerNameController.text,
            region: _regionController.text,
            deliveryIncluded: _deliveryIncluded,
            deliveryDate: _deliveryDate,
            orderDate: _orderDate,
            salesResponsible: _salesResponsibleController.text,
            paymentMethod: _paymentMethod,
            deliveryPlace: _deliveryPlaceController.text,
            notes: _notesController.text,
            items: validItems,
            // Assuming the constructor handles date initialization if not provided,
            // but we pass all fields here.
          );

          await InvoiceLocalDataSource().saveInvoice(order);
        }

        final pdf = await PdfSalesOrderGenerator.generate(order);
        final bytes = await pdf.save();

        final settingsService = SettingsService();
        final strategy = settingsService.getInvoiceSaveStrategy();
        final defaultPath = settingsService.getDefaultSavePath();

        String? finalPath;
        final safeName = (order.customerName ?? 'Client').replaceAll(
          RegExp(r'[^\w\s\u0600-\u06FF]'),
          '',
        );
        final fileName = '${safeName}_${order.sn}.pdf';

        if (Platform.isAndroid || Platform.isIOS) {
          // Mobile: Share directly
          if (mounted) {
            Navigator.of(context).pop();
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          }
        } else {
          // Desktop: Follow settings strategy
          if (strategy == InvoiceSaveStrategy.auto && defaultPath != null) {
            // Auto-save logic
            final customerDir = Directory('$defaultPath/$safeName');
            if (!await customerDir.exists()) {
              await customerDir.create(recursive: true);
            }
            finalPath = '${customerDir.path}/$fileName';
            final file = File(finalPath);
            await file.writeAsBytes(bytes);
          } else {
            // "Always Ask" or fallback logic
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
              // On desktop, use save file picker if strategy is "ask"
              finalPath = await FilePicker.platform.saveFile(
                dialogTitle: 'حفظ الفاتورة',
                fileName: fileName,
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );

              if (finalPath != null) {
                final file = File(finalPath);
                await file.writeAsBytes(bytes);
              } else {
                // User cancelled
                if (mounted) Navigator.of(context).pop();
                return;
              }
            } else {
              // Fallback for other platforms
              Directory? directory = await getExternalStorageDirectory();
              directory ??= await getApplicationDocumentsDirectory();
              finalPath = '${directory.path}/$fileName';
              final file = File(finalPath);
              await file.writeAsBytes(bytes);
            }
          }

          // Dismiss loading indicator and show success (Desktop only path)
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                showCloseIcon: true,
                closeIconColor: Colors.yellowAccent,
                content: Text('تم حفظ الملف: $finalPath'),
                duration: (!Platform.isAndroid && !Platform.isIOS)
                    ? const Duration(seconds: 1)
                    : const Duration(days: 365),
                action: SnackBarAction(
                  label: 'مشاركة',
                  textColor: Colors.yellowAccent,
                  backgroundColor: Colors.black,
                  onPressed: () {
                    Printing.sharePdf(bytes: bytes, filename: fileName);
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        // Dismiss loading indicator if error occurs
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onMenuPressed != null
            ? IconButton(
                icon: Icon(CupertinoIcons.list_dash),
                onPressed: widget.onMenuPressed,
                tooltip: 'Menu',
              )
            : IconButton(
                icon: Icon(CupertinoIcons.back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'رجوع',
              ),
        title: const Text('Annex Group'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            tooltip: 'طلب جديد',
            onPressed: _resetForm,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.folder),
            tooltip: 'الفواتير المحفوظة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedInvoicesPage(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              constraints.maxWidth < ResponsiveConstants.kMobileBreakpoint;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Header Section
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: isMobile
                                  ? Column(
                                      children: [
                                        Center(
                                          child: Text(
                                            'Essential Sales Order ',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 22,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _snController,
                                          decoration: InputDecoration(
                                            labelText: 'S/N',
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                CupertinoIcons.refresh,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _snController.text =
                                                      _generateUniqueSn();
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) =>
                                              value?.isEmpty ?? true
                                              ? 'مطلوب'
                                              : null,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              'Essential Sales Order',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 150,
                                          child: TextFormField(
                                            controller: _snController,
                                            decoration: InputDecoration(
                                              labelText: 'S/N',
                                              suffixIcon: IconButton(
                                                icon: const Icon(
                                                  CupertinoIcons.refresh,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _snController.text =
                                                        _generateUniqueSn();
                                                  });
                                                },
                                              ),
                                            ),
                                            validator: (value) =>
                                                value?.isEmpty ?? true
                                                ? 'مطلوب'
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Branch and Store
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: isMobile
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DropdownButtonFormField<String>(
                                          initialValue: _selectedBranch,
                                          decoration: const InputDecoration(
                                            labelText: 'الفرع',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: ['القاهرة', 'المحلة']
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  value: e,
                                                  child: Text(e),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) => setState(
                                            () => _selectedBranch = v,
                                          ),
                                          validator: (v) =>
                                              v == null ? 'مطلوب' : null,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text('النوع: '),
                                        Wrap(
                                          spacing: 10,
                                          children: _orderTypes.keys.map((key) {
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Checkbox(
                                                  value: _orderTypes[key],
                                                  onChanged: (v) => setState(
                                                    () => _orderTypes[key] =
                                                        v ?? false,
                                                  ),
                                                ),
                                                Text(key),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            width: 150,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child:
                                                DropdownButtonFormField<String>(
                                                  initialValue: _selectedBranch,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'الفرع',
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                            ),
                                                        border:
                                                            InputBorder.none,
                                                      ),
                                                  items: ['القاهرة', 'المحلة']
                                                      .map(
                                                        (e) => DropdownMenuItem(
                                                          value: e,
                                                          child: Text(e),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (v) => setState(
                                                    () => _selectedBranch = v,
                                                  ),
                                                  validator: (v) => v == null
                                                      ? 'مطلوب'
                                                      : null,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const SizedBox(width: 20),
                                        const Text('النوع: '),
                                        ..._orderTypes.keys.map((key) {
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: _orderTypes[key],
                                                onChanged: (v) => setState(
                                                  () => _orderTypes[key] =
                                                      v ?? false,
                                                ),
                                              ),
                                              Text(key),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Info Grid
                          CustomerInfoSection(
                            isMobile: isMobile,
                            customerNameController: _customerNameController,
                            regionController: _regionController,
                            salesResponsibleController:
                                _salesResponsibleController,
                            deliveryPlaceController: _deliveryPlaceController,
                            deliveryIncluded: _deliveryIncluded,
                            orderDate: _orderDate,
                            deliveryDate: _deliveryDate,
                            paymentMethod: _paymentMethod,
                            onDeliveryIncludedChanged: (v) =>
                                setState(() => _deliveryIncluded = v),
                            onOrderDateChanged: (v) =>
                                setState(() => _orderDate = v),
                            onDeliveryDateChanged: (v) =>
                                setState(() => _deliveryDate = v),
                            onPaymentMethodChanged: (v) =>
                                setState(() => _paymentMethod = v),
                          ),
                          const SizedBox(height: 20),
                        ]),
                      ),
                    ),

                    // Items Sections (Slivers)
                    ..._sections.asMap().entries.expand((entry) {
                      return _buildSectionSlivers(
                        entry.key,
                        entry.value,
                        isMobile,
                      );
                    }),

                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _addSection()),
                              icon: const Icon(CupertinoIcons.add_circled),
                              label: const Text('إضافة تصنيف جديد'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[100],
                                foregroundColor: Colors.blue[900],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ValueListenableBuilder<int>(
                            valueListenable: _totalQuantityNotifier,
                            builder: (context, totalQty, child) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'إجمالي الكميات:',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      totalQty.toString(),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          ValueListenableBuilder<double>(
                            valueListenable: _totalValueNotifier,
                            builder: (context, total, child) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'الإجمالي الكلي:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      total.toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'ملاحظات',
                                  hintText: 'أضف ملاحظات أو تعليقات (اختياري)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                minLines: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (_isEditing)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: CheckboxListTile(
                                title: const Text('حفظ كفاتورة جديدة (نسخة)'),
                                value: _saveAsNew,
                                onChanged: (val) {
                                  setState(() {
                                    _saveAsNew = val ?? false;
                                    if (_saveAsNew) {
                                      _snController.text = _generateUniqueSn();
                                    } else if (widget.existingOrder != null) {
                                      _snController.text =
                                          widget.existingOrder!.sn ?? '';
                                    }
                                  });
                                },
                              ),
                            ),
                          Center(
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _saveInvoice,
                                  icon: const Icon(
                                    CupertinoIcons.floppy_disk,
                                    size: 24,
                                  ),
                                  label: Text(
                                    _isEditing && !_saveAsNew ? 'تحديث' : 'حفظ',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 15,
                                    ),
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(150, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _generatePdf,
                                  icon: const Icon(
                                    CupertinoIcons.doc_text_fill,
                                    size: 24,
                                  ),
                                  label: const Text(
                                    'PDF',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 15,
                                    ),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(150, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSectionSlivers(
    int sectionIndex,
    OrderSection section,
    bool isMobile,
  ) {
    return [
      // Section Header (Category)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: section.categoryController,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: section.defaultUnitController,
                      decoration: const InputDecoration(
                        labelText: 'الوحدة',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          for (var item in section.items) {
                            item.unit = value;
                          }
                          for (var controller in section.itemControllers) {
                            controller.unitController.text = value;
                          }
                        });
                      },
                    ),
                  ),
                  if (_sections.length > 1)
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeSection(sectionIndex),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Table Header
      if (!isMobile)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'الصنف',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'الكمية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'الوحدة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'السعر',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'القيمة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 40), // For delete button
                  ],
                ),
              ),
            ),
          ),
        ),

      // Items List
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = section.items[index];
            final controllers = section.itemControllers[index];
            return Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),

              child: Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: SalesOrderItemRow(
                  key: ObjectKey(item),
                  index: index,
                  item: item,
                  controllers: controllers,
                  isMobile: isMobile,
                  onDelete: () => _removeItem(sectionIndex, index),
                  onStateChanged: _calculateTotal,
                ),
              ),
            );
          }, childCount: section.items.length),
        ),
      ),

      // Add Item Button (Footer of section)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _addItem(sectionIndex),
                  icon: const Icon(CupertinoIcons.add),
                  label: const Text('إضافة صنف'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final count = await showBulkAddDialog(context);
                    if (count != null) {
                      _addItem(sectionIndex, count: count);
                    }
                  },
                  icon: const Icon(CupertinoIcons.plus_square_on_square),
                  label: const Text('إضافة جماعية'),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
