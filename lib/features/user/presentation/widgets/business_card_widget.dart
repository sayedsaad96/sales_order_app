import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:annex_sales_order/features/user/data/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessCardWidget extends StatelessWidget {
  final UserModel user;
  final double scale;

  const BusinessCardWidget({super.key, required this.user, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate scale based on available width if it's smaller than the target width (400)
          final double cardWidth = 400;
          final double availableWidth = constraints.maxWidth;
          final double effectiveScale = (availableWidth < cardWidth) 
              ? (availableWidth / cardWidth) * 0.95 // 5% margin
              : scale;

          return Transform.scale(
            scale: effectiveScale,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Card(
                elevation: isDark ? 8 : 4,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: isDark
                      ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5)
                      : BorderSide.none,
                ),
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ProfileHeader(),
                      const SizedBox(height: 28),
                      _UserIdentity(user: user, colorScheme: colorScheme),
                      const SizedBox(height: 32),
                      _ContactInfoSection(user: user, colorScheme: colorScheme),
                      const SizedBox(height: 32),
                      _SocialLinksRow(colorScheme: colorScheme),
                      const SizedBox(height: 32),
                      _QRCodeSection(user: user, colorScheme: colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 12),
        Text(
          'ANNEX GROUP',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _UserIdentity extends StatelessWidget {
  final UserModel user;
  final ColorScheme colorScheme;
  const _UserIdentity({required this.user, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          user.fullName.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'Merienda',
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (user.jobTitle ?? 'SALES REPRESENTATIVE').toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ContactInfoSection extends StatelessWidget {
  final UserModel user;
  final ColorScheme colorScheme;
  const _ContactInfoSection({required this.user, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoTile(
          icon: Icons.phone_android_rounded,
          text: user.mobileNumber,
          colorScheme: colorScheme,
        ),
        if (user.email != null && user.email!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.alternate_email_rounded,
            text: user.email!,
            colorScheme: colorScheme,
          ),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const _InfoTile({
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Montserrat',
                color: colorScheme.onSurface,
                fontSize: 16, // Adjusted size for better fit
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, size: 20, color: colorScheme.primary),
        ],
      ),
    );
  }
}

class _SocialLinksRow extends StatelessWidget {
  final ColorScheme colorScheme;
  const _SocialLinksRow({required this.colorScheme});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIcon(
          icon: FontAwesomeIcons.facebookF,
          colorScheme: colorScheme,
          onTap: () => _launchURL('https://www.facebook.com/annexeg/'),
        ),
        const SizedBox(width: 16),
        _SocialIcon(
          icon: FontAwesomeIcons.instagram,
          colorScheme: colorScheme,
          onTap: () => _launchURL('https://www.instagram.com/annexeg/'),
        ),
        const SizedBox(width: 16),
        _SocialIcon(
          icon: FontAwesomeIcons.linkedinIn,
          colorScheme: colorScheme,
          onTap: () => _launchURL('https://www.linkedin.com/company/annexeg/'),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _QRCodeSection extends StatelessWidget {
  final UserModel user;
  final ColorScheme colorScheme;
  const _QRCodeSection({required this.user, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data:
                'BEGIN:VCARD\nVERSION:3.0\nFN:${user.fullName}\nTEL:${user.mobileNumber}\nEMAIL:${user.email ?? ""}\nEND:VCARD',
            version: QrVersions.auto,
            size: 100.0,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'SCAN TO SAVE CONTACT',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
