import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/models/return_order.dart';
import '../utils/return_order_helpers.dart';

class ReturnOrderItemRow extends StatefulWidget {
  final int index;
  final ReturnOrderItem item;
  final ReturnItemControllers controllers;
  final bool isMobile;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const ReturnOrderItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.controllers,
    required this.isMobile,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<ReturnOrderItemRow> createState() => _ReturnOrderItemRowState();
}

class _ReturnOrderItemRowState extends State<ReturnOrderItemRow> {
  @override
  void initState() {
    super.initState();
    widget.controllers.itemController.addListener(_onItemChanged);
    widget.controllers.quantityController.addListener(_onQuantityChanged);
    widget.controllers.unitController.addListener(_onUnitChanged);
  }

  @override
  void dispose() {
    widget.controllers.itemController.removeListener(_onItemChanged);
    widget.controllers.quantityController.removeListener(_onQuantityChanged);
    widget.controllers.unitController.removeListener(_onUnitChanged);
    super.dispose();
  }

  void _onItemChanged() {
    widget.item.item = widget.controllers.itemController.text;
  }

  void _onQuantityChanged() {
    final val = double.tryParse(widget.controllers.quantityController.text) ?? 0;
    if (widget.item.quantity != val) {
      widget.item.quantity = val;
      widget.onUpdate();
    }
  }

  void _onUnitChanged() {
    widget.item.unit = widget.controllers.unitController.text;
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
            controller: widget.controllers.itemController,
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
                  controller: widget.controllers.quantityController,
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
                  controller: widget.controllers.unitController,
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
            controller: widget.controllers.itemController,
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
            controller: widget.controllers.quantityController,
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
            controller: widget.controllers.unitController,
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

