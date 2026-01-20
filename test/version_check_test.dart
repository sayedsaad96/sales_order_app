// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual version check script', () async {
      const String versionControlSheetUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQnhO5hmSgRo2-rgzX6MKytNRushWV9s1o2V1ihBpsCy2OEqjK8qXAsfEJHeS0jZJfq4g-UvgK0MUFp/pub?output=csv';

  try {
    print('Fetching URL: $versionControlSheetUrl');
    final response = await http
          .get(Uri.parse(versionControlSheetUrl))
          .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final content = utf8.decode(response.bodyBytes);
      print('Content received (first 100 chars): ${content.substring(0, content.length > 100 ? 100 : content.length)}');
      
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        content,
      );

      print('Rows parsed: ${rows.length}');

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        print('Row $i length: ${row.length}');
        if (row.length < 6) {
             print('Row $i skipped (length < 6)');
             continue;
        }

        final platform = row[0].toString().trim().toLowerCase();
        // final minVersion = row[1].toString().trim(); // Unused
        final latestVersion = row[2].toString().trim();
        final forceUpdate = row[3].toString().trim().toLowerCase();
        final message = row[4].toString().trim();
        final storeUrl = row[5].toString().trim();

        print('Platform: $platform');
        print('Latest Version: $latestVersion');
        print('Force Update: $forceUpdate');
        print('Message: $message');
        print('Store URL: $storeUrl');
        print('---');
      }
    } else {
      print('Error: Status code ${response.statusCode}');
    }
  } catch (e) {
    print('Exception: $e');
  }
  });
}
