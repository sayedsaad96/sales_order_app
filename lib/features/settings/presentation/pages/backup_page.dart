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
        title: const Text('استعادة البيانات'),
        content: const Text(
          'تحذير: سيتم حذف جميع البيانات الحالية واستبدالها ببيانات النسخة الاحتياطية. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('استعادة'),
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
              title: const Text('تمت الاستعادة بنجاح'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: const Text('حسنًا'),
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
        title: const Text('النسخ الاحتياطي والاستعادة'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildModernCard(
                    icon: CupertinoIcons.cloud_upload_fill,
                    title: 'نسخ احتياطي',
                    subtitle: 'حفظ جميع البيانات في ملف',
                    color: Colors.blue,
                    onTap: _createBackup,
                  ),
                  const SizedBox(height: 16),
                  _buildModernCard(
                    icon: CupertinoIcons.cloud_download_fill,
                    title: 'استعادة البيانات',
                    subtitle: 'استعادة البيانات من ملف النسخ الاحتياطي',
                    color: Colors.orange,
                    onTap: _restoreBackup,
                    isDangerous: true,
                  ),
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'معلومات النسخ الاحتياطي',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'يتضمن النسخ الاحتياطي:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text('• بيانات المستخدم والإعدادات'),
                          Text('• جميع الفواتير والطلبات'),
                          Text('• طلبات الغزل'),
                          Text('• عروض الأسعار'),
                          Text('• طلبات القماش والتشغيل'),
                          Text('• مرتجعات الطلبات'),
                          Text('• قائمة العملاء'),
                          Text('• المفوضين بالاستلام'),
                          Text('• طلبات الفاتورة الضريبية'),
                          SizedBox(height: 12),
                          Text(
                            'ملاحظة: يمكنك مشاركة ملف النسخة الاحتياطية عبر WhatsApp أو Google Drive أو أي تطبيق آخر لحفظه واستعادته لاحقًا.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'جاري المعالجة...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
              Icon(Icons.chevron_left, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
