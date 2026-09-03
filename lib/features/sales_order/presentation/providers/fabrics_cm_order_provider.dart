import 'package:flutter/material.dart';
import 'package:annex_sales_order/core/widgets/confetti_overlay.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';
import '../../data/models/fabrics_cm_sales_order.dart';
import '../../data/datasources/fabrics_cm_invoice_local_data_source.dart';
import '../../../user/data/datasources/user_local_data_source.dart';
import '../../pdf/fabrics_cm_pdf_generator.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/settings_service.dart';

class FabricsCmOrderProvider extends ChangeNotifier {
  FabricsCmOrderProvider({this.existingOrder}) {
    if (existingOrder != null) {
      _loadExistingOrder(existingOrder!);
    } else {
      resetForm();
    }
  }

  FabricsCmSalesOrder? existingOrder;

  // Header Controllers
  final snController = TextEditingController();
  final customerNameController = TextEditingController();
  final salesResponsibleController = TextEditingController();
  final paymentMethodController = TextEditingController();
  final notesController = TextEditingController();

  // Header State
  DateTime orderDate = DateTime.now();
  DateTime? deliveryDate = DateTime.now().add(const Duration(days: 1));
  String? orderType; // Legacy
  String? paymentMethod;
  String? selectedBranch = 'القاهرة';
  Map<String, bool> orderTypes = {
    'قماش': true,
    'CM': false,
    'CM Y from Annex': false,
  };

  // Items State (Dynamic Controllers)
  final List<TextEditingController> quantityControllers = [];
  final List<TextEditingController> fabricDetailsControllers = [];
  final List<TextEditingController> priceControllers = [];
  final List<TextEditingController> spinningCompanyControllers = [];
  final List<TextEditingController> gaugeControllers = [];
  final List<TextEditingController> inchControllers = [];
  final List<TextEditingController> stitchLengthControllers = [];

  double get totalValue {
    double total = 0;
    for (int i = 0; i < quantityControllers.length; i++) {
      double qty = double.tryParse(quantityControllers[i].text) ?? 0;
      double price = double.tryParse(priceControllers[i].text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  double get totalQuantity {
    double total = 0;
    for (int i = 0; i < quantityControllers.length; i++) {
      total += double.tryParse(quantityControllers[i].text) ?? 0;
    }
    return total;
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  void _loadExistingOrder(FabricsCmSalesOrder order) {
    existingOrder = order;
    snController.text = order.sn ?? '';
    customerNameController.text = order.customerName ?? '';
    paymentMethodController.text = order.paymentMethod ?? '';
    notesController.text = order.notes ?? '';
    salesResponsibleController.text = order.salesResponsible ?? '';

    orderDate = order.orderDate;
    deliveryDate = order.deliveryDate;

    paymentMethod = _mapPaymentMethod(order.paymentMethod);
    selectedBranch = order.branch;

    // Reset types
    orderTypes.clear();
    orderTypes['قماش'] = false;
    orderTypes['CM'] = false;
    orderTypes['CM Y from Annex'] = false;
    for (var t in order.orderTypesList) {
      if (orderTypes.containsKey(t)) {
        orderTypes[t] = true;
      }
    }

    // Legacy fallback if list is empty
    if (order.orderTypesList.isEmpty && order.orderType != null) {
      if (order.orderType!.contains('قماش')) orderTypes['قماش'] = true;
      if (order.orderType!.contains('CM')) orderTypes['CM'] = true;
      if (order.orderType!.contains('CM Y from Annex')) {
        orderTypes['CM Y from Annex'] = true;
      }
      // No legacy fallback for new type as it didn't exist
    }

    _disposeAllItemControllers();

    for (var item in order.items) {
      addItem(
        quantity: item.quantity,
        fabricDetails: item.fabricDetails,
        price: item.price,
        spinCo: item.spinningCompany,
        inch: item.inch?.toString(),
        gauge: item.gauge?.toString(),
        stitchLength: item.stitchLength?.toString(),
      );
    }

    notifyListeners();
  }

  void resetForm() {
    generateUniqueSN();
    customerNameController.clear();
    paymentMethodController.clear();
    notesController.clear();

    orderDate = DateTime.now();
    deliveryDate = DateTime.now().add(const Duration(days: 1));
    orderType = null;
    paymentMethod = null;
    selectedBranch = 'القاهرة';
    orderTypes = {'قماش': true, 'CM': false, 'CM Y from Annex': false};

    _disposeAllItemControllers();

    _loadCurrentUser();
    addItem(); // Add one initial empty row
    notifyListeners();
  }

  void generateUniqueSN() {
    final box = FabricsCmInvoiceLocalDataSource().getInvoices();
    final existingSns = box.map((e) => e.sn ?? '').toSet();

    final List<int> available = [];
    for (int i = 10; i <= 9999; i++) {
      final sn = 'FCM-$i';
      if (!existingSns.contains(sn)) {
        available.add(i);
      }
    }

    if (available.isNotEmpty) {
      final randomIndex =
          (DateTime.now().microsecondsSinceEpoch % available.length);
      final chosen = available[randomIndex.toInt()];
      snController.text = 'FCM-$chosen';
    } else {
      snController.text =
          'FCM-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';
    }
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
    String? fabricDetails,
    double? price,
    String? spinCo,
    String? inch,
    String? gauge,
    String? stitchLength,
    int count = 1,
  }) {
    for (int i = 0; i < count; i++) {
      // Pre-fill from the first item if current values are null and we already have items
      if (quantityControllers.isNotEmpty) {
        fabricDetails ??= fabricDetailsControllers[0].text;
        price ??= double.tryParse(priceControllers[0].text);
        spinCo ??= spinningCompanyControllers[0].text;
        inch ??= inchControllers[0].text;
        gauge ??= gaugeControllers[0].text;
        stitchLength ??= stitchLengthControllers[0].text;
      }

      final qc = TextEditingController(text: quantity?.toString() ?? '');
      final fdc = TextEditingController(text: fabricDetails ?? '');
      final pc = TextEditingController(text: price?.toString() ?? '');
      final scc = TextEditingController(text: spinCo ?? '');
      final ic = TextEditingController(text: inch?.toString() ?? '');
      final gc = TextEditingController(text: gauge?.toString() ?? '');
      final slc = TextEditingController(text: stitchLength?.toString() ?? '');

      void listener() => notifyListeners();
      qc.addListener(listener);
      pc.addListener(listener);

      quantityControllers.add(qc);
      fabricDetailsControllers.add(fdc);
      priceControllers.add(pc);
      spinningCompanyControllers.add(scc);
      inchControllers.add(ic);
      gaugeControllers.add(gc);
      stitchLengthControllers.add(slc);
    }

    notifyListeners();
  }

  void removeItem(int index) {
    if (quantityControllers.length > 1) {
      quantityControllers[index].dispose();
      fabricDetailsControllers[index].dispose();
      priceControllers[index].dispose();
      spinningCompanyControllers[index].dispose();
      inchControllers[index].dispose();
      gaugeControllers[index].dispose();
      stitchLengthControllers[index].dispose();

      quantityControllers.removeAt(index);
      fabricDetailsControllers.removeAt(index);
      priceControllers.removeAt(index);
      spinningCompanyControllers.removeAt(index);
      gaugeControllers.removeAt(index);
      inchControllers.removeAt(index);
      stitchLengthControllers.removeAt(index);

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
      'Cash': 'كاش مع المبيعات',
      'Bank transfer': 'تحويل بنكي',
      'Credit': 'اجل شهر', // Approximating Credit to 'اجل شهر'
      'Cheque': 'تحويل بنكي', // Fallback
      'Other': 'كاش مع المبيعات', // Fallback
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
      // Basic validation: skip empty rows where key fields are missing
      if (qty > 0) {
        items.add(
          FabricsCmLineItem(
            quantity: qty,
            fabricDetails: fabricDetailsControllers[i].text,
            price: double.tryParse(priceControllers[i].text) ?? 0.0,
            spinningCompany: spinningCompanyControllers[i].text,
            inch: inchControllers[i].text,
            gauge: gaugeControllers[i].text,
            stitchLength: stitchLengthControllers[i].text,
          ),
        );
      }
    }

    final typesList = orderTypes.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

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
    if (saveAsNew) {
      generateUniqueSN();
      orderDate = DateTime.now();
    } else if (existingOrder != null) {
      snController.text = existingOrder!.sn ?? '';
      orderDate = existingOrder!.orderDate;
    }
    notifyListeners();
  }

  Future<bool> saveOrder(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة بشكل صحيح'),
        ),
      );
      return false;
    }

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
        const SnackBar(
          content: Text('يجب إضافة صنف واحد على الأقل بكمية صحيحة'),
        ),
      );
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final sn = snController.text;
      final isDuplicate = FabricsCmInvoiceLocalDataSource().isSnExists(
        sn,
        excludeKey: (existingOrder != null && existingOrder!.isInBox)
            ? existingOrder!.key
            : null,
      );

      if (isDuplicate) {
        _isSaving = false;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الفاتورة (S/N) موجود بالفعل، يرجى تغييره'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

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

      AnalysisService.clearCache();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      return false;
    }
  }

  Future<void> generatePdf(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى ملء جميع الحقول المطلوبة بشكل صحيح قبل إنشاء PDF',
          ),
        ),
      );
      return;
    }

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
      final sn = snController.text;
      final isDuplicate = FabricsCmInvoiceLocalDataSource().isSnExists(
        sn,
        excludeKey: (existingOrder != null && existingOrder!.isInBox)
            ? existingOrder!.key
            : null,
      );

      if (isDuplicate) {
        if (context.mounted) Navigator.of(context).pop(); // Dismiss loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الفاتورة (S/N) موجود بالفعل، يرجى تغييره'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

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

      AnalysisService.clearCache();

      // Use the data (either new or updated) for PDF
      // Note: For PDF we can use newOrderData as it holds the current UI values
      final pdf = await FabricsCmPdfGenerator.generate(newOrderData);
      final bytes = await pdf.save();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      final settingsService = SettingsService();
      final strategy = settingsService.getInvoiceSaveStrategy();
      final defaultPath = settingsService.getDefaultSavePath();

      String? finalPath;
      final safeName = (newOrderData.customerName ?? 'Client').replaceAll(
        RegExp(r'[^\w\s\u0600-\u06FF]'),
        '',
      );
      final fileName = '${safeName}_${newOrderData.sn}.pdf';

      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Share directly
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Dismiss loading
        ConfettiOverlay.show(context);
        await Printing.sharePdf(bytes: bytes, filename: fileName);
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
              dialogTitle: 'حفظ الفاتورة',
              fileName: fileName,
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );

            if (finalPath != null) {
              final file = File(finalPath);
              await file.writeAsBytes(bytes);
            } else {
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

        if (!context.mounted) return;
        ConfettiOverlay.show(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الملف: $finalPath'),
            showCloseIcon: true,
            closeIconColor: Colors.yellowAccent,
            duration: (!Platform.isAndroid && !Platform.isIOS)
                ? const Duration(seconds: 2)
                : const Duration(seconds: 5),
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
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')));
    }
  }

  @override
  void dispose() {
    snController.dispose();
    customerNameController.dispose();
    salesResponsibleController.dispose();
    paymentMethodController.dispose();
    notesController.dispose();

    _disposeAllItemControllers();

    super.dispose();
  }

  void _disposeAllItemControllers() {
    for (var c in quantityControllers) {
      c.dispose();
    }
    for (var c in fabricDetailsControllers) {
      c.dispose();
    }
    for (var c in priceControllers) {
      c.dispose();
    }
    for (var c in spinningCompanyControllers) {
      c.dispose();
    }
    for (var c in inchControllers) {
      c.dispose();
    }
    for (var c in gaugeControllers) {
      c.dispose();
    }
    for (var c in stitchLengthControllers) {
      c.dispose();
    }

    quantityControllers.clear();
    fabricDetailsControllers.clear();
    priceControllers.clear();
    spinningCompanyControllers.clear();
    inchControllers.clear();
    gaugeControllers.clear();
    stitchLengthControllers.clear();
  }
}
