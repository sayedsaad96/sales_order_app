import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

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
      appBar: AppBar(title: Text(title), centerTitle: true),
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
        // We can disable internal sharing if we want to force the outer button,
        // but keeping it is fine as a backup.
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
