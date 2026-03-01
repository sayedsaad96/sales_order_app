import 'package:flutter/material.dart';
import 'package:annex_sales_order/core/utils/fabrics_calculations.dart';

class FabricsFormulaReferencePage extends StatefulWidget {
  const FabricsFormulaReferencePage({super.key});

  @override
  State<FabricsFormulaReferencePage> createState() =>
      _FabricsFormulaReferencePageState();
}

class _FabricsFormulaReferencePageState
    extends State<FabricsFormulaReferencePage> {
  final _qtyController = TextEditingController();
  final _lycraPercentController = TextEditingController();
  final _yarnPriceController = TextEditingController();
  final _lycraPriceController = TextEditingController();
  final _mfgPriceController = TextEditingController();

  bool _isFabric = true;

  @override
  void dispose() {
    _qtyController.dispose();
    _lycraPercentController.dispose();
    _yarnPriceController.dispose();
    _lycraPriceController.dispose();
    _mfgPriceController.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_qtyController.text) ?? 0.0;
  double get _lycraP => double.tryParse(_lycraPercentController.text) ?? 0.0;
  double get _yarnP => double.tryParse(_yarnPriceController.text) ?? 0.0;
  double get _lycraPr => double.tryParse(_lycraPriceController.text) ?? 0.0;
  double get _mfgP => double.tryParse(_mfgPriceController.text) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    // Live Calculations
    final yarnQty = FabricsCalculations.calculateYarnQuantity(
      totalQuantity: _qty,
      lycraPercentage: _lycraP,
    );
    final lycraQty = FabricsCalculations.calculateLycraQuantity(
      totalQuantity: _qty,
      lycraPercentage: _lycraP,
    );
    final baseValue = FabricsCalculations.calculateItemBaseValue(
      quantity: _qty,
      lycraPercentage: _lycraP,
      isFabric: _isFabric,
      isCm: !_isFabric,
      yarnPrice: _yarnP,
      lycraPrice: _lycraPr,
      manufacturingPrice: _mfgP,
    );
    final yarnValue = FabricsCalculations.calculateItemYarnValue(
      quantity: _qty,
      lycraPercentage: _lycraP,
      yarnPrice: _yarnP,
    );
    final wasteValue = FabricsCalculations.calculateItemWaste(
      yarnValue: yarnValue,
      isFabric: _isFabric,
    );
    final finalTotal = FabricsCalculations.calculateItemTotalValue(
      baseValue: baseValue,
      wasteValue: wasteValue,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(' Fabrics & CM Calculator'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalculatorSection(
                      context,
                      yarnQty: yarnQty,
                      lycraQty: lycraQty,
                      baseValue: baseValue,
                      wasteValue: wasteValue,
                      finalTotal: finalTotal,
                      isMobile:
                          constraints.maxWidth <
                          600, // Using local check or constant
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorSection(
    BuildContext context, {
    required double yarnQty,
    required double lycraQty,
    required double baseValue,
    required double wasteValue,
    required double finalTotal,
    required bool isMobile,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('قماش (Fabric)')),
                ButtonSegment(value: false, label: Text('تشغيل (CM)')),
              ],
              selected: {_isFabric},
              onSelectionChanged: (val) =>
                  setState(() => _isFabric = val.first),
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              _buildCalcInput(_qtyController, 'الكمية (كجم)'),
              const SizedBox(height: 10),
              _buildCalcInput(_lycraPercentController, 'نسبة الليكرا %'),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _buildCalcInput(_qtyController, 'الكمية (كجم)'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCalcInput(
                      _lycraPercentController,
                      'نسبة الليكرا %',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            if (isMobile) ...[
              Column(
                children: [
                  Expanded(
                    child: _buildCalcInput(_yarnPriceController, 'سعر الغزل'),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildCalcInput(
                      _lycraPriceController,
                      'سعر الليكرا',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildCalcInput(_mfgPriceController, 'المصنعية'),
                  ),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _buildCalcInput(_yarnPriceController, 'سعر الغزل'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCalcInput(
                      _lycraPriceController,
                      'سعر الليكرا',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCalcInput(_mfgPriceController, 'المصنعية'),
                  ),
                ],
              ),
            const Divider(height: 32),
            _buildResultRow('كمية الغزل:', '${yarnQty.toStringAsFixed(2)} كجم'),
            _buildResultRow(
              'كمية الليكرا:',
              '${lycraQty.toStringAsFixed(2)} كجم',
            ),
            _buildResultRow('القيمة الأساسية:', baseValue.toStringAsFixed(2)),
            if (_isFabric)
              _buildResultRow('الهالك (2%):', wasteValue.toStringAsFixed(2)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإجمالي النهائي:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    finalTotal.toStringAsFixed(2),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcInput(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: '0.0',
        isDense: true,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onTap: () {
        if (controller.text.isNotEmpty) {
          controller.clear();
          setState(() {});
        }
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
