import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckResult {
  final String latestVersion;
  final bool forceUpdate;
  final String message;
  final String storeUrl;

  VersionCheckResult({
    required this.latestVersion,
    required this.forceUpdate,
    required this.message,
    required this.storeUrl,
  });
}

class AppVersionService {
  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  // Replace with actual Google Sheet CSV URL
  static const String _versionControlSheetUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQnhO5hmSgRo2-rgzX6MKytNRushWV9s1o2V1ihBpsCy2OEqjK8qXAsfEJHeS0jZJfq4g-UvgK0MUFp/pub?output=csv';

  Future<VersionCheckResult?> checkVersion() async {
    try {
      if (_versionControlSheetUrl.contains('YOUR_GOOGLE_SHEET')) {
        debugPrint('AppVersionService: Version control sheet URL is not set.');
        return null;
      }

      // 1. Get Current Version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersionStr = packageInfo.version;
      debugPrint('Current App Version: $currentVersionStr');

      // 2. Fetch Remote Config
      final response = await http
          .get(Uri.parse(_versionControlSheetUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final List<List<dynamic>> rows = const CsvToListConverter().convert(
          content,
        );

        // Expected Columns in CSV:
        // 0: platform (android/windows)
        // 1: minimum_version (e.g. 1.0.0)
        // 2: latest_version (e.g. 1.0.6)
        // 3: force_update (TRUE/FALSE)
        // 4: update_message_ar (Arabic message)
        // 5: store_url (URL to open)

        final String currentPlatform = Platform.isAndroid
            ? 'android'
            : (Platform.isWindows ? 'windows' : 'other');

        // Skip header (row 0)
        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 6) continue;

          final platform = row[0].toString().trim().toLowerCase();

          if (platform == currentPlatform) {
            String latestVersionStr = row[2].toString().trim();
            bool forceUpdate = row[3].toString().trim().toLowerCase() == 'true';
            String updateMessage = row[4].toString().trim();
            String storeUrl = row[5].toString().trim();

            if (_isUpdateAvailable(currentVersionStr, latestVersionStr)) {
              return VersionCheckResult(
                latestVersion: latestVersionStr,
                forceUpdate: forceUpdate,
                message: updateMessage,
                storeUrl: storeUrl,
              );
            }
            break; // Found our platform, stop searching
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking app version: $e");
    }
    return null;
  }

  bool _isUpdateAvailable(String current, String latest) {
    try {
      // Remove build number if present (e.g. 1.0.0+1 -> 1.0.0)
      if (current.contains('+')) current = current.split('+').first;
      if (latest.contains('+')) latest = latest.split('+').first;

      List<int> currentParts = current
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      List<int> latestParts = latest
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      // Compare parts
      for (int i = 0; i < latestParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int latestPart = latestParts[i];

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
    } catch (e) {
      debugPrint("Error comparing versions: $e");
    }
    return false;
  }
}
