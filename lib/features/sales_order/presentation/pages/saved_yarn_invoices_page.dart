import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/yarn_invoice_local_data_source.dart';
import '../../data/models/yarn_sales_order.dart';
import 'yarn_sales_order_page.dart';

import '../../../../core/utils/performance_utils.dart';

class SavedYarnInvoicesPage extends StatefulWidget {
  const SavedYarnInvoicesPage({super.key});

  @override
  State<SavedYarnInvoicesPage> createState() => _SavedYarnInvoicesPageState();
}

class _SavedYarnInvoicesPageState extends State<SavedYarnInvoicesPage> {
  final _invoiceDataSource = YarnInvoiceLocalDataSource();
  final _searchController = TextEditingController();
  List<YarnSalesOrder> _invoices = [];
  String? _selectedCustomer;
  bool _isLoading = true;
  String _searchQuery = '';

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
            });
          }
        },
      );
    });
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    PerformanceUtils.cancelDebounce();
    super.dispose();
  }

  void _loadInvoices() {
    try {
      setState(() {
        _isLoading = true;
      });

      final invoices = _invoiceDataSource.getAllInvoices();

      setState(() {
        _invoices = invoices;
        _isLoading = false;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل الفواتير: $e')));
      }
    }
  }

  Future<void> _deleteInvoice(YarnSalesOrder invoice) async {
    await _invoiceDataSource.deleteInvoice(invoice);
    _loadInvoices();
  }

  Future<void> _deleteCustomerFolder(String customerName) async {
    // Show loading
    setState(() => _isLoading = true);

    try {
      // Find all invoices for this customer
      final customerInvoices = _invoices
          .where((i) => (i.customerName ?? "بدون اسم") == customerName)
          .toList();

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء الحذف: $e')));
      }
      _loadInvoices(); // Reload to reset state
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
          'هل أنت متأكد من حذف مجلد "$customerName" وجميع الفواتير بداخله؟\nلا يمكن التراجع عن هذا الإجراء.',
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

  Future<void> _confirmDelete(
    BuildContext context,
    YarnSalesOrder invoice,
  ) async {
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

    // Build customer counts and last date map
    final Map<String, int> customerCounts = {};
    final Map<String, DateTime> customerLastDate = {};

    for (var invoice in _invoices) {
      final name = invoice.customerName ?? "بدون اسم";
      customerCounts[name] = (customerCounts[name] ?? 0) + 1;

      // Track latest date
      final invoiceDate = invoice.orderDate;
      if (!customerLastDate.containsKey(name) ||
          invoiceDate.isAfter(customerLastDate[name]!)) {
        customerLastDate[name] = invoiceDate;
      }
    }

    // Sort customer names by last date (Descending: Newest first)
    final sortedCustomers = customerCounts.keys.toList()
      ..sort((a, b) {
        final dateA = customerLastDate[a]!;
        final dateB = customerLastDate[b]!;
        // Compare B to A for descending order
        return dateB.compareTo(dateA);
      });

    // Filter based on search query
    final filteredCustomers = _searchQuery.isEmpty
        ? sortedCustomers
        : sortedCustomers
              .where(
                (name) =>
                    name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // Search bar and Stats wrapped in a sliver
        SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث عن عميل...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'النتائج: ${filteredCustomers.length} من ${sortedCustomers.length}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
        
        // Grid View as a Sliver
        if (filteredCustomers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد نتائج للبحث',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                  final customerName = filteredCustomers[index];
                  final count = customerCounts[customerName] ?? 0;
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
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.folder,
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
                            onTap: () => _confirmDeleteFolder(
                              context,
                              customerName,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline,
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
                childCount: filteredCustomers.length,
              ),
            ),
          ),
      ],
    );
  }

  double _calculateTotalValue(YarnSalesOrder invoice) {
    double total = 0;
    for (var item in invoice.items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  Widget _buildInvoiceList() {
    final filteredInvoices = _invoices
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
              final totalValue = _calculateTotalValue(invoice);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Dismissible(
                    key: Key(invoice.key.toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
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
                          'التاريخ: ${DateFormat('dd-MMM-yyyy').format(invoice.orderDate)}\nالقيمة: ${totalValue.toStringAsFixed(2)}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, invoice),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  YarnSalesOrderPage(existingOrder: invoice),
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
        // Bottom padding for scrollability
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define Teal Theme for this page
    final tealTheme = Theme.of(context).copyWith(
      primaryColor: Colors.teal,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.teal,
        secondary: Colors.tealAccent,
        surfaceContainerHigh: Colors.teal.withValues(alpha: 0.1),
      ),
      appBarTheme: Theme.of(context).appBarTheme.copyWith(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: Theme.of(context).floatingActionButtonTheme
          .copyWith(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelStyle: const TextStyle(color: Colors.teal),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.teal,
        selectionHandleColor: Colors.teal,
        selectionColor: Color(0x4D009688), // Teal with opacity
      ),
    );

    return Theme(
      data: tealTheme,
      child: PopScope(
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
            title: Text(_selectedCustomer ?? 'فواتير الغزول المحفوظة'),
            leading: _selectedCustomer != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedCustomer = null;
                      });
                    },
                  )
                : null,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedCustomer == null
              ? _buildCustomerFolders()
              : _buildInvoiceList(),
        ),
      ),
    );
  }
}
