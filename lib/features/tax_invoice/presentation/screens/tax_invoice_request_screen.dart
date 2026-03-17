import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/core/widgets/confetti_overlay.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:printing/printing.dart';
import 'package:annex_sales_order/features/tax_invoice/data/models/tax_invoice_request.dart';
import 'package:annex_sales_order/core/services/settings_service.dart';
import 'package:annex_sales_order/features/tax_invoice/pdf/tax_invoice_pdf_generator.dart';
import 'package:annex_sales_order/features/tax_invoice/data/datasources/tax_invoice_local_data_source.dart';
import 'package:annex_sales_order/features/tax_invoice/presentation/screens/saved_tax_invoices_screen.dart';

class TaxInvoiceRequestScreen extends StatefulWidget {
  final TaxInvoiceRequest? initialRequest;
  final int? initialIndex;

  const TaxInvoiceRequestScreen({
    super.key,
    this.initialRequest,
    this.initialIndex,
  });

  @override
  State<TaxInvoiceRequestScreen> createState() =>
      _TaxInvoiceRequestScreenState();
}

class _TaxInvoiceRequestScreenState extends State<TaxInvoiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataSource = TaxInvoiceLocalDataSource();

  final _sapCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  bool _isAfterTaxSelected = true;
  int? _editingIndex;

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _hasTaxCardImage = false;

  // Unit Dropdown
  String? _selectedUnit;
  final List<String> _units = ['KG', 'Cone', 'Roll', 'Box', 'Other', 'Unit'];

  @override
  void initState() {
    super.initState();
    if (widget.initialRequest != null) {
      _loadRequest(widget.initialRequest!, widget.initialIndex);
    }
  }

  void _loadRequest(TaxInvoiceRequest request, int? index) {
    _sapCodeController.text = request.sapCustomerCode;
    _nameController.text = request.customerNameOnTaxCard;
    _taxNumberController.text = request.taxCardNumber ?? '';
    _itemController.text = request.itemName;
    _quantityController.text = request.quantity?.toString() ?? '';
    _priceController.text = request.unitPrice?.toString() ?? '';
    _additionalInfoController.text = request.additionalInfo ?? '';

    _fromDate = request.fromDate;
    _toDate = request.toDate;
    _hasTaxCardImage = request.taxCardImage != null;
    _selectedUnit = request.unit; // Load unit

    if (request.totalAfterTax != null) {
      _taxAmountController.text = request.totalAfterTax.toString();
      _isAfterTaxSelected = true;
    } else if (request.totalBeforeTax != null) {
      _taxAmountController.text = request.totalBeforeTax.toString();
      _isAfterTaxSelected = false;
    }

    _editingIndex = index;
    setState(() {});
  }

  @override
  void dispose() {
    _sapCodeController.dispose();
    _nameController.dispose();
    _taxNumberController.dispose();
    _itemController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _taxAmountController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isFromDate ? _fromDate : _toDate) ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _saveRequest() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_taxAmountController.text);
      final request = TaxInvoiceRequest(
        sapCustomerCode: _sapCodeController.text,
        customerNameOnTaxCard: _nameController.text,
        taxCardNumber: _hasTaxCardImage ? null : _taxNumberController.text,
        itemName: _itemController.text,
        quantity: double.tryParse(_quantityController.text),
        unitPrice: double.tryParse(_priceController.text),
        fromDate: _fromDate,
        toDate: _toDate,
        totalBeforeTax: !_isAfterTaxSelected ? amount : null,
        totalAfterTax: _isAfterTaxSelected ? amount : null,
        additionalInfo: _additionalInfoController.text,
        unit: _selectedUnit, // Save unit
      );

      try {
        if (_editingIndex != null) {
          await _dataSource.update(_editingIndex!, request);
        } else {
          await _dataSource.add(request);
          // After adding, we want to know its index if we want to stay in "edit mode"
          // but for simplicity, we'll just show success and let user continue or reset.
          // Let's set the index to the last one.
          _editingIndex = _dataSource.getAll().length - 1;
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حفظ الطلب بنجاح')));
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e')));
        }
      }
    }
  }

  void _generatePdf() async {
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
                    const Text(
                      'جارٍ إعداد ملف PDF...',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
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
        final amount = double.tryParse(_taxAmountController.text);
        final request = TaxInvoiceRequest(
          sapCustomerCode: _sapCodeController.text,
          customerNameOnTaxCard: _nameController.text,
          taxCardNumber: _hasTaxCardImage ? null : _taxNumberController.text,
          itemName: _itemController.text,
          quantity: double.tryParse(_quantityController.text),
          unitPrice: double.tryParse(_priceController.text),
          fromDate: _fromDate,
          toDate: _toDate,
          totalBeforeTax: !_isAfterTaxSelected ? amount : null,
          totalAfterTax: _isAfterTaxSelected ? amount : null,
          additionalInfo: _additionalInfoController.text,
          unit: _selectedUnit,
        );

        final pdf = await TaxInvoicePdfGenerator.generate(request);
        final bytes = await pdf.save();

        final settingsService = SettingsService();
        final strategy = settingsService.getInvoiceSaveStrategy();
        final defaultPath = settingsService.getDefaultSavePath();

        final safeName = request.customerNameOnTaxCard.replaceAll(
          RegExp(r'[^\w\s\u0600-\u06FF]'),
          '',
        );
        final fileName = 'TaxInvoice_$safeName.pdf';

        if (Platform.isAndroid || Platform.isIOS) {
          // Mobile: Share directly
          if (mounted) {
            Navigator.of(context).pop(); // Dismiss loading
            ConfettiOverlay.show(context);
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          }
        } else {
          // Desktop: Save or Ask
          String? finalPath;
          if (strategy == InvoiceSaveStrategy.auto && defaultPath != null) {
            final customerDir = Directory('$defaultPath/$safeName');
            if (!await customerDir.exists()) {
              await customerDir.create(recursive: true);
            }
            finalPath = '${customerDir.path}/$fileName';
            final file = File(finalPath);
            await file.writeAsBytes(bytes);
          } else {
            finalPath = await FilePicker.platform.saveFile(
              dialogTitle: 'حفظ طلب الفاتورة',
              fileName: fileName,
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );

            if (finalPath != null) {
              final file = File(finalPath);
              await file.writeAsBytes(bytes);
            } else {
              // User cancelled
              if (mounted) Navigator.of(context).pop();
              return;
            }
          }

          // Dismiss loading and show success
          if (mounted) {
            Navigator.of(context).pop();
            ConfettiOverlay.show(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                showCloseIcon: true,
                content: Text('تم حفظ الملف: $finalPath'),
                action: SnackBarAction(
                  label: 'مشاركة',
                  onPressed: () {
                    Printing.sharePdf(bytes: bytes, filename: fileName);
                  },
                ),
              ),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editingIndex != null ? 'تعديل طلب فاتورة' : 'طلب فاتورة ضريبية',
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(CupertinoIcons.list_dash),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveRequest,
            tooltip: 'حفظ',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              await _dataSource.ensureInitialized();
              if (context.mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedTaxInvoicesScreen(),
                  ),
                );
                if (result != null && result is Map) {
                  _loadRequest(result['request'], result['index']);
                }
              }
            },
            tooltip: 'الطلبات المحفوظة',
          ),
          if (_editingIndex != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  _editingIndex = null;
                  _formKey.currentState?.reset();
                  _sapCodeController.clear();
                  _nameController.clear();
                  _taxNumberController.clear();
                  _itemController.clear();
                  _quantityController.clear();
                  _priceController.clear();
                  _taxAmountController.clear();
                  _additionalInfoController.clear();
                  _fromDate = null;
                  _toDate = null;
                  _hasTaxCardImage = false;
                });
              },
              tooltip: 'طلب جديد',
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column (Customer Info) - on RTL it's Right visually
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('بيانات العميل'),
                                _buildTextField(
                                  _sapCodeController,
                                  'كود العميل ساب',
                                  isRequired: true,
                                ),
                                _buildTextField(
                                  _nameController,
                                  'اسم العميل بالبطاقة الضريبية',
                                  isRequired: true,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _taxNumberController,
                                        'رقم البطاقة الضريبية',
                                        isRequired: !_hasTaxCardImage,
                                        enabled: !_hasTaxCardImage,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      children: [
                                        const Text(
                                          'مرفق صورة',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Checkbox(
                                          value: _hasTaxCardImage,
                                          onChanged: (val) => setState(
                                            () =>
                                                _hasTaxCardImage = val ?? false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),
                                _buildSectionTitle('معلومات إضافية'),
                                _buildTextField(
                                  _additionalInfoController,
                                  'معلومات إضافية',
                                  maxLines: 5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Right Column (Invoice Info) - on RTL it's Left visually
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('بيانات الفاتورة'),
                                _buildTextField(
                                  _itemController,
                                  'الصنف',
                                  isRequired: true,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: _buildTextField(
                                              _quantityController,
                                              'الكمية',
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16.0,
                                              ),
                                              child:
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    initialValue: _selectedUnit,
                                                    isExpanded: true,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'الوحدة',
                                                          border:
                                                              OutlineInputBorder(),
                                                        ),
                                                    items: _units.map((unit) {
                                                      return DropdownMenuItem(
                                                        value: unit,
                                                        child: Text(unit),
                                                      );
                                                    }).toList(),
                                                    onChanged: (val) =>
                                                        setState(
                                                          () => _selectedUnit =
                                                              val,
                                                        ),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        _priceController,
                                        'السعر',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDatePicker(
                                        'من',
                                        _fromDate,
                                        () => _selectDate(context, true),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDatePicker(
                                        'إلى',
                                        _toDate,
                                        () => _selectDate(context, false),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildSectionTitle('أجمالي قيمة الفاتورة'),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildTextField(
                                        _taxAmountController,
                                        'المبلغ',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      children: [
                                        const Text(
                                          'بعد الضريبة',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Checkbox(
                                          value: _isAfterTaxSelected,
                                          onChanged: (val) {
                                            if (val == true) {
                                              setState(
                                                () =>
                                                    _isAfterTaxSelected = true,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      children: [
                                        const Text(
                                          'قبل الضريبة',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Checkbox(
                                          value: !_isAfterTaxSelected,
                                          onChanged: (val) {
                                            if (val == true) {
                                              setState(
                                                () =>
                                                    _isAfterTaxSelected = false,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('بيانات العميل'),
                          _buildTextField(
                            _sapCodeController,
                            'كود العميل ساب',
                            isRequired: true,
                          ),
                          _buildTextField(
                            _nameController,
                            'اسم العميل بالبطاقة الضريبية',
                            isRequired: true,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _taxNumberController,
                                  'رقم البطاقة الضريبية',
                                  isRequired: !_hasTaxCardImage,
                                  enabled: !_hasTaxCardImage,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  const Text(
                                    'مرفق صورة',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Checkbox(
                                    value: _hasTaxCardImage,
                                    onChanged: (val) => setState(
                                      () => _hasTaxCardImage = val ?? false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const Divider(height: 32),
                          _buildSectionTitle('بيانات الفاتورة'),
                          _buildTextField(
                            _itemController,
                            'الصنف',
                            isRequired: true,
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  _quantityController,
                                  'الكمية',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedUnit,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Unit',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _units.map((unit) {
                                      return DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      );
                                    }).toList(),
                                    onChanged: (val) =>
                                        setState(() => _selectedUnit = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildTextField(
                            _priceController,
                            'السعر',
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDatePicker(
                                  'من',
                                  _fromDate,
                                  () => _selectDate(context, true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDatePicker(
                                  'إلى',
                                  _toDate,
                                  () => _selectDate(context, false),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _buildSectionTitle('أجمالي قيمة الفاتورة'),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  _taxAmountController,
                                  'المبلغ',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                children: [
                                  const Text(
                                    'بعد الضريبة',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Checkbox(
                                    value: _isAfterTaxSelected,
                                    onChanged: (val) {
                                      if (val == true) {
                                        setState(
                                          () => _isAfterTaxSelected = true,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  const Text(
                                    'قبل الضريبة',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Checkbox(
                                    value: !_isAfterTaxSelected,
                                    onChanged: (val) {
                                      if (val == true) {
                                        setState(
                                          () => _isAfterTaxSelected = false,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          _buildTextField(
                            _additionalInfoController,
                            'معلومات إضافية',
                            maxLines: 5,
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),
                    const Text(
                      'ملحوظة: في حالة وجود صورة البطاقة الضريبية لا يهم رقم البطاقة الضريبية',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _generatePdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(
                          _editingIndex != null ? 'تحديث PDF' : 'PDF',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: Colors.grey.withValues(alpha: 0.1),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? intl.DateFormat('yyyy/MM/dd').format(date)
                  : 'يتم تحديده',
              style: TextStyle(
                fontSize: 16,
                color: date != null ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
