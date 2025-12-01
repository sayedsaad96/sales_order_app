import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/sales_order.dart';
import '../../pdf/pdf_generator.dart';
import 'package:printing/printing.dart';
import '../../data/datasources/invoice_local_data_source.dart';
import 'saved_invoices_page.dart';

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
  // Removed unused _branchController

  final List<ItemControllers> _itemControllers = [];

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

  final List<SalesOrderItem> _items = [];

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

      _items.clear();
      _items.addAll(order.items);

      // Initialize controllers
      for (var item in _items) {
        _itemControllers.add(
          ItemControllers(
            name: item.itemName,
            quantity: item.quantity == 0 ? '' : item.quantity.toString(),
            unit: item.unit,
            price: item.price == 0 ? '' : item.price.toString(),
          ),
        );
      }
    } else {
      // Initialize with empty rows
      for (int i = 0; i < 1; i++) {
        _items.add(SalesOrderItem());
        _itemControllers.add(ItemControllers());
      }
    }
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      final validItems = _items
          .where((item) => item.itemName.isNotEmpty || item.quantity > 0)
          .toList();

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
      order.items = validItems;

      await InvoiceLocalDataSource().saveInvoice(order);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')));
      }
    }
  }

  void _addItem() {
    setState(() {
      double? defaultPrice;
      if (_items.isNotEmpty && _items.first.price > 0) {
        defaultPrice = _items.first.price;
      }
      _items.add(SalesOrderItem(price: defaultPrice ?? 0));
      _itemControllers.add(
        ItemControllers(
          price: (defaultPrice != null && defaultPrice > 0)
              ? defaultPrice.toString()
              : '',
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        _items.removeAt(index);
        _itemControllers[index].dispose();
        _itemControllers.removeAt(index);
      }
    });
  }

  @override
  void dispose() {
    _snController.dispose();
    _customerNameController.dispose();
    _regionController.dispose();
    _salesResponsibleController.dispose();
    _deliveryPlaceController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalValue => _items.fold(0, (sum, item) => sum + item.value);

  Future<void> _generatePdf() async {
    if (_formKey.currentState!.validate()) {
      // Filter out empty items (where name is empty and quantity is 0)
      final validItems = _items
          .where((item) => item.itemName.isNotEmpty || item.quantity > 0)
          .toList();

      if (validItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل')),
        );
        return;
      }

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
        items: validItems,
      );

      final pdf = await PdfSalesOrderGenerator.generate(order);

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'SalesOrder_${order.sn}.pdf',
      );
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
              Row(
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
                      decoration: const InputDecoration(
                        labelText: 'S/N',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Branch and Store
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedBranch,
                      decoration: const InputDecoration(labelText: 'الفرع'),
                      items: ['القاهرة', 'المحلة']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBranch = v),
                      validator: (v) => v == null ? 'مطلوب' : null,
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
              const SizedBox(height: 20),

              // Info Grid
              Row(
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
                            filled: true,
                            fillColor: Color(0xFFE3F2FD),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _regionController,
                          decoration: const InputDecoration(
                            labelText: 'المنطقة',
                            filled: true,
                            fillColor: Color(0xFFE3F2FD),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                        const SizedBox(height: 10),
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
                              filled: true,
                              fillColor: Color(0xFFE3F2FD),
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
                            if (date != null) setState(() => _orderDate = date);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'التاريخ',
                              filled: true,
                              fillColor: Color(0xFFE3F2FD),
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
                            filled: true,
                            fillColor: Color(0xFFE3F2FD),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'طريقة السداد',
                            filled: true,
                            fillColor: Color(0xFFE3F2FD),
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
                          onChanged: (v) => setState(() => _paymentMethod = v),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _deliveryPlaceController,
                          decoration: const InputDecoration(
                            labelText: 'مكان التسليم',
                            filled: true,
                            fillColor: Color(0xFFE3F2FD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Items Table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      color: const Color(0xFF1565C0),
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
                    // Rows
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final controllers = _itemControllers[index];
                        return Container(
                          key: ValueKey(index),
                          color: index % 2 == 0
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: controllers.nameController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onChanged: (v) => item.itemName = v,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: controllers.quantityController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onChanged: (v) {
                                    setState(() {
                                      item.quantity = int.tryParse(v) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: controllers.unitController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onChanged: (v) => item.unit = v,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: controllers.priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onChanged: (v) {
                                    setState(() {
                                      item.price = double.tryParse(v) ?? 0;
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
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _removeItem(index),
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
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة صنف'),
                  ),
                  const Spacer(),
                  Container(
                    color: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Text(
                      'الإجمالي: ${_totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
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
