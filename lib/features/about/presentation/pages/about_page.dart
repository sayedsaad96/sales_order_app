import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';

import 'package:annex_sales_order/core/widgets/pdf_viewer_page.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/about/presentation/pages/bank_accounts_page.dart';

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
    try {
      final response = await http.get(Uri.parse(_sheetUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<List<dynamic>> rows = const CsvToListConverter().convert(
          decodedBody,
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
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load documents';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Check internet connection';
        });
      }
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
        trailing: const Icon(CupertinoIcons.eye),
        onTap: () {
          // If it's a Drive URL, PdfViewerPage handles it if logic is updated,
          // or we pass it as a URL.
          // PdfViewerPage usually takes 'assetPath' which initially meant local assets,
          // checking PdfViewerPage implementation is important, but typically it might need adjustment
          // if it only supports local assets.
          // Assuming PdfViewerPage can handle URLs or we need to check it.
          // For now, let's pass the URL.

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
