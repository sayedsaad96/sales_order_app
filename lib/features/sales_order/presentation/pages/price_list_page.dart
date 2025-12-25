import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';
import 'package:annex_sales_order/core/services/document_repository.dart';
import 'package:annex_sales_order/core/widgets/pdf_viewer_page.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';

class PriceListPage extends StatelessWidget {
  const PriceListPage({super.key});

  static const String factoryPriceListPath =
      'https://drive.google.com/uc?export=download&id=1cRIjzY8AeQG62qGMo4mCmbsPE1BtB6HD';
  static const String traderPriceListPath =
      'https://drive.google.com/uc?export=download&id=1UFOBXRdIsLTNlZ8k4TJYpBgUx_rhIUTL';

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
        title: const Text('قوائم الأسعار'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              children: [
                _buildPriceListTile(
                  context,
                  title: 'قائمة أسعار المصنع',
                  assetPath: factoryPriceListPath,
                  icon: CupertinoIcons.building_2_fill,
                ),
                const SizedBox(height: 16),
                _buildPriceListTile(
                  context,
                  title: 'قائمة أسعار التاجر',
                  assetPath: traderPriceListPath,
                  icon: CupertinoIcons.cart_fill,
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

  Future<void> _shareFile(
    BuildContext context,
    String assetPath,
    String title,
  ) async {
    try {
      File fileToShare;

      if (assetPath.startsWith('http')) {
        // Use repository to get/cache file
        final safeTitle = title
            .replaceAll(RegExp(r'[^\w\s]+'), '')
            .replaceAll(' ', '_');
        final filename = '$safeTitle.pdf';
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
