import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/invoice_local_data_source.dart';
import '../../data/models/sales_order.dart';
import 'sales_order_page.dart';
import '../../../../core/utils/performance_utils.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الفواتير: $e')),
        );
      }
    }
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
    return Column(
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
            .where((name) => name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        // Search bar
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
        // Results count
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'النتائج: ${filteredCustomers.length} من ${sortedCustomers.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        // Grid view
        Expanded(
          child: filteredCustomers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
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
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 2;
                    if (constraints.maxWidth > 900) {
                      crossAxisCount = 5;
                    } else if (constraints.maxWidth > 600) {
                      crossAxisCount = 3;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.folder,
                                          size: 50,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          customerName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '$count فواتير',
                                          style: const TextStyle(
                                              color: Colors.grey),
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
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInvoiceList() {
    final filteredInvoices = _invoices
        .where((i) => (i.customerName ?? "بدون اسم") == _selectedCustomer)
        .toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: ListView.builder(
        itemCount: filteredInvoices.length,
        itemBuilder: (context, index) {
          final invoice = filteredInvoices[index];
          return Dismissible(
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
                  'التاريخ: ${DateFormat('dd-MMM-yyyy').format(invoice.orderDate)}\nالقيمة: ${invoice.totalValue.toStringAsFixed(2)}',
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
                          SalesOrderPage(existingOrder: invoice),
                    ),
                  );
                  _loadInvoices();
                },
              ),
            ),
          );
        },
      ),
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
    );
  }
}
