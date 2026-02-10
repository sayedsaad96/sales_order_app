import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/tax_invoice_request.dart';
import '../../data/datasources/tax_invoice_local_data_source.dart';
import 'package:intl/intl.dart' as intl;

class SavedTaxInvoicesScreen extends StatefulWidget {
  const SavedTaxInvoicesScreen({super.key});

  @override
  State<SavedTaxInvoicesScreen> createState() => _SavedTaxInvoicesScreenState();
}

class _SavedTaxInvoicesScreenState extends State<SavedTaxInvoicesScreen> {
  final _dataSource = TaxInvoiceLocalDataSource();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الفواتير المحفوظة'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ValueListenableBuilder<Box<TaxInvoiceRequest>>(
          valueListenable: _dataSource.getListenable(),
          builder: (context, box, _) {
            final requests = box.values.toList().reversed.toList();

            if (requests.isEmpty) {
              return const Center(
                child: Text('لا توجد طلبات محفوظة'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                
                // Hive index for non-reversed list is needed for update/delete
                // But we can use the key if we use put/delete with key
                // Or calculate the actual index in the box
                final actualIndex = box.length - 1 - index;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      request.customerNameOnTaxCard,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('ساب: ${request.sapCustomerCode}'),
                        Text('الصنف: ${request.itemName}'),
                        if (request.fromDate != null || request.toDate != null)
                          Text(
                            'الفترة: ${request.fromDate != null ? intl.DateFormat('yyyy/MM/dd').format(request.fromDate!) : ''} - ${request.toDate != null ? intl.DateFormat('yyyy/MM/dd').format(request.toDate!) : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, actualIndex),
                    ),
                    onTap: () {
                      Navigator.pop(context, {'request': request, 'index': actualIndex});
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الطلب'),
          content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                _dataSource.delete(index);
                Navigator.pop(context);
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
