import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../../features/sales_order/presentation/pages/price_list_page.dart';

import '../../features/user/presentation/pages/edit_profile_page.dart';
import '../../features/about/presentation/pages/about_page.dart';
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
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 60,
                          width: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text(' Price Lists'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PriceListPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Us'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ExpansionTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Edit Profile'),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                      },
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return SwitchListTile(
                          secondary: Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                          title: themeProvider.isDarkMode
                              ? const Text(' Dark Mode')
                              : const Text(' Light Mode'),
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Social Media Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SocialIcon(
                  icon: FontAwesomeIcons.facebook,
                  onTap: () =>
                      _launchSocialMedia('https://www.facebook.com/annexeg/'),
                  color: Colors.blue,
                ),
                _SocialIcon(
                  icon: FontAwesomeIcons.instagram,
                  onTap: () =>
                      _launchSocialMedia('https://www.instagram.com/annexeg/'),
                  color: Colors.purple,
                ),
                _SocialIcon(
                  icon: FontAwesomeIcons.linkedin,
                  onTap: () => _launchSocialMedia(
                    'https://www.linkedin.com/company/annexeg/',
                  ),
                  color: Colors.blueAccent,
                ),
                _SocialIcon(
                  icon: FontAwesomeIcons.globe,
                  onTap: () => _launchSocialMedia('https://www.annexeg.com/'),
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _SocialIcon({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 28, color: color),
      ),
    );
  }
}
