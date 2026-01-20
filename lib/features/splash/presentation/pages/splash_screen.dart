import 'dart:async';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/sales_order_container_page.dart';
import 'package:annex_sales_order/features/user/presentation/pages/registration_page.dart';
import 'package:annex_sales_order/core/services/app_version_service.dart';
import 'package:annex_sales_order/core/widgets/update_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // Start minimum delay
    final minDelay = Future.delayed(const Duration(seconds: 3));
    
    // Check for updates
    VersionCheckResult? updateInfo;
    try {
      updateInfo = await AppVersionService().checkVersion();
    } catch (e) {
      debugPrint("Version check failed: $e");
    }

    await minDelay;
    if (!mounted) return;

    // Show update dialog if needed
    final info = updateInfo;
    if (info != null) {
      await showDialog(
        context: context,
        barrierDismissible: !info.forceUpdate,
        builder: (context) => UpdateDialog(
          message: info.message,
          storeUrl: info.storeUrl,
          forceUpdate: info.forceUpdate,
        ),
      );

      if (info.forceUpdate) {
        // If forced update, do not proceed to app
        return;
      }
    }

    if (!mounted) return;

    final userDataSource = UserLocalDataSource();
    final isRegistered = userDataSource.isUserRegistered();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isRegistered ? const SalesOrderContainerPage() : const RegistrationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
            ),
          ),
        ),
      ),
    );
  }
}
