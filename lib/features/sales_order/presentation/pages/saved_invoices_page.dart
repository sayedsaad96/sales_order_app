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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير المحفوظة')),
      body: _invoices.isEmpty
          ? const Center(child: Text('لا توجد فواتير محفوظة'))
          : ListView.builder(
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
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalesOrderPage(
                              existingOrder: invoice,
                            ),
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
}
