import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:annex_sales_order/features/user/data/models/user_model.dart';
import 'package:annex_sales_order/features/user/presentation/widgets/business_card_widget.dart';
import 'package:annex_sales_order/features/user/services/business_card_service.dart';

class BusinessCardScreen extends StatefulWidget {
  final UserModel user;

  const BusinessCardScreen({super.key, required this.user});

  @override
  State<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends State<BusinessCardScreen> {
  final GlobalKey _globalKey = GlobalKey();
  final BusinessCardService _service = BusinessCardService();
  bool _isLoading = false;

  Future<void> _handleAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      ),
      appBar: AppBar(
        title: const Text('Business Card'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          final isTablet =
              constraints.maxWidth > 600 && constraints.maxWidth <= 900;

          if (isDesktop) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: _buildCardPreview(isDark)),
                      const SizedBox(width: 60),
                      Expanded(flex: 4, child: _buildActionSection(true)),
                    ],
                  ),
                ),
              ),
            );
          }

          if (isTablet) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    _buildCardPreview(isDark),
                    const SizedBox(height: 50),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _buildActionSection(false),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                _buildCardPreview(isDark),
                const SizedBox(height: 40),
                _buildActionSection(false),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardPreview(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: RepaintBoundary(
        key: _globalKey,
        child: BusinessCardWidget(key: ValueKey(isDark), user: widget.user),
      ),
    );
  }

  Widget _buildActionSection(bool isDesktop) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (isDesktop) ...[
          Text(
            'Share Your Card',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with your customers by sharing your digital business card.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
        ],
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          _buildActionList(),
      ],
    );
  }

  Widget _buildActionList() {
    return Column(
      children: [
        _buildActionButton(
          label: 'Share',
          icon: CupertinoIcons.share,
          color: Colors.blue,
          onTap: () => _handleAction(() => _service.shareAsImage(_globalKey)),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'Save',
          icon: CupertinoIcons.photo_fill,
          color: Colors.purple,
          onTap: () =>
              _handleAction(() => _service.saveToGallery(_globalKey, context)),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.15 : 0.08),
            color.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black87,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
