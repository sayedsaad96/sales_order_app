import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/customer_list/data/models/customer.dart';
import 'package:annex_sales_order/features/customer_list/data/datasources/customer_local_data_source.dart';

class AddEditCustomerPage extends StatefulWidget {
  final Customer? customer;
  final int? index;

  const AddEditCustomerPage({super.key, this.customer, this.index});

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _dataSource = CustomerLocalDataSource();

  // Controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _termController = TextEditingController();

  // Dropdown Values
  String? _selectedArchetype;
  String? _selectedCustomerType;
  String? _selectedIndustry;

  // Options
  final List<String> _archetypes = [
    'Strategic Account',
    'Opportunistic Account',
    'Core Account',
    'Growth Account',
    'Risk Account',
    'Under Evaluation Account',
  ];
  final List<String> _customerTypes = [
    'Broker',
    'Factory',
    'Trader',
  ]; // '0' seen in screenshot
  final List<String> _industries = [
    'Yarn and Fabrics',
    'Essentials',
    'Elastic Tapes',
    'Rubber',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.customerName;
      _codeController.text = widget.customer!.customerCode;
      _termController.text = widget.customer!.paymentTerm ?? '';
      _selectedArchetype = widget.customer!.archtype;
      _selectedCustomerType = widget.customer!.customerType;
      _selectedIndustry = widget.customer!.industry;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _termController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        customerName: _nameController.text,
        customerCode: _codeController.text,
        paymentTerm: _termController.text,
        archtype: _selectedArchetype,
        customerType: _selectedCustomerType,
        industry: _selectedIndustry,
      );

      try {
        if (widget.index != null) {
          await _dataSource.updateCustomer(widget.index!, customer);
        } else {
          await _dataSource.addCustomer(customer);
        }
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving customer: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'إضافة عميل' : 'تعديل عميل'),
        centerTitle: true,
        leading: IconButton(
          icon:  Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Customer Name',
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _codeController,
                label: 'Customer Code',
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Archetype',
                value: _selectedArchetype,
                items: _archetypes,
                onChanged: (v) => setState(() => _selectedArchetype = v),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Customer Type',
                value: _selectedCustomerType,
                items: _customerTypes,
                onChanged: (v) => setState(() => _selectedCustomerType = v),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Industry',
                value: _selectedIndustry,
                items: _industries,
                onChanged: (v) => setState(() => _selectedIndustry = v),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _termController,
                label: 'Payment Term',
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('حفظ', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
