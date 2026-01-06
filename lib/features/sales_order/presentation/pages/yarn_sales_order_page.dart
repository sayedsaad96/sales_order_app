import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:annex_sales_order/core/utils/responsive_constants.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/data/models/yarn_sales_order.dart';
import 'package:annex_sales_order/features/sales_order/data/datasources/yarn_invoice_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/pdf/yarn_pdf_generator.dart';
import 'package:annex_sales_order/features/sales_order/presentation/widgets/yarn_installment_widget.dart';
import 'package:annex_sales_order/features/sales_order/presentation/widgets/yarn_specific_widgets.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/saved_yarn_invoices_page.dart';

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
  final _salesResponsibleController = TextEditingController();
  final _notesController = TextEditingController();
  String? _paymentMethod;

  // Selected values
  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;
  String? _selectedBranch = 'القاهرة';
  String _editQuantity = 'الكمية المحددة';
  String _deliveryResponsibility = 'العميل';

  final Map<String, bool> _orderTypes = {
    'غزل': true,
  };

  // Dynamic lists
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _unitControllers = [];
  final List<TextEditingController> _priceControllers = [];

  // Installments
  final List<TextEditingController> _installmentDurationControllers = [];
  final List<TextEditingController> _installmentValueControllers = [];

  final ValueNotifier<double> _totalValueNotifier = ValueNotifier(0.0);
  bool _saveAsNew = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.existingOrder != null) {
      final order = widget.existingOrder!;
      _snController.text = order.sn ?? '';
      _customerNameController.text = order.customerName ?? '';
      _contactNameController.text = order.contactName ?? '';
      _mobileNumberController.text = order.mobileNumber ?? '';
      _regionController.text = order.region ?? '';
      _deliveryPlaceController.text = order.deliveryPlace ?? '';
      _paymentMethod = _mapPaymentMethod(order.paymentMethod);
      _salesResponsibleController.text = order.salesResponsible ?? '';
      _notesController.text = order.notes ?? '';
      _orderDate = order.orderDate;
      _deliveryDate = order.deliveryDate;
      _selectedBranch = order.branch ?? 'القاهرة';
      _editQuantity = order.editQuantity ?? 'الكمية المحددة';
      _deliveryResponsibility = order.deliveryResponsibility;

      _orderTypes.clear();
      _orderTypes['غزل'] = order.orderTypes.contains('غزل');

      for (var item in order.items) {
        _addItem(
          description: item.description,
          quantity: item.quantity,
          unit: item.unit,
          price: item.price,
        );
      }
      if (order.items.isEmpty) _addItem();

      for (var inst in order.installments) {
        _addInstallment(
          duration: inst.duration,
          value: inst.value,
        );
      }
      if (order.installments.isEmpty) _addInstallment();
    } else {
      _snController.text = 'YSO-${DateTime.now().microsecond}';
      _addItem();
      _addInstallment();
      _loadCurrentUser();
    }
    _calculateTotal();
  }

  YarnSalesOrder _createOrderObject() {
    final List<YarnSalesOrderItem> items = [];
    for (int i = 0; i < _descriptionControllers.length; i++) {
      final desc = _descriptionControllers[i].text;
      final qty = double.tryParse(_quantityControllers[i].text) ?? 0.0;
      final unit = _unitControllers[i].text;
      final price = double.tryParse(_priceControllers[i].text) ?? 0.0;
      if (desc.isNotEmpty || qty > 0) {
        items.add(YarnSalesOrderItem(
          description: desc,
          quantity: qty,
          unit: unit,
          price: price,
        ));
      }
    }

    final List<YarnInstallment> installments = [];
    for (int i = 0; i < _installmentDurationControllers.length; i++) {
      final duration = _installmentDurationControllers[i].text;
      final value = _installmentValueControllers[i].text;
      if (duration.isNotEmpty || value.isNotEmpty) {
        installments.add(YarnInstallment(duration: duration, value: value));
      }
    }

    return YarnSalesOrder(
      sn: _snController.text,
      customerName: _customerNameController.text,
      contactName: _contactNameController.text,
      mobileNumber: _mobileNumberController.text,
      region: _regionController.text,
      deliveryPlace: _deliveryPlaceController.text,
      paymentMethod: _paymentMethod,
      salesResponsible: _salesResponsibleController.text,
      notes: _notesController.text,
      orderDate: _orderDate,
      deliveryDate: _deliveryDate,
      branch: _selectedBranch,
      editQuantity: _editQuantity,
      deliveryResponsibility: _deliveryResponsibility,
      orderTypes: _orderTypes.entries.where((e) => e.value).map((e) => e.key).toList(),
      items: items,
      installments: installments,
    );
  }

  void _addItem({String? description, double? quantity, String? unit, double? price}) {
    setState(() {
      _descriptionControllers.add(TextEditingController(text: description ?? ''));
      _quantityControllers.add(TextEditingController(text: quantity?.toString() ?? ''));
      _unitControllers.add(TextEditingController(text: unit ?? 'KG'));
      _priceControllers.add(TextEditingController(text: price?.toString() ?? ''));
      
      _quantityControllers.last.addListener(_calculateTotal);
      _priceControllers.last.addListener(_calculateTotal);
    });
  }

  void _removeItem(int index) {
    if (_descriptionControllers.length > 1) {
      setState(() {
        _descriptionControllers[index].dispose();
        _quantityControllers[index].dispose();
        _unitControllers[index].dispose();
        _priceControllers[index].dispose();

        _descriptionControllers.removeAt(index);
        _quantityControllers.removeAt(index);
        _unitControllers.removeAt(index);
        _priceControllers.removeAt(index);
        _calculateTotal();
      });
    }
  }

  void _addInstallment({String? duration, String? value}) {
    setState(() {
      _installmentDurationControllers.add(TextEditingController(text: duration ?? ''));
      _installmentValueControllers.add(TextEditingController(text: value ?? ''));
    });
  }

  void _removeInstallment(int index) {
    if (_installmentDurationControllers.length > 1) {
      setState(() {
        _installmentDurationControllers[index].dispose();
        _installmentValueControllers[index].dispose();
        _installmentDurationControllers.removeAt(index);
        _installmentValueControllers.removeAt(index);
      });
    }
  }

   String? _mapPaymentMethod(String? method) {
    if (method == null) return null;
    final mapping = {
      'Cash': 'كاش',
      'Bank transfer': 'تحويل بنكي',
      'Credit': 'اجل شهر',
      'Cheque': 'تحويل بنكي',
      'Other': 'كاش',
    };
    return mapping[method] ?? method;
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

  void _calculateTotal() {
    double total = 0.0;
    for (int i = 0; i < _quantityControllers.length; i++) {
      final qty = double.tryParse(_quantityControllers[i].text) ?? 0.0;
      final price = double.tryParse(_priceControllers[i].text) ?? 0.0;
      total += qty * price;
    }
    _totalValueNotifier.value = total;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newOrderData = _createOrderObject();
        
        if (widget.existingOrder != null && !_saveAsNew) {
           // Update existing order
           widget.existingOrder!.sn = newOrderData.sn;
           widget.existingOrder!.orderDate = newOrderData.orderDate;
           widget.existingOrder!.deliveryDate = newOrderData.deliveryDate;
           widget.existingOrder!.branch = newOrderData.branch;
           widget.existingOrder!.customerName = newOrderData.customerName;
           widget.existingOrder!.contactName = newOrderData.contactName;
           widget.existingOrder!.mobileNumber = newOrderData.mobileNumber;
           widget.existingOrder!.region = newOrderData.region;
           widget.existingOrder!.deliveryPlace = newOrderData.deliveryPlace;
           widget.existingOrder!.paymentMethod = newOrderData.paymentMethod;
           widget.existingOrder!.salesResponsible = newOrderData.salesResponsible;
           widget.existingOrder!.notes = newOrderData.notes;
           widget.existingOrder!.editQuantity = newOrderData.editQuantity;
           widget.existingOrder!.deliveryResponsibility = newOrderData.deliveryResponsibility;
           widget.existingOrder!.orderTypes = newOrderData.orderTypes;
           widget.existingOrder!.items = newOrderData.items;
           widget.existingOrder!.installments = newOrderData.installments;

           await widget.existingOrder!.save();
        } else {
           await YarnInvoiceLocalDataSource().saveInvoice(newOrderData);
        }

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
                      errorBuilder: (context, error, stackTrace) => const Icon(CupertinoIcons.doc_text_fill, size: 80, color: Colors.teal),
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
        final newOrderData = _createOrderObject();
        
        // Auto-save logic
        if (widget.existingOrder != null && !_saveAsNew) {
           widget.existingOrder!.sn = newOrderData.sn;
           widget.existingOrder!.orderDate = newOrderData.orderDate;
           widget.existingOrder!.deliveryDate = newOrderData.deliveryDate;
           widget.existingOrder!.branch = newOrderData.branch;
           widget.existingOrder!.customerName = newOrderData.customerName;
           widget.existingOrder!.contactName = newOrderData.contactName;
           widget.existingOrder!.mobileNumber = newOrderData.mobileNumber;
           widget.existingOrder!.region = newOrderData.region;
           widget.existingOrder!.deliveryPlace = newOrderData.deliveryPlace;
           widget.existingOrder!.paymentMethod = newOrderData.paymentMethod;
           widget.existingOrder!.salesResponsible = newOrderData.salesResponsible;
           widget.existingOrder!.notes = newOrderData.notes;
           widget.existingOrder!.editQuantity = newOrderData.editQuantity;
           widget.existingOrder!.deliveryResponsibility = newOrderData.deliveryResponsibility;
           widget.existingOrder!.orderTypes = newOrderData.orderTypes;
           widget.existingOrder!.items = newOrderData.items;
           widget.existingOrder!.installments = newOrderData.installments;

           await widget.existingOrder!.save();
        } else {
           await YarnInvoiceLocalDataSource().saveInvoice(newOrderData);
        }

        final pdf = await YarnPdfGenerator.generate(newOrderData);
        final bytes = await pdf.save();

        Directory? directory;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
        directory ??= await getApplicationDocumentsDirectory();

        final safeName = (newOrderData.customerName ?? 'Client').replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
        final fileName = '${safeName}_${newOrderData.sn}.pdf';
        
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
      _saveAsNew = false;
      _snController.text = 'YSO-${DateTime.now().microsecond}';
// ... rest of reset

      _customerNameController.clear();
      _contactNameController.clear();
      _mobileNumberController.clear();
      _regionController.clear();
      _deliveryPlaceController.clear();
      _notesController.clear();
      _paymentMethod = null;
      _selectedBranch = "القاهرة";
      _deliveryResponsibility = "العميل";
      _editQuantity = "الكمية المحددة";
      _orderDate = DateTime.now();
      _deliveryDate = null;

      _orderTypes['غزل'] = true;

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
                  icon: const Icon(CupertinoIcons.list_dash),
                  onPressed: widget.onMenuPressed,
                  tooltip: 'Menu',
                )
              : null,
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
                        paymentMethod: _paymentMethod,
                        onPaymentMethodChanged: (v) => setState(() => _paymentMethod = v),
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
                      const SizedBox(height: 20),
                      YarnInstallmentWidget(
                        durationControllers: _installmentDurationControllers,
                        valueControllers: _installmentValueControllers,
                        isMobile: isMobile,
                        onAddInstallment: _addInstallment,
                        onRemoveInstallment: _removeInstallment,
                      ),
                      const SizedBox(height: 30),
                      const SizedBox(height: 20),
                      if (widget.existingOrder != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: CheckboxListTile(
                            title: const Text('حفظ كفاتورة جديدة (نسخة)'),
                            value: _saveAsNew,
                            onChanged: (val) => setState(() => _saveAsNew = val ?? false),
                          ),
                        ),
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
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _saveInvoice,
            icon: const Icon(CupertinoIcons.floppy_disk, size: 24),
            label: const Text('حفظ', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
            icon: const Icon(CupertinoIcons.doc_text_fill, size: 24),
            label: const Text('PDF', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
