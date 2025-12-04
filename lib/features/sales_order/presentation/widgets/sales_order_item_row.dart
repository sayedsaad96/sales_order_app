import 'package:flutter/material.dart';
import '../../data/models/sales_order.dart';
import '../utils/sales_order_helpers.dart'; // For ItemControllers

class SalesOrderItemRow extends StatefulWidget {
  final int index;
  final SalesOrderItem item;
  final ItemControllers controllers;
  final bool isMobile;
  final VoidCallback onDelete;
  final VoidCallback onStateChanged; // To notify parent to rebuild (e.g. total value)

  const SalesOrderItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.controllers,
    required this.isMobile,
    required this.onDelete,
    required this.onStateChanged,
  });

  @override
  State<SalesOrderItemRow> createState() => _SalesOrderItemRowState();
}

class _SalesOrderItemRowState extends State<SalesOrderItemRow> {
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
            controller: widget.controllers.nameController,
            decoration: const InputDecoration(
              labelText: 'الصنف',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              widget.item.itemName = v;
              // No need to rebuild parent for name change
            },
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
                  onChanged: (v) {
                    setState(() {
                      widget.item.quantity = int.tryParse(v) ?? 0;
                    });
                    widget.onStateChanged();
                  },
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
                  onChanged: (v) => widget.item.unit = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controllers.priceController,
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    setState(() {
                      widget.item.price = double.tryParse(v) ?? 0;
                    });
                    widget.onStateChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.item.value.toStringAsFixed(2)} ج.م',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
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
          flex: 2,
          child: TextFormField(
            controller: widget.controllers.nameController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: (v) => widget.item.itemName = v,
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
            onChanged: (v) {
              setState(() {
                widget.item.quantity = int.tryParse(v) ?? 0;
              });
              widget.onStateChanged();
            },
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
            onChanged: (v) => widget.item.unit = v,
          ),
        ),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: widget.controllers.priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              filled: false,
            ),
            onChanged: (v) {
              setState(() {
                widget.item.price = double.tryParse(v) ?? 0;
              });
              widget.onStateChanged();
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            widget.item.value.toStringAsFixed(2),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}
