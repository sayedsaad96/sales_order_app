import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/sales_order/data/models/quotation.dart';
import 'package:annex_sales_order/features/sales_order/data/datasources/quotation_local_data_source.dart';

class QuotationProvider extends ChangeNotifier {
  final _dataSource = QuotationLocalDataSource();

  // Header Fields
  final snController = TextEditingController();
  final customerController = TextEditingController();
  final notesController = TextEditingController();
  final termsController = TextEditingController();
  DateTime orderDate = DateTime.now();
  DateTime? validUntil;

  // Item State
  // We keep the source Item models, but we also need controllers for editable fields (Price, Qty)
  final List<QuotationItem> _items = [];
  List<QuotationItem> get items => _items;

  final List<TextEditingController> quantityControllers = [];
  final List<TextEditingController> priceControllers = [];

  // Editing existing quotation
  Quotation? _existingQuotation;

  void init({Quotation? existingQuotation}) {
    if (existingQuotation != null) {
      _existingQuotation = existingQuotation;
      snController.text = existingQuotation.sn ?? '';
      customerController.text = existingQuotation.customerName ?? '';
      notesController.text = existingQuotation.notes ?? '';
      orderDate = existingQuotation.date;

      for (var item in existingQuotation.items) {
        addItem(item);
      }
      validUntil = existingQuotation.validUntil;
      termsController.text = existingQuotation.termsAndConditions ?? '';
    } else {
      // Start fresh
      generateUniqueSN();
      // No specific validity date - "ساري حتى اشعار اخر"
      termsController.text =
          'الدفع كاش عند الاستلام أو حسب الاتفاق.\nالبضاعة المباعة لا ترد ولا تستبدل بعد خروجها من المخزن.';
    }
  }

  void generateUniqueSN() {
    final box = _dataSource.getQuotations();
    final existingSns = box.map((e) => e.sn ?? '').toSet();

    final List<int> available = [];
    for (int i = 10; i <= 9999; i++) {
      final sn = 'Q-$i';
      if (!existingSns.contains(sn)) {
        available.add(i);
      }
    }

    if (available.isNotEmpty) {
      final randomIndex =
          (DateTime.now().microsecondsSinceEpoch % available.length);
      final chosen = available[randomIndex.toInt()];
      snController.text = 'Q-$chosen';
    } else {
      snController.text =
          'Q-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';
    }
    notifyListeners();
  }

  void setValidity(DateTime date) {
    validUntil = date;
    notifyListeners();
  }

  void addItem(QuotationItem item) {
    _items.add(item);

    final qc = TextEditingController(text: item.quantity.toString());
    final pc = TextEditingController(text: item.price.toString());

    // Listeners to update total value
    qc.addListener(notifyListeners);
    pc.addListener(notifyListeners);

    quantityControllers.add(qc);
    priceControllers.add(pc);

    notifyListeners();
  }

  void updateItem(int index, QuotationItem item) {
    if (index < 0 || index >= _items.length) return;

    _items[index] = item;

    // Update controllers if valid
    // Note: If user edits Qty/Price in dialog, we should sync back to controllers
    if (index < quantityControllers.length) {
      quantityControllers[index].text = item.quantity.toString();
    }
    if (index < priceControllers.length) {
      priceControllers[index].text = item.price.toString();
    }

    notifyListeners();
  }

  void removeItem(int index) {
    if (index < _items.length) {
      quantityControllers[index].dispose();
      priceControllers[index].dispose();

      quantityControllers.removeAt(index);
      priceControllers.removeAt(index);
      _items.removeAt(index);

      notifyListeners();
    }
  }

  void updateDate(DateTime date) {
    orderDate = date;
    notifyListeners();
  }

  double get totalBasePrice {
    double total = 0;
    for (int i = 0; i < _items.length; i++) {
      final qty = double.tryParse(quantityControllers[i].text) ?? 0;
      final prc = double.tryParse(priceControllers[i].text) ?? 0;
      // Temp update to get correct base price if item has costing parameters
      _items[i].quantity = qty;
      _items[i].price = prc;
      total += qty * _items[i].calculateBaseUnitPrice;
    }
    return total;
  }

  double get totalWaste {
    double total = 0;
    for (int i = 0; i < _items.length; i++) {
      final qty = double.tryParse(quantityControllers[i].text) ?? 0;
      final prc = double.tryParse(priceControllers[i].text) ?? 0;
      _items[i].quantity = qty;
      _items[i].price = prc;
      total += qty * _items[i].calculateWasteAmountPerUnit;
    }
    return total;
  }

  double get totalValue => totalBasePrice + totalWaste;

  Future<String?> saveQuotation() async {
    final sn = snController.text;
    final isDuplicate = _dataSource.isSnExists(
      sn,
      excludeKey: (_existingQuotation != null && _existingQuotation!.isInBox)
          ? _existingQuotation!.key
          : null,
    );

    if (isDuplicate) {
      return 'رقم عرض السعر موجود بالفعل، يرجى تغييره';
    }

    // Sync controllers back to items
    for (int i = 0; i < _items.length; i++) {
      _items[i].quantity = double.tryParse(quantityControllers[i].text) ?? 0;
      _items[i].price = double.tryParse(priceControllers[i].text) ?? 0;
    }

    final newQuotation = Quotation(
      sn: snController.text,
      customerName: customerController.text,
      date: orderDate,
      items: _items, // HiveObject List
      notes: notesController.text,
      validUntil: validUntil,
      termsAndConditions: termsController.text,
    );

    if (_existingQuotation != null && _existingQuotation!.isInBox) {
      // Update existing
      _existingQuotation!.sn = newQuotation.sn;
      _existingQuotation!.customerName = newQuotation.customerName;
      _existingQuotation!.date = newQuotation.date;
      _existingQuotation!.items = newQuotation.items;
      _existingQuotation!.notes = newQuotation.notes;
      _existingQuotation!.validUntil = newQuotation.validUntil;
      _existingQuotation!.termsAndConditions = newQuotation.termsAndConditions;
      await _existingQuotation!.save();
    } else {
      await _dataSource.saveQuotation(newQuotation);
    }
    return null; // Success
  }

  @override
  void dispose() {
    snController.dispose();
    customerController.dispose();
    notesController.dispose();
    termsController.dispose();
    for (var c in quantityControllers) {
      c.dispose();
    }
    for (var c in priceControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
