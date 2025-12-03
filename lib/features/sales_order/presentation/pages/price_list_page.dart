import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

class PriceListPage extends StatelessWidget {
  const PriceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قوائم الأسعار'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPriceListTile(
            context,
            title: 'قائمة أسعار المصنع',
            assetPath: 'assets/docs/Factory Price List.pdf',
            icon: Icons.factory,
          ),
          const SizedBox(height: 16),
          _buildPriceListTile(
            context,
            title: 'قائمة أسعار التجار',
            assetPath: 'assets/docs/Trader Price List.pdf',
            icon: Icons.store,
          ),
        ],
      ),
    );
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
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PdfViewerPage(title: title, assetPath: assetPath),
            ),
          );
        },
      ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final String title;
  final String assetPath;

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: PdfPreview(
        build: (format) async {
          try {
            final byteData = await rootBundle.load(assetPath);
            return byteData.buffer.asUint8List();
          } catch (e) {
            // Fallback or error handling if file not found
            throw Exception('Error loading PDF: $e');
          }
        },
        useActions: false,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        maxPageWidth: 700,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) => Center(child: Text('حدث خطأ: $error')),
      ),
    );
  }
}
