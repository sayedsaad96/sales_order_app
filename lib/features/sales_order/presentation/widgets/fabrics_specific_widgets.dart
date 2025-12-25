import 'package:flutter/material.dart';

class FabricsBranchAndTypeSection extends StatelessWidget {
  final String? selectedBranch;
  final Map<String, bool> orderTypes;
  final Function(String?) onBranchChanged;
  final Function(String, bool) onTypeChanged;
  final bool isMobile;

  const FabricsBranchAndTypeSection({
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
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBranchDropdown(context),
                  const SizedBox(height: 10),
                  const Text('النوع: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildTypeCheckboxes(),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildBranchDropdown(context, isDesktop: true)),
                  const SizedBox(width: 20),
                  const Text('النوع: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...orderTypes.keys.map((key) => _buildTypeTile(key)),
                ],
              ),
      ),
    );
  }

  Widget _buildBranchDropdown(BuildContext context, {bool isDesktop = false}) {
    return Container(
      width: isDesktop ? 200 : double.infinity,
      decoration: isDesktop
          ? BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
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
        items: ['القاهرة', 'المحلة']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onBranchChanged,
        validator: (v) => v == null ? 'مطلوب' : null,
      ),
    );
  }

  Widget _buildTypeCheckboxes() {
    return Wrap(
      spacing: 12,
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
          activeColor: Colors.indigo, // Use Fabrics theme color
        ),
        Text(key),
      ],
    );
  }
}
