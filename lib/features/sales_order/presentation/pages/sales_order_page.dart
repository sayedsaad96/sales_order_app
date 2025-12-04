import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/models/sales_order.dart';
import '../../pdf/pdf_generator.dart';
import 'package:printing/printing.dart';
import '../../data/datasources/invoice_local_data_source.dart';
import 'saved_invoices_page.dart';
import 'price_list_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../user/data/datasources/user_local_data_source.dart';
import '../../../../core/utils/responsive_constants.dart';
import '../widgets/customer_info_section.dart';
// import '../widgets/order_section_widget.dart'; // Removed in favor of direct sliver building
import '../widgets/sales_order_item_row.dart';
import '../utils/sales_order_helpers.dart';

class SalesOrderPage extends StatefulWidget {
  final SalesOrder? existingOrder;
  const SalesOrderPage({super.key, this.existingOrder});

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _snController = TextEditingController(
    text: 'SO-${DateTime.now().microsecond}',
  );
  final _customerNameController = TextEditingController();
  final _regionController = TextEditingController();
  final _salesResponsibleController = TextEditingController();
  final _deliveryPlaceController = TextEditingController();
  final _notesController = TextEditingController();
  final List<OrderSection> _sections = [];
  final ValueNotifier<double> _totalValueNotifier = ValueNotifier(0.0);

  String? _selectedBranch = "القاهرة";
  final Map<String, bool> _orderTypes = {
    'غزل': false,
    'مستلزمات': true,
    'قماش': false,
  };
  bool _deliveryIncluded = true;
  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    if (widget.existingOrder != null) {
      final order = widget.existingOrder!;
      // _snController.text = order.sn ?? ''; // Don't copy SN, generate new one for "Clone" behavior
      // Keep default initialized value: 'SO-${DateTime.now().microsecond}'
      _selectedBranch = order.branch;
      _customerNameController.text = order.customerName ?? '';
      _regionController.text = order.region ?? '';
      _salesResponsibleController.text = order.salesResponsible ?? '';
      _deliveryPlaceController.text = order.deliveryPlace ?? '';
      _notesController.text = order.notes ?? '';
      _paymentMethod = order.paymentMethod;
      _deliveryIncluded = order.deliveryIncluded;
      _orderDate = order.orderDate;
      _deliveryDate = order.deliveryDate;

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
          _sections.add(
            OrderSection(
              category: cat,
              items: items,
              itemControllers: controllers,
            ),
          );
        });
      }
    } else {
      _addSection();
    }
    _calculateTotal();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (widget.existingOrder == null) {
      final user = UserLocalDataSource().getUser();
      if (user != null) {
        setState(() {
          _salesResponsibleController.text = user.fullName;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _snController.text = 'SO-${DateTime.now().microsecond}';
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
    setState(() {
      if (_sections.length > 1) {
        _sections[index].dispose();
        _sections.removeAt(index);
        _calculateTotal();
      }
    });
  }

  void _addItem(int sectionIndex) {
    setState(() {
      final section = _sections[sectionIndex];
      double? defaultPrice;
      if (section.items.isNotEmpty && section.items.first.price > 0) {
        defaultPrice = section.items.first.price;
      }
      section.items.add(SalesOrderItem(price: defaultPrice ?? 0));
      section.itemControllers.add(
        ItemControllers(
          price: (defaultPrice != null && defaultPrice > 0)
              ? defaultPrice.toString()
              : '',
        ),
      );
    });
    // No need to calculate total here as new item has 0 price
  }

  void _removeItem(int sectionIndex, int itemIndex) {
    setState(() {
      final section = _sections[sectionIndex];
      if (section.items.length > 1) {
        section.items.removeAt(itemIndex);
        section.itemControllers[itemIndex].dispose();
        section.itemControllers.removeAt(itemIndex);
        _calculateTotal();
      }
    });
  }

  List<SalesOrderItem> get _allValidItems {
    final allItems = <SalesOrderItem>[];
    for (var section in _sections) {
      for (var item in section.items) {
        if (item.itemName.isNotEmpty || item.quantity > 0) {
          item.category = section.categoryController.text;
          allItems.add(item);
        }
      }
    }
    return allItems;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      final validItems = _allValidItems;

      if (validItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل')),
        );
        return;
      }

      // Always create a NEW SalesOrder to ensure it's saved as a new entry (Clone)
      final order = SalesOrder(orderDate: _orderDate);

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
      // order.category = _categoryController.text; // Deprecated
      order.items = validItems;

      await InvoiceLocalDataSource().saveInvoice(order);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')));
      }
    }
  }

  @override
  void dispose() {
    _snController.dispose();
    _customerNameController.dispose();
    _regionController.dispose();
    _salesResponsibleController.dispose();
    _deliveryPlaceController.dispose();
    _notesController.dispose();
    for (var section in _sections) {
      section.dispose();
    }
    _totalValueNotifier.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double total = 0;
    for (var section in _sections) {
      for (var item in section.items) {
        total += item.value;
      }
    }
    _totalValueNotifier.value = total;
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
        final order = SalesOrder(
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
          // category: _categoryController.text,
          items: validItems,
        );

        final pdf = await PdfSalesOrderGenerator.generate(order);
        final bytes = await pdf.save();

        Directory? directory;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
        directory ??= await getApplicationDocumentsDirectory();

        final safeCustomerName =
            order.customerName?.replaceAll(
              RegExp(r'[^\w\s\u0600-\u06FF]'),
              '',
            ) ??
            'Client';
        final fileName = '${safeCustomerName}_${order.sn}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);

        // Dismiss loading indicator
        if (mounted) {
          Navigator.of(context).pop();
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
        title: const Text('طلب بيع'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.receipt),
          tooltip: 'قائمة الأسعار',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PriceListPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'طلب جديد',
            onPressed: _resetForm,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedInvoicesPage(),
                ),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              constraints.maxWidth < ResponsiveConstants.kMobileBreakpoint;
          return Form(
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
                                        'طلب بيع',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _snController,
                                      decoration: const InputDecoration(
                                        labelText: 'S/N',
                                      ),
                                      validator: (value) =>
                                          value?.isEmpty ?? true ? 'مطلوب' : null,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'طلب بيع',
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
                                        decoration: const InputDecoration(
                                          labelText: 'S/N',
                                        ),
                                        validator: (value) =>
                                            value?.isEmpty ?? true ? 'مطلوب' : null,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      onChanged: (v) =>
                                          setState(() => _selectedBranch = v),
                                      validator: (v) => v == null ? 'مطلوب' : null,
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
                                                () => _orderTypes[key] = v ?? false,
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 150,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedBranch,
                                          decoration: const InputDecoration(
                                            labelText: 'الفرع',
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          items: ['القاهرة', 'المحلة']
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  value: e,
                                                  child: Text(e),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => _selectedBranch = v),
                                          validator: (v) =>
                                              v == null ? 'مطلوب' : null,
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
                                              () => _orderTypes[key] = v ?? false,
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
                        salesResponsibleController: _salesResponsibleController,
                        deliveryPlaceController: _deliveryPlaceController,
                        deliveryIncluded: _deliveryIncluded,
                        orderDate: _orderDate,
                        deliveryDate: _deliveryDate,
                        paymentMethod: _paymentMethod,
                        onDeliveryIncludedChanged: (v) =>
                            setState(() => _deliveryIncluded = v),
                        onOrderDateChanged: (v) => setState(() => _orderDate = v),
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
                  return _buildSectionSlivers(entry.key, entry.value, isMobile);
                }),

                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _addSection()),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('إضافة تصنيف جديد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات',
                          hintText: 'أضف ملاحظات أو تعليقات (اختياري)',
                        ),
                        maxLines: 3,
                        minLines: 2,
                      ),
                      const SizedBox(height: 20),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      const SizedBox(height: 30),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _saveInvoice,
                              icon: const Icon(Icons.save),
                              label: const Text(
                                'حفظ',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                                backgroundColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              onPressed: _generatePdf,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text(
                                'إنشاء PDF',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isMobile
                      ? Expanded(
                          child: TextFormField(
                            controller: section.categoryController,
                            decoration: const InputDecoration(
                              labelText: 'التصنيف',
                            ),
                          ),
                        )
                      : SizedBox(
                          width: 250,
                          height: 50,
                          child: TextFormField(
                            controller: section.categoryController,
                            decoration: const InputDecoration(
                              labelText: 'التصنيف',
                            ),
                          ),
                        ),
                  if (_sections.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = section.items[index];
              final controllers = section.itemControllers[index];
              return Container(
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
            },
            childCount: section.items.length,
          ),
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
            child: TextButton.icon(
              onPressed: () => _addItem(sectionIndex),
              icon: const Icon(Icons.add),
              label: const Text('إضافة صنف'),
            ),
          ),
        ),
      ),
    ];
  }
}


