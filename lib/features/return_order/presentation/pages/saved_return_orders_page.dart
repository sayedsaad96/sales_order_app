import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/datasources/return_order_local_data_source.dart';
import '../../data/models/return_order.dart';
import 'return_order_page.dart';
import '../../../../core/widgets/app_drawer.dart';

// Assuming core/utils exists as seen in SavedInvoicesPage path: ../../../../core/utils/performance_utils.dart

class SavedReturnOrdersPage extends StatefulWidget {
  const SavedReturnOrdersPage({super.key});

  @override
  State<SavedReturnOrdersPage> createState() => _SavedReturnOrdersPageState();
}

class _SavedReturnOrdersPageState extends State<SavedReturnOrdersPage> {
  final _dataSource = ReturnOrderLocalDataSource();
  final _searchController = TextEditingController();
  List<ReturnOrder> _orders = [];
  String? _selectedCustomer;
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, int> _customerCounts = {};
  List<String> _sortedCustomers = [];
  List<String> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Simple debounce logic if PerformanceUtils is not available or to simplify imports
      // But assuming it is available since copied from SavedInvoicesPage
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _filterCustomers();
        });
      }
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    try {
      setState(() => _isLoading = true);
      // Assuming getReturnOrders returns List<ReturnOrder>
      final orders = _dataSource.getReturnOrders();

      setState(() {
        _orders = orders;
        _isLoading = false;
        _calculateCustomerFolders();
        _filterCustomers();

        if (_selectedCustomer != null) {
          final hasOrders = _orders.any(
            (i) => (i.customerName ?? "بدون اسم") == _selectedCustomer,
          );
          if (!hasOrders) {
            _selectedCustomer = null;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل المرتجعات: $e')));
      }
    }
  }

  void _calculateCustomerFolders() {
    final Map<String, int> counts = {};
    final Map<String, DateTime> lastDateMap = {};

    for (var order in _orders) {
      final name = order.customerName ?? "بدون اسم";
      counts[name] = (counts[name] ?? 0) + 1;
      final orderDate = order.returnDate;
      if (!lastDateMap.containsKey(name) ||
          orderDate.isAfter(lastDateMap[name]!)) {
        lastDateMap[name] = orderDate;
      }
    }

    _customerCounts = counts;
    _sortedCustomers = counts.keys.toList()
      ..sort((a, b) => lastDateMap[b]!.compareTo(lastDateMap[a]!));
  }

  void _filterCustomers() {
    _filteredCustomers = _searchQuery.isEmpty
        ? _sortedCustomers
        : _sortedCustomers
              .where(
                (name) =>
                    name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
  }

  Future<void> _deleteOrder(ReturnOrder order) async {
    await _dataSource.deleteReturnOrder(order);
    _loadOrders();
  }

  Future<void> _deleteCustomerFolder(String customerName) async {
    setState(() => _isLoading = true);
    try {
      final customerOrders = _orders
          .where((i) => (i.customerName ?? "بدون اسم") == customerName)
          .toList();

      for (var order in customerOrders) {
        await _dataSource.deleteReturnOrder(order);
      }

      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف مجلد $customerName بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء الحذف: $e')));
      }
      _loadOrders();
    }
  }

  Future<void> _confirmDeleteFolder(
    BuildContext context,
    String customerName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المجلد'),
        content: Text(
          'هل أنت متأكد من حذف مجلد "$customerName" وجميع المرتجعات بداخله؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteCustomerFolder(customerName);
    }
  }

  Future<void> _confirmDelete(BuildContext context, ReturnOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المرتجع؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteOrder(order);
    }
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'لا توجد مرتجعات محفوظة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerFolders() {
    if (_orders.isEmpty) {
      return _buildEmptyState();
    }
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث عن عميل...',
                    prefixIcon: const Icon(CupertinoIcons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(CupertinoIcons.clear_circled),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _filterCustomers();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    'النتائج: ${_filteredCustomers.length} من ${_sortedCustomers.length}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),

        if (_filteredCustomers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد نتائج للبحث',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(10),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900
                    ? 5
                    : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final customerName = _filteredCustomers[index];
                final count = _customerCounts[customerName];
                return Stack(
                  children: [
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedCustomer = customerName;
                          _searchController.clear();
                        }),
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.folder,
                                  size: 44,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count مرتجع',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () =>
                              _confirmDeleteFolder(context, customerName),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.trash,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }, childCount: _filteredCustomers.length),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderList() {
    final filteredOrders = _orders
        .where((i) => (i.customerName ?? "بدون اسم") == _selectedCustomer)
        .toList();

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Text(
                'عدد الطلبات: ${filteredOrders.length}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final order = filteredOrders[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Dismissible(
                  key: Key(order.key.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      CupertinoIcons.trash_fill,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (_) => _deleteOrder(order),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      title: Text(
                        '${order.customerName ?? "بدون اسم"} - ${order.sn}',
                      ),
                      subtitle: Text(
                        'التاريخ: ${intl.DateFormat('dd-MMM-yyyy').format(order.returnDate)}\nإجمالي الكمية: ${order.totalQuantity.toStringAsFixed(2)}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(
                          CupertinoIcons.trash_fill,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, order),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReturnOrderPage(existingOrder: order),
                          ),
                        );
                        _loadOrders();
                      },
                    ),
                  ),
                ),
              ),
            );
          }, childCount: filteredOrders.length),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedCustomer == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedCustomer != null) {
          setState(() => _selectedCustomer = null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedCustomer ?? 'طلبات المرتجعات المحفوظة'),
          leading: _selectedCustomer != null
              ? IconButton(
                  icon: const Icon(CupertinoIcons.back),
                  onPressed: () => setState(() => _selectedCustomer = null),
                )
              : Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(CupertinoIcons.list_dash),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Menu',
                  ),
                ),
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedCustomer == null
            ? _buildCustomerFolders()
            : _buildOrderList(),
      ),
    );
  }
}
