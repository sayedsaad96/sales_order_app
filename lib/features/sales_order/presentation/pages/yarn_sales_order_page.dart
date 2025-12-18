// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../data/models/yarn_sales_order.dart';
import '../../data/datasources/yarn_invoice_local_data_source.dart';
import '../../pdf/yarn_pdf_generator.dart';
import '../../../user/data/datasources/user_local_data_source.dart';
import '../../../../core/utils/responsive_constants.dart';

import '../widgets/yarn_installment_widget.dart';
import '../widgets/carton_calculator_dialog.dart';
import 'saved_yarn_invoices_page.dart';
import '../../../../core/widgets/app_drawer.dart';

class YarnSalesOrderPage extends StatefulWidget {
  final YarnSalesOrder? existingOrder;
  final VoidCallback? onMenuPressed;
  const YarnSalesOrderPage({super.key, this.existingOrder, this.onMenuPressed});

  @override
  State<YarnSalesOrderPage> createState() => _YarnSalesOrderPageState();
}

class _YarnSalesOrderPageState extends State<YarnSalesOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _snController = TextEditingController(
    text: 'YSO-${DateTime.now().microsecond}',
  );
  final _customerNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _regionController = TextEditingController();
  final _salesResponsibleController = TextEditingController();
  final _deliveryPlaceController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _notesController = TextEditingController();

  // Dynamic item rows (starts with 1)
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _unitControllers = [];

  // Dynamic installment rows (starts with 1)
  final List<TextEditingController> _installmentDurationControllers = [];
  final List<TextEditingController> _installmentValueControllers = [];

  String? _selectedBranch = "القاهرة";
  String _deliveryResponsibility = "العميل"; // العميل or الشركة
  String _editQuantity =
      "الكمية المحددة"; // الكمية المحددة, يفضل الزيادة, يفضل التخفيض

  bool _specifiedQuantity = false;
  DateTime _orderDate = DateTime.now();

  final Map<String, bool> _orderTypes = {'غزل': true, 'قماش': false};
  DateTime? _deliveryDate;

  final ValueNotifier<double> _totalValueNotifier = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();

    // Initialize with 1 item row
    _addItem();

    // Initialize with 1 installment row
    _addInstallment();

    if (widget.existingOrder != null) {
      _loadExistingOrder();
    }

    _loadCurrentUser();
  }

  void _loadExistingOrder() {
    final order = widget.existingOrder!;
    _snController.text = order.sn ?? '';
    _selectedBranch = order.branch;
    _deliveryResponsibility = order.deliveryResponsibility;
    _customerNameController.text = order.customerName ?? '';
    _contactNameController.text = order.contactName ?? '';
    _mobileNumberController.text = order.mobileNumber ?? '';
    _regionController.text = order.region ?? '';
    _deliveryDate = order.deliveryDate;
    _deliveryPlaceController.text = order.deliveryPlace ?? '';
    _editQuantity = order.editQuantity ?? 'الكمية المحددة';

    _specifiedQuantity = order.specifiedQuantity;
    _paymentMethodController.text = order.paymentMethod ?? '';
    _salesResponsibleController.text = order.salesResponsible ?? '';
    _notesController.text = order.notes ?? '';
    _orderDate = order.orderDate;

    _orderTypes.updateAll((key, value) => false);
    for (var type in order.orderTypes) {
      if (_orderTypes.containsKey(type)) {
        _orderTypes[type] = true;
      }
    }

    // Clear existing items and load from order
    _clearAllItems();
    for (int i = 0; i < order.items.length; i++) {
      if (i == 0) {
        // First item already exists from initialization
        _descriptionControllers[0].text = order.items[0].description;
        _priceControllers[0].text = order.items[0].price > 0
            ? order.items[0].price.toString()
            : '';
        _quantityControllers[0].text = order.items[0].quantity > 0
            ? order.items[0].quantity.toString()
            : '';
        _unitControllers[0].text = order.items[0].unit;
      } else {
        // Add additional items
        _addItem();
        _descriptionControllers[i].text = order.items[i].description;
        _priceControllers[i].text = order.items[i].price > 0
            ? order.items[i].price.toString()
            : '';
        _quantityControllers[i].text = order.items[i].quantity > 0
            ? order.items[i].quantity.toString()
            : '';
        _unitControllers[i].text = order.items[i].unit;
      }
    }

    // Clear existing installments and load from order
    _clearAllInstallments();
    for (int i = 0; i < order.installments.length; i++) {
      if (i == 0) {
        // First installment already exists from initialization
        _installmentDurationControllers[0].text =
            order.installments[0].duration;
        _installmentValueControllers[0].text = order.installments[0].value;
      } else {
        // Add additional installments
        _addInstallment();
        _installmentDurationControllers[i].text =
            order.installments[i].duration;
        _installmentValueControllers[i].text = order.installments[i].value;
      }
    }

    _calculateTotal();
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
        debugPrint('Failed to load user: $e');
      }
    }
  }

  void _calculateTotal() {
    double total = 0;
    for (int i = 0; i < _priceControllers.length; i++) {
      final price = double.tryParse(_priceControllers[i].text) ?? 0;
      final quantity = double.tryParse(_quantityControllers[i].text) ?? 0;
      total += price * quantity;
    }
    _totalValueNotifier.value = total;
  }

  List<YarnSalesOrderItem> _getValidItems() {
    final items = <YarnSalesOrderItem>[];
    for (int i = 0; i < _descriptionControllers.length; i++) {
      final description = _descriptionControllers[i].text;
      final price = double.tryParse(_priceControllers[i].text) ?? 0;
      final quantity = double.tryParse(_quantityControllers[i].text) ?? 0;

      // Include item if it has any data
      if (description.isNotEmpty || price > 0 || quantity > 0) {
        items.add(
          YarnSalesOrderItem(
            description: description,
            price: price,
            quantity: quantity,
            unit: _unitControllers[i].text,
          ),
        );
      }
    }
    return items;
  }

  List<YarnInstallment> _getInstallments() {
    final installments = <YarnInstallment>[];
    for (int i = 0; i < _installmentDurationControllers.length; i++) {
      final duration = _installmentDurationControllers[i].text;
      final value = _installmentValueControllers[i].text;

      if (duration.isNotEmpty || value.isNotEmpty) {
        installments.add(YarnInstallment(duration: duration, value: value));
      }
    }
    return installments;
  }

  void _addItem() {
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    _descriptionControllers.add(descController);
    _priceControllers.add(priceController);
    _quantityControllers.add(quantityController);
    _unitControllers.add(TextEditingController(text: 'KG'));

    // Add listeners to calculate total
    priceController.addListener(_calculateTotal);
    quantityController.addListener(_calculateTotal);

    if (mounted) {
      setState(() {});
    }
  }

  void _removeItem(int index) {
    if (_descriptionControllers.length > 1) {
      _descriptionControllers[index].dispose();
      _priceControllers[index].dispose();
      _quantityControllers[index].dispose();
      _unitControllers[index].dispose();

      _descriptionControllers.removeAt(index);
      _priceControllers.removeAt(index);
      _quantityControllers.removeAt(index);
      _unitControllers.removeAt(index);

      if (mounted) {
        setState(() {});
        _calculateTotal();
      }
    }
  }

  void _clearAllItems() {
    for (var controller in _descriptionControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _unitControllers) {
      controller.dispose();
    }

    _descriptionControllers.clear();
    _priceControllers.clear();
    _quantityControllers.clear();
    _unitControllers.clear();

    // Add one empty item
    _addItem();
  }

  void _addInstallment() {
    final durationController = TextEditingController();
    final valueController = TextEditingController();

    _installmentDurationControllers.add(durationController);
    _installmentValueControllers.add(valueController);

    if (mounted) {
      setState(() {});
    }
  }

  void _removeInstallment(int index) {
    if (_installmentDurationControllers.length > 1) {
      _installmentDurationControllers[index].dispose();
      _installmentValueControllers[index].dispose();

      _installmentDurationControllers.removeAt(index);
      _installmentValueControllers.removeAt(index);

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _clearAllInstallments() {
    for (var controller in _installmentDurationControllers) {
      controller.dispose();
    }
    for (var controller in _installmentValueControllers) {
      controller.dispose();
    }

    _installmentDurationControllers.clear();
    _installmentValueControllers.clear();

    // Add one empty installment
    _addInstallment();
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      final order = widget.existingOrder ?? YarnSalesOrder(
        orderDate: _orderDate,
      );

      order
        ..sn = _snController.text
        ..branch = _selectedBranch
        ..deliveryResponsibility = _deliveryResponsibility
        ..customerName = _customerNameController.text
        ..region = _regionController.text
        ..deliveryDate = _deliveryDate
        ..orderDate = _orderDate
        ..deliveryPlace = _deliveryPlaceController.text
        ..editQuantity = _editQuantity
        ..contactName = _contactNameController.text
        ..mobileNumber = _mobileNumberController.text
        ..specifiedQuantity = _specifiedQuantity
        ..paymentMethod = _paymentMethodController.text
        ..salesResponsible = _salesResponsibleController.text
        ..items = _getValidItems()
        ..installments = _getInstallments()
        ..notes = _notesController.text
        ..orderTypes = _orderTypes.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

      await YarnInvoiceLocalDataSource().saveInvoice(order);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')));
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_formKey.currentState!.validate()) {
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
        final order = YarnSalesOrder(
          sn: _snController.text,
          branch: _selectedBranch,
          deliveryResponsibility: _deliveryResponsibility,
          customerName: _customerNameController.text,
          region: _regionController.text,
          deliveryDate: _deliveryDate,
          orderDate: _orderDate,
          deliveryPlace: _deliveryPlaceController.text,
          editQuantity: _editQuantity,
          contactName: _contactNameController.text,
          mobileNumber: _mobileNumberController.text,
          paymentMethod: _paymentMethodController.text,
          salesResponsible: _salesResponsibleController.text,
          items: _getValidItems(),
          installments: _getInstallments(),
          notes: _notesController.text,
          orderTypes: _orderTypes.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList(),
        );

        final pdf = await YarnPdfGenerator.generate(order);
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
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')),
          );
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _snController.text = 'YSO-${DateTime.now().microsecond}';
      _customerNameController.clear();
      _contactNameController.clear();
      _mobileNumberController.clear();
      _regionController.clear();
      _deliveryPlaceController.clear();
      _paymentMethodController.clear();
      _notesController.clear();
      _selectedBranch = "القاهرة";
      _deliveryResponsibility = "العميل";
      _editQuantity = "الكمية المحددة";

      _specifiedQuantity = false;
      _orderDate = DateTime.now();
      _deliveryDate = null;

      // Default: Check 'Yarn' (غزل) if new order
      _orderTypes.updateAll((key, value) => false);
      _orderTypes['غزل'] = true;
      _orderTypes['قماش'] = false;

      _clearAllItems();

      _clearAllInstallments();

      _loadCurrentUser();
      _calculateTotal();
    });
  }

  @override
  void dispose() {
    _snController.dispose();
    _customerNameController.dispose();
    _contactNameController.dispose();
    _mobileNumberController.dispose();
    _regionController.dispose();
    _salesResponsibleController.dispose();
    _deliveryPlaceController.dispose();
    _paymentMethodController.dispose();
    _notesController.dispose();

    for (var controller in _descriptionControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _unitControllers) {
      controller.dispose();
    }
    for (var controller in _installmentDurationControllers) {
      controller.dispose();
    }
    for (var controller in _installmentValueControllers) {
      controller.dispose();
    }

    _totalValueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define Teal Theme
    final tealTheme = Theme.of(context).copyWith(
      primaryColor: Colors.teal,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.teal,
        secondary: Colors.tealAccent,
        surfaceContainerHigh: Colors.teal.withValues(alpha: 0.1),
      ),
      appBarTheme: Theme.of(context).appBarTheme.copyWith(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: Theme.of(context).floatingActionButtonTheme
          .copyWith(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelStyle: const TextStyle(color: Colors.teal),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.teal,
        selectionHandleColor: Colors.teal,
        selectionColor: Color(0x4D009688), // Teal with opacity
      ),
    );

    return Theme(
      data: tealTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: widget.onMenuPressed != null
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: widget.onMenuPressed,
                  tooltip: 'Menu',
                )
              : null,
          title: const Text('Annex Group'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'طلب جديد',
              onPressed: _resetForm,
            ),
            IconButton(
              icon: const Icon(Icons.folder),
              tooltip: 'الفواتير المحفوظة',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedYarnInvoicesPage(),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: LayoutBuilder(
          builder: (builderContext, constraints) {
            final isMobile =
                constraints.maxWidth < ResponsiveConstants.kMobileBreakpoint;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
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
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _snController,
                                      decoration: const InputDecoration(
                                        labelText: 'S/N',
                                      ),
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                          ? 'مطلوب'
                                          : null,
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _orderDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (!mounted) return;
                                        if (date != null) {
                                          setState(() => _orderDate = date);
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'التاريخ',
                                          border: OutlineInputBorder(),
                                        ),
                                        child: Text(
                                          DateFormat(
                                            'dd-MMM-yyyy',
                                          ).format(_orderDate),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Yarn Sales Order',
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
                                      child: InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _orderDate,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (!mounted) return;
                                          if (date != null) {
                                            setState(() => _orderDate = date);
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'التاريخ',
                                          ),
                                          child: Text(
                                            DateFormat(
                                              'dd-MMM-yyyy',
                                            ).format(_orderDate),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        controller: _snController,
                                        decoration: const InputDecoration(
                                          labelText: 'S/N',
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

                      // Branch and Type
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
                                              activeColor: Colors.teal,
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
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedBranch,
                                          decoration: const InputDecoration(
                                            labelText: 'الفرع',
                                            contentPadding:
                                                EdgeInsets.symmetric(
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
                                          onChanged: (v) => setState(
                                            () => _selectedBranch = v,
                                          ),
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
                                              () =>
                                                  _orderTypes[key] = v ?? false,
                                            ),
                                            activeColor: Colors.teal,
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

                      // Consolidated Customer Info & Additional Fields
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (isMobile) ...[
                                // Mobile Layout
                                TextFormField(
                                  controller: _customerNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'اسم العميل',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v?.isEmpty ?? true ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _contactNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'اسم للتواصل',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _mobileNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم للتواصل',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _regionController,
                                  decoration: const InputDecoration(
                                    labelText: 'المنطقة',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _deliveryPlaceController,
                                  decoration: const InputDecoration(
                                    labelText: 'مكان التسليم',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _deliveryDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (!mounted) return;
                                    if (date != null) {
                                      setState(() => _deliveryDate = date);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'تاريخ التسليم',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(
                                      _deliveryDate != null
                                          ? DateFormat(
                                              'dd-MMM-yyyy',
                                            ).format(_deliveryDate!)
                                          : 'اختر التاريخ',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _paymentMethodController,
                                  decoration: const InputDecoration(
                                    labelText: 'طريقة السداد',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _salesResponsibleController,
                                  decoration: const InputDecoration(
                                    labelText: 'مسئول البيع',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'تعديل الكمية',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        RadioListTile<String>(
                                          title: const Text('الكمية المحددة'),
                                          value: 'الكمية المحددة',
                                          groupValue: _editQuantity,
                                          onChanged: (v) => setState(
                                            () => _editQuantity =
                                                v ?? 'الكمية المحددة',
                                          ),
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        RadioListTile<String>(
                                          title: const Text('يفضل الزيادة'),
                                          value: 'يفضل الزيادة',
                                          groupValue: _editQuantity,
                                          onChanged: (v) => setState(
                                            () => _editQuantity =
                                                v ?? 'الكمية المحددة',
                                          ),
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        RadioListTile<String>(
                                          title: const Text('يفضل التخفيض'),
                                          value: 'يفضل التخفيض',
                                          groupValue: _editQuantity,
                                          onChanged: (v) => setState(
                                            () => _editQuantity =
                                                v ?? 'الكمية المحددة',
                                          ),
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'مسئولية التوصيل',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Radio<String>(
                                              value: 'العميل',
                                              groupValue:
                                                  _deliveryResponsibility,
                                              onChanged: (v) => setState(
                                                () => _deliveryResponsibility =
                                                    v ?? 'العميل',
                                              ),
                                            ),
                                            const Text('العميل'),
                                            const SizedBox(width: 16),
                                            Radio<String>(
                                              value: 'الشركة',
                                              groupValue:
                                                  _deliveryResponsibility,
                                              onChanged: (v) => setState(
                                                () => _deliveryResponsibility =
                                                    v ?? 'العميل',
                                              ),
                                            ),
                                            const Text('الشركة'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ] else ...[
                                // Desktop Layout
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _customerNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'اسم العميل',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (v) =>
                                            v?.isEmpty ?? true ? 'مطلوب' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _regionController,
                                        decoration: const InputDecoration(
                                          labelText: 'المنطقة',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _contactNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'اسم للتواصل',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _mobileNumberController,
                                        decoration: const InputDecoration(
                                          labelText: 'رقم للتواصل',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _deliveryPlaceController,
                                        decoration: const InputDecoration(
                                          labelText: 'مكان التسليم',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                _deliveryDate ?? DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                          );
                                          if (!mounted) return;
                                          if (date != null) {
                                            setState(
                                              () => _deliveryDate = date,
                                            );
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'تاريخ التوصيل',
                                            border: OutlineInputBorder(),
                                          ),
                                          child: Text(
                                            _deliveryDate != null
                                                ? '${_deliveryDate!.year}-${_deliveryDate!.month}-${_deliveryDate!.day}'
                                                : ' ',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _paymentMethodController,
                                        decoration: const InputDecoration(
                                          labelText: 'طريقة السداد',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _salesResponsibleController,
                                        decoration: const InputDecoration(
                                          labelText: 'مسئول البيع',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'تعديل الكمية',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'الكمية المحددة',
                                          groupValue: _editQuantity,
                                          onChanged: (v) => setState(
                                            () => _editQuantity =
                                                v ?? 'الكمية المحددة',
                                          ),
                                        ),
                                        const Text('الكمية المحددة'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'يفضل الزيادة',
                                          groupValue: _editQuantity,
                                          onChanged: (v) => setState(
                                            () => _editQuantity =
                                                v ?? 'الكمية المحددة',
                                          ),
                                        ),
                                        const Text('يفضل الزيادة'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'يفضل التخفيض',
                                          groupValue: _editQuantity,
                                          onChanged: (v) => setState(
                                            () => _editQuantity =
                                                v ?? 'الكمية المحددة',
                                          ),
                                        ),
                                        const Text('يفضل التخفيض'),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    const Text(
                                      'مسئولية التوصيل',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'العميل',
                                          groupValue: _deliveryResponsibility,
                                          onChanged: (v) => setState(
                                            () => _deliveryResponsibility =
                                                v ?? 'العميل',
                                          ),
                                        ),
                                        const Text('العميل'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'الشركة',
                                          groupValue: _deliveryResponsibility,
                                          onChanged: (v) => setState(
                                            () => _deliveryResponsibility =
                                                v ?? 'العميل',
                                          ),
                                        ),
                                        const Text('الشركة'),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Items Table
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: isMobile
                              ? Column(
                                  children: [
                                    ...List.generate(_descriptionControllers.length, (
                                      index,
                                    ) {
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.only(
                                          bottom: 16.0,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                controller:
                                                    _descriptionControllers[index],
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'الصنف',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _quantityControllers[index],
                                                      decoration: InputDecoration(
                                                        labelText: 'الكمية',
                                                        border:
                                                            OutlineInputBorder(),
                                                        suffixIcon: IconButton(
                                                          icon: const Icon(
                                                            Icons.calculate,
                                                            color: Colors.teal,
                                                          ),
                                                          onPressed: () async {
                                                            final currentQty =
                                                                double.tryParse(
                                                                  _quantityControllers[index]
                                                                      .text,
                                                                );
                                                            final result =
                                                                await showDialog<
                                                                  double
                                                                >(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) => CartonCalculatorDialog(
                                                                        initialQuantity:
                                                                            currentQty,
                                                                      ),
                                                                );
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            if (result !=
                                                                null) {
                                                              setState(() {
                                                                _quantityControllers[index]
                                                                    .text = result
                                                                    .toStringAsFixed(
                                                                      2,
                                                                    );
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _unitControllers[index],
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText: 'الوحدة',
                                                            border:
                                                                OutlineInputBorder(),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),

                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _priceControllers[index],
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText: 'السعر',
                                                            border:
                                                                OutlineInputBorder(),
                                                          ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: ListenableBuilder(
                                                      listenable: Listenable.merge([
                                                        _priceControllers[index],
                                                        _quantityControllers[index],
                                                      ]),
                                                      builder: (context, _) {
                                                        final price =
                                                            double.tryParse(
                                                              _priceControllers[index]
                                                                  .text,
                                                            ) ??
                                                            0;
                                                        final quantity =
                                                            double.tryParse(
                                                              _quantityControllers[index]
                                                                  .text,
                                                            ) ??
                                                            0;
                                                        return InputDecorator(
                                                          decoration: InputDecoration(
                                                            labelText: 'القيمة',
                                                            border:
                                                                OutlineInputBorder(),
                                                            filled: true,
                                                            fillColor:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .surfaceContainerHighest
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                          ),
                                                          child: Text(
                                                            (price * quantity)
                                                                .toStringAsFixed(
                                                                  2,
                                                                ),
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              if (_descriptionControllers
                                                      .length >
                                                  1) ...[
                                                const SizedBox(height: 8),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () =>
                                                        _removeItem(index),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: _addItem,
                                        icon: const Icon(Icons.add),
                                        label: const Text('إضافة صنف'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.teal,
                                        ),
                                      ),
                                    ),
                                    const Divider(thickness: 2),
                                    ValueListenableBuilder<double>(
                                      valueListenable: _totalValueNotifier,
                                      builder: (context, total, child) {
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.teal,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'الإجمالي',
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
                                  ],
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    const minWidth = 700.0;
                                    final tableWidth =
                                        constraints.maxWidth < minWidth
                                        ? minWidth
                                        : constraints.maxWidth;
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: tableWidth,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.teal,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      'الصنف',
                                                      style: _headerStyle(),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      'الوحدة',
                                                      style: _headerStyle(),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      'الكمية',
                                                      style: _headerStyle(),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      'السعر',
                                                      style: _headerStyle(),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      'القيمة',
                                                      style: _headerStyle(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...List.generate(_descriptionControllers.length, (
                                              index,
                                            ) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: TextFormField(
                                                        controller:
                                                            _descriptionControllers[index],
                                                        decoration: const InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          isDense: true,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      flex: 2,
                                                      child: TextFormField(
                                                        controller:
                                                            _unitControllers[index],
                                                        decoration: const InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          isDense: true,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      flex: 2,
                                                      child: TextFormField(
                                                        controller:
                                                            _quantityControllers[index],
                                                        decoration: InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          isDense: true,
                                                          suffixIcon: IconButton(
                                                            icon: const Icon(
                                                              Icons.calculate,
                                                              color:
                                                                  Colors.teal,
                                                              size: 20,
                                                            ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                BoxConstraints(),
                                                            onPressed: () async {
                                                              final currentQty =
                                                                  double.tryParse(
                                                                    _quantityControllers[index]
                                                                        .text,
                                                                  );
                                                              final result =
                                                                  await showDialog<
                                                                    double
                                                                  >(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (
                                                                          context,
                                                                        ) => CartonCalculatorDialog(
                                                                          initialQuantity:
                                                                              currentQty,
                                                                        ),
                                                                  );
                                                              if (result !=
                                                                  null) {
                                                                setState(() {
                                                                  _quantityControllers[index]
                                                                      .text = result
                                                                      .toStringAsFixed(
                                                                        2,
                                                                      );
                                                                });
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      flex: 2,
                                                      child: TextFormField(
                                                        controller:
                                                            _priceControllers[index],
                                                        decoration: const InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          isDense: true,
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      flex: 2,
                                                      child: ListenableBuilder(
                                                        listenable: Listenable.merge([
                                                          _priceControllers[index],
                                                          _quantityControllers[index],
                                                        ]),
                                                        builder: (context, _) {
                                                          final price =
                                                              double.tryParse(
                                                                _priceControllers[index]
                                                                    .text,
                                                              ) ??
                                                              0;
                                                          final quantity =
                                                              double.tryParse(
                                                                _quantityControllers[index]
                                                                    .text,
                                                              ) ??
                                                              0;
                                                          return Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 8,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              (price * quantity)
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    if (_descriptionControllers
                                                            .length >
                                                        1)
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                          size: 20,
                                                        ),
                                                        onPressed: () =>
                                                            _removeItem(index),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }),
                                            const SizedBox(height: 8),
                                            Center(
                                              child: TextButton.icon(
                                                onPressed: _addItem,
                                                icon: const Icon(Icons.add),
                                                label: const Text('إضافة صنف'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.teal,
                                                ),
                                              ),
                                            ),
                                            const Divider(thickness: 2),
                                            ValueListenableBuilder<double>(
                                              valueListenable:
                                                  _totalValueNotifier,
                                              builder: (context, total, child) {
                                                return Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'الإجمالي',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      Text(
                                                        total.toStringAsFixed(
                                                          2,
                                                        ),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Payment Schedule
                      YarnInstallmentWidget(
                        durationControllers: _installmentDurationControllers,
                        valueControllers: _installmentValueControllers,
                        isMobile: isMobile,
                        onAddInstallment: _addInstallment,
                        onRemoveInstallment: _removeInstallment,
                      ),
                      const SizedBox(height: 20),

                      // Notes
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

                      // Action Buttons
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
                                backgroundColor: Colors.red,
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
          },
        ),
      ),
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
  }
}
