
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocumentRepository {
  // Time-To-Live: 24 Hours
  static const Duration _cacheTtl = Duration(hours: 24);

  Future<File> getPdf(String url, String filename) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final file = File('${docsDir.path}/$filename');

    bool shouldDownload = true;

    if (await file.exists()) {
      final lastModified = await file.lastModified();
      final difference = DateTime.now().difference(lastModified);

      if (difference < _cacheTtl) {
        // Cache is fresh, use it
        shouldDownload = false;
        // print('Using fresh cached file: $filename');
      } else {
        // Cache is stale, try to update
        // print('Cache is stale for: $filename, attempting update...');
      }
    }

    if (shouldDownload) {
      try {
        final response = await http.get(Uri.parse(url));
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
        }
        rethrow;
      }
    }

    return file;
  }
}
