
import 'package:hive_flutter/hive_flutter.dart';
import 'package:annex_sales_order/features/sales_order/data/models/quotation.dart';

class QuotationLocalDataSource {
  static const String _boxName = 'quotations';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Quotation>(_boxName);
    }
  }

  Future<void> saveQuotation(Quotation quotation) async {
    final box = Hive.box<Quotation>(_boxName);
    if (quotation.isInBox) {
      await quotation.save();
    } else {
      await box.add(quotation);
    }
  }

  List<Quotation> getQuotations() {
    if (!Hive.isBoxOpen(_boxName)) return [];
    final box = Hive.box<Quotation>(_boxName);
    return box.values.toList();
  }

  bool isSnExists(String sn, {dynamic excludeKey}) {
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      final box = Hive.box<Quotation>(_boxName);
      return box.values.any((q) => q.sn == sn && q.key != excludeKey);
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteQuotation(Quotation quotation) async {
    await quotation.delete();
  }
}
