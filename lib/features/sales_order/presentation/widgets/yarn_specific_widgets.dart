import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:annex_sales_order/features/sales_order/presentation/widgets/carton_calculator_dialog.dart';

class YarnOrderHeader extends StatelessWidget {
  final TextEditingController snController;
  final DateTime orderDate;
  final Function(DateTime) onDateChanged;
  final bool isMobile;

  const YarnOrderHeader({
    super.key,
    required this.snController,
    required this.orderDate,
    required this.onDateChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isMobile
            ? Column(
                children: [
                  Center(
                    child: Text(
                      'Yarn Sales Order',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: snController,
                    decoration: const InputDecoration(labelText: 'S/N'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 10),
                  _buildDatePicker(context),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Yarn Sales Order',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 150, child: _buildDatePicker(context)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: snController,
                      decoration: const InputDecoration(labelText: 'S/N'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: orderDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) onDateChanged(date);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'التاريخ',
          border: OutlineInputBorder(),
        ),
        child: Text(DateFormat('dd-MMM-yyyy').format(orderDate)),
      ),
    );
  }
}

class YarnBranchAndTypeSection extends StatelessWidget {
  final String? selectedBranch;
  final Map<String, bool> orderTypes;
  final Function(String?) onBranchChanged;
  final Function(String, bool) onTypeChanged;
  final bool isMobile;

  const YarnBranchAndTypeSection({
    super.key,
    required this.selectedBranch,
    required this.orderTypes,
    required this.onBranchChanged,
    required this.onTypeChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBranchDropdown(),
                  const SizedBox(height: 10),
                  const Text('النوع: '),
                  _buildTypeCheckboxes(),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildBranchDropdown(isDesktop: true)),
                  const SizedBox(width: 20),
                  const Text('النوع: '),
                  ...orderTypes.keys.map((key) => _buildTypeTile(key)),
                ],
              ),
      ),
    );
  }

  Widget _buildBranchDropdown({bool isDesktop = false}) {
    return Container(
      width: isDesktop ? 150 : double.infinity,
      decoration: isDesktop
          ? BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: DropdownButtonFormField<String>(
        initialValue: selectedBranch,
        decoration: InputDecoration(
          labelText: 'الفرع',
          border: isDesktop ? InputBorder.none : const OutlineInputBorder(),
          contentPadding: isDesktop
              ? const EdgeInsets.symmetric(horizontal: 10)
              : null,
        ),
        items: [
          'القاهرة',
          'المحلة',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onBranchChanged,
        validator: (v) => v == null ? 'مطلوب' : null,
      ),
    );
  }

  Widget _buildTypeCheckboxes() {
    return Wrap(
      spacing: 10,
      children: orderTypes.keys.map((key) => _buildTypeTile(key)).toList(),
    );
  }

  Widget _buildTypeTile(String key) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: orderTypes[key],
          onChanged: (v) => onTypeChanged(key, v ?? false),
          activeColor: Colors.teal,
        ),
        Text(key),
      ],
    );
  }
}

class YarnCustomerInfoSection extends StatelessWidget {
  final TextEditingController customerNameController;
  final TextEditingController contactNameController;
  final TextEditingController mobileNumberController;
  final TextEditingController regionController;
  final TextEditingController deliveryPlaceController;
  final String? paymentMethod;
  final TextEditingController salesResponsibleController;
  final DateTime? deliveryDate;
  final String editQuantity;
  final String deliveryResponsibility;
  final Function(DateTime) onDeliveryDateChanged;
  final Function(String) onEditQuantityChanged;
  final Function(String) onDeliveryResponsibilityChanged;
  final Function(String?) onPaymentMethodChanged;
  final bool isMobile;

  const YarnCustomerInfoSection({
    super.key,
    required this.customerNameController,
    required this.contactNameController,
    required this.mobileNumberController,
    required this.regionController,
    required this.deliveryPlaceController,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.salesResponsibleController,
    required this.deliveryDate,
    required this.editQuantity,
    required this.deliveryResponsibility,
    required this.onDeliveryDateChanged,
    required this.onEditQuantityChanged,
    required this.onDeliveryResponsibilityChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isMobile)
              _buildMobileLayout(context)
            else
              _buildDesktopLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildTextField(customerNameController, 'اسم العميل', required: true),
        const SizedBox(height: 12),
        _buildTextField(contactNameController, 'اسم للتواصل'),
        const SizedBox(height: 12),
        _buildTextField(mobileNumberController, 'رقم للتواصل'),
        const SizedBox(height: 12),
        _buildTextField(regionController, 'المنطقة'),
        const SizedBox(height: 12),
        _buildTextField(deliveryPlaceController, 'مكان التسليم'),
        const SizedBox(height: 12),
        _buildDatePicker(context),
        const SizedBox(height: 12),
        _buildPaymentMethodDropdown(),
        const SizedBox(height: 12),
        _buildTextField(salesResponsibleController, 'مسئول البيع'),
        const SizedBox(height: 12),
        _buildRadioSections(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                customerNameController,
                'اسم العميل',
                required: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(regionController, 'المنطقة')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(contactNameController, 'اسم للتواصل'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(mobileNumberController, 'رقم للتواصل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(deliveryPlaceController, 'مكان التسليم'),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildDatePicker(context, isDesktop: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPaymentMethodDropdown()),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(salesResponsibleController, 'مسئول البيع'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDesktopRadioSections(),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
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
          ].contains(paymentMethod)
          ? paymentMethod
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
      onChanged: onPaymentMethodChanged,
      validator: (v) => v == null ? 'مطلوب' : null,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required ? (v) => v?.isEmpty ?? true ? 'مطلوب' : null : null,
    );
  }

  Widget _buildDatePicker(BuildContext context, {bool isDesktop = false}) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: deliveryDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) onDeliveryDateChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isDesktop ? 'تاريخ التوصيل' : 'تاريخ التوصيل',
          border: const OutlineInputBorder(),
        ),
        child: Text(
          deliveryDate != null
              ? (isDesktop
                    ? '${deliveryDate!.year}-${deliveryDate!.month}-${deliveryDate!.day}'
                    : DateFormat('dd-MMM-yyyy').format(deliveryDate!))
              : (isDesktop ? ' ' : ' '),
        ),
      ),
    );
  }

  Widget _buildRadioSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioGroup(
          'تعديل الكمية',
          ['الكمية المحددة', 'يفضل الزيادة', 'يفضل التخفيض'],
          editQuantity,
          onEditQuantityChanged,
        ),
        const SizedBox(height: 16),
        _buildRadioGroup(
          'مسئولية التوصيل',
          ['العميل', 'الشركة'],
          deliveryResponsibility,
          onDeliveryResponsibilityChanged,
          isRow: true,
        ),
      ],
    );
  }

  Widget _buildDesktopRadioSections() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'تعديل الكمية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...['الكمية المحددة', 'يفضل الزيادة', 'يفضل التخفيض'].map(
          (e) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: e,
                // ignore: deprecated_member_use
                groupValue: editQuantity,
                // ignore: deprecated_member_use
                onChanged: (v) => onEditQuantityChanged(v!),
              ),
              Text(e),
            ],
          ),
        ),
        const SizedBox(width: 24),
        const Text(
          'مسئولية التوصيل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...['العميل', 'الشركة'].map(
          (e) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: e,
                // ignore: deprecated_member_use
                groupValue: deliveryResponsibility,
                // ignore: deprecated_member_use
                onChanged: (v) => onDeliveryResponsibilityChanged(v!),
              ),
              Text(e),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadioGroup(
    String title,
    List<String> options,
    String groupValue,
    Function(String) onChanged, {
    bool isRow = false,
  }) {
    final list = options
        .map(
          (e) => isRow
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: e, // ignore: deprecated_member_use
                      groupValue: groupValue, // ignore: deprecated_member_use
                      // ignore: deprecated_member_use
                      onChanged: (v) => onChanged(v!),
                    ),
                    Text(e),
                    if (e != options.last) const SizedBox(width: 16),
                  ],
                )
              : RadioListTile<String>(
                  title: Text(e),
                  value: e,
                  // ignore: deprecated_member_use
                  groupValue: groupValue,
                  // ignore: deprecated_member_use
                  onChanged: (v) => onChanged(v!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        isRow ? Row(children: list) : Column(children: list),
      ],
    );
  }
}

class YarnItemsTable extends StatelessWidget {
  final List<TextEditingController> descriptionControllers;
  final List<TextEditingController> quantityControllers;
  final List<TextEditingController> unitControllers;
  final List<TextEditingController> priceControllers;
  final ValueNotifier<double> totalValueNotifier;
  final VoidCallback onAddItem;
  final Function(int) onRemoveItem;
  final bool isMobile;

  const YarnItemsTable({
    super.key,
    required this.descriptionControllers,
    required this.quantityControllers,
    required this.unitControllers,
    required this.priceControllers,
    required this.totalValueNotifier,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isMobile)
              _buildMobileItemList(context)
            else
              _buildDesktopTable(context),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(CupertinoIcons.add),
              label: const Text('إضافة صنف'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildTotalSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileItemList(BuildContext context) {
    return Column(
      children: List.generate(descriptionControllers.length, (index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'صنف #${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.delete, color: Colors.red),
                      onPressed: () => onRemoveItem(index),
                    ),
                  ],
                ),
                TextFormField(
                  controller: descriptionControllers[index],
                  decoration: const InputDecoration(
                    labelText: 'الصنف',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildQuantityField(context, index)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitControllers[index],
                        decoration: const InputDecoration(
                          labelText: 'الوحدة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceControllers[index],
                        decoration: const InputDecoration(
                          labelText: 'السعر',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildValueField(context, index)),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.5),
        5: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildTableHeader(context),
        ...List.generate(descriptionControllers.length, (index) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: descriptionControllers[index],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: unitControllers[index],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: _buildQuantityField(context, index),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: priceControllers[index],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: _buildValueField(context, index),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.delete, color: Colors.red),
                onPressed: () => onRemoveItem(index),
              ),
            ],
          );
        }),
      ],
    );
  }

  TableRow _buildTableHeader(BuildContext context) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.teal.shade700),
      children: [
        _buildHeaderCell('الصنف'),
        _buildHeaderCell('الوحدة'),
        _buildHeaderCell('الكمية'),
        _buildHeaderCell('السعر'),
        _buildHeaderCell('القيمة'),
        const SizedBox(),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityField(BuildContext context, int index) {
    return TextFormField(
      controller: quantityControllers[index],
      decoration: InputDecoration(
        labelText: isMobile ? 'الكمية' : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        suffixIcon: IconButton(
          icon: const Icon(CupertinoIcons.divide_circle, color: Colors.teal, size: 20),
          onPressed: () async {
            final currentQty = double.tryParse(quantityControllers[index].text);
            final result = await showDialog<double>(
              context: context,
              builder: (context) =>
                  CartonCalculatorDialog(initialQuantity: currentQty),
            );
            if (result != null) {
              quantityControllers[index].text = result.toStringAsFixed(2);
            }
          },
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildValueField(BuildContext context, int index) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        priceControllers[index],
        quantityControllers[index],
      ]),
      builder: (context, _) {
        final price = double.tryParse(priceControllers[index].text) ?? 0;
        final quantity = double.tryParse(quantityControllers[index].text) ?? 0;
        final value = price * quantity;
        return InputDecorator(
          decoration: InputDecoration(
            labelText: isMobile ? 'القيمة' : null,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Text(value.toStringAsFixed(2), textAlign: TextAlign.center),
        );
      },
    );
  }

  Widget _buildTotalSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.teal.shade700,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: totalValueNotifier,
        builder: (context, total, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي القيمة:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                total.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
