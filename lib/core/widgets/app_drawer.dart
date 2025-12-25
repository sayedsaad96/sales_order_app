import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:annex_sales_order/core/providers/theme_provider.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/price_list_page.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/sales_order_container_page.dart';
import 'package:annex_sales_order/features/return_order/presentation/pages/return_order_page.dart';

import 'package:annex_sales_order/features/user/presentation/pages/edit_profile_page.dart';
import 'package:annex_sales_order/features/about/presentation/pages/about_page.dart';
import 'package:annex_sales_order/features/analysis/presentation/pages/sales_analysis_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
    // Adaptive width: 75% of screen for standard phones, capped at 280px for larger screens.
    // For very small devices (< 350px), use 85% to ensure content fits.
    final drawerWidth = width < 350
        ? width * 0.85
        : (width * 0.75).clamp(0.0, 280.0);

    return Drawer(
      width: drawerWidth,
      child: Column(
        children: [
          // Modern Gradient Header
          _buildModernHeader(context, isDark),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),

                // Main Menu Section
                _buildSectionHeader('Main Menu'),
                _buildModernMenuItem(
                  context,
                  icon: CupertinoIcons.doc_text,
                  title: 'Price Lists',
                  subtitle: 'View pricing information',
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
                _buildModernMenuItem(
                  context,
                  icon: CupertinoIcons.square_list,
                  title: 'Essential Sales Order',
                  subtitle: 'Create essential orders',
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
                  title: 'Yarn Sales Order',
                  subtitle: 'Create yarn orders',
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
                  icon: CupertinoIcons.tag,
                  title: 'Fabrics & CM Order',
                  subtitle: 'Create fabrics & CM orders',
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
                  icon: CupertinoIcons.arrow_counterclockwise,
                  title: 'Return Order',
                  subtitle: 'Create return orders',
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
                  title: 'Sales Analysis',
                  subtitle: 'Insights and performance',
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

                const SizedBox(height: 16),

                // Information Section
                _buildSectionHeader('Information'),
                _buildModernMenuItem(
                  context,
                  icon: CupertinoIcons.info,
                  title: 'About Us',
                  subtitle: 'Company information',
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

                const SizedBox(height: 16),

                // Settings Section
                _buildSectionHeader('Settings'),
                _buildModernMenuItem(
                  context,
                  icon: CupertinoIcons.person,
                  title: 'Edit Profile',
                  subtitle: 'Update your information',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                ),

                // Dark Mode Toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildModernThemeToggle(context, themeProvider);
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Modern Social Media Footer
          _buildModernSocialFooter(context, isDark),
        ],
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

  Widget _buildModernThemeToggle(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: const StadiumBorder(),
        onTap: () => themeProvider.toggleTheme(),
        leading: Icon(
          themeProvider.isDarkMode ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Toggle theme',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: CupertinoSwitch(
          value: themeProvider.isDarkMode,
          onChanged: (value) => themeProvider.toggleTheme(),
        ),
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
