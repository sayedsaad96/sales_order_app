import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';
import '../../../../core/widgets/pdf_viewer_page.dart';

class PriceListPage extends StatelessWidget {
  const PriceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قوائم الأسعار'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
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
                title: 'قائمة أسعار التاجر',
                assetPath: 'assets/docs/Trader Price List.pdf',
                icon: Icons.store,
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
    );
  }

  Future<void> _shareFile(BuildContext context, String assetPath, String title) async {
    try {
      // 1. Load asset bytes
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // 2. Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$title.pdf');

      // 3. Write bytes to file
      await tempFile.writeAsBytes(bytes, flush: true);

      // 4. Share the file
      // Check if the device can share
      // ignore: deprecated_member_use
      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'مشاركة $title',
      );

      if (result.status == ShareResultStatus.dismissed) {
         // Optional: handle dismissed
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في المشاركة: $e')),
        );
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
              icon: const Icon(Icons.share, color: Colors.blue),
              tooltip: 'مشاركة',
              onPressed: () => _shareFile(context, assetPath, title),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
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


