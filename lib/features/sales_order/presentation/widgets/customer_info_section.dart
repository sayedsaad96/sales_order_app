import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerInfoSection extends StatefulWidget {
  final bool isMobile;
  final TextEditingController customerNameController;
  final TextEditingController regionController;
  final TextEditingController salesResponsibleController;
  final TextEditingController deliveryPlaceController;
  final bool deliveryIncluded;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String? paymentMethod;
  final ValueChanged<bool> onDeliveryIncludedChanged;
  final ValueChanged<DateTime> onOrderDateChanged;
  final ValueChanged<DateTime> onDeliveryDateChanged;
  final ValueChanged<String?> onPaymentMethodChanged;

  const CustomerInfoSection({
    super.key,
    required this.isMobile,
    required this.customerNameController,
    required this.regionController,
    required this.salesResponsibleController,
    required this.deliveryPlaceController,
    required this.deliveryIncluded,
    required this.orderDate,
    required this.deliveryDate,
    required this.paymentMethod,
    required this.onDeliveryIncludedChanged,
    required this.onOrderDateChanged,
    required this.onDeliveryDateChanged,
    required this.onPaymentMethodChanged,
  });

  @override
  State<CustomerInfoSection> createState() => _CustomerInfoSectionState();
}

class _CustomerInfoSectionState extends State<CustomerInfoSection> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        TextFormField(
          controller: widget.customerNameController,
          decoration: const InputDecoration(labelText: 'اسم العميل'),
          validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: widget.regionController,
          decoration: const InputDecoration(labelText: 'المنطقة'),
        ),
        const SizedBox(height: 20),
        _buildDeliveryIncludedRadio(),
        const SizedBox(height: 18),
        _buildOrderDatePicker(),
        const SizedBox(height: 10),
        _buildDeliveryDatePicker(),
        const SizedBox(height: 10),
        TextFormField(
          controller: widget.salesResponsibleController,
          decoration: const InputDecoration(labelText: 'مسؤول البيع'),
        ),
        const SizedBox(height: 10),
        _buildPaymentMethodDropdown(),
        const SizedBox(height: 10),
        TextFormField(
          controller: widget.deliveryPlaceController,
          decoration: const InputDecoration(labelText: 'مكان التسليم'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Right Column
        Expanded(
          child: Column(
            children: [
              TextFormField(
                controller: widget.customerNameController,
                decoration: const InputDecoration(labelText: 'اسم العميل'),
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: widget.regionController,
                decoration: const InputDecoration(labelText: 'المنطقة'),
              ),
              const SizedBox(height: 20),
              _buildDeliveryIncludedRadio(),
              const SizedBox(height: 18),
              _buildDeliveryDatePicker(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Left Column
        Expanded(
          child: Column(
            children: [
              _buildOrderDatePicker(),
              const SizedBox(height: 10),
              TextFormField(
                controller: widget.salesResponsibleController,
                decoration: const InputDecoration(labelText: 'مسؤول البيع'),
              ),
              const SizedBox(height: 10),
              _buildPaymentMethodDropdown(),
              const SizedBox(height: 10),
              TextFormField(
                controller: widget.deliveryPlaceController,
                decoration: const InputDecoration(labelText: 'مكان التسليم'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryIncludedRadio() {
    return RadioGroup<bool>(
      groupValue: widget.deliveryIncluded,
      onChanged: (v) {
        if (v != null) widget.onDeliveryIncludedChanged(v);
      },
      child: Row(
        children: [
          const Text('شامل التوصيل: '),
          Radio<bool>(value: true),
          const Text('نعم'),
          Radio<bool>(value: false),
          const Text('لا'),
        ],
      ),
    );
  }

  Widget _buildOrderDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: widget.orderDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          widget.onOrderDateChanged(date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'التاريخ'),
        child: Text(DateFormat('dd-MMM-yyyy').format(widget.orderDate)),
      ),
    );
  }

  Widget _buildDeliveryDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: widget.deliveryDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          widget.onDeliveryDateChanged(date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'تاريخ التوصيل'),
        child: Text(
          widget.deliveryDate != null
              ? DateFormat('dd-MMM-yyyy').format(widget.deliveryDate!)
              : '',
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: widget.paymentMethod,
      decoration: const InputDecoration(labelText: 'طريقة السداد'),
      items:
          [
                'كاش',
                'تحويل بنكي',
                'اسبوعين',
                ' شهر',
                ' شهرين',
                ' 3 شهور',
              ]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
      onChanged: widget.onPaymentMethodChanged,
    );
  }
}
