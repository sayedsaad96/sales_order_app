import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:annex_sales_order/core/widgets/pdf_viewer_page.dart';
import 'package:annex_sales_order/core/services/update_notification_service.dart';
import 'package:annex_sales_order/core/services/document_repository.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/about/presentation/pages/bank_accounts_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class PdfDocumentItem {
  final String title;
  final String url;

  PdfDocumentItem({required this.title, required this.url});
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // The Google Sheet URL for PDF Documents (Export as CSV)
  static const String _sheetUrl =
      'https://docs.google.com/spreadsheets/d/1Sj82OgBoBX7XGvF_sKSuDRVfFy9UMqvefJo3dHW_x08/export?format=csv';

  List<PdfDocumentItem> _pdfDocuments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPdfList();
  }

  Future<void> _fetchPdfList() async {
    final cacheFile = await _getCacheFile();

    try {
      final response = await http.get(Uri.parse(_sheetUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        await cacheFile.writeAsString(decodedBody); // Cache
        _parseAndLoad(decodedBody);
        UpdateNotificationService().silentlyUpdateMetadata();
      } else {
        await _loadFromCache(cacheFile, 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      await _loadFromCache(cacheFile, 'No internet connection');
    }
  }

  Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/about_docs_cache.csv');
  }

  Future<void> _loadFromCache(File file, String errorMsg) async {
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        _parseAndLoad(content);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('عرض نسخة محفوظة offline ($errorMsg)')),
          );
        }
      } catch (e) {
        _showError(errorMsg);
      }
    } else {
      _showError(errorMsg);
    }
  }

  void _parseAndLoad(String csvContent) {
    try {
        final List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvContent,
        );

        final List<PdfDocumentItem> loadedDocs = [];

        // Skip header row (index 0)
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length >= 2) {
            final title = row[0].toString().trim();
            final url = row[1].toString().trim();

            if (title.isNotEmpty && url.isNotEmpty) {
              loadedDocs.add(PdfDocumentItem(title: title, url: url));
            }
          }
        }

        if (mounted) {
          setState(() {
            _pdfDocuments = loadedDocs;
            _isLoading = false;
            _errorMessage = null;
          });
        }
    } catch (e) {
      _showError('Error parsing data');
    }
  }

  void _showError(String msg) {
     if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(CupertinoIcons.list_dash),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: const Text('About Us'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchPdfList();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo.png', width: 100),
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      // Dynamic PDF List Section
                      ..._pdfDocuments.map(
                        (doc) => _buildPdfTile(
                          context,
                          icon:
                              CupertinoIcons.doc_text_fill, // Generic doc icon
                          title: doc.title,
                          assetPath: doc.url,
                          isNetworkUrl: true,
                        ),
                      ),

                      if (_pdfDocuments.isEmpty &&
                          !_isLoading &&
                          _errorMessage == null)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No documents found.'),
                        ),

                      const SizedBox(height: 10),
                      _buildBankAccountTile(context),
                      const SizedBox(height: 25),
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 150,
                          height: 150,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPdfTile(
    BuildContext context, {
    required String title,
    required String assetPath,
    IconData? icon,
    bool isNetworkUrl = false,
  }) {
    // Determine icon based on title content for better visuals if possible, or use passed icon
    IconData displayIcon = icon ?? CupertinoIcons.doc_text;
    if (title.toLowerCase().contains('certificate')) {
      displayIcon = CupertinoIcons.shield_fill;
    } else if (title.toLowerCase().contains('profile')) {
      displayIcon = CupertinoIcons.building_2_fill;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(displayIcon, color: Colors.blue[800]),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
              IconButton(
                icon: const Icon(CupertinoIcons.cloud_download, color: Colors.blue),
                tooltip: 'تنزيل',
                onPressed: () => _downloadFile(context, assetPath, title),
              )
            else
              IconButton(
                icon: const Icon(CupertinoIcons.share, color: Colors.blue),
                tooltip: 'مشاركة',
                onPressed: () => _shareFile(context, assetPath, title),
              ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.eye),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PdfViewerPage(title: title, assetPath: assetPath),
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareFile(
    BuildContext context,
    String assetPath,
    String title,
  ) async {
    try {
      File fileToShare;

      if (assetPath.startsWith('http')) {
        final safeTitle = title
            .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]+'), '')
            .replaceAll(' ', '_');
        final filename = '${safeTitle}_${assetPath.hashCode}.pdf';

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('جاري تحميل الملف للمشاركة...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        fileToShare = await DocumentRepository().getPdf(assetPath, filename);
      } else {
        final byteData = await rootBundle.load(assetPath);
        final bytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        fileToShare = File('${tempDir.path}/$title.pdf');
        await fileToShare.writeAsBytes(bytes, flush: true);
      }

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(fileToShare.path)], text: 'مشاركة $title');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في المشاركة: $e')),
        );
      }
    }
  }

  Future<void> _downloadFile(
    BuildContext context,
    String url,
    String title,
  ) async {
    try {
      String? downloadsPath;
      if (Platform.isWindows) {
        downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      } else if (Platform.isMacOS || Platform.isLinux) {
        downloadsPath = '${Platform.environment['HOME']}/Downloads';
      }

      if (downloadsPath == null) {
        throw Exception('Could not determine downloads directory');
      }

      final safeTitle = title
          .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]+'), '')
          .replaceAll(' ', '_');
      final filename = '${safeTitle}_${url.hashCode}.pdf';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري بدء التنزيل...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final cachedFile = await DocumentRepository().getPdf(url, filename);
      final separator = Platform.isWindows ? '\\' : '/';
      final finalPath = '$downloadsPath$separator$safeTitle.pdf';
      await cachedFile.copy(finalPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تنزيل الملف بنجاح في: $downloadsPath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التنزيل: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildBankAccountTile(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(
          CupertinoIcons.money_dollar_circle,
          color: Colors.green,
        ), // Green for money
        title: const Text(
          'Bank Accounts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('الحسابات البنكية'),
        trailing: const Icon(CupertinoIcons.chevron_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BankAccountsPage()),
          );
        },
      ),
    );
  }
}
