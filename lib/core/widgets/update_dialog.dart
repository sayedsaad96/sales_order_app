import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final String message;
  final String storeUrl;
  final bool forceUpdate;

  const UpdateDialog({
    super.key,
    required this.message,
    required this.storeUrl,
    required this.forceUpdate,
  });

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(storeUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope is deprecated but used here for compatibility with older Flutter versions in 3.10 range
    // If using Flutter > 3.12, consider using PopScope
    // PopScope is the replacement for WillPopScope
    return PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        title: const Text(
          'تحديث جديد',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 10),
            if (forceUpdate)
               const Text(
                'هذا التحديث إجباري للاستمرار في استخدام التطبيق.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Cairo', 
                  fontSize: 12, 
                  color: Colors.red
                ),
              ),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('لاحقاً', style: TextStyle(fontFamily: 'Cairo')),
            ),
          FilledButton(
            onPressed: _launchURL,
            child: const Text('تحديث الآن', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
