import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';
import 'package:annex_sales_order/core/services/document_repository.dart';
import 'package:annex_sales_order/core/widgets/pdf_viewer_page.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';

class PriceListItem {
  final String title;
  final String url;

  PriceListItem({required this.title, required this.url});
}

class PriceListPage extends StatefulWidget {
  const PriceListPage({super.key});

  @override
  State<PriceListPage> createState() => _PriceListPageState();
}

class _PriceListPageState extends State<PriceListPage> {
  // Google Sheet URL for Price Lists
  static const String _sheetUrl =
      'https://docs.google.com/spreadsheets/d/11nspnKx9BEPkee6C52TmDIw4VXs5BAKfn-d6o7g7E6E/export?format=csv';

  List<PriceListItem> _priceLists = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPriceLists();
  }

  Future<void> _fetchPriceLists() async {
    final cacheFile = await _getCacheFile();

    try {
      final response = await http
          .get(Uri.parse(_sheetUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        await cacheFile.writeAsString(decodedBody); // Cache it
        _parseAndLoad(decodedBody);
      } else {
        // Server error, try cache
        await _loadFromCache(cacheFile, 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Network error, try cache
      await _loadFromCache(cacheFile, 'No internet connection');
    }
  }

  Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/price_list_cache.csv');
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

      final List<PriceListItem> loadedItems = [];

      // Skip header row (index 0)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 2) {
          final title = row[0].toString().trim();
          final url = row[1].toString().trim();

          if (title.isNotEmpty && url.isNotEmpty) {
            loadedItems.add(PriceListItem(title: title, url: url));
          }
        }
      }

      if (mounted) {
        setState(() {
          _priceLists = loadedItems;
          _isLoading = false;
          _errorMessage = null; // Clear error if loaded successfully
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
        title: const Text('Price Lists'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchPriceLists();
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

                      if (_priceLists.isEmpty &&
                          !_isLoading &&
                          _errorMessage == null)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('لا توجد قوائم أسعار متاحة حالياً.'),
                        ),

                      ..._priceLists.map(
                        (item) => Column(
                          children: [
                            _buildPriceListTile(
                              context,
                              title: item.title,
                              assetPath: item.url,
                              icon: _getIconForTitle(item.title),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

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

  IconData _getIconForTitle(String title) {
    if (title.contains('مصنع') || title.toLowerCase().contains('factory')) {
      return CupertinoIcons.building_2_fill;
    } else if (title.contains('تاجر') ||
        title.toLowerCase().contains('trader')) {
      return CupertinoIcons.cart_fill;
    }
    return CupertinoIcons.doc_text_fill;
  }

  Future<void> _shareFile(
    BuildContext context,
    String assetPath,
    String title,
  ) async {
    try {
      File fileToShare;

      if (assetPath.startsWith('http')) {
        // Use repository to get/cache file
        // Sanitize title for filename
        final safeTitle = title
            .replaceAll(
              RegExp(r'[^\w\s\u0600-\u06FF]+'),
              '',
            ) // Allow Arabic chars
            .replaceAll(' ', '_');
        final filename = '${safeTitle}_${assetPath.hashCode}.pdf';

        // Show loading indicator
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
        // Handle local assets
        final byteData = await rootBundle.load(assetPath);
        final bytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        fileToShare = File('${tempDir.path}/$title.pdf');
        await fileToShare.writeAsBytes(bytes, flush: true);
      }

      // 4. Share the file
      // Check if the device can share
      // ignore: deprecated_member_use
      final result = await Share.shareXFiles([
        XFile(fileToShare.path),
      ], text: 'مشاركة $title');

      if (result.status == ShareResultStatus.dismissed) {
        // Optional: handle dismissed
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في المشاركة: $e')));
      }
    }
  }

  Widget _buildPriceListTile(
    BuildContext context, {
    required String title,
    required String assetPath,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.share, color: Colors.blue),
              tooltip: 'مشاركة',
              onPressed: () => _shareFile(context, assetPath, title),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 20,
              color: Colors.grey,
            ),
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
}
