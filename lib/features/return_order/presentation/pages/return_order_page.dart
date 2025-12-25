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
  DateTime? _deliveryDate;

  // Items
  final List<ReturnOrderItem> _items = [];
  final ValueNotifier<double> _totalQuantityNotifier = ValueNotifier(0.0);

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
    } else {
      _addNewItem();
      _loadCurrentUser();
    }
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
    _deliveryDate = order.deliveryDate;
    if (order.items.isNotEmpty) {
      _items.addAll(order.items);
    } else {
      _addNewItem();
    }
    _updateTotalQuantity();
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
    _totalQuantityNotifier.dispose();
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add(ReturnOrderItem(unit: '')); // No default unit
    });
    // No need to update total as new item has 0 quantity, but good practice
    // _updateTotalQuantity(); 
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
      _updateTotalQuantity();
    }
  }

  void _updateTotalQuantity() {
    _totalQuantityNotifier.value = _items.fold(0.0, (sum, item) => sum + item.quantity);
  }

  // Calculate Total Quantity
  // Removed getter and using ValueNotifier instead

  Future<void> _selectDate(BuildContext context, bool isDelivery) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final returnOrder = _buildReturnOrderFromForm();
      await _dataSource.saveReturnOrder(returnOrder);

      if (mounted) {
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

    if (_items.isEmpty) {
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

      // Save file
      Directory? directory;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        directory = await getDownloadsDirectory();
      }
      directory ??= await getApplicationDocumentsDirectory();

      final safeCustomerName =
          returnOrder.customerName?.replaceAll(
            RegExp(r'[^\w\s\u0600-\u06FF]'),
            '',
          ) ??
          'Client';
      final fileName = 'Return_${safeCustomerName}_${returnOrder.sn}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الملف: ${file.path}'),
            duration: const Duration(seconds: 8),
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
    final order = widget.existingOrder ?? ReturnOrder(
      sn: (DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0'),
      returnDate: _returnDate,
    );

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
      ..deliveryDate = _deliveryDate
      ..items = List.from(_items);

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
        title: const Text('طلب مرتجع'),
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

                    // Items Header (Desktop only)
                    if (!isMobile)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildItemsHeader(isMobile),
                        ),
                      ),

                    // Items List
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: ReturnOrderItemRow(
                              key: ObjectKey(_items[index]),
                              index: index,
                              item: _items[index],
                              isMobile: isMobile,
                              onRemove: () => _removeItem(index),
                              onUpdate: _updateTotalQuantity,
                            ),
                          );
                        },
                        childCount: _items.length,
                      ),
                    ),


                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _addNewItem,
                              icon: const Icon(CupertinoIcons.add_circled),
                              label: const Text('إضافة صنف'),
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
                                        icon: const Icon(CupertinoIcons.floppy_disk),
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
                                        icon: const Icon(CupertinoIcons.doc_text_fill),
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
                'طلب مرتجع',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            if (isMobile) ...[
              _buildDropdown('الفرع', _selectedBranch, [
                'المحلة',
                'القاهرة',
              ], (v) => setState(() => _selectedBranch = v)),
              const SizedBox(height: 10),
              _buildDropdown(
                'القسم',
                _selectedCategory,
                ['غزل', 'مستلزمات', 'قماش'],
                (v) => setState(() => _selectedCategory = v),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'الفرع',
                      _selectedBranch,
                      ['المحلة', 'القاهرة'],
                      (v) => setState(() => _selectedBranch = v),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildDropdown(
                      'القسم',
                      _selectedCategory,
                      ['غزل', 'مستلزمات', 'قماش'],
                      (v) => setState(() => _selectedCategory = v),
                    ),
                  ),
                ],
              ),
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
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: readOnly,
        fillColor: readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : null,
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

  Widget _buildItemsHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFD32F2F), // Red for return items
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 3,
            child: Text(
              'الصنف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              'الكمية',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              'الوحدة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 40), // Space for delete icon
        ],
      ),
    );
  }


}
