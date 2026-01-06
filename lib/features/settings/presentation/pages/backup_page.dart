import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/backup_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;

  void _createBackup() async {
    setState(() => _isLoading = true);
    await _backupService.createBackup(
      onSuccess: (message) {
        if (mounted) {
           setState(() => _isLoading = false);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(message), backgroundColor: Colors.green),
           );
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  void _restoreBackup() async {
    // Confirm first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'Warning: This will DELETE all current data and replace it with the backup. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    await _backupService.restoreBackup(
      onSuccess: (message) {
        if (mounted) {
          setState(() => _isLoading = false);
          // Show dialog requiring restart
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Restore Successful'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ideally restart app, but popping strictly might be enough if state reloads.
                    // For Hive, usually hot restart is safer, or we just navigate to home.
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildModernCard(
                icon: CupertinoIcons.cloud_upload_fill,
                title: 'Backup Data',
                subtitle: 'Save all your data to a file',
                color: Colors.blue,
                onTap: _createBackup,
              ),
              const SizedBox(height: 16),
              _buildModernCard(
                icon: CupertinoIcons.cloud_download_fill,
                title: 'Restore Data',
                subtitle: 'Restore data from a backup file',
                color: Colors.orange,
                onTap: _restoreBackup,
                isDangerous: true,
              ),
              const SizedBox(height: 24),
              const Text(
                'Note: Backup includes all customers, orders, quotations, and settings. Photos and external files are not included.',
                 style: TextStyle(color: Colors.grey),
                 textAlign: TextAlign.center,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
