
import 'package:flutter/material.dart';
import '../../data/models/quotation.dart';

class QuotationItemDialog extends StatefulWidget {
  final String type;
  final QuotationItem? existingItem;

  const QuotationItemDialog({super.key, required this.type, this.existingItem});

  @override
  State<QuotationItemDialog> createState() => _QuotationItemDialogState();
}

class _QuotationItemDialogState extends State<QuotationItemDialog> {
  final _formKey = GlobalKey<FormState>();

  // Common
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final unitController = TextEditingController(text: 'kg');

  // Standard
  final itemNameController = TextEditingController();
  
  // Yarn
  final descriptionController = TextEditingController();

  // Fabric
  final fabricTypeController = TextEditingController();
  final yarnTypeController = TextEditingController();
  final yarnCountController = TextEditingController();
  final spinningCompanyController = TextEditingController();
  final lycraNumberController = TextEditingController();
  final lycraPercentageController = TextEditingController();
  final widthInchesController = TextEditingController();
  final gaugeController = TextEditingController();
  final stitchLengthController = TextEditingController();
  final yarnPriceController = TextEditingController();
  final lycraPriceController = TextEditingController();
  final cmPriceController = TextEditingController();
  double calculatedWaste = 0.0;


  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
        _populateFields(widget.existingItem!);
    }
    
    // Add auto-calc listeners for fabric
    if (widget.type == 'fabric') {
        yarnPriceController.addListener(_updateCalculatedPrice);
        lycraPriceController.addListener(_updateCalculatedPrice);
        cmPriceController.addListener(_updateCalculatedPrice);
        lycraPercentageController.addListener(_updateCalculatedPrice);
    }
  }

  void _updateCalculatedPrice() {
      final yp = double.tryParse(yarnPriceController.text) ?? 0;
      final lp = double.tryParse(lycraPriceController.text) ?? 0;
      final cmp = double.tryParse(cmPriceController.text) ?? 0;
      final lperc = double.tryParse(lycraPercentageController.text) ?? 0;
      
      if (yp > 0 || lp > 0 || cmp > 0) {
          double lycraDecimal = lperc / 100;
          double yarnPart = (1 - lycraDecimal) * yp;
          double lycraPart = lycraDecimal * lp;
          double base = yarnPart + lycraPart + cmp;
          double waste = base * 0.02;
          double total = base + waste;
          setState(() {
              calculatedWaste = waste;
          });
          priceController.text = total.toStringAsFixed(2);
      }
  }

  void _populateFields(QuotationItem item) {
       quantityController.text = item.quantity.toString();
       priceController.text = item.price.toString();
       unitController.text = item.unit ?? 'kg';
       
       if (widget.type == 'standard') {
           itemNameController.text = item.itemName ?? '';
           descriptionController.text = item.description ?? '';
       } else if (widget.type == 'yarn') {
           descriptionController.text = item.description ?? '';
       } else if (widget.type == 'fabric') {
           fabricTypeController.text = item.fabricType ?? '';
           yarnTypeController.text = item.yarnType ?? '';
           yarnCountController.text = item.yarnCount ?? '';
           spinningCompanyController.text = item.spinningCompany ?? '';
           lycraNumberController.text = item.lycraNumber ?? '';
           lycraPercentageController.text = item.lycraPercentage?.toString() ?? '';
           widthInchesController.text = item.widthInches?.toString() ?? '';
           gaugeController.text = item.gauge?.toString() ?? '';
           stitchLengthController.text = item.stitchLength?.toString() ?? '';
           yarnPriceController.text = item.yarnPrice?.toString() ?? '';
           lycraPriceController.text = item.lycraPrice?.toString() ?? '';
           cmPriceController.text = item.cmPrice?.toString() ?? '';
       }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem == null ? 'إضافة صنف' : 'تعديل صنف'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTextField(quantityController, 'الكمية', isNumber: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(priceController, 'السعر', isNumber: true)),
                  ],
                ),
                if (calculatedWaste > 0) ...[
                    const SizedBox(height: 5),
                    Text('الهالك: ${calculatedWaste.toStringAsFixed(2)} / كجم', 
                        style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 10),
                _buildTextField(unitController, 'الوحدة'),
                const SizedBox(height: 10),

                if (widget.type == 'standard') ...[
                    _buildTextField(itemNameController, 'اسم الصنف'),
                    const SizedBox(height: 10),
                    _buildTextField(descriptionController, 'الوصف (اختياري)', maxLines: 2, isRequired: false),
                ] else if (widget.type == 'yarn') ...[
                    _buildTextField(descriptionController, 'وصف الغزل', maxLines: 2),
                ] else if (widget.type == 'fabric') ..._buildFabricFields(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _submit, child: const Text('تم')),
      ],
    );
  }

  List<Widget> _buildFabricFields() {
      return [
          Row(
              children: [
                  Expanded(child: _buildTextField(fabricTypeController, 'نوع القماش')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(spinningCompanyController, 'شركة الغزل')),
              ],
          ),
          const SizedBox(height: 10),
          Row(
              children: [
                  Expanded(child: _buildTextField(yarnTypeController, 'نوع الغزل')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(yarnCountController, 'نمرة الغزل')),
              ],
          ),
          const SizedBox(height: 10),
          Row(
              children: [
                  Expanded(child: _buildTextField(lycraNumberController, 'رقم الليكرا', isNumber: false)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(lycraPercentageController, 'نسبة الليكرا %', isNumber: true)),
              ],
          ),
          const SizedBox(height: 10),
          Row(
              children: [
                  Expanded(child: _buildTextField(widthInchesController, 'العرض (بوصة)', isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(gaugeController, 'الجوج (Gauge)', isNumber: true)),
              ],
          ),
          const SizedBox(height: 10),
          _buildTextField(stitchLengthController, 'طول الغرزة', isNumber: true),
          const SizedBox(height: 10),
          const Text('معايير التكلفة (اختياري - تحسب السعر تلقائياً)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 5),
          Row(
              children: [
                  Expanded(child: _buildTextField(yarnPriceController, 'سعر الغزل', isNumber: true, isRequired: false)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(lycraPriceController, 'سعر الليكرا', isNumber: true, isRequired: false)),
              ],
          ),
          const SizedBox(height: 10),
          _buildTextField(cmPriceController, 'المصنعية', isNumber: true, isRequired: false),
      ];
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1, bool isRequired = true}) {
      return Focus(
          onFocusChange: (hasFocus) {
              if (!hasFocus && isNumber && controller.text.isEmpty) {
                  controller.text = '0.0';
              }
          },
          child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
              maxLines: maxLines,
              onTap: () {
                  if (isNumber && (controller.text == '0.0' || controller.text == '0')) {
                      controller.clear();
                  }
              },
              validator: (val) {
                  if (isRequired && (val == null || val.isEmpty)) return 'مطلوب';
                  return null;
              },
          ),
      );
  }

  void _submit() {
      if (!_formKey.currentState!.validate()) return;
      
      final item = QuotationItem(
          type: widget.type,
          quantity: double.tryParse(quantityController.text) ?? 0,
          price: double.tryParse(priceController.text) ?? 0,
          unit: unitController.text,
          itemName: widget.type == 'standard' ? itemNameController.text : null,
          description: (widget.type == 'standard' || widget.type == 'yarn') ? descriptionController.text : null,
          fabricType: widget.type == 'fabric' ? fabricTypeController.text : null,
          yarnType: widget.type == 'fabric' ? yarnTypeController.text : null,
          yarnCount: widget.type == 'fabric' ? yarnCountController.text : null,
          spinningCompany: widget.type == 'fabric' ? spinningCompanyController.text : null,
          lycraNumber: widget.type == 'fabric' ? lycraNumberController.text : null,
          lycraPercentage: widget.type == 'fabric' ? (double.tryParse(lycraPercentageController.text)) : null,
          widthInches: widget.type == 'fabric' ? (double.tryParse(widthInchesController.text)) : null,
          gauge: widget.type == 'fabric' ? (int.tryParse(gaugeController.text)) : null,
          stitchLength: widget.type == 'fabric' ? (double.tryParse(stitchLengthController.text)) : null,
          yarnPrice: widget.type == 'fabric' ? (double.tryParse(yarnPriceController.text)) : null,
          lycraPrice: widget.type == 'fabric' ? (double.tryParse(lycraPriceController.text)) : null,
          cmPrice: widget.type == 'fabric' ? (double.tryParse(cmPriceController.text)) : null,
      );
      
      Navigator.pop(context, item);
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    unitController.dispose();
    itemNameController.dispose();
    descriptionController.dispose();
    fabricTypeController.dispose();
    yarnTypeController.dispose();
    yarnCountController.dispose();
    spinningCompanyController.dispose();
    lycraNumberController.dispose();
    lycraPercentageController.dispose();
    widthInchesController.dispose();
    gaugeController.dispose();
    stitchLengthController.dispose();
    yarnPriceController.dispose();
    lycraPriceController.dispose();
    cmPriceController.dispose();
    super.dispose();
  }
}
