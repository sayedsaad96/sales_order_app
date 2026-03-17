import 'package:flutter/material.dart';
import 'package:annex_sales_order/core/widgets/confetti_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:annex_sales_order/features/sales_order/data/datasources/quotation_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/data/models/quotation.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/create_quotation_page.dart';
import 'package:annex_sales_order/features/sales_order/pdf/quotation_pdf_generator.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:annex_sales_order/core/services/settings_service.dart';
import 'package:printing/printing.dart';

class SavedQuotationsPage extends StatefulWidget {
  const SavedQuotationsPage({super.key});

  @override
  State<SavedQuotationsPage> createState() => _SavedQuotationsPageState();
}

class _SavedQuotationsPageState extends State<SavedQuotationsPage> {
  final _dataSource = QuotationLocalDataSource();
  List<Quotation> _quotations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  void _loadQuotations() {
    setState(() => _isLoading = true);
    try {
      _quotations = _dataSource.getQuotations();
      // Sort by date desc
      _quotations.sort((a, b) => b.date.compareTo(a.date));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuotation(Quotation quotation) async {
    await _dataSource.deleteQuotation(quotation);
    _loadQuotations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عروض الأسعار المحفوظة')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateQuotationPage()),
          );
          _loadQuotations();
        },
        child: const Icon(CupertinoIcons.add),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _quotations.isEmpty
              ? const Center(child: Text('لا توجد عروض أسعار محفوظة'))
              : ListView.builder(
                  itemCount: _quotations.length,
                  itemBuilder: (context, index) {
                    final quotation = _quotations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        title: Text(
                          '${quotation.customerName} - ${quotation.sn ?? "No SN"}',
                        ),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd').format(quotation.date),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                !kIsWeb &&
                                        (Platform.isWindows ||
                                            Platform.isMacOS ||
                                            Platform.isLinux)
                                    ? CupertinoIcons.cloud_download
                                    : CupertinoIcons.share,
                              ),
                              onPressed: () => _shareQuotation(quotation),
                            ),
                            IconButton(
                              icon: const Icon(
                                CupertinoIcons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(index),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateQuotationPage(
                                existingQuotation: quotation,
                              ),
                            ),
                          );
                          _loadQuotations();
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف عرض السعر'),
        content: const Text('هل أنت متأكد من الحذف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteQuotation(_quotations[index]);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _shareQuotation(Quotation quotation) async {
    try {
      final pdf = await QuotationPdfGenerator.generate(quotation);
      final bytes = await pdf.save();

      final settingsService = SettingsService();
      final strategy = settingsService.getInvoiceSaveStrategy();
      final defaultPath = settingsService.getDefaultSavePath();

      String? finalPath;
      final safeName = (quotation.customerName ?? 'Client').replaceAll(
        RegExp(r'[^\w\s\u0600-\u06FF]'),
        '',
      );
      final fileName = '${safeName}_Quotation_${quotation.sn}.pdf';

      if (!kIsWeb &&
          strategy == InvoiceSaveStrategy.auto &&
          defaultPath != null) {
        final customerDir = Directory('$defaultPath/$safeName');
        if (!await customerDir.exists()) {
          await customerDir.create(recursive: true);
        }
        finalPath = '${customerDir.path}/$fileName';
        final file = File(finalPath);
        await file.writeAsBytes(bytes);
        if (mounted) {
          ConfettiOverlay.show(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ الملف: $finalPath'),
              duration:
                  (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                  ? const Duration(seconds: 1)
                  : const Duration(seconds: 5),
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
      } else if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        // Desktop: Save As or Always Ask
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ عرض السعر',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(bytes);
          if (mounted) {
            ConfettiOverlay.show(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حفظ الملف بنجاح'),
                duration:
                    (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                    ? const Duration(seconds: 1)
                    : const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'مشاركة',
                  onPressed: () =>
                      Printing.sharePdf(bytes: bytes, filename: fileName),
                ),
              ),
            );
          }
        }
      } else {
        // Mobile or Web fallback: Share
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing PDF: $e')));
      }
    }
  }
}
