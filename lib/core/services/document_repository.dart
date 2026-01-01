
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocumentRepository {
  // Time-To-Live: 7 Days
  static const Duration _cacheTtl = Duration(days: 7);

  Future<File> getPdf(String url, String filename) async {
    final downloadUrl = _convertDriveUrl(url);
    final docsDir = await getApplicationDocumentsDirectory();
    final file = File('${docsDir.path}/$filename');

    bool shouldDownload = true;

    if (await file.exists()) {
      // 1. Check if file is a valid PDF
      final isValidPdf = await _isValidPdf(file);
      if (!isValidPdf) {
        // print('Invalid PDF found in cache (HTML or corrupted). Deleting...');
        await file.delete();
        shouldDownload = true;
      } else {
        // 2. Check TTL
        final lastModified = await file.lastModified();
        final difference = DateTime.now().difference(lastModified);

        if (difference < _cacheTtl) {
          shouldDownload = false;
        }
      }
    }

    if (shouldDownload) {
      try {
        final response = await http.get(Uri.parse(downloadUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes, flush: true);
          // print('Downloaded and cached: $filename');
        } else {
          // print('Failed to download $filename: ${response.statusCode}');
          // If download failed but we have a local file (even if stale), use it
          if (await file.exists()) {
            // print('Fallback to stale cache for: $filename');
            return file;
          }
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      } catch (e) {
        // print('Error downloading $filename: $e');
        // Network error? Fallback to local if exists
        if (await file.exists()) {
          // print('Fallback to stale cache (offline) for: $filename');
          return file;
          // ignore: dead_code
        }
        rethrow;
      }
    }

    return file;
  }

  Future<bool> _isValidPdf(File file) async {
    try {
      if (await file.length() < 5) return false;
      final bytes = await file.openRead(0, 5).first;
      final header = String.fromCharCodes(bytes);
      // More robust check: %PDF is often at start, but sometimes has BOM or whitespace
      return header.contains('%PDF');
    } catch (_) {
      return false;
    }
  }

  String _convertDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
      // Extract ID from various formats
      // 1. /file/d/ID/view
      // 2. id=ID
      RegExp regExp = RegExp(r'\/file\/d\/([a-zA-Z0-9_-]+)|id=([a-zA-Z0-9_-]+)');
      Match? match = regExp.firstMatch(url);
      
      if (match != null) {
        String? id = match.group(1) ?? match.group(2);
        if (id != null) {
          return 'https://drive.google.com/uc?export=download&id=$id';
        }
      }
    }
    return url;
  }
}
