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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          FabricsCmOrderProvider(existingOrder: widget.existingOrder),
      child: Consumer<FabricsCmOrderProvider>(
        builder: (context, provider, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              primaryColor: Colors.indigo,
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Colors.indigo,
                secondary: Colors.indigoAccent,
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
                    onPressed: provider.resetForm,
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
                    Text(
                      'Fabrics & CM Sales Order',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(provider.snController, 'S/N'),
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
                      child: _buildTextField(provider.snController, 'S/N'),
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
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (val) => isRequired && (val?.isEmpty ?? true) ? 'مطلوب' : null,
    );
  }

  Widget _buildPaymentDropdown(FabricsCmOrderProvider provider) {
    return DropdownButtonFormField<String>(
      initialValue:
          [
            'كاش',
            'تحويل بنكي',
            'اجل اسبوعين ',
            'اجل 3 اسابيع ',
            'اجل شهر',
            'اجل شهرين',
            'اجل 3 شهور',
          ].contains(provider.paymentMethod)
          ? provider.paymentMethod
          : null,
      decoration: const InputDecoration(
        labelText: 'طريقة السداد',
        border: OutlineInputBorder(),
      ),
      items: [
        'كاش',
        'تحويل بنكي',
        'اجل اسبوعين ',
        'اجل 3 اسابيع ',
        'اجل شهر',
        'اجل شهرين',
        'اجل 3 شهور',
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
                        icon: const Icon(CupertinoIcons.delete, color: Colors.red),
                        onPressed: () => provider.removeItem(index),
                      ),
                  ],
                ),
                const Divider(),
                // Row 1: Qty, Price, Total (Auto calc)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        provider.quantityControllers[index],
                        'الكمية (كجم)',
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        provider.priceControllers[index],
                        'السعر',
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Text(
                    'مواصفات القماش',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                // Row 3: Grid of other specs
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    final int cols = isWide ? 4 : 2;
                    final List<Widget> gridFields = [
                      _buildTextField(
                        provider.yarnTypeControllers[index],
                        'نوع الغزل',
                        isRequired: true,
                      ),
                      _buildTextField(
                        provider.yarnCountControllers[index],
                        'نمرة الغزل',
                        isRequired: true,
                      ),
                      _buildTextField(
                        provider.lycraNumControllers[index],
                        'نمرة الليكرا',
                        isRequired: true,
                      ),
                      _buildTextField(
                        provider.lycraPercentControllers[index],
                        'نسبة الليكرا',
                        isRequired: true,
                      ),
                      _buildTextField(
                        provider.fabricTypeControllers[index],
                        'نوع القماش',
                        isRequired: true,
                      ),
                      _buildTextField(
                        provider.widthControllers[index],
                        'البوصة',
                        isRequired: true,
                      ),
                      _buildTextField(
                        provider.gaugeControllers[index],
                        'الجوج',
                        isRequired: true,
                      ),
                      _buildTextField(
                        provider.stitchLengthControllers[index],
                        'طول الغرزة',
                        isRequired: true,
                      ),
                      _buildTextField(
                        provider.spinningCompanyControllers[index],
                        'شركة الغزل',
                        isRequired: true,
                      ),
                    ];

                    final List<Widget> rows = [];
                    for (int i = 0; i < gridFields.length; i += cols) {
                      final int end = (i + cols < gridFields.length)
                          ? i + cols
                          : gridFields.length;
                      List<Widget> rowChildren = gridFields.sublist(i, end);

                      // Pad with empty Expandeds if needed to maintain size
                      while (rowChildren.length < cols) {
                        rowChildren.add(const SizedBox());
                      }

                      rows.add(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: rowChildren.asMap().entries.map((entry) {
                              final w = entry.value;
                              final isLast =
                                  entry.key == rowChildren.length - 1;

                              if (w is SizedBox && w.child == null) {
                                return Expanded(child: w);
                              }

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: isLast ? 0 : 8.0,
                                  ), // Add spacing except for last item
                                  child: w,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }
                    return Column(children: rows);
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
          ElevatedButton.icon(
            icon: const Icon(CupertinoIcons.add),
            label: const Text('إضافة بند جديد'),
            onPressed: provider.addItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي الكلي:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
