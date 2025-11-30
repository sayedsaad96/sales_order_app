import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/sales_order.dart';
import '../../pdf/pdf_generator.dart';
import 'package:printing/printing.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

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
    // Initialize with empty rows
    for (int i = 0; i < 1; i++) {
      _items.add(SalesOrderItem());
    }
  }

  void _addItem() {
    setState(() {
      double? defaultPrice;
      if (_items.isNotEmpty && _items.first.price > 0) {
        defaultPrice = _items.first.price;
      }
      _items.add(SalesOrderItem(price: defaultPrice ?? 0));
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        _items.removeAt(index);
      }
    });
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
      appBar: AppBar(title: const Text('طلب بيع'), centerTitle: true),
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
                        return Container(
                          key: ValueKey(index),
                          color: index % 2 == 0
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: TextEditingController(
                                    text: item.itemName,
                                  ),
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
                                  controller: TextEditingController(
                                    text: item.quantity == 0
                                        ? ''
                                        : item.quantity.toString(),
                                  ),
                                  keyboardType: TextInputType.number,
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
                                  controller: TextEditingController(
                                    text: item.unit,
                                  ),
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
                                  controller: TextEditingController(
                                    text: item.price == 0
                                        ? ''
                                        : item.price.toString(),
                                  ),
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
                child: ElevatedButton.icon(
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    'إنشاء PDF',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
