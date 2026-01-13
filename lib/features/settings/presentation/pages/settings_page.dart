// import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added
import 'package:file_picker/file_picker.dart';
import 'package:annex_sales_order/core/services/settings_service.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/core/providers/theme_provider.dart'; // Added
import 'package:annex_sales_order/features/user/presentation/pages/edit_profile_page.dart'; // Added
import 'package:annex_sales_order/features/settings/presentation/pages/backup_page.dart'; // Added

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late InvoiceSaveStrategy _saveStrategy;
  String? _defaultPath;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _saveStrategy = _settingsService.getInvoiceSaveStrategy();
    _defaultPath = _settingsService.getDefaultSavePath();
  }

  Future<void> _pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        _defaultPath = selectedDirectory;
      });
      await _settingsService.setDefaultSavePath(selectedDirectory);
    }
  }

  Future<void> _updateStrategy(InvoiceSaveStrategy strategy) async {
    setState(() {
      _saveStrategy = strategy;
    });
    await _settingsService.setInvoiceSaveStrategy(strategy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // -- General Preferences Section --
          _buildSectionHeader('تفضيلات عامة'),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.person_crop_circle),
                  title: const Text('تعديل الملف الشخصي'),
                  subtitle: const Text('تحديث بياناتك الشخصية'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(CupertinoIcons.cloud_upload),
                  title: const Text('النسخ الاحتياطي والاستعادة'),
                  subtitle: const Text('إدارة نسخ البيانات'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackupPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      secondary: Icon(
                        themeProvider.isDarkMode
                            ? CupertinoIcons.moon_fill
                            : CupertinoIcons.sun_max_fill,
                      ),
                      title: const Text('الوضع الليلي'),
                      subtitle: Text(themeProvider.isDarkMode ? 'مفعل' : 'غير مفعل'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // -- Invoice Settings Section (Matching User Image) --
          _buildSectionHeader('إعدادات حفظ الفواتير'),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            child: Column(
              children: [
                _buildRadioOptionUI(
                  title: 'سؤال مكان الحفظ دائماً',
                  subtitle: 'سيتم فتح نافذة اختيار مكان الحفظ عند إنشاء كل فاتورة',
                  value: InvoiceSaveStrategy.ask,
                ),
                Divider(height: 1, color: Colors.grey[400]),
                _buildRadioOptionUI(
                  title: 'الحفظ التلقائي في مجلد محدد',
                  subtitle: 'سيتم إنشاء مجلد باسم العميل وحفظ الفاتورة بداخله تلقائياً',
                  value: InvoiceSaveStrategy.auto,
                ),
                if (_saveStrategy == InvoiceSaveStrategy.auto) ...[
                  Divider(height: 1, color: Colors.grey[400]),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'مسار الحفظ الافتراضي:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickFolder,
                              icon: const Icon(CupertinoIcons.folder, size: 18),
                              label: const Text('تغيير'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  _defaultPath ?? 'لم يتم تحديد مسار',
                                  style: TextStyle(
                                    color: _defaultPath == null ? Colors.grey : Colors.black87,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.left,
                                  textDirection: TextDirection.ltr,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildRadioOptionUI({
    required String title,
    required String subtitle,
    required InvoiceSaveStrategy value,
  }) {
    final isSelected = _saveStrategy == value;
    return InkWell(
      onTap: () => _updateStrategy(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
} // End of class
