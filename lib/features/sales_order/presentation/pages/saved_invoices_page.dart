import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:annex_sales_order/features/sales_order/data/datasources/invoice_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/data/models/sales_order.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/sales_order_page.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';

import 'package:annex_sales_order/core/utils/performance_utils.dart';

class SavedInvoicesPage extends StatefulWidget {
  const SavedInvoicesPage({super.key});

  @override
  State<SavedInvoicesPage> createState() => _SavedInvoicesPageState();
}

class _SavedInvoicesPageState extends State<SavedInvoicesPage> {
  final _invoiceDataSource = InvoiceLocalDataSource();
  final _searchController = TextEditingController();
  List<SalesOrder> _invoices = [];
  String? _selectedCustomer;
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, int> _customerCounts = {};
  List<String> _sortedCustomers = [];
  List<String> _filteredCustomers = [];

  ValueListenable<Box<SalesOrder>>? _boxListenable;

  @override
  void initState() {
    super.initState();
    // Use debouncing to avoid rebuilding on every keystroke
    _searchController.addListener(() {
      PerformanceUtils.debounce(
        duration: const Duration(milliseconds: 300),
        action: () {
          if (mounted) {
            setState(() {
              _searchQuery = _searchController.text;
              _filterCustomers();
            });
          }
        },
      );
    });
    
    _setupBoxListener();
    _loadInvoices();
  }

  void _setupBoxListener() {
    try {
      _boxListenable = _invoiceDataSource.getInvoicesListenable();
      _boxListenable?.addListener(_loadInvoices);
    } catch (e) {
      debugPrint('Failed to setup listener: $e');
    }
  }

  @override
  void dispose() {
    _boxListenable?.removeListener(_loadInvoices);
    _searchController.dispose();
    PerformanceUtils.cancelDebounce();
    super.dispose();
  }

  void _loadInvoices() {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
      });
      
      final invoices = _invoiceDataSource.getAllInvoices();
      
      setState(() {
        _invoices = invoices;
        _isLoading = false;
        _calculateCustomerFolders();
        _filterCustomers();

        // If the selected customer no longer has invoices, go back to folders
        if (_selectedCustomer != null) {
          final hasInvoices = _invoices.any(
            (i) => (i.customerName ?? "بدون اسم") == _selectedCustomer,
          );
          if (!hasInvoices) {
            _selectedCustomer = null;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الفواتير: $e')),
        );
      }
    }
  }

  void _calculateCustomerFolders() {
    final Map<String, int> counts = {};
    final Map<String, DateTime> lastDateMap = {};

    for (var invoice in _invoices) {
      final name = invoice.customerName ?? "بدون اسم";
      counts[name] = (counts[name] ?? 0) + 1;

      final invoiceDate = invoice.orderDate;
      if (!lastDateMap.containsKey(name) ||
          invoiceDate.isAfter(lastDateMap[name]!)) {
        lastDateMap[name] = invoiceDate;
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
            .where((name) =>
                name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
  }

  Future<void> _deleteInvoice(SalesOrder invoice) async {
    await _invoiceDataSource.deleteInvoice(invoice);
    _loadInvoices();
  }

  Future<void> _deleteCustomerFolder(String customerName) async {
    // Show loading
    setState(() => _isLoading = true);

    try {
      // Find all invoices for this customer
      final customerInvoices = _invoices.where(
        (i) => (i.customerName ?? "بدون اسم") == customerName,
      ).toList();

      // Delete them all
      for (var invoice in customerInvoices) {
        await _invoiceDataSource.deleteInvoice(invoice);
      }
      
      // Reload
      _loadInvoices();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف مجلد $customerName بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('خطأ أثناء الحذف: $e')),
        );
      }
      _loadInvoices(); // Reload to reset state
    }
  }

  Future<void> _confirmDeleteFolder(BuildContext context, String customerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المجلد'),
        content: Text('هل أنت متأكد من حذف مجلد "$customerName" وجميع الفواتير بداخله؟\nلا يمكن التراجع عن هذا الإجراء.'),
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

  Future<void> _confirmDelete(BuildContext context, SalesOrder invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الفاتورة؟'),
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
      _deleteInvoice(invoice);
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
              child: Image.asset('assets/images/logo.png', width: 150, height: 150),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'لا توجد فواتير محفوظة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerFolders() {
    if (_invoices.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Search bar
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
              // Results count
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  Icon(CupertinoIcons.search, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد نتائج للبحث',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final customerName = _filteredCustomers[index];
                  final count = _customerCounts[customerName] ?? 0;
                  return Stack(
                    children: [
                      Card(
                        elevation: 4,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCustomer = customerName;
                              _searchController.clear();
                            });
                          },
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
                                    '$count فواتير',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Delete Button (Top Left)
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
                },
                childCount: _filteredCustomers.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInvoiceList() {
    final filteredInvoices = _invoices
        .where((i) => (i.customerName ?? "بدون اسم") == _selectedCustomer)
        .toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Text(
                'عدد الفواتير: ${filteredInvoices.length}',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final invoice = filteredInvoices[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Dismissible(
                    key: Key(invoice.key.toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(CupertinoIcons.trash_fill, color: Colors.white),
                    ),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      _deleteInvoice(invoice);
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(
                          '${invoice.customerName ?? "بدون اسم"} - ${invoice.sn}',
                        ),
                        subtitle: Text(
                          'التاريخ: ${DateFormat('dd-MMM-yyyy').format(invoice.orderDate)}\nالقيمة: ${invoice.totalValue.toStringAsFixed(2)}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash_fill, color: Colors.red),
                          onPressed: () => _confirmDelete(context, invoice),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SalesOrderPage(existingOrder: invoice),
                            ),
                          );
                          _loadInvoices();
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: filteredInvoices.length,
          ),
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
        if (didPop) {
          return;
        }
        if (_selectedCustomer != null) {
          setState(() {
            _selectedCustomer = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedCustomer ?? 'الفواتير المحفوظة'),
          leading: _selectedCustomer != null
              ? IconButton(
                  icon: const Icon(CupertinoIcons.back),
                  onPressed: () {
                    setState(() {
                      _selectedCustomer = null;
                    });
                  },
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
        body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedCustomer == null
                  ? _buildCustomerFolders()
                  : _buildInvoiceList(),
        ),
        ),
      ),
    );
  }
}
