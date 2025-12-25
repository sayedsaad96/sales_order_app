import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CartonCalculatorDialog extends StatefulWidget {
  final double? initialQuantity;

  const CartonCalculatorDialog({super.key, this.initialQuantity});

  @override
  State<CartonCalculatorDialog> createState() => _CartonCalculatorDialogState();
}

class _CartonCalculatorDialogState extends State<CartonCalculatorDialog> {
  final _cartonWeightController = TextEditingController();
  final _targetQuantityController = TextEditingController();
  final _numCartonsController = TextEditingController();

  double _calculatedActualQuantity = 0.0;
  int _calculatedNumCartons = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuantity != null && widget.initialQuantity! > 0) {
      _targetQuantityController.text = widget.initialQuantity.toString();
      // We don't auto-calculate here because we need weight, which is unknown initially
      // unless we want to assume a default weight? No, let user enter it.
    }

    _cartonWeightController.addListener(_recalculate);
    _targetQuantityController.addListener(_recalculateFromTarget);
    _numCartonsController.addListener(_recalculateFromCartons);
  }

  @override
  void dispose() {
    _cartonWeightController.dispose();
    _targetQuantityController.dispose();
    _numCartonsController.dispose();
    super.dispose();
  }

  void _recalculate() {
    if (_targetQuantityController.text.isNotEmpty) {
      _recalculateFromTarget();
    } else if (_numCartonsController.text.isNotEmpty) {
      _recalculateFromCartons();
    }
  }

  void _recalculateFromTarget() {
    final weight = double.tryParse(_cartonWeightController.text) ?? 0;
    final target = double.tryParse(_targetQuantityController.text) ?? 0;

    if (weight > 0 && target > 0) {
      final rawCartons = target / weight;
      final cartons = rawCartons.round();

      setState(() {
        _calculatedNumCartons = cartons;
        _calculatedActualQuantity = cartons * weight;
        // Do not update _numCartonsController text to avoid circular loop if fighting for focus
      });
    } else {
      _resetCalculations();
    }
  }

  void _recalculateFromCartons() {
    final weight = double.tryParse(_cartonWeightController.text) ?? 0;
    final cartons = int.tryParse(_numCartonsController.text) ?? 0;

    if (weight > 0 && cartons > 0) {
      setState(() {
        _calculatedActualQuantity = cartons * weight;
        _calculatedNumCartons = cartons;
      });
    } else {
      _resetCalculations();
    }
  }

  void _resetCalculations() {
    if (_calculatedActualQuantity != 0 || _calculatedNumCartons != 0) {
      setState(() {
        _calculatedActualQuantity = 0;
        _calculatedNumCartons = 0;
      });
    }
  }

  void _clearAll() {
    _cartonWeightController.clear();
    _targetQuantityController.clear();
    _numCartonsController.clear();
    _resetCalculations();
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsiveness
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 600;
    // For very small screens (< 350), keep it wider (90%) to ensure readability.
    // For standard phones, use the requested smaller size (80%).
    final dialogWidth = isDesktop
        ? 500.0
        : (width < 350 ? width * 0.9 : width * 0.8);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تقفيل الكراتين',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: _clearAll,
                    icon: const Icon(CupertinoIcons.refresh, color: Colors.grey),
                    tooltip: 'إعادة تعيين',
                  ),
                ],
              ),
              const Divider(thickness: 1, height: 20),

              const SizedBox(height: 10),

              // Weight Input (Always Required)
              _buildInputField(
                controller: _cartonWeightController,
                label: 'وزن الكرتونة (كجم)',
                icon: CupertinoIcons.gauge,
                autoFocus: true,
              ),

              const SizedBox(height: 20),

              // Calculation Options
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _targetQuantityController,
                      label: 'الكمية المطلوبة (تقريباً)',
                      icon: CupertinoIcons.number,
                      onChanged: (val) {
                        if (val.isNotEmpty &&
                            _numCartonsController.text.isNotEmpty) {
                          _numCartonsController.clear();
                        }
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'أو',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildInputField(
                      controller: _numCartonsController,
                      label: 'عدد الكراتين المباشر',
                      icon: CupertinoIcons.square_stack_3d_up,
                      onChanged: (val) {
                        if (val.isNotEmpty &&
                            _targetQuantityController.text.isNotEmpty) {
                          _targetQuantityController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Result Area
              AnimatedOpacity(
                opacity: _calculatedActualQuantity > 0 ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'الكمية الفعلية (الصافي)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calculatedActualQuantity > 0
                            ? _calculatedActualQuantity.toStringAsFixed(2)
                            : '---',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (_calculatedNumCartons > 0 &&
                          double.tryParse(_cartonWeightController.text) != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_calculatedNumCartons كرتونة  ×  ${_cartonWeightController.text} كجم',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Actions
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 10,
                overflowSpacing: 10,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: _calculatedActualQuantity > 0
                        ? () {
                            Navigator.of(
                              context,
                            ).pop(_calculatedActualQuantity);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    child: const Text(
                      'اعتماد الكمية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool autoFocus = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      autofocus: autoFocus,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }
}
