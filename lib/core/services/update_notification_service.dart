import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

// Top-level function for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == UpdateNotificationService.taskKey) {
        final service = UpdateNotificationService();
        await service.prepareBackground();
        await service.checkForUpdates();
      }
    } catch (e) {
      debugPrint("Background task error: $e");
      return Future.value(false);
    }
    return Future.value(true);
  });
}

class UpdateNotificationService {
  static final UpdateNotificationService _instance =
      UpdateNotificationService._internal();

  factory UpdateNotificationService() => _instance;

  UpdateNotificationService._internal();

  // Constants
  static const String taskKey = "check_pdf_updates";
  static const String channelId = "pdf_updates_channel";
  static const String channelName = "PDF Updates";
  static const String channelDesc =
      "Notifications for Price List and About Us updates";
  static const String metadataBoxName = "pdf_metadata";

  // URLs
  static const String _aboutUsSheetUrl =
      'https://docs.google.com/spreadsheets/d/1Sj82OgBoBX7XGvF_sKSuDRVfFy9UMqvefJo3dHW_x08/export?format=csv';
  static const String _priceListSheetUrl =
      'https://docs.google.com/spreadsheets/d/11nspnKx9BEPkee6C52TmDIw4VXs5BAKfn-d6o7g7E6E/export?format=csv';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 2. Init Local Notifications (Mobile Only for now to avoid Windows DLL issues)
    if (Platform.isAndroid || Platform.isIOS) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
        },
      );
    }

    // 3. Init Workmanager
    // Only on Android/iOS mobile
    if (Platform.isAndroid || Platform.isIOS) {
      await Workmanager().initialize(callbackDispatcher);

      // Register periodic task
      await Workmanager().registerPeriodicTask(
        "1", // Unique name
        taskKey,
        frequency: const Duration(hours: 4), // Minimum 15 mins
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }

    // 4. Init Hive for metadata
    await prepareBackground();
  }

  Future<void> prepareBackground() async {
    if (!Hive.isBoxOpen(metadataBoxName)) {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      await Hive.openBox(metadataBoxName);
    }
  }

  Future<void> checkForUpdates() async {
    // We need to use a separate directory access in background isolate if needed,
    // but getApplicationDocumentsDirectory works.
    final dir = await getApplicationDocumentsDirectory();

    // Check About Us
    final aboutUsChanges = await _checkUrl(
      _aboutUsSheetUrl,
      File('${dir.path}/about_docs_cache.csv'),
    );
    if (aboutUsChanges.isNotEmpty) {
      await _showNotification(aboutUsChanges);
    }

    // Check Price List
    final priceListChanges = await _checkUrl(
      _priceListSheetUrl,
      File('${dir.path}/price_list_cache.csv'),
    );
    if (priceListChanges.isNotEmpty) {
      await _showNotification(priceListChanges);
    }

    // New: Check PDF content changes (file size)
    await _checkPdfContentChanges(dir);
  }

  /// Updates the metadata box without showing notifications.
  /// Useful when the user manualy refreshes the data in the UI.
  Future<void> silentlyUpdateMetadata() async {
    final dir = await getApplicationDocumentsDirectory();
    await _checkPdfContentChanges(dir, notify: false);
  }

  Future<void> _checkPdfContentChanges(
    Directory dir, {
    bool notify = true,
  }) async {
    final aboutUsFile = File('${dir.path}/about_docs_cache.csv');
    final priceListFile = File('${dir.path}/price_list_cache.csv');

    final List<String> changedTitles = [];
    final box = Hive.box(metadataBoxName);

    Future<void> processCsv(File file) async {
      if (!await file.exists()) return;
      try {
        final content = await file.readAsString();
        final List<List<dynamic>> rows = const CsvToListConverter().convert(
          content,
        );

        for (var i = 1; i < rows.length; i++) {
          if (rows[i].length >= 2) {
            final title = rows[i][0].toString().trim();
            final url = rows[i][1].toString().trim();
            if (url.isEmpty) continue;

            final downloadUrl = _convertDriveUrl(url);
            final currentSize = await _getFileSize(downloadUrl);

            if (currentSize != null && currentSize > 0) {
              final lastSize = box.get(url);
              if (notify && lastSize != null && lastSize != currentSize) {
                changedTitles.add(title);
              }
              await box.put(url, currentSize);
            }
          }
        }
      } catch (e) {
        debugPrint("Error processing CSV for PDF check: $e");
      }
    }

    await processCsv(aboutUsFile);
    await processCsv(priceListFile);

    if (notify && changedTitles.isNotEmpty) {
      await _showNotification(changedTitles);
    }
  }

  Future<int?> _getFileSize(String url) async {
    try {
      final uri = Uri.parse(url);
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      };

      // Try HEAD request first
      // Timeout reduced to 5s for responsiveness
      final response = await http
          .head(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return int.tryParse(response.headers['content-length'] ?? '');
      } else if (response.statusCode == 302 || response.statusCode == 301) {
        // Follow redirect
        final newUrl = response.headers['location'];
        if (newUrl != null) return _getFileSize(newUrl);
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        // explicitly return null to signfiy unknown
        return null;
      }

      // If HEAD fails, try partial GET
      final getResponse = await http
          .get(uri, headers: {...headers, 'Range': 'bytes=0-0'})
          .timeout(const Duration(seconds: 5));

      if (getResponse.statusCode == 206 || getResponse.statusCode == 200) {
        final rangeHeader = getResponse.headers['content-range'];
        if (rangeHeader != null) {
          final sizeStr = rangeHeader.split('/').last;
          return int.tryParse(sizeStr);
        }
        return int.tryParse(getResponse.headers['content-length'] ?? '');
      }
    } catch (e) {
      debugPrint("Error getting file size for $url: $e");
    }
    return null;
  }

  String _convertDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
      RegExp regExp = RegExp(
        r'\/file\/d\/([a-zA-Z0-9_-]+)|id=([a-zA-Z0-9_-]+)',
      );
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

  /// Returns a list of titles that are new or updated.
  Future<List<String>> _checkUrl(String url, File cacheFile) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final newContent = utf8.decode(response.bodyBytes);

        if (await cacheFile.exists()) {
          final oldContent = await cacheFile.readAsString();

          if (newContent != oldContent) {
            // Content changed, identify specific changes
            final changes = _identifyChanges(oldContent, newContent);

            // Update cache
            await cacheFile.writeAsString(newContent);
            return changes;
          }
        } else {
          // First time, save and maybe return everything as "Added"?
          // Use case: First run triggers notification for everything?
          // Probably better to just save silently to avoid spamming 50 items on install.
          await cacheFile.writeAsString(newContent);
          return [];
        }
      }
    } catch (e) {
      debugPrint("Error checking $url: $e");
    }
    return [];
  }

  /// Diff logic:
  /// Parses CSVs.
  /// If a (Title, URL) pair is in New but not in Old, it's considered an update/add.
  /// Note: If title changes, it counts as new. If URL changes, it counts as new.
  List<String> _identifyChanges(String oldCsv, String newCsv) {
    try {
      final List<List<dynamic>> oldRows = const CsvToListConverter().convert(
        oldCsv,
      );
      final List<List<dynamic>> newRows = const CsvToListConverter().convert(
        newCsv,
      );

      final Set<String> oldItems = {};
      for (var i = 1; i < oldRows.length; i++) {
        if (oldRows[i].length >= 2) {
          // Store specific signature: Title|URL
          oldItems.add(
            "${oldRows[i][0].toString().trim()}|${oldRows[i][1].toString().trim()}",
          );
        }
      }

      final List<String> changes = [];
      for (var i = 1; i < newRows.length; i++) {
        if (newRows[i].length >= 2) {
          final title = newRows[i][0].toString().trim();
          final url = newRows[i][1].toString().trim();
          final signature = "$title|$url";

          if (!oldItems.contains(signature)) {
            changes.add(title);
          }
        }
      }
      return changes;
    } catch (e) {
      debugPrint("Error parsing CSV for diff: $e");
      // Fallback: if parsing failed but strings differed, return a generic message?
      // Or return empty to be safe.
      return [];
    }
  }

  Future<void> _showNotification(List<String> items) async {
    if (items.isEmpty) return;

    // "تم تحديث او اضافه [اسم الملف] برجاء الاطلاع عليه"
    // If multiple, join them?
    final String contentText;
    if (items.length == 1) {
      contentText = 'تم تحديث او اضافه "${items.first}" برجاء الاطلاع عليه';
    } else {
      // Limit to first 3 to avoid huge notification
      final names = items.take(3).join(" و ");
      final more = items.length > 3 ? " و ${items.length - 3} آخرين" : "";
      contentText = 'تم تحديث او اضافه "$names$more" برجاء الاطلاع عليه';
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'تحديث جديد',
      body: contentText,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
