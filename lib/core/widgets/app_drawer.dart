import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/price_list_page.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/sales_order_container_page.dart';
import 'package:annex_sales_order/features/return_order/presentation/pages/return_order_page.dart';

import 'package:annex_sales_order/features/about/presentation/pages/about_page.dart';
import 'package:annex_sales_order/features/analysis/presentation/pages/sales_analysis_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/saved_quotations_page.dart';
import 'package:annex_sales_order/features/settings/presentation/pages/settings_page.dart';
import 'package:annex_sales_order/features/customer_list/presentation/pages/customer_list_page.dart';
import 'package:annex_sales_order/features/authorization/presentation/screens/authorization_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static bool _isArabic = false;

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'main_menu': 'Main Menu',
      'essential_so': 'Essential Sales Order',
      'essential_so_sub': 'Create essential orders',
      'yarn_so': 'Yarn Sales Order',
      'yarn_so_sub': 'Create yarn orders',
      'fabrics_so': 'Fabrics & CM Order',
      'fabrics_so_sub': 'Create fabrics & CM orders',
      'quotations': 'Quotations',
      'quotations_sub': 'Create & view quotations',
      'return_order': 'Return Order',
      'return_order_sub': 'Create return orders',
      'sales_analysis': 'Sales Analysis',
      'sales_analysis_sub': 'Insights and performance',
      'customer_list': 'Customer List',
      'customer_list_sub': 'Manage customers',
      'auth_pdf': 'Authorization',
      'auth_pdf_sub': 'Create authorization',
      'information': 'Information',
      'about_us': 'About Us',
      'about_us_sub': 'Company information',
      'price_lists': 'Price Lists',
      'price_lists_sub': 'View pricing information',
      'settings': 'Settings',
      'settings_sub': 'App and invoice save settings',
      'language': 'Language / اللغة',
      'switch_lang': 'تغير للغة العربية',
    },
    'ar': {
      'main_menu': 'القائمة الرئيسية',
      'essential_so': 'أمر بيع أساسي',
      'essential_so_sub': 'إنشاء أوامر بيع أساسية',
      'yarn_so': 'أمر بيع غزل',
      'yarn_so_sub': 'إنشاء أوامر بيع غزل',
      'fabrics_so': 'أمر بيع أقمشة وتصنيع',
      'fabrics_so_sub': 'إنشاء أوامر بيع أقمشة وتصنيع',
      'quotations': 'عروض أسعار',
      'quotations_sub': 'إنشاء وعرض عروض الأسعار',
      'return_order': 'مرتجع مبيعات',
      'return_order_sub': 'إنشاء مرتجعات مبيعات',
      'sales_analysis': 'تحليل المبيعات',
      'sales_analysis_sub': 'رؤى وأداء المبيعات',
      'customer_list': 'قائمة العملاء',
      'customer_list_sub': 'إدارة العملاء',
      'auth_pdf': 'تفويض',
      'auth_pdf_sub': 'إنشاء تفويض',
      'information': 'معلومات',
      'about_us': 'من نحن',
      'about_us_sub': 'معلومات الشركة',
      'price_lists': 'قوائم الأسعار',
      'price_lists_sub': 'عرض معلومات الأسعار',
      'settings': 'الإعدادات',
      'settings_sub': 'إعدادات التطبيق وحفظ الفواتير',
      'language': 'اللغة / Language',
      'switch_lang': 'Switch to English',
    },
  };

  String _t(String key) {
    return _translations[_isArabic ? 'ar' : 'en']![key]!;
  }

  Future<void> _launchSocialMedia(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width < 350
        ? width * 0.85
        : (width * 0.75).clamp(0.0, 280.0);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : Directionality.of(context),
      child: Drawer(
        width: drawerWidth,
        child: Column(
          children: [
            _buildModernHeader(context, isDark),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),

                  _buildSectionHeader(_t('main_menu')),
                  _buildModernMenuItem(
                    context,
                    icon: Icons.ac_unit_outlined,
                    title: _t('essential_so'),
                    subtitle: _t('essential_so_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SalesOrderContainerPage(initialIndex: 0),
                        ),
                      );
                    },
                  ),
                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.layers_alt,
                    title: _t('yarn_so'),
                    subtitle: _t('yarn_so_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SalesOrderContainerPage(initialIndex: 1),
                        ),
                      );
                    },
                  ),
                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.scissors,
                    title: _t('fabrics_so'),
                    subtitle: _t('fabrics_so_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SalesOrderContainerPage(initialIndex: 2),
                        ),
                      );
                    },
                  ),
                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.doc_text,
                    title: _t('quotations'),
                    subtitle: _t('quotations_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedQuotationsPage(),
                        ),
                      );
                    },
                  ),
                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.arrow_counterclockwise,
                    title: _t('return_order'),
                    subtitle: _t('return_order_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReturnOrderPage(),
                        ),
                      );
                    },
                  ),

                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.graph_square,
                    title: _t('sales_analysis'),
                    subtitle: _t('sales_analysis_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SalesAnalysisPage(),
                        ),
                      );
                    },
                  ),
                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.person_2_fill,
                    title: _t('customer_list'),
                    subtitle: _t('customer_list_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerListPage(),
                        ),
                      );
                    },
                  ),

                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.doc_person,
                    title: _t('auth_pdf'),
                    subtitle: _t('auth_pdf_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthorizationPdfScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildSectionHeader(_t('information')),
                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.info,
                    title: _t('about_us'),
                    subtitle: _t('about_us_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.money_dollar_circle,
                    title: _t('price_lists'),
                    subtitle: _t('price_lists_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PriceListPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildSectionHeader(_t('settings')),
                  _buildModernMenuItem(
                    context,
                    icon: CupertinoIcons.settings,
                    title: _t('settings'),
                    subtitle: _t('settings_sub'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),

                  const Divider(indent: 20, endIndent: 20),

                  // Language Toggle Widget
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.translate,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        title: Text(
                          _t('language'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _t('switch_lang'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Switch.adaptive(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          value: _isArabic,
                          onChanged: (value) {
                            setState(() {
                              _isArabic = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
            _buildModernSocialFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [Colors.blueAccent, Colors.lightBlueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 20),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: const StadiumBorder(),
        onTap: onTap,
        leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildModernSocialFooter(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          _ModernSocialIcon(
            icon: FontAwesomeIcons.facebook,
            onTap: () =>
                _launchSocialMedia('https://www.facebook.com/annexeg/'),
            color: const Color(0xFF1877F2),
          ),
          _ModernSocialIcon(
            icon: FontAwesomeIcons.instagram,
            onTap: () =>
                _launchSocialMedia('https://www.instagram.com/annexeg/'),
            color: const Color(0xFFE4405F),
          ),
          _ModernSocialIcon(
            icon: FontAwesomeIcons.linkedin,
            onTap: () =>
                _launchSocialMedia('https://www.linkedin.com/company/annexeg/'),
            color: const Color(0xFF0A66C2),
          ),
          _ModernSocialIcon(
            icon: FontAwesomeIcons.globe,
            onTap: () => _launchSocialMedia('https://www.annexeg.com/'),
            color: const Color(0xFF00A8E8),
          ),
        ],
      ),
    );
  }
}

class _ModernSocialIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ModernSocialIcon({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  State<_ModernSocialIcon> createState() => _ModernSocialIconState();
}

class _ModernSocialIconState extends State<_ModernSocialIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isHovered
                  ? widget.color
                  : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 24,
            color: _isHovered ? widget.color : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
