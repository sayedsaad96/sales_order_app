import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/responsive_constants.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../user/data/datasources/user_local_data_source.dart';
import '../../data/models/yarn_sales_order.dart';
import '../../data/datasources/yarn_invoice_local_data_source.dart';
import '../../pdf/yarn_pdf_generator.dart';
import '../widgets/yarn_installment_widget.dart';
import '../widgets/yarn_specific_widgets.dart';
import 'saved_yarn_invoices_page.dart';

class YarnSalesOrderPage extends StatefulWidget {
  final YarnSalesOrder? existingOrder;
  final VoidCallback? onMenuPressed;
  const YarnSalesOrderPage({super.key, this.existingOrder, this.onMenuPressed});

  @override
  State<YarnSalesOrderPage> createState() => _YarnSalesOrderPageState();
}

class _YarnSalesOrderPageState extends State<YarnSalesOrderPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _snController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _regionController = TextEditingController();
  final _deliveryPlaceController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _salesResponsibleController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected values
  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;
  String? _selectedBranch = 'القاهرة';
  String _editQuantity = 'الكمية المحددة';
  String _deliveryResponsibility = 'العميل';

  final Map<String, bool> _orderTypes = {
    'غزل': true,
    'قماش': false,
  };

  // Dynamic lists
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _unitControllers = [];
  final List<TextEditingController> _priceControllers = [];

  // Installments
  final List<TextEditingController> _installmentDurationControllers = [];
  final List<TextEditingController> _installmentValueControllers = [];

  final ValueNotifier<double> _totalValueNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.existingOrder != null) {
      _loadExistingOrder();
    } else {
      _snController.text = 'YSO-${DateTime.now().microsecond}';
      _loadCurrentUser();
      _addItem();
      _addInstallment();
    }
  }

  Future<void> _loadCurrentUser() async {
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

  void _loadExistingOrder() {
    final order = widget.existingOrder!;
    _snController.text = order.sn ?? '';
    _orderDate = order.orderDate;
    _deliveryDate = order.deliveryDate;
    _selectedBranch = order.branch;
    _customerNameController.text = order.customerName ?? '';
    _contactNameController.text = order.contactName ?? '';
    _mobileNumberController.text = order.mobileNumber ?? '';
    _regionController.text = order.region ?? '';
    _deliveryPlaceController.text = order.deliveryPlace ?? '';
    _paymentMethodController.text = order.paymentMethod ?? '';
    _salesResponsibleController.text = order.salesResponsible ?? '';
    _notesController.text = order.notes ?? '';
    _editQuantity = order.editQuantity ?? 'الكمية المحددة';
    _deliveryResponsibility = order.deliveryResponsibility;

    _orderTypes.updateAll((key, value) => order.orderTypes.contains(key));

    for (var item in order.items) {
      _addItem(
        description: item.description,
        quantity: item.quantity,
        unit: item.unit,
        price: item.price,
      );
    }

    for (var inst in order.installments) {
      _addInstallment(duration: inst.duration, value: inst.value);
    }

    _calculateTotal();
  }

  void _addItem({
    String? description,
    double? quantity,
    String? unit,
    double? price,
  }) {
    setState(() {
      final descCtrl = TextEditingController(text: description);
      final qtyCtrl = TextEditingController(text: quantity?.toString() ?? '');
      final unitCtrl = TextEditingController(text: unit ?? 'KG');
      final priceCtrl = TextEditingController(text: price?.toString() ?? '');

      descCtrl.addListener(_calculateTotal);
      qtyCtrl.addListener(_calculateTotal);
      priceCtrl.addListener(_calculateTotal);

      _descriptionControllers.add(descCtrl);
      _quantityControllers.add(qtyCtrl);
      _unitControllers.add(unitCtrl);
      _priceControllers.add(priceCtrl);
    });
  }

  void _removeItem(int index) {
    if (_descriptionControllers.length > 1) {
      setState(() {
        _descriptionControllers.removeAt(index).dispose();
        _quantityControllers.removeAt(index).dispose();
        _unitControllers.removeAt(index).dispose();
        _priceControllers.removeAt(index).dispose();
      });
      _calculateTotal();
    }
  }

  void _addInstallment({String? duration, String? value}) {
    setState(() {
      _installmentDurationControllers
          .add(TextEditingController(text: duration));
      _installmentValueControllers
          .add(TextEditingController(text: value ?? ''));
    });
  }

  void _removeInstallment(int index) {
      setState(() {
        if (_installmentDurationControllers.length > 1) {
           _installmentDurationControllers.removeAt(index).dispose();
           _installmentValueControllers.removeAt(index).dispose();
        }
      });
  }

  void _calculateTotal() {
    double total = 0;
    for (int i = 0; i < _descriptionControllers.length; i++) {
      double qty = double.tryParse(_quantityControllers[i].text) ?? 0;
      double price = double.tryParse(_priceControllers[i].text) ?? 0;
      total += qty * price;
    }
    _totalValueNotifier.value = total;
  }

  YarnSalesOrder _createOrderObject() {
    final List<YarnSalesOrderItem> items = [];
    for (int i = 0; i < _descriptionControllers.length; i++) {
        final description = _descriptionControllers[i].text;
        final price = double.tryParse(_priceControllers[i].text) ?? 0;
        final quantity = double.tryParse(_quantityControllers[i].text) ?? 0;

        if (description.isNotEmpty || price > 0 || quantity > 0) {
          items.add(YarnSalesOrderItem(
            description: description,
            quantity: quantity,
            unit: _unitControllers[i].text,
            price: price,
          ));
        }
    }

    final List<YarnInstallment> installments = [];
    for (int i = 0; i < _installmentDurationControllers.length; i++) {
      final duration = _installmentDurationControllers[i].text;
      final value = _installmentValueControllers[i].text;
      if (duration.isNotEmpty || value.isNotEmpty) {
        installments.add(YarnInstallment(
          duration: duration,
          value: value,
        ));
      }
    }

    return (widget.existingOrder ?? YarnSalesOrder(orderDate: _orderDate))
      ..sn = _snController.text
      ..orderDate = _orderDate
      ..deliveryDate = _deliveryDate
      ..branch = _selectedBranch ?? 'القاهرة'
      ..customerName = _customerNameController.text
      ..contactName = _contactNameController.text
      ..mobileNumber = _mobileNumberController.text
      ..region = _regionController.text
      ..deliveryPlace = _deliveryPlaceController.text
      ..paymentMethod = _paymentMethodController.text
      ..salesResponsible = _salesResponsibleController.text
      ..notes = _notesController.text
      ..editQuantity = _editQuantity
      ..deliveryResponsibility = _deliveryResponsibility
      ..orderTypes = _orderTypes.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList()
      ..items = items
      ..installments = installments;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      try {
        final order = _createOrderObject();
        await YarnInvoiceLocalDataSource().saveInvoice(order);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
        );
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
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.picture_as_pdf, size: 80, color: Colors.teal),
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
        final order = _createOrderObject();
        final pdf = await YarnPdfGenerator.generate(order);
        final bytes = await pdf.save();

        Directory? directory;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
        directory ??= await getApplicationDocumentsDirectory();

        final safeCustomerName = order.customerName?.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '') ?? 'Client';
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
      _orderDate = DateTime.now();
      _deliveryDate = null;

      _orderTypes.updateAll((key, value) => key == 'غزل');

      for (var c in _descriptionControllers) { c.dispose(); }
      for (var c in _quantityControllers) { c.dispose(); }
      for (var c in _unitControllers) { c.dispose(); }
      for (var c in _priceControllers) { c.dispose(); }
      _descriptionControllers.clear();
      _quantityControllers.clear();
      _unitControllers.clear();
      _priceControllers.clear();
      _addItem();

      for (var c in _installmentDurationControllers) { c.dispose(); }
      for (var c in _installmentValueControllers) { c.dispose(); }
      _installmentDurationControllers.clear();
      _installmentValueControllers.clear();
      _addInstallment();

      _loadCurrentUser();
      _calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
            primaryColor: Colors.teal,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.teal,
              secondary: Colors.tealAccent,
            ),
          ),
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
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < ResponsiveConstants.kMobileBreakpoint;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      YarnOrderHeader(
                        snController: _snController,
                        orderDate: _orderDate,
                        onDateChanged: (date) => setState(() => _orderDate = date),
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 20),
                      YarnBranchAndTypeSection(
                        selectedBranch: _selectedBranch,
                        orderTypes: _orderTypes,
                        onBranchChanged: (v) => setState(() => _selectedBranch = v),
                        onTypeChanged: (key, v) => setState(() => _orderTypes[key] = v),
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 20),
                      YarnCustomerInfoSection(
                        customerNameController: _customerNameController,
                        contactNameController: _contactNameController,
                        mobileNumberController: _mobileNumberController,
                        regionController: _regionController,
                        deliveryPlaceController: _deliveryPlaceController,
                        paymentMethodController: _paymentMethodController,
                        salesResponsibleController: _salesResponsibleController,
                        deliveryDate: _deliveryDate,
                        editQuantity: _editQuantity,
                        deliveryResponsibility: _deliveryResponsibility,
                        onDeliveryDateChanged: (date) => setState(() => _deliveryDate = date),
                        onEditQuantityChanged: (v) => setState(() => _editQuantity = v),
                        onDeliveryResponsibilityChanged: (v) => setState(() => _deliveryResponsibility = v),
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 20),
                      YarnItemsTable(
                        descriptionControllers: _descriptionControllers,
                        quantityControllers: _quantityControllers,
                        unitControllers: _unitControllers,
                        priceControllers: _priceControllers,
                        totalValueNotifier: _totalValueNotifier,
                        onAddItem: _addItem,
                        onRemoveItem: _removeItem,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 20),
                      YarnInstallmentWidget(
                        durationControllers: _installmentDurationControllers,
                        valueControllers: _installmentValueControllers,
                        isMobile: isMobile,
                        onAddInstallment: _addInstallment,
                        onRemoveInstallment: _removeInstallment,
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
                      _buildActionButtons(),
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

  Widget _buildActionButtons() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _saveInvoice,
            icon: const Icon(Icons.save),
            label: const Text('حفظ', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: _generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('إنشاء PDF', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _snController.dispose();
    _customerNameController.dispose();
    _contactNameController.dispose();
    _mobileNumberController.dispose();
    _regionController.dispose();
    _deliveryPlaceController.dispose();
    _paymentMethodController.dispose();
    _salesResponsibleController.dispose();
    _notesController.dispose();
    
    for (var c in _descriptionControllers) { c.dispose(); }
    for (var c in _quantityControllers) { c.dispose(); }
    for (var c in _unitControllers) { c.dispose(); }
    for (var c in _priceControllers) { c.dispose(); }
    for (var c in _installmentDurationControllers) { c.dispose(); }
    for (var c in _installmentValueControllers) { c.dispose(); }
    _totalValueNotifier.dispose();
    super.dispose();
  }
}
