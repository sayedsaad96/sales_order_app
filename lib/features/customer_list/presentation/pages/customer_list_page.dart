import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:annex_sales_order/features/customer_list/data/models/customer.dart';
import 'package:annex_sales_order/features/customer_list/data/datasources/customer_local_data_source.dart';
import 'package:annex_sales_order/features/customer_list/presentation/pages/add_edit_customer_page.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _dataSource = CustomerLocalDataSource();
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDataSource();
  }

  Future<void> _initializeDataSource() async {
    try {
      await _dataSource.init();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل بيانات العملاء: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة العملاء'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(CupertinoIcons.list_dash),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditCustomerPage(),
            ),
          );
        },
        label: const Text('إضافة عميل'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    // Show error if initialization failed
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeDataSource,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    // Show loading while initializing
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show customer list
    return ValueListenableBuilder<Box<Customer>>(
      valueListenable: _dataSource.getListenable(),
      builder: (context, box, _) {
        final customers = box.values.toList();

        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا يوجد عملاء، قم بإضافة عميل جديد',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return _buildMobileView(customers);
            } else {
              return _buildDesktopView(customers);
            }
          },
        );
      },
    );
  }

  // --- Mobile/Tablet View (Cards) ---
  Widget _buildMobileView(List<Customer> customers) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        customer.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildActionButtons(index, customer),
                  ],
                ),
                const Divider(),
                _buildInfoRow(Icons.qr_code, 'Code', customer.customerCode ?? '-'),
                _buildInfoRow(
                  Icons.business,
                  'Type',
                  customer.customerType ?? '-',
                ),
                _buildInfoRow(
                  Icons.category,
                  'Industry',
                  customer.industry ?? '-',
                ),
                _buildInfoRow(
                  Icons.payment,
                  'Payment',
                  customer.paymentTerm ?? '-',
                ),
                _buildInfoRow(
                  Icons.label,
                  'Archetype',
                  customer.archtype ?? '-',
                ),
                _buildInfoRow(
                  Icons.info_outline,
                  'معلومات اضافيه',
                  customer.additionalInfo ?? '-',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // --- Desktop View (Enhanced Table) ---
  Widget _buildDesktopView(List<Customer> customers) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.grey.withValues(alpha: 0.2),
                dataTableTheme: DataTableThemeData(
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08);
                    }
                    return null;
                  }),
                ),
              ),
              child: DataTable(
                headingRowHeight: 56,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 64,
                columnSpacing: 24,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Customer Code',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Customer Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Archetype',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Industry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Payment Term',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'معلومات اضافيه',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: customers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final customer = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            customer.customerCode ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          customer.customerName,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      DataCell(_buildTag(customer.archtype)),
                      DataCell(Text(customer.customerType ?? '-')),
                      DataCell(Text(customer.industry ?? '-')),
                      DataCell(
                        Text(
                          customer.paymentTerm ?? '-',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            customer.additionalInfo ?? '-',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      DataCell(_buildActionButtons(index, customer)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String? text) {
    if (text == null || text.isEmpty) return const Text('-');
    Color color = Colors.grey;
    if (text.contains('Key') ||
        text.contains('Core') ||
        text.contains('Strategic')) {
      color = Colors.blue;
    }
    if (text.contains('Risk')) color = Colors.red;
    if (text.contains('Growth')) color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(int index, Customer customer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddEditCustomerPage(customer: customer, index: index),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(index),
        ),
      ],
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العميل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _dataSource.deleteCustomer(index);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
