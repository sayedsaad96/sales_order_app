import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocumentRepository {
  // Check for updates once every 24 hours
  static const Duration _cacheTtl = Duration(hours: 24);
  Map<String, int> _metadata = {};
  bool _metadataLoaded = false;

  Future<File> getPdf(String url, String filename) async {
    await _ensureMetadataLoaded();

    final downloadUrl = _convertDriveUrl(url);
    final docsDir = await getApplicationDocumentsDirectory();
    final file = File('${docsDir.path}/$filename');

    bool shouldDownload = true;
    
    // Check local file first
    if (await file.exists()) {
      // 1. Check if file is a valid PDF
      final isValidPdf = await _isValidPdf(file);
      if (!isValidPdf) {
        // Corrupted, clean up
        try { await file.delete(); } catch (_) {}
        shouldDownload = true;
      } else {
        // 2. Check TTL
        final lastChecked = _metadata[filename];
        final now = DateTime.now().millisecondsSinceEpoch;
        
        if (lastChecked != null && (now - lastChecked) < _cacheTtl.inMilliseconds) {
           // Within TTL, skip network check
           shouldDownload = false;
        } else {
           // 3. Online Check (Fail-safe)
          try {
            // Short timeout for check. If it fails, assume local is good.
            final remoteSize = await _getRemoteFileSize(downloadUrl);
            
            if (remoteSize != null) {
              final localSize = await file.length();
              if (remoteSize == localSize) {
                // Up to date
                _updateMetadata(filename); // Reset TTL
                shouldDownload = false; 
              } else {
                shouldDownload = true; // Changed
              }
            } else {
              // Null means: Offline, or 403/429, or unknown size.
              // In all cases, prefer existing local file.
              shouldDownload = false;
            }
          } catch (e) {
            // Network error? Offline? Use local cache.
            shouldDownload = false;
          }
        }
      }
    }

    if (shouldDownload) {
        try {
          await _downloadFile(downloadUrl, file);
          await _updateMetadata(filename);
        } catch (e) {
             // download failed.
             // If we have a valid local file, return it.
             if (await file.exists() && await _isValidPdf(file)) {
                 return file;
             }
             rethrow;
        }
    }

    return file;
  }
  
  Future<void> _ensureMetadataLoaded() async {
    if (_metadataLoaded) return;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pdf_cache_metadata.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);
        _metadata = json.map((key, value) => MapEntry(key, value as int));
      }
    } catch (_) {
      // Ignore load errors, start fresh
    }
    _metadataLoaded = true;
  }

  Future<void> _updateMetadata(String filename) async {
    _metadata[filename] = DateTime.now().millisecondsSinceEpoch;
    await _saveMetadata();
  }

  Future<void> _saveMetadata() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pdf_cache_metadata.json');
      await file.writeAsString(jsonEncode(_metadata));
    } catch (_) {
      // Ignore save errors
    }
  }

  Future<void> _downloadFile(String url, File targetFile) async {
     // Download to a temporary file first (atomic write)
     // This prevents corrupting the existing cache file if download fails midway.
     final tempFile = File('${targetFile.path}.tmp');
     
     try {
       final request = http.Request('GET', Uri.parse(url));
       request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
       
       final streamedResponse = await request.send();
       
       if (streamedResponse.statusCode == 200) {
         final sink = tempFile.openWrite();
         await streamedResponse.stream.pipe(sink); // Closes sink automatically
         
         // Verify the downloaded file is valid before replacing the old one
         if (await _isValidPdf(tempFile)) {
            if (await targetFile.exists()) {
              await targetFile.delete();
            }
            await tempFile.rename(targetFile.path);
         } else {
            throw Exception('Downloaded file is not a valid PDF');
         }
       } else {
         throw Exception('Failed to download file: ${streamedResponse.statusCode}');
       }
     } catch (e) {
       // Clean up temp file
       if (await tempFile.exists()) {
         try { await tempFile.delete(); } catch (_) {}
       }
       rethrow;
     }
  }

  Future<int?> _getRemoteFileSize(String url) async {
    try {
      final uri = Uri.parse(url);
      final headers = {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      };
      
      // Try HEAD request first
      // Timeout reduced to 2.5s for responsiveness
      final response = await http
          .head(uri, headers: headers)
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        return int.tryParse(response.headers['content-length'] ?? '');
      } else if (response.statusCode == 302 || response.statusCode == 301) {
         // Follow redirect
        final newUrl = response.headers['location'];
        if (newUrl != null) return _getRemoteFileSize(newUrl);
      } else if (response.statusCode == 403 || response.statusCode == 429) {
          // explicitly return null to fallback to local
          return null;
      }
      
       // Fallback to partial GET
        final getResponse = await http.get(
          uri, 
          headers: {
              ...headers,
              'Range': 'bytes=0-0'
          }
        ).timeout(const Duration(milliseconds: 3000));

        if (getResponse.statusCode == 206 || getResponse.statusCode == 200) {
          final rangeHeader = getResponse.headers['content-range'];
          if (rangeHeader != null) {
             final sizeStr = rangeHeader.split('/').last;
             return int.tryParse(sizeStr);
          }
          return int.tryParse(getResponse.headers['content-length'] ?? '');
        }

    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  Future<bool> _isValidPdf(File file) async {
    try {
      final len = await file.length();
      if (len < 50) return false; // Too small to be a valid PDF
      
      // Check Header
      final headerBytes = await file.openRead(0, 5).first;
      final header = String.fromCharCodes(headerBytes);
      if (!header.contains('%PDF')) return false;

      // Check Footer (EOF)
      // Read last 1024 bytes (or less) to find %%EOF
      final start = len > 1024 ? len - 1024 : 0;
      final stream = file.openRead(start, len);
      final footerList = await stream.toList();
      // Flatten list of lists
      final footerBytes = footerList.expand((x) => x).toList(); 
      // Convert to string (latin1 to be safe/fast)
      final footer = String.fromCharCodes(footerBytes);
      
      return footer.contains('%%EOF');
    } catch (_) {
      return false;
    }
  }

  String _convertDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
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
