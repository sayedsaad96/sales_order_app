
import 'package:flutter/material.dart';
import '../../data/models/fabrics_cm_sales_order.dart';
import '../../data/datasources/fabrics_cm_invoice_local_data_source.dart';
import '../../../user/data/datasources/user_local_data_source.dart';
import '../../pdf/fabrics_cm_pdf_generator.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FabricsCmOrderProvider extends ChangeNotifier {
  // Header Controllers
  final snController = TextEditingController();
  final customerNameController = TextEditingController();
  final salesResponsibleController = TextEditingController();
  final paymentMethodController = TextEditingController(); // used as dropdown in UI typically, but keeping string here
  final notesController = TextEditingController();
  
  // Header State
  DateTime orderDate = DateTime.now();
  DateTime? deliveryDate;
  String? orderType; // Legacy
  String? paymentMethod;
  String? selectedBranch = 'المحلة';
  Map<String, bool> orderTypes = {'قماش': true, 'CM': false};

  // Items State (Dynamic Controllers)
  final List<TextEditingController> quantityControllers = [];

  final List<TextEditingController> lycraNumControllers = [];
  final List<TextEditingController> lycraPercentControllers = [];
  final List<TextEditingController> fabricTypeControllers = [];
  final List<TextEditingController> yarnCountControllers = [];
  final List<TextEditingController> yarnTypeControllers = [];
  final List<TextEditingController> gaugeControllers = [];
  final List<TextEditingController> widthControllers = [];
  final List<TextEditingController> stitchLengthControllers = [];

  final List<TextEditingController> spinningCompanyControllers = [];
  final List<TextEditingController> priceControllers = [];

  double get totalValue {
    double total = 0;
    for (int i = 0; i < quantityControllers.length; i++) {
        final qty = double.tryParse(quantityControllers[i].text) ?? 0;
        final price = double.tryParse(priceControllers[i].text) ?? 0;
        total += qty * price;
    }
    return total;
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  final FabricsCmSalesOrder? existingOrder;

  FabricsCmOrderProvider({this.existingOrder}) {
    _init();
  }

  void _init() {
    if (existingOrder != null) {
      _loadExistingOrder(existingOrder!);
    } else {
      resetForm();
    }
  }

  void _loadExistingOrder(FabricsCmSalesOrder order) {
    snController.text = order.sn ?? '';
    customerNameController.text = order.customerName ?? '';
    paymentMethodController.text = order.paymentMethod ?? '';
    notesController.text = order.notes ?? '';
    salesResponsibleController.text = order.salesResponsible ?? '';
    
    orderDate = order.orderDate;
    deliveryDate = order.deliveryDate;
    orderType = order.orderType;
    paymentMethod = _mapPaymentMethod(order.paymentMethod);
    selectedBranch = order.branch;

    // Reset types
    orderTypes = {'قماش': false, 'CM': false};
    if (order.orderTypesList.isNotEmpty) {
      for (var t in order.orderTypesList) {
        if (orderTypes.containsKey(t)) {
            orderTypes[t] = true;
        }
      }
    } else if (order.orderType != null) {
       // Legacy fallback
       if (order.orderType!.contains('قماش')) orderTypes['قماش'] = true;
       if (order.orderType!.contains('CM')) orderTypes['CM'] = true;
    }

    // Clear dynamic lists before loading
    for (var c in quantityControllers) { c.dispose(); }

    for (var c in lycraNumControllers) { c.dispose(); }
    for (var c in lycraPercentControllers) { c.dispose(); }
    for (var c in fabricTypeControllers) { c.dispose(); }
    for (var c in yarnCountControllers) { c.dispose(); }
    for (var c in yarnTypeControllers) { c.dispose(); }
    for (var c in gaugeControllers) { c.dispose(); }
    for (var c in widthControllers) { c.dispose(); }
    for (var c in stitchLengthControllers) { c.dispose(); }

    for (var c in spinningCompanyControllers) { c.dispose(); }
    for (var c in priceControllers) { c.dispose(); }

    quantityControllers.clear();

    lycraNumControllers.clear();
    lycraPercentControllers.clear();
    fabricTypeControllers.clear();
    yarnCountControllers.clear();
    yarnTypeControllers.clear();
    gaugeControllers.clear();
    widthControllers.clear();
    stitchLengthControllers.clear();

    spinningCompanyControllers.clear();
    priceControllers.clear();

    for (var item in order.items) {
      addItem(
        quantity: item.quantity,

        lycraNum: item.lycraNumber,
        lycraPercent: item.lycraPercentage,
        fabricType: item.fabricType,
        yarnCount: item.yarnCount,
        yarnType: item.yarnType,
        gauge: item.gauge,
        width: item.widthInches,
        stitchLen: item.stitchLength,

        spinCo: item.spinningCompany,
        price: item.price,
      );
    }
    
    notifyListeners();
  }

  void resetForm() {
    snController.text = 'FCM-${DateTime.now().microsecond}';
    customerNameController.clear();
    paymentMethodController.clear();
    notesController.clear();
    
    orderDate = DateTime.now();
    deliveryDate = null;
    orderType = null;
    paymentMethod = null;
    selectedBranch = 'المحلة';
    orderTypes = {'قماش': true, 'CM': false};

    // Clear dynamic lists
    for (var c in quantityControllers) { c.dispose(); }

    for (var c in lycraNumControllers) { c.dispose(); }
    for (var c in lycraPercentControllers) { c.dispose(); }
    for (var c in fabricTypeControllers) { c.dispose(); }
    for (var c in yarnCountControllers) { c.dispose(); }
    for (var c in yarnTypeControllers) { c.dispose(); }
    for (var c in gaugeControllers) { c.dispose(); }
    for (var c in widthControllers) { c.dispose(); }
    for (var c in stitchLengthControllers) { c.dispose(); }

    for (var c in spinningCompanyControllers) { c.dispose(); }
    for (var c in priceControllers) { c.dispose(); }

    quantityControllers.clear();

    lycraNumControllers.clear();
    lycraPercentControllers.clear();
    fabricTypeControllers.clear();
    yarnCountControllers.clear();
    yarnTypeControllers.clear();
    gaugeControllers.clear();
    widthControllers.clear();
    stitchLengthControllers.clear();

    spinningCompanyControllers.clear();
    priceControllers.clear();

    _loadCurrentUser();
    addItem(); // Add one initial empty row
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = UserLocalDataSource().getUser();
      if (user != null) {
        salesResponsibleController.text = user.fullName;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load user: $e');
    }
  }

  void addItem({
    double? quantity,

    String? lycraNum,
    double? lycraPercent,
    String? fabricType,
    String? yarnCount,
    String? yarnType,
    int? gauge,
    double? width,
    double? stitchLen,

    String? spinCo,
    double? price,
  }) {
    final qc = TextEditingController(text: quantity?.toString() ?? '');

    final lnc = TextEditingController(text: lycraNum ?? '');
    final lpc = TextEditingController(text: lycraPercent?.toString() ?? '');
    final ftc = TextEditingController(text: fabricType ?? '');
    final ycc = TextEditingController(text: yarnCount ?? '');
    final ytc = TextEditingController(text: yarnType ?? '');
    final gc = TextEditingController(text: gauge?.toString() ?? '');
    final wc = TextEditingController(text: width?.toString() ?? '');
    final slc = TextEditingController(text: stitchLen?.toString() ?? '');

    final scc = TextEditingController(text: spinCo ?? '');
    final pc = TextEditingController(text: price?.toString() ?? '');

    void listener() => notifyListeners();
    qc.addListener(listener);
    pc.addListener(listener);

    quantityControllers.add(qc);

    lycraNumControllers.add(lnc);
    lycraPercentControllers.add(lpc);
    fabricTypeControllers.add(ftc);
    yarnCountControllers.add(ycc);
    yarnTypeControllers.add(ytc);
    gaugeControllers.add(gc);
    widthControllers.add(wc);
    stitchLengthControllers.add(slc);

    spinningCompanyControllers.add(scc);
    priceControllers.add(pc);

    notifyListeners();
  }

  void removeItem(int index) {
    if (quantityControllers.length > 1) {
      quantityControllers[index].dispose();

      lycraNumControllers[index].dispose();
      lycraPercentControllers[index].dispose();
      fabricTypeControllers[index].dispose();
      yarnCountControllers[index].dispose();
      yarnTypeControllers[index].dispose();
      gaugeControllers[index].dispose();
      widthControllers[index].dispose();
      stitchLengthControllers[index].dispose();

      spinningCompanyControllers[index].dispose();
      priceControllers[index].dispose();

      quantityControllers.removeAt(index);

      lycraNumControllers.removeAt(index);
      lycraPercentControllers.removeAt(index);
      fabricTypeControllers.removeAt(index);
      yarnCountControllers.removeAt(index);
      yarnTypeControllers.removeAt(index);
      gaugeControllers.removeAt(index);
      widthControllers.removeAt(index);
      stitchLengthControllers.removeAt(index);

      spinningCompanyControllers.removeAt(index);
      priceControllers.removeAt(index);

      notifyListeners();
    }
  }

  // Setters for UI
  void setDeliveryDate(DateTime? date) {
    deliveryDate = date;
    notifyListeners();
  }

  void setOrderType(String? type) {
    orderType = type;
    notifyListeners();
  }

  void setPaymentMethod(String? method) {
    paymentMethod = method;
    notifyListeners();
  }

  void setBranch(String? value) {
    selectedBranch = value;
    notifyListeners();
  }

  String? _mapPaymentMethod(String? method) {
    if (method == null) return null;
    final mapping = {
      'Cash': 'كاش',
      'Bank transfer': 'تحويل بنكي',
      'Credit': 'اجل شهر', // Approximating Credit to 'اجل شهر'
      'Cheque': 'تحويل بنكي', // Fallback
      'Other': 'كاش', // Fallback
    };
    return mapping[method] ?? method;
  }

  void setOrderTypeState(String key, bool value) {
    orderTypes[key] = value;
    notifyListeners();
  }

  FabricsCmSalesOrder _createOrderObject() {
    final List<FabricsCmLineItem> items = [];
    for (int i = 0; i < quantityControllers.length; i++) {
        final qty = double.tryParse(quantityControllers[i].text) ?? 0;
        final price = double.tryParse(priceControllers[i].text) ?? 0;
        
        // Basic validation: skip empty rows where key fields are missing
        if (qty > 0 || price > 0) {
           items.add(FabricsCmLineItem(
             quantity: qty,

             lycraNumber: lycraNumControllers[i].text,
             lycraPercentage: double.tryParse(lycraPercentControllers[i].text) ?? 0,
             fabricType: fabricTypeControllers[i].text,
             yarnCount: yarnCountControllers[i].text,
             yarnType: yarnTypeControllers[i].text,
             gauge: int.tryParse(gaugeControllers[i].text) ?? 0,
             widthInches: double.tryParse(widthControllers[i].text) ?? 0,
             stitchLength: double.tryParse(stitchLengthControllers[i].text) ?? 0,

             spinningCompany: spinningCompanyControllers[i].text,
             price: price,
           ));
        }
    }

    final typesList = orderTypes.entries.where((e) => e.value).map((e) => e.key).toList();

    return FabricsCmSalesOrder(
      sn: snController.text,
      customerName: customerNameController.text,
      salesResponsible: salesResponsibleController.text,
      paymentMethod: paymentMethod,
      deliveryDate: deliveryDate,
      orderType: typesList.join(' + '), // Keep legacy sync
      orderTypesList: typesList,
      branch: selectedBranch,
      orderDate: orderDate,
      notes: notesController.text,
      items: items,
    );
  }

  bool saveAsNew = false;

  void setSaveAsNew(bool value) {
    saveAsNew = value;
    notifyListeners();
  }

  Future<bool> saveOrder(BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return false;
    
    // Check if at least one item
    bool hasItems = false;
     for (int i = 0; i < quantityControllers.length; i++) {
        if ((double.tryParse(quantityControllers[i].text) ?? 0) > 0) {
            hasItems = true;
            break;
        }
     }
     if (!hasItems) {
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل بكمية صحيحة')),
         );
         return false;
     }

    _isSaving = true;
    notifyListeners();

    try {
      final newOrderData = _createOrderObject();
      
      if (existingOrder != null && !saveAsNew) {
          // Update existing order
          existingOrder!.sn = newOrderData.sn;
          existingOrder!.customerName = newOrderData.customerName;
          existingOrder!.salesResponsible = newOrderData.salesResponsible;
          existingOrder!.paymentMethod = newOrderData.paymentMethod;
          existingOrder!.deliveryDate = newOrderData.deliveryDate;
          existingOrder!.orderType = newOrderData.orderType;
          existingOrder!.orderTypesList = newOrderData.orderTypesList;
          existingOrder!.branch = newOrderData.branch;
          existingOrder!.orderDate = newOrderData.orderDate;
          existingOrder!.notes = newOrderData.notes;
          existingOrder!.items = newOrderData.items;
          
          await existingOrder!.save();
      } else {
          // Save as new (or first time save)
          await FabricsCmInvoiceLocalDataSource().saveInvoice(newOrderData);
      }
      
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
      );
      return false;
    }
  }

  Future<void> generatePdf(BuildContext context, GlobalKey<FormState> formKey) async {
      if (!formKey.currentState!.validate()) return;
      
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
        final newOrderData = _createOrderObject();
        
        // Auto-save logic
        if (existingOrder != null && !saveAsNew) {
           existingOrder!.sn = newOrderData.sn;
           existingOrder!.customerName = newOrderData.customerName;
           existingOrder!.salesResponsible = newOrderData.salesResponsible;
           existingOrder!.paymentMethod = newOrderData.paymentMethod;
           existingOrder!.deliveryDate = newOrderData.deliveryDate;
           existingOrder!.orderType = newOrderData.orderType;
           existingOrder!.orderTypesList = newOrderData.orderTypesList;
           existingOrder!.branch = newOrderData.branch;
           existingOrder!.orderDate = newOrderData.orderDate;
           existingOrder!.items = newOrderData.items;
           existingOrder!.notes = newOrderData.notes;
           await existingOrder!.save();
        } else {
           await FabricsCmInvoiceLocalDataSource().saveInvoice(newOrderData);
        }

        // Use the data (either new or updated) for PDF
        // Note: For PDF we can use newOrderData as it holds the current UI values
        final pdf = await FabricsCmPdfGenerator.generate(newOrderData);
        final bytes = await pdf.save();

        if (!context.mounted) return;
        Navigator.of(context).pop(); // Dismiss loading

        // Save logic similar to other pages
        Directory? directory;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
        directory ??= await getApplicationDocumentsDirectory();

        final safeName = (newOrderData.customerName ?? 'Client').replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
        final fileName = '${safeName}_${newOrderData.sn}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (!context.mounted) return;
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
      } catch (e) {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')),
        );
      }
  }

  @override
  void dispose() {
    snController.dispose();
    customerNameController.dispose();
    salesResponsibleController.dispose();
    paymentMethodController.dispose();
    notesController.dispose();
    
    for (var c in quantityControllers) { c.dispose(); }

    for (var c in lycraNumControllers) { c.dispose(); }
    for (var c in lycraPercentControllers) { c.dispose(); }
    for (var c in fabricTypeControllers) { c.dispose(); }
    for (var c in yarnCountControllers) { c.dispose(); }
    for (var c in yarnTypeControllers) { c.dispose(); }
    for (var c in gaugeControllers) { c.dispose(); }
    for (var c in widthControllers) { c.dispose(); }
    for (var c in stitchLengthControllers) { c.dispose(); }

    for (var c in spinningCompanyControllers) { c.dispose(); }
    for (var c in priceControllers) { c.dispose(); }
    
    super.dispose();
  }
}
