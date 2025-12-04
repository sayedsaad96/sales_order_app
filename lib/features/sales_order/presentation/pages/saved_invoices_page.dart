import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/invoice_local_data_source.dart';
import '../../data/models/sales_order.dart';
import 'sales_order_page.dart';

class SavedInvoicesPage extends StatefulWidget {
  const SavedInvoicesPage({super.key});

  @override
  State<SavedInvoicesPage> createState() => _SavedInvoicesPageState();
}

class _SavedInvoicesPageState extends State<SavedInvoicesPage> {
  final _invoiceDataSource = InvoiceLocalDataSource();
  List<SalesOrder> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _loadInvoices() {
    setState(() {
      _invoices = _invoiceDataSource.getAllInvoices();
    });
  }

  Future<void> _deleteInvoice(SalesOrder invoice) async {
    await _invoiceDataSource.deleteInvoice(invoice);
    _loadInvoices();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير المحفوظة')),
      body: _invoices.isEmpty
          ? Column(
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
                    'لا توجد فواتير محفوظة',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView.builder(
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _invoices[index];
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
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
              ),
            ),
    );
  }
}
