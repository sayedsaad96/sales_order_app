import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sales_order_page.dart';
import 'yarn_sales_order_page.dart';
import '../../../../core/widgets/app_drawer.dart';

class SalesOrderContainerPage extends StatefulWidget {
  final int initialIndex;

  const SalesOrderContainerPage({super.key, this.initialIndex = 0});

  @override
  State<SalesOrderContainerPage> createState() =>
      _SalesOrderContainerPageState();
}

class _SalesOrderContainerPageState extends State<SalesOrderContainerPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: const [SalesOrderPage(), YarnSalesOrderPage()],
      ),
      bottomNavigationBar: _buildFloatingNavBar(context),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: FontAwesomeIcons.linktree,
            label: 'Essential',
            activeColor: Colors.blue.shade600,
            activeBg: Colors.blue.shade50,
          ),
          _buildNavItem(
            index: 1,
            icon: FontAwesomeIcons.yarn,
            label: 'Yarn',
            activeColor: Colors.teal.shade600,
            activeBg: Colors.teal.shade50,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.grey.shade600,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
