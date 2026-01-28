import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/return_order/data/models/return_order.dart';
import 'package:annex_sales_order/features/return_order/data/datasources/return_order_local_data_source.dart';
import 'package:annex_sales_order/features/return_order/pdf/return_order_pdf_generator.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import 'package:annex_sales_order/features/return_order/presentation/pages/saved_return_orders_page.dart';
import 'package:annex_sales_order/core/utils/responsive_constants.dart';
import 'package:annex_sales_order/features/return_order/presentation/widgets/return_order_item_row.dart';
import 'package:annex_sales_order/core/services/settings_service.dart';
import 'package:annex_sales_order/features/return_order/presentation/utils/return_order_helpers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';

class ReturnOrderPage extends StatefulWidget {
  final ReturnOrder? existingOrder;
  const ReturnOrderPage({super.key, this.existingOrder});

  @override
  State<ReturnOrderPage> createState() => _ReturnOrderPageState();
}

class _ReturnOrderPageState extends State<ReturnOrderPage> {
  final _formKey = GlobalKey<FormState>();

  // Header
  String? _selectedCategory = 'مستلزمات';
  String? _selectedBranch =
      'القاهرة'; // Corrected spelling from 'المحله' to standard if needed, but keeping consistent with request might be better. Let's stick to user's 'المحلة' or 'المحله'. Usually 'المحلة'.

  // Client Info
  final _customerNameController = TextEditingController();
  DateTime _returnDate = DateTime.now();
  final _regionController = TextEditingController();
  final _returnResponsibleController = TextEditingController();

  // Delivery
  String _deliveryCostPayer = 'الشركة';
  final _routeFromController = TextEditingController();
  final _routeToController = TextEditingController();
  final _returnReasonController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _deliveryDate;

  // Sections
  final List<ReturnOrderSection> _sections = [];
  final ValueNotifier<double> _totalQuantityNotifier = ValueNotifier(0.0);
  String? _currentSn;

  // Data Source
  final _dataSource = ReturnOrderLocalDataSource();

  // Loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dataSource.init();

    if (widget.existingOrder != null) {
      _loadExistingOrder(widget.existingOrder!);
      _currentSn = widget.existingOrder!.sn;
    } else {
      _addSection();
      _loadCurrentUser();
      _currentSn = 'RET-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    _updateTotalQuantity();
  }

  void _loadExistingOrder(ReturnOrder order) {
    _selectedCategory = order.category;
    _selectedBranch = order.branch;
    _customerNameController.text = order.customerName ?? '';
    _returnDate = order.returnDate;
    _regionController.text = order.region ?? '';
    _returnResponsibleController.text = order.returnResponsible ?? '';
    _deliveryCostPayer = order.deliveryCostPayer;
    _routeFromController.text = order.routeFrom ?? '';
    _routeToController.text = order.routeTo ?? '';
    _returnReasonController.text = order.returnReason ?? '';
    _notesController.text = order.notes ?? '';
    _deliveryDate = order.deliveryDate;

    // Group items by category
    final groupedItems = <String, List<ReturnOrderItem>>{};
    if (order.items.isNotEmpty) {
      for (var item in order.items) {
        final cat = item.category ?? '';
        groupedItems.putIfAbsent(cat, () => []).add(item);
      }
    }

    if (groupedItems.isEmpty) {
      _addSection();
    } else {
      groupedItems.forEach((cat, items) {
        final controllers = items
            .map(
              (i) => ReturnItemControllers(
                item: i.item,
                quantity: i.quantity == 0 ? '' : i.quantity.toString(),
                unit: i.unit,
              ),
            )
            .toList();

        final defaultUnit = items.isNotEmpty ? items.first.unit : '';

        _sections.add(
          ReturnOrderSection(
            category: cat,
            defaultUnit: defaultUnit,
            items: items,
            itemControllers: controllers,
          ),
        );
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = UserLocalDataSource().getUser();
      if (user != null && mounted) {
        setState(() {
          _returnResponsibleController.text = user.fullName;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user: $e');
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _regionController.dispose();
    _returnResponsibleController.dispose();
    _routeFromController.dispose();
    _routeToController.dispose();
    _returnReasonController.dispose();
    _notesController.dispose();
    for (var section in _sections) {
      section.dispose();
    }
    _totalQuantityNotifier.dispose();
    super.dispose();
  }

  void _addSection() {
    _sections.add(
      ReturnOrderSection(
        items: [ReturnOrderItem()],
        itemControllers: [ReturnItemControllers()],
      ),
    );
  }

  void _removeSection(int index) {
    if (_sections.length > 1) {
      _sections[index].dispose();
      _sections.removeAt(index);
      if (mounted) {
        setState(() {});
        _updateTotalQuantity();
      }
    }
  }

  void _addItemToSection(int sectionIndex, {int count = 1}) {
    final section = _sections[sectionIndex];
    for (int i = 0; i < count; i++) {
      section.items.add(
        ReturnOrderItem(unit: section.defaultUnitController.text),
      );
      section.itemControllers.add(
        ReturnItemControllers(unit: section.defaultUnitController.text),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _removeItemFromSection(int sectionIndex, int itemIndex) {
    final section = _sections[sectionIndex];
    if (section.items.length > 1) {
      section.items.removeAt(itemIndex);
      section.itemControllers[itemIndex].dispose();
      section.itemControllers.removeAt(itemIndex);
      if (mounted) {
        setState(() {});
        _updateTotalQuantity();
      }
    }
  }

  void _updateTotalQuantity() {
    double total = 0;
    for (var section in _sections) {
      for (var item in section.items) {
        total += item.quantity;
      }
    }
    _totalQuantityNotifier.value = total;
  }

  // Calculate Total Quantity
  // Removed getter and using ValueNotifier instead

  Future<void> _selectDate(BuildContext context, bool isDelivery) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        if (isDelivery) {
          _deliveryDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final returnOrder = _buildReturnOrderFromForm();
    if (returnOrder.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _dataSource.saveReturnOrder(returnOrder);

      if (mounted) {
        AnalysisService.clearCache();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الطلب بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) return;

    final returnOrder = _buildReturnOrderFromForm();
    if (returnOrder.items.isEmpty) {
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
                  Image.asset('assets/images/logo.png', height: 80, width: 80),
                  const SizedBox(height: 15),
                  const Text('جارٍ إعداد ملف PDF...'),
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
      final returnOrder = _buildReturnOrderFromForm();
      final bytes = await ReturnOrderPdfGenerator.generate(returnOrder);

      final settingsService = SettingsService();
      final strategy = settingsService.getInvoiceSaveStrategy();
      final defaultPath = settingsService.getDefaultSavePath();

      String? finalPath;
      final safeName = (returnOrder.customerName ?? 'Client').replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
      final fileName = '${safeName}_${returnOrder.sn}.pdf';

      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Share directly
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss dialog
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        }
      } else {
        // Desktop: Follow settings strategy
        if (strategy == InvoiceSaveStrategy.auto && defaultPath != null) {
          final customerDir = Directory('$defaultPath/$safeName');
          if (!await customerDir.exists()) {
            await customerDir.create(recursive: true);
          }
          finalPath = '${customerDir.path}/$fileName';
          final file = File(finalPath);
          await file.writeAsBytes(bytes);
        } else {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            finalPath = await FilePicker.platform.saveFile(
              dialogTitle: 'حفظ المرتجع',
              fileName: fileName,
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );

            if (finalPath != null) {
              final file = File(finalPath);
              await file.writeAsBytes(bytes);
            } else {
              if (mounted) Navigator.of(context).pop();
              return;
            }
          } else {
            Directory? directory = await getExternalStorageDirectory();
            directory ??= await getApplicationDocumentsDirectory();
            finalPath = '${directory.path}/$fileName';
            final file = File(finalPath);
            await file.writeAsBytes(bytes);
          }
        }

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ الملف: $finalPath'),
              duration: (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                  ? const Duration(seconds: 5)
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
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')));
      }
    }
  }

  ReturnOrder _buildReturnOrderFromForm() {
    final order =
        widget.existingOrder ??
        ReturnOrder(
          sn:
              _currentSn ??
              'RET-${DateTime.now().millisecondsSinceEpoch % 10000}',
          returnDate: _returnDate,
        );

    final allItems = <ReturnOrderItem>[];
    for (var section in _sections) {
      for (var item in section.items) {
        if (item.item.isNotEmpty || item.quantity > 0) {
          item.category = section.categoryController.text;
          item.unit = section.defaultUnitController.text;
          allItems.add(item);
        }
      }
    }

    order
      ..category = _selectedCategory
      ..branch = _selectedBranch
      ..customerName = _customerNameController.text
      ..returnDate = _returnDate
      ..region = _regionController.text
      ..returnResponsible = _returnResponsibleController.text
      ..deliveryCostPayer = _deliveryCostPayer
      ..routeFrom = _routeFromController.text
      ..routeTo = _routeToController.text
      ..returnReason = _returnReasonController.text
      ..notes = _notesController.text
      ..deliveryDate = _deliveryDate
      ..items = allItems;

    return order;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(CupertinoIcons.list_dash),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        centerTitle: true,
        title: const Text('Annex Group'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ReturnOrderPage()),
              );
            },
            tooltip: 'جديد',
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.folder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SavedReturnOrdersPage(),
                ), // Corrected: const constructor
              );
            },
            tooltip: 'الطلبات المحفوظة',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              constraints.maxWidth < ResponsiveConstants.kMobileBreakpoint;
          return Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeaderCard(isMobile),
                          const SizedBox(height: 16),
                          _buildInfoCard(isMobile),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    ),

                    // Sections
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
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue[900],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Total Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'إجمالي الكمية:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                ValueListenableBuilder<double>(
                                  valueListenable: _totalQuantityNotifier,
                                  builder: (context, value, child) {
                                    return Text(
                                      value.toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Notes Section
                          _buildTextField(
                            'ملاحظات',
                            _notesController,
                            isRequired: false,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 30),

                          // Action Buttons
                          Center(
                            child: _isSaving
                                ? const CircularProgressIndicator()
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _saveOrder,
                                        icon: const Icon(
                                          CupertinoIcons.floppy_disk,
                                        ),
                                        label: const Text(
                                          'حفظ',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: 15,
                                          ),
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      ElevatedButton.icon(
                                        onPressed: _generatePdf,
                                        icon: const Icon(
                                          CupertinoIcons.doc_text_fill,
                                        ),
                                        label: const Text(
                                          'PDF',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 40),
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

  Widget _buildHeaderCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Center(
              child: Text(
                'Return Order',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              'رقم المرتجع',
              TextEditingController(text: _currentSn),
              readOnly: true,
            ),
            const SizedBox(height: 10),
            _buildDropdown('الفرع', _selectedBranch, [
              'المحلة',
              'القاهرة',
            ], (v) => setState(() => _selectedBranch = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildInfoCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildResponsiveRow(isMobile, [
              _buildTextField('اسم العميل', _customerNameController),
              _buildDatePicker('تاريخ المرتجع', _returnDate, false),
            ]),
            const SizedBox(height: 10),
            _buildResponsiveRow(isMobile, [
              _buildTextField('المنطقة', _regionController),
              _buildTextField(
                'مسئول المرتجع',
                _returnResponsibleController,
                readOnly: true,
              ), // Auto-filled
            ]),
            const SizedBox(height: 10),

            // Delivery Costs
            Row(
              children: [
                const Text(
                  'تكلفة التوصيل على:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('الشركة'),
                  selected: _deliveryCostPayer == 'الشركة',
                  onSelected: (selected) =>
                      setState(() => _deliveryCostPayer = 'الشركة'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('العميل'),
                  selected: _deliveryCostPayer == 'العميل',
                  onSelected: (selected) =>
                      setState(() => _deliveryCostPayer = 'العميل'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildResponsiveRow(isMobile, [
              _buildTextField('من', _routeFromController, isRequired: false),
              _buildTextField('إلى', _routeToController, isRequired: false),
            ]),
            const SizedBox(height: 10),

            _buildResponsiveRow(isMobile, [
              _buildTextField('سبب الاسترجاع', _returnReasonController),
              _buildDatePicker('تاريخ التوصيل', _deliveryDate, true),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        children: children
            .map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: c),
            )
            .toList(),
      );
    }
    return Row(
      children: children
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: c,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool isRequired = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: readOnly,
        fillColor: readOnly
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : null,
      ),
      validator: (v) {
        if (isRequired && !readOnly && (v == null || v.isEmpty)) return 'مطلوب';
        return null;
      },
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isDelivery) {
    return InkWell(
      onTap: () => _selectDate(context, isDelivery),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null ? intl.DateFormat('yyyy-MM-dd').format(date) : '',
        ),
      ),
    );
  }

  List<Widget> _buildSectionSlivers(
    int sectionIndex,
    ReturnOrderSection section,
    bool isMobile,
  ) {
    return [
      // Section Header (Category & Unit)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
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

      // Table Header (Desktop only)
      if (!isMobile)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFD32F2F),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'الصنف',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'الكمية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'الوحدة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
        ),

      // Items List
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = section.items[index];
          final controllers = section.itemControllers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300),
                    right: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: ReturnOrderItemRow(
                  key: ObjectKey(item),
                  index: index,
                  item: item,
                  controllers: controllers,
                  isMobile: isMobile,
                  onRemove: () => _removeItemFromSection(sectionIndex, index),
                  onUpdate: _updateTotalQuantity,
                ),
              ),
            ),
          );
        }, childCount: section.items.length),
      ),

      // Add Item Button
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  onPressed: () => _addItemToSection(sectionIndex),
                  icon: const Icon(CupertinoIcons.add),
                  label: const Text('إضافة صنف'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final count = await showBulkAddDialog(context);
                    if (count != null) {
                      _addItemToSection(sectionIndex, count: count);
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
