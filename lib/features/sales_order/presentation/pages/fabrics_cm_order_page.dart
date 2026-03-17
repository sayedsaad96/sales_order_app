import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:annex_sales_order/core/utils/responsive_constants.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/sales_order/presentation/providers/fabrics_cm_order_provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:annex_sales_order/features/sales_order/data/models/fabrics_cm_sales_order.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/saved_fabrics_cm_invoices_page.dart';
import 'package:annex_sales_order/features/sales_order/presentation/widgets/fabrics_specific_widgets.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/fabrics_formula_reference_page.dart';

class FabricsCmOrderPage extends StatefulWidget {
  final FabricsCmSalesOrder? existingOrder;
  final VoidCallback? onMenuPressed;
  const FabricsCmOrderPage({super.key, this.existingOrder, this.onMenuPressed});

  @override
  State<FabricsCmOrderPage> createState() => _FabricsCmOrderPageState();
}

class _FabricsCmOrderPageState extends State<FabricsCmOrderPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Clear SnackBars when leaving the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          FabricsCmOrderProvider(existingOrder: widget.existingOrder),
      child: Consumer<FabricsCmOrderProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              leading: widget.onMenuPressed != null
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.list_dash),
                      onPressed: widget.onMenuPressed,
                      tooltip: 'Menu',
                    )
                  : IconButton(
                      icon: const Icon(CupertinoIcons.back),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'رجوع',
                    ),
              title: const Text('Annex Group'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.add),
                  tooltip: 'طلب جديد',
                  onPressed: provider.resetForm,
                ),
                IconButton(
                  icon: const Icon(Icons.calculate_outlined),
                  tooltip: ' حساب القماش',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const FabricsFormulaReferencePage(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.folder),
                  tooltip: 'الفواتير المحفوظة',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SavedFabricsCmInvoicesPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile =
                    constraints.maxWidth <
                    ResponsiveConstants.kMobileBreakpoint;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Form(
                      key: _formKey,
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverMainAxisGroup(
                              slivers: [
                                _buildTopHeader(context, provider, isMobile),

                                SliverToBoxAdapter(
                                  child: FabricsBranchAndTypeSection(
                                    selectedBranch: provider.selectedBranch,
                                    orderTypes: provider.orderTypes,
                                    onBranchChanged: provider.setBranch,
                                    onTypeChanged: provider.setOrderTypeState,
                                    isMobile: isMobile,
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 20),
                                ),
                                _buildHeaderSection(
                                  context,
                                  provider,
                                  isMobile,
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 20),
                                ),
                                _buildItemsList(context, provider, isMobile),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 20),
                                ),
                                _buildFooterSection(context, provider),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    FabricsCmOrderProvider provider,
    bool isMobile,
  ) {
    return SliverToBoxAdapter(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: isMobile
              ? Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Fabrics & CM Sales Order',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      provider.snController,
                      'S/N',
                      onRefresh: () => provider.generateUniqueSN(),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Fabrics & CM Sales Order',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: _buildTextField(
                        provider.snController,
                        'S/N',
                        onRefresh: () => provider.generateUniqueSN(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    FabricsCmOrderProvider provider,
    bool isMobile,
  ) {
    return SliverToBoxAdapter(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (isMobile) ...[
                // S/N moved to top header
                _buildTextField(provider.customerNameController, 'اسم العميل'),
                const SizedBox(height: 10),
                _buildTextField(
                  provider.salesResponsibleController,
                  'مسئول البيع',
                ),
                const SizedBox(height: 10),
                _buildPaymentDropdown(provider),
                const SizedBox(height: 10),
                // Order Type moved to separate section
                _buildDatePicker(context, provider),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        provider.customerNameController,
                        'اسم العميل',
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        provider.salesResponsibleController,
                        'مسئول البيع',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildPaymentDropdown(provider)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDatePicker(context, provider)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    int maxLines = 1,
    bool isRequired = false,
    bool isNumeric = false,
    VoidCallback? onRefresh,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (isNumeric && !hasFocus && controller.text.isEmpty) {
          controller.text = '0.0';
        }
      },
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: onRefresh != null
              ? IconButton(
                  icon: const Icon(CupertinoIcons.refresh),
                  onPressed: onRefresh,
                )
              : null,
        ),
        onTap: () {
          if (isNumeric &&
              (controller.text == '0.0' || controller.text == '0')) {
            controller.clear();
          }
        },
        validator: (val) {
          if (isRequired && (val?.trim().isEmpty ?? true)) {
            return 'مطلوب';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPaymentDropdown(FabricsCmOrderProvider provider) {
    return DropdownButtonFormField<String>(
      initialValue:
          [
            'كاش مع المبيعات',
            'كاش مع السيارة',
            'تحويل بنكي',
            'اجل اسبوع',
            'اجل اسبوعين',
            'اجل 3 اسابيع',
            'اجل شهر',
            'اجل 45 يوم',
            'اجل شهرين',
            'اجل شهرين ونصف',
            'اجل 3 شهور',
            'اجل 4 شهور',
          ].contains(provider.paymentMethod)
          ? provider.paymentMethod
          : null,
      decoration: const InputDecoration(
        labelText: 'طريقة السداد',
        border: OutlineInputBorder(),
      ),
      items: [
        'كاش مع المبيعات',
        'كاش مع السيارة',
        'تحويل بنكي',
        'اجل اسبوع',
        'اجل اسبوعين',
        'اجل 3 اسابيع',
        'اجل شهر',
        'اجل 45 يوم',
        'اجل شهرين',
        'اجل شهرين ونصف',
        'اجل 3 شهور',
        'اجل 4 شهور',
      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => provider.setPaymentMethod(v),
      validator: (v) => v == null ? 'مطلوب' : null,
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    FabricsCmOrderProvider provider,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) provider.setDeliveryDate(date);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ التوصيل',
          border: OutlineInputBorder(),
        ),
        child: Text(
          provider.deliveryDate != null
              ? intl.DateFormat('yyyy-MM-dd').format(provider.deliveryDate!)
              : ' ',
        ),
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    FabricsCmOrderProvider provider,
    bool isMobile,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index >= provider.quantityControllers.length) return null;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          // color removed to use default card theme
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header for row with delete button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'بند رقم ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (provider.quantityControllers.length > 1)
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => provider.removeItem(index),
                      ),
                  ],
                ),
                const Divider(),

                // Row 1: Fabric Specs (Multi-line)
                _buildTextField(
                  provider.fabricDetailsControllers[index],
                  'مواصفة القماش',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                // Row 2: Inch, Gauge, Stitch Length
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow =
                        constraints.maxWidth <
                        ResponsiveConstants.kMobileBreakpoint;
                    if (isNarrow) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  provider.inchControllers[index],
                                  'البوصة',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  provider.gaugeControllers[index],
                                  'الجوج',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            provider.stitchLengthControllers[index],
                            'طول الغرزة',
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              provider.inchControllers[index],
                              'البوصة',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              provider.gaugeControllers[index],
                              'الجوج',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              provider.stitchLengthControllers[index],
                              'طول الغرزة',
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Row 2: Yarn Company & Price & Quantity
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive layout
                    if (constraints.maxWidth <
                        ResponsiveConstants.kMobileBreakpoint) {
                      // Mobile/Narrow: Stacked or 2x2
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  provider.quantityControllers[index],
                                  'الكمية (كجم)',
                                  isRequired: true,
                                  isNumeric: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  provider.priceControllers[index],
                                  'السعر',
                                  isNumeric: true,
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            provider.spinningCompanyControllers[index],
                            'شركة الغزل',
                          ),
                        ],
                      );
                    } else {
                      // Desktop/Wide: Row
                      return Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              provider.quantityControllers[index],
                              'الكمية (كجم)',
                              isRequired: true,
                              isNumeric: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              provider.priceControllers[index],
                              'السعر',
                              isNumeric: true,
                              isRequired: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              provider.spinningCompanyControllers[index],
                              'شركة الغزل',
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }, childCount: provider.quantityControllers.length),
    );
  }

  Widget _buildFooterSection(
    BuildContext context,
    FabricsCmOrderProvider provider,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.add),
                label: const Text('إضافة بند '),
                onPressed: provider.addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
              ),
              // Bulk Add Removed/Disabled for now as logic changed significantly, or keep if generic
              /*
              ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.plus_square_on_square),
                label: const Text('إضافة جماعية'),
                onPressed: () async {
                  final count = await showBulkAddDialog(context);
                  if (count != null) {
                    provider.addItem(count: count);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
              ),
              */
            ],
          ),
          const SizedBox(height: 20),

          // Cost Section Removed
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إجمالي الكمية (كجم):',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.totalQuantity.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإجمالي النهائي:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.totalValue.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: provider.notesController,
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
          if (provider.existingOrder != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: CheckboxListTile(
                title: const Text('حفظ كفاتورة جديدة (نسخة)'),
                value: provider.saveAsNew,
                onChanged: (val) => provider.setSaveAsNew(val ?? false),
              ),
            ),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () async {
                        if (await provider.saveOrder(context, _formKey)) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم الحفظ بنجاح')),
                          );
                        }
                      },
                icon: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.floppy_disk, size: 24),
                label: const Text('حفظ', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => provider.generatePdf(context, _formKey),
                icon: const Icon(CupertinoIcons.doc_text_fill, size: 24),
                label: const Text('PDF', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
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
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
