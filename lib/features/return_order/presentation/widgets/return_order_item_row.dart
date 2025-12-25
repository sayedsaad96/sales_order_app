import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/models/return_order.dart';

class ReturnOrderItemRow extends StatefulWidget {
  final int index;
  final ReturnOrderItem item;
  final bool isMobile;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const ReturnOrderItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.isMobile,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<ReturnOrderItemRow> createState() => _ReturnOrderItemRowState();
}

class _ReturnOrderItemRowState extends State<ReturnOrderItemRow> {
  late TextEditingController _itemController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController(text: widget.item.item);
    _quantityController = TextEditingController(
        text: widget.item.quantity == 0 ? '' : widget.item.quantity.toString());
    _unitController = TextEditingController(text: widget.item.unit);

    _itemController.addListener(_onItemChanged);
    _quantityController.addListener(_onQuantityChanged);
    _unitController.addListener(_onUnitChanged);
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onItemChanged() {
    widget.item.item = _itemController.text;
  }

  void _onQuantityChanged() {
    final val = double.tryParse(_quantityController.text) ?? 0;
    if (widget.item.quantity != val) {
      widget.item.quantity = val;
      widget.onUpdate();
    }
  }

  void _onUnitChanged() {
    widget.item.unit = _unitController.text;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: widget.index % 2 == 0
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: widget.isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextFormField(
            controller: _itemController,
            decoration: const InputDecoration(
              labelText: 'الصنف',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'الوحدة',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(CupertinoIcons.trash, color: Colors.red),
              onPressed: widget.onRemove,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _itemController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              filled: false,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              filled: false,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _unitController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              filled: false,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            CupertinoIcons.trash,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          onPressed: widget.onRemove,
        ),
      ],
    );
  }
}

