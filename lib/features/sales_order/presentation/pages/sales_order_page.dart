import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/models/sales_order.dart';
import '../../pdf/pdf_generator.dart';
import 'package:printing/printing.dart';
import '../../data/datasources/invoice_local_data_source.dart';
import 'saved_invoices_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../user/data/datasources/user_local_data_source.dart';

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
  final List<OrderSection> _sections = [];

  String? _selectedBranch;
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
      _snController.text = order.sn ?? '';
      _selectedBranch = order.branch;
      _customerNameController.text = order.customerName ?? '';
      _regionController.text = order.region ?? '';
      _salesResponsibleController.text = order.salesResponsible ?? '';
      _deliveryPlaceController.text = order.deliveryPlace ?? '';
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
  }

  void _removeItem(int sectionIndex, int itemIndex) {
    setState(() {
      final section = _sections[sectionIndex];
      if (section.items.length > 1) {
        section.items.removeAt(itemIndex);
        section.itemControllers[itemIndex].dispose();
        section.itemControllers.removeAt(itemIndex);
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

      final order = widget.existingOrder ?? SalesOrder(orderDate: _orderDate);

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
    for (var section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  double get _totalValue => _sections.fold(
    0,
    (sum, section) => sum + section.items.fold(0, (s, item) => s + item.value),
  );

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

        final fileName = 'SalesOrder_${order.sn}.pdf';
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
                textColor: Colors.yellow,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'طلب بيع',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: TextFormField(
                          controller: _snController,
                          decoration: const InputDecoration(labelText: 'S/N'),
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
                  child: Row(
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
                              onChanged: (v) =>
                                  setState(() => _orderTypes[key] = v ?? false),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Right Column
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _customerNameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم العميل',
                              ),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _regionController,
                              decoration: const InputDecoration(
                                labelText: 'المنطقة',
                              ),
                            ),
                            const SizedBox(height: 20),
                            RadioGroup<bool>(
                              groupValue: _deliveryIncluded,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _deliveryIncluded = v);
                                }
                              },
                              child: Row(
                                children: [
                                  const Text('شامل التوصيل: '),
                                  Radio<bool>(value: true),
                                  const Text('نعم'),
                                  Radio<bool>(value: false),
                                  const Text('لا'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _deliveryDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() => _deliveryDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ التوصيل',
                                ),
                                child: Text(
                                  _deliveryDate != null
                                      ? DateFormat(
                                          'dd-MMM-yyyy',
                                        ).format(_deliveryDate!)
                                      : '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Left Column
                      Expanded(
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _orderDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() => _orderDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'التاريخ',
                                ),
                                child: Text(
                                  DateFormat('dd-MMM-yyyy').format(_orderDate),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _salesResponsibleController,
                              decoration: const InputDecoration(
                                labelText: 'مسؤول البيع',
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'طريقة السداد',
                              ),
                              items:
                                  [
                                        'كاش',
                                        'تحويل بنكي',
                                        'اسبوعين',
                                        ' شهر',
                                        ' شهرين',
                                        ' 3 شهور',
                                      ]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _deliveryPlaceController,
                              decoration: const InputDecoration(
                                labelText: 'مكان التسليم',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Items Table
              // Items Sections
              ..._sections.asMap().entries.map((entry) {
                final sectionIndex = entry.key;
                final section = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
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
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeSection(sectionIndex),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                              // Rows
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: section.items.length,
                                itemBuilder: (context, index) {
                                  final item = section.items[index];
                                  final controllers =
                                      section.itemControllers[index];
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    key: ValueKey(index),
                                    color: index % 2 == 0
                                        ? Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.3)
                                        : Theme.of(context).colorScheme.surface,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            controller:
                                                controllers.nameController,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              filled: false,
                                            ),
                                            onChanged: (v) => item.itemName = v,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            controller:
                                                controllers.quantityController,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.right,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              filled: false,
                                            ),
                                            onChanged: (v) {
                                              setState(() {
                                                item.quantity =
                                                    int.tryParse(v) ?? 0;
                                              });
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            controller:
                                                controllers.unitController,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              filled: false,
                                            ),
                                            onChanged: (v) => item.unit = v,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            controller:
                                                controllers.priceController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              filled: false,
                                            ),
                                            onChanged: (v) {
                                              setState(() {
                                                item.price =
                                                    double.tryParse(v) ?? 0;
                                              });
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            item.value.toStringAsFixed(2),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _removeItem(sectionIndex, index),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => _addItem(sectionIndex),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة صنف'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
              Container(
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
                      _totalValue.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveInvoice,
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ', style: TextStyle(fontSize: 18)),
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
            ],
          ),
        ),
      ),
    );
  }
}

class ItemControllers {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController priceController;

  ItemControllers({
    String name = '',
    String quantity = '',
    String unit = '',
    String price = '',
  }) : nameController = TextEditingController(text: name),
       quantityController = TextEditingController(text: quantity),
       unitController = TextEditingController(text: unit),
       priceController = TextEditingController(text: price);

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
}

class OrderSection {
  TextEditingController categoryController;
  List<SalesOrderItem> items;
  List<ItemControllers> itemControllers;

  OrderSection({
    String category = '',
    List<SalesOrderItem>? items,
    List<ItemControllers>? itemControllers,
  }) : categoryController = TextEditingController(text: category),
       items = items ?? [],
       itemControllers = itemControllers ?? [];

  void dispose() {
    categoryController.dispose();
    for (var controller in itemControllers) {
      controller.dispose();
    }
  }
}
