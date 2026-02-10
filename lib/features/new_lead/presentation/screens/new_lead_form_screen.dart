import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/core/services/settings_service.dart';
import '../../data/models/new_lead.dart';
import '../../pdf/new_lead_pdf_generator.dart';
import '../../../../features/user/data/datasources/user_local_data_source.dart';

class NewLeadFormScreen extends StatefulWidget {
  const NewLeadFormScreen({super.key});

  @override
  State<NewLeadFormScreen> createState() => _NewLeadFormScreenState();
}

class _NewLeadFormScreenState extends State<NewLeadFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Account Manager
  final _accountManagerController = TextEditingController();

  // Customer General Info
  final _accountNameController = TextEditingController();
  final _mainContactNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _zoneController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  Rating? _size;
  Rating? _creditScore;
  CustomerType? _customerType;

  // Products
  final Map<String, ProductSelection> _products = {
    'SEWING THREAD': const ProductSelection(),
    'JEANS SEWING THREAD': const ProductSelection(),
    'POLYESTER EMBROIDERY': const ProductSelection(),
    'RAYON': const ProductSelection(),
    'NON-WOVEN': const ProductSelection(),
    'SPRAY': const ProductSelection(),
    'METALLIC YARN': const ProductSelection(),
    'RUBBER THREAD': const ProductSelection(),
    'YARN': const ProductSelection(),
    'FABRIC': const ProductSelection(),
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDataSource = UserLocalDataSource();
    final user = userDataSource.getUser();
    if (user != null) {
      setState(() {
        _accountManagerController.text = user.fullName;
      });
    }
  }

  @override
  void dispose() {
    _accountManagerController.dispose();
    _accountNameController.dispose();
    _mainContactNameController.dispose();
    _cityController.dispose();
    _zoneController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _accountManagerController.clear();
    _accountNameController.clear();
    _mainContactNameController.clear();
    _cityController.clear();
    _zoneController.clear();
    _phoneController.clear();
    _addressController.clear();
    setState(() {
      _size = null;
      _creditScore = null;
      _customerType = null;
      _products.updateAll((key, value) => const ProductSelection());
    });
  }

  void _generatePdf() async {
    if (_formKey.currentState!.validate()) {
      // Show loading
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
        final newLead = NewLead(
          accountManager: _accountManagerController.text,
          accountName: _accountNameController.text,
          mainContactName: _mainContactNameController.text,
          city: _cityController.text,
          zone: _zoneController.text,
          size: _size,
          creditScoreAssessment: _creditScore,
          customerType: _customerType,
          phoneNo: _phoneController.text,
          addressGpsLocation: _addressController.text,
          sewingThread: _products['SEWING THREAD']!,
          jeansSewingThread: _products['JEANS SEWING THREAD']!,
          polyesterEmbroidery: _products['POLYESTER EMBROIDERY']!,
          rayon: _products['RAYON']!,
          nonWoven: _products['NON-WOVEN']!,
          spray: _products['SPRAY']!,
          metallicYarn: _products['METALLIC YARN']!,
          rubberThread: _products['RUBBER THREAD']!,
          yarn: _products['YARN']!,
          fabric: _products['FABRIC']!,
        );

        final pdf = await NewLeadPdfGenerator.generate(newLead);
        final bytes = await pdf.save();

        final settingsService = SettingsService();
        final strategy = settingsService.getInvoiceSaveStrategy();
        final defaultPath = settingsService.getDefaultSavePath();

        final safeName = newLead.accountName.replaceAll(
          RegExp(r'[^\w\s\u0600-\u06FF]'),
          '',
        );
        final fileName = 'New_Lead_$safeName.pdf';

        if (Platform.isAndroid || Platform.isIOS) {
          if (mounted) {
            Navigator.of(context).pop();
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          }
        } else {
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
              dialogTitle: 'حفظ New Lead',
              fileName: fileName,
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );

            if (finalPath != null) {
              final file = File(finalPath);
              await file.writeAsBytes(bytes);
            } else {
              if (mounted) Navigator.of(context).pop();
              return;
            }
          }

          if (mounted) {
            Navigator.of(context).pop();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Lead'),
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
            icon: const Icon(Icons.refresh),
            onPressed: _clearForm,
            tooltip: 'مسح النموذج',
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
                          // Left Column: Account Manager + General Info
                          Expanded(
                            child: Column(
                              children: [
                                _buildSectionCard(
                                  title: 'ACCOUNT MANAGER',
                                  titleArabic: 'مدير الحساب',
                                  icon: Icons.person_outline,
                                  isDark: isDark,
                                  child: _buildTextField(
                                    _accountManagerController,
                                    'Account Manager Name / اسم مدير الحساب',
                                    isRequired: true,
                                    readOnly: true,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSectionCard(
                                  title: 'CUSTOMER GENERAL INFO',
                                  titleArabic: 'معلومات العميل العامة',
                                  icon: Icons.business_center_outlined,
                                  isDark: isDark,
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        _accountNameController,
                                        'Account Name / اسم الحساب',
                                        isRequired: true,
                                      ),
                                      _buildTextField(
                                        _mainContactNameController,
                                        'Main Contact Name / مسئول التواصل  ',
                                        isRequired: true,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              _cityController,
                                              'City / المدينة',
                                              isRequired: true,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTextField(
                                              _zoneController,
                                              'Zone / المنطقة',
                                              isRequired: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildRatingRow('SIZE / الحجم', _size, (
                                        val,
                                      ) {
                                        setState(() => _size = val);
                                      }),
                                      const SizedBox(height: 12),
                                      _buildRatingRow(
                                        'CREDIT SCORE / تقييم الائتمان',
                                        _creditScore,
                                        (val) {
                                          setState(() => _creditScore = val);
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCustomerTypeRow(),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        _phoneController,
                                        'Phone No / رقم الموبيل',
                                        isRequired: true,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      _buildTextField(
                                        _addressController,
                                        'Address / العنوان',
                                        isRequired: true,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Right Column: Products
                          Expanded(
                            child: _buildSectionCard(
                              title: "CUSTOMER'S PRODUCTS",
                              titleArabic: 'اصناف العميل',
                              icon: Icons.inventory_2_outlined,
                              isDark: isDark,
                              child: Column(
                                children: _products.keys.map((productName) {
                                  return _buildProductRow(productName);
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          // Account Manager Section
                          _buildSectionCard(
                            title: 'ACCOUNT MANAGER',
                            titleArabic: 'مدير الحساب',
                            icon: Icons.person_outline,
                            isDark: isDark,
                            child: _buildTextField(
                              _accountManagerController,
                              'Account Manager Name / اسم مدير الحساب',
                              isRequired: true,
                              readOnly: true,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Customer General Info Section
                          _buildSectionCard(
                            title: 'CUSTOMER GENERAL INFO',
                            titleArabic: 'معلومات العميل العامة',
                            icon: Icons.business_center_outlined,
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildTextField(
                                  _accountNameController,
                                  'Account Name / اسم الحساب',
                                  isRequired: true,
                                ),
                                _buildTextField(
                                  _mainContactNameController,
                                  'Main Contact Name / مسئول التواصل  ',
                                  isRequired: true,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _cityController,
                                        'City / المدينة',
                                        isRequired: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        _zoneController,
                                        'Zone / المنطقة',
                                        isRequired: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildRatingRow('SIZE / الحجم', _size, (val) {
                                  setState(() => _size = val);
                                }),
                                const SizedBox(height: 12),
                                _buildRatingRow(
                                  'CREDIT SCORE / تقييم الائتمان',
                                  _creditScore,
                                  (val) {
                                    setState(() => _creditScore = val);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildCustomerTypeRow(),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  _phoneController,
                                  'Phone No / رقم الموبيل',
                                  isRequired: true,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildTextField(
                                  _addressController,
                                  'Address / العنوان',
                                  isRequired: true,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Customer's Products Section
                          _buildSectionCard(
                            title: "CUSTOMER'S PRODUCTS",
                            titleArabic: 'اصناف العميل',
                            icon: Icons.inventory_2_outlined,
                            isDark: isDark,
                            child: Column(
                              children: _products.keys.map((productName) {
                                return _buildProductRow(productName);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 32),

                    // Generate PDF Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _generatePdf,
                        icon: const Icon(Icons.picture_as_pdf, size: 28),
                        label: const Text(
                          'Generate PDF',
                          style: TextStyle(
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

  Widget _buildSectionCard({
    required String title,
    required String titleArabic,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        titleArabic,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
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

  Widget _buildRatingRow(
    String label,
    Rating? selectedRating,
    ValueChanged<Rating?> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Wrap(
            spacing: 8,
            children: Rating.values.map((rating) {
              final isSelected = selectedRating == rating;
              return ChoiceChip(
                label: Text(rating.label),
                selected: isSelected,
                onSelected: (selected) {
                  onChanged(selected ? rating : null);
                },
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerTypeRow() {
    return Row(
      children: [
        const Expanded(
          flex: 2,
          child: Text(
            'CUSTOMER TYPE / نوع نشاط العميل',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Wrap(
            spacing: 8,
            children: CustomerType.values.map((type) {
              final isSelected = _customerType == type;
              return ChoiceChip(
                label: Text(type.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _customerType = selected ? type : null;
                  });
                },
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(String productName) {
    final product = _products[productName]!;
    final arabicName = NewLead.productNamesArabic[productName] ?? productName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Checkbox(
            value: product.selected,
            onChanged: (val) {
              setState(() {
                _products[productName] = product.copyWith(
                  selected: val ?? false,
                  priority: val == true ? product.priority : null,
                );
              });
            },
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: product.selected ? null : Colors.grey,
                  ),
                ),
                Text(
                  arabicName,
                  style: TextStyle(
                    fontSize: 11,
                    color: product.selected
                        ? Colors.grey[600]
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (product.selected)
            SizedBox(
              width: 120,
              child: Wrap(
                spacing: 4,
                children: Rating.values.map((rating) {
                  final isSelected = product.priority == rating;
                  return ChoiceChip(
                    label: Text(
                      rating.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _products[productName] = product.copyWith(
                          priority: selected ? rating : null,
                        );
                      });
                    },
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
