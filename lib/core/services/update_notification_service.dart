import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

// Top-level function for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == UpdateNotificationService.taskKey) {
        await UpdateNotificationService().checkForUpdates();
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
  static const String channelDesc = "Notifications for Price List and About Us updates";

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
          initializationSettings,
          onDidReceiveNotificationResponse: (details) {
            // Handle notification tap
          },
        );
    }

    // 3. Init Workmanager
    // Only on Android/iOS mobile
    if (Platform.isAndroid || Platform.isIOS) {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      // Register periodic task
      await Workmanager().registerPeriodicTask(
        "1", // Unique name
        taskKey,
        frequency: const Duration(hours: 4), // Minimum 15 mins
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }
  }

  Future<void> checkForUpdates() async {
    // We need to use a separate directory access in background isolate if needed,
    // but getApplicationDocumentsDirectory works.
    final dir = await getApplicationDocumentsDirectory();
    
    // Check About Us
    final aboutUsChanges = await _checkUrl(
      _aboutUsSheetUrl, 
      File('${dir.path}/about_docs_cache.csv')
    );
     if (aboutUsChanges.isNotEmpty) {
      await _showNotification(aboutUsChanges);
    }

    // Check Price List
    final priceListChanges = await _checkUrl(
      _priceListSheetUrl, 
      File('${dir.path}/price_list_cache.csv')
    );
    if (priceListChanges.isNotEmpty) {
      await _showNotification(priceListChanges);
    }
  }

  /// Returns a list of titles that are new or updated.
  Future<List<String>> _checkUrl(String url, File cacheFile) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      
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
        final List<List<dynamic>> oldRows = const CsvToListConverter().convert(oldCsv);
        final List<List<dynamic>> newRows = const CsvToListConverter().convert(newCsv);

        final Set<String> oldItems = {};
        for (var i = 1; i < oldRows.length; i++) {
           if (oldRows[i].length >= 2) {
             // Store specific signature: Title|URL
             oldItems.add("${oldRows[i][0].toString().trim()}|${oldRows[i][1].toString().trim()}");
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
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID based on time
      'تحديث جديد', // Title
      contentText,
      platformChannelSpecifics,
    );
  }
}
