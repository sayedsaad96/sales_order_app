
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:annex_sales_order/features/sales_order/presentation/providers/quotation_provider.dart';
import 'package:annex_sales_order/features/sales_order/data/models/quotation.dart';
import 'package:annex_sales_order/features/sales_order/presentation/widgets/quotation_item_dialog.dart';
import 'package:annex_sales_order/core/services/settings_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:annex_sales_order/features/sales_order/pdf/quotation_pdf_generator.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CreateQuotationPage extends StatelessWidget {
  final Quotation? existingQuotation;

  const CreateQuotationPage({super.key, this.existingQuotation});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuotationProvider()..init(existingQuotation: existingQuotation),
      child: const _CreateQuotationView(),
    );
  }
}

class _CreateQuotationView extends StatelessWidget {
  const _CreateQuotationView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuotationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(provider.customerController.text.isEmpty ? 'إنشاء عرض سعر' : 'تعديل عرض سعر'),
        actions: [
            IconButton(
                icon: const Icon(CupertinoIcons.doc_text_fill),
                tooltip: 'إنشاء PDF',
                onPressed: () => _generatePdf(context, provider),
            ),
            IconButton(
                icon: const Icon(CupertinoIcons.floppy_disk),
                tooltip: 'حفظ',
                onPressed: () async {
                    await provider.saveQuotation();
                    if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('تم حفظ عرض السعر بنجاح')),
                        );
                    }
                },
            )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildHeaderSection(context, provider, isWide),
                          const SizedBox(height: 10),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),
                  _buildSliverItemsSection(context, provider, isWide),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildFooterFields(provider, isWide),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for FAB
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, provider),
        label: const Text('إضافة بنود'),
        icon: const Icon(CupertinoIcons.add),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('إجمالي البنود:'),
                          Text('${provider.items.length}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      if (provider.totalWaste > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي الهالك (2%):'),
                            Text(provider.totalWaste.toStringAsFixed(2), style: const TextStyle(fontSize: 14, color: Colors.orange)),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإجمالي الكلي:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${provider.totalValue.toStringAsFixed(2)} EGP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, QuotationProvider provider, bool isWide) {
      return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Text('بيانات العميل والعرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      if (isWide) ...[
                          Row(
                              children: [
                                  Expanded(
                                      child: TextField(
                                          controller: provider.customerController,
                                          decoration: const InputDecoration(labelText: 'اسم العميل', border: OutlineInputBorder()),
                                      ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: TextField(
                                          controller: provider.snController,
                                          decoration: const InputDecoration(labelText: 'رقم عرض السعر', border: OutlineInputBorder()),
                                      ),
                                  ),
                              ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                              children: [
                                  Expanded(
                                      child: _buildDateTile(context, 'التاريخ', provider.orderDate, (date) => provider.updateDate(date)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildDateTile(context, 'صالح حتى', provider.validUntil, (date) => provider.setValidity(date)),
                                  ),
                              ],
                          ),
                      ] else ...[
                          TextField(
                              controller: provider.customerController,
                              decoration: const InputDecoration(labelText: 'اسم العميل', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: provider.snController,
                              decoration: const InputDecoration(labelText: 'رقم عرض السعر', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          _buildDateTile(context, 'التاريخ', provider.orderDate, (date) => provider.updateDate(date)),
                          const SizedBox(height: 10),
                          _buildDateTile(context, 'صالح حتى', provider.validUntil, (date) => provider.setValidity(date)),
                      ],
                  ],
              ),
          ),
      );
  }

  Widget _buildFooterFields(QuotationProvider provider, bool isWide) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const Text('الشروط والملاحظات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                    controller: provider.termsController,
                    decoration: const InputDecoration(labelText: 'الشروط والأحكام', border: OutlineInputBorder(), alignLabelWithHint: true),
                    maxLines: isWide ? 3 : 5,
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: provider.notesController,
                    decoration: const InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(), alignLabelWithHint: true),
                    maxLines: 2,
                ),
            ],
          ),
        ),
      );
  }

  Widget _buildDateTile(BuildContext context, String title, DateTime? date, Function(DateTime) onPicked) {
      return Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
          ),
          child: ListTile(
              dense: true,
              title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(date != null ? DateFormat('yyyy-MM-dd').format(date) : 'غير محدد', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(CupertinoIcons.calendar, size: 20),
              onTap: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                  );
                  if (picked != null) onPicked(picked);
              },
          ),
      );
  }

  Widget _buildSliverItemsSection(BuildContext context, QuotationProvider provider, bool isWide) {
      if (provider.items.isEmpty) {
          return const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child: Column(
                          children: [
                              Icon(CupertinoIcons.doc_text_search, size: 64, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('لا توجد بنود مضافة لهذا العرض', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              Text('اضغط على "إضافة بنود" للبدء', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                      ),
                  ),
              ),
          );
      }
      
      return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: isWide 
            ? SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 260,
                ),
                delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildItemCard(context, provider, index),
                    childCount: provider.items.length,
                ),
            )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildItemCard(context, provider, index),
                    childCount: provider.items.length,
                ),
            ),
      );
  }

  Widget _buildItemCard(BuildContext context, QuotationProvider provider, int index) {
      final item = provider.items[index];
      final qc = provider.quantityControllers[index];
      final pc = provider.priceControllers[index];
      
      return Card(
          key: ValueKey('item_${item.hashCode}_$index'),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(
                                                getHeaderForItem(item), 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                                                maxLines: 2, 
                                                overflow: TextOverflow.ellipsis
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                                getSubHeaderForItem(item), 
                                                style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700), 
                                                maxLines: 2, 
                                                overflow: TextOverflow.ellipsis
                                            ),
                                        ],
                                    ),
                                ),
                                Column(
                                    children: [
                                        IconButton(
                                            icon: const Icon(CupertinoIcons.pencil_circle_fill, color: Colors.blue, size: 28),
                                            onPressed: () => _openItemDialog(context, provider, item.type, existingItem: item, index: index),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(height: 8),
                                        IconButton(
                                            icon: const Icon(CupertinoIcons.delete_solid, color: Colors.red, size: 24),
                                            onPressed: () => provider.removeItem(index),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                        ),
                                    ],
                                ),
                            ],
                         ),
                         if (item.type == 'fabric') ...[
                             const SizedBox(height: 8),
                             Wrap(
                                 spacing: 8,
                                 runSpacing: 4,
                                 children: [
                                     if (item.spinningCompany != null && item.spinningCompany!.isNotEmpty)
                                         _buildDetailChip('الشركة: ${item.spinningCompany}'),
                                     if (item.widthInches != null)
                                         _buildDetailChip('العرض: ${item.widthInches}"'),
                                     if (item.gauge != null)
                                         _buildDetailChip('G: ${item.gauge}'),
                                     if (item.lycraPercentage != null)
                                         _buildDetailChip('ليكرا: ${item.lycraPercentage}%'),
                                 ],
                             ),
                         ],
                         const Divider(height: 20),
                         Row(
                            children: [
                                Expanded(child: TextField(
                                    controller: qc,
                                    decoration: const InputDecoration(
                                        labelText: 'الكمية', 
                                        isDense: true, 
                                        border: OutlineInputBorder(),
                                        suffixText: 'كجم'
                                    ),
                                    keyboardType: TextInputType.number,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: TextField(
                                     controller: pc,
                                     decoration: const InputDecoration(
                                         labelText: 'السعر', 
                                         isDense: true, 
                                         border: OutlineInputBorder(),
                                         suffixText: 'ج.م'
                                     ),
                                     keyboardType: TextInputType.number,
                                )),
                            ],
                         ),
                         const SizedBox(height: 10),
                         Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                                 Text('إجمالي الصنف:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                 Text(
                                     '${((double.tryParse(qc.text) ?? 0) * (double.tryParse(pc.text) ?? 0)).toStringAsFixed(2)} EGP',
                                     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                 ),
                             ],
                         ),
                  ],
              ),
          ),
      );
  }

  Widget _buildDetailChip(String label) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade100),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, color: Colors.blue.shade900)),
      );
  }
  
  String getHeaderForItem(QuotationItem item) {
      if (item.type == 'standard') return item.itemName ?? 'مستلزمات';
      if (item.type == 'yarn') return item.description ?? 'غزل';
      if (item.type == 'fabric') return '${item.fabricType ?? "قماش"} - ${item.yarnType ?? ""} ${item.yarnCount ?? ""}';
      return 'بند غير معروف';
  }
  
  String getSubHeaderForItem(QuotationItem item) {
     if (item.type == 'fabric') {
         return 'ليكرا: ${item.lycraPercentage?.toString() ?? "0"}% - ${item.spinningCompany ?? ""}';
     }
     if (item.type == 'yarn') {
         return item.unit ?? 'كجم';
     }
     return item.description ?? item.unit ?? '';
  }

  void _showAddItemDialog(BuildContext context, QuotationProvider provider) {
      showModalBottomSheet(
          context: context,
          builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      const Text('إضافة بند جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ListTile(
                          leading: const Icon(CupertinoIcons.layers),
                          title: const Text('قماش (Fabric)'),
                          onTap: () {
                              Navigator.pop(context);
                              _openItemDialog(context, provider, 'fabric');
                          },
                      ),
                      ListTile(
                          leading: const Icon(CupertinoIcons.circle_grid_hex),
                          title: const Text('غزل (Yarn)'),
                          onTap: () {
                              Navigator.pop(context);
                              _openItemDialog(context, provider, 'yarn');
                          },
                      ),
                      ListTile(
                          leading: const Icon(CupertinoIcons.doc_text),
                          title: const Text('مستلزمات (Essential)'),
                          onTap: () {
                              Navigator.pop(context);
                              _openItemDialog(context, provider, 'standard');
                          },
                      ),
                  ],
              ),
          ),
      );
  }
  
  void _openItemDialog(BuildContext context, QuotationProvider provider, String type, {QuotationItem? existingItem, int? index}) async {
      final result = await showDialog(
          context: context,
          builder: (_) => QuotationItemDialog(type: type, existingItem: existingItem),
      );
      
      if (result != null && result is QuotationItem) {
          if (existingItem != null && index != null) {
              provider.updateItem(index, result);
          } else {
              provider.addItem(result);
          }
      }
  }

  Future<void> _generatePdf(BuildContext context, QuotationProvider provider) async {
    if (provider.customerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم العميل أولاً')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    width: 80,
                    errorBuilder: (context, error, stackTrace) => const Icon(CupertinoIcons.doc_text_fill, size: 80, color: Colors.blue),
                  ),
                  const SizedBox(height: 15),
                  const Text('جارٍ إعداد ملف PDF...'),
                  const SizedBox(height: 15),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await provider.saveQuotation(); // Ensure latest data is saved
      
      final quotation = Quotation(
        sn: provider.snController.text,
        customerName: provider.customerController.text,
        date: provider.orderDate,
        items: List.from(provider.items),
        notes: provider.notesController.text,
        validUntil: provider.validUntil,
        termsAndConditions: provider.termsController.text,
      );

      final pdf = await QuotationPdfGenerator.generate(quotation);
      final bytes = await pdf.save();

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading

      final settingsService = SettingsService();
      final strategy = settingsService.getInvoiceSaveStrategy();
      final defaultPath = settingsService.getDefaultSavePath();

      String? finalPath;
      final safeName = (quotation.customerName ?? 'Client').replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
      final fileName = '${safeName}_Quotation_${quotation.sn}.pdf';

      if (strategy == InvoiceSaveStrategy.auto && defaultPath != null) {
        final customerDir = Directory('$defaultPath/$safeName');
        if (!await customerDir.exists()) {
          await customerDir.create(recursive: true);
        }
        finalPath = '${customerDir.path}/$fileName';
        final file = File(finalPath);
        await file.writeAsBytes(bytes);
      } else {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          finalPath = await FilePicker.platform.saveFile(
            dialogTitle: 'حفظ عرض السعر',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          
          if (finalPath != null) {
            final file = File(finalPath);
            await file.writeAsBytes(bytes);
          } else {
            return;
          }
        } else {
          Directory? directory = await getExternalStorageDirectory();
          directory ??= await getApplicationDocumentsDirectory();
          finalPath = '${directory.path}/$fileName';
          final file = File(finalPath);
          await file.writeAsBytes(bytes);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الملف: $finalPath'),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'مشاركة',
              textColor: Colors.yellowAccent,
              onPressed: () {
                Printing.sharePdf(bytes: bytes, filename: fileName);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')),
        );
      }
    }
  }
}
