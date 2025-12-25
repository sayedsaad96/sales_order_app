import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:annex_sales_order/core/services/document_repository.dart';

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
    // Determine if we are on a mobile platform
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PdfPreview(
        build: (format) async {
          try {
            if (assetPath.startsWith('http')) {
              // Create a unique filename based on the URL or Title
              // Simple sanitize of title for filename
              final safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
              final filename = '$safeTitle.pdf';
              
              final file = await DocumentRepository().getPdf(assetPath, filename);
              return file.readAsBytes();
            } else {
              final byteData = await rootBundle.load(assetPath);
              return byteData.buffer.asUint8List();
            }
          } catch (e) {
            // Fallback or error handling
            throw Exception('Error loading PDF: $e');
          }
        },
        // Enable sharing on all platforms
        allowSharing: true,
        // Disable printing on mobile, enable on desktop
        allowPrinting: !isMobile,
        // Set the filename for export/share
        pdfFileName: '$title.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        maxPageWidth: 1200,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) => Center(child: Text('حدث خطأ: $error')),
      ),
    );
  }
}
