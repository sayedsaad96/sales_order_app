import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/sales_order/data/datasources/invoice_local_data_source.dart';
import 'features/sales_order/data/datasources/yarn_invoice_local_data_source.dart';
import 'features/sales_order/data/models/sales_order.dart';
import 'features/sales_order/data/models/yarn_sales_order.dart';
import 'features/user/data/datasources/user_local_data_source.dart';
import 'features/user/data/models/user_model.dart';
import 'features/splash/presentation/pages/splash_screen.dart';
import 'features/return_order/data/models/return_order.dart';
import 'features/return_order/data/datasources/return_order_local_data_source.dart';

void main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global Error Handling for Flutter Framework Errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter Error: ${details.exception}');
      };

      try {
        await Hive.initFlutter();
        Hive.registerAdapter(UserModelAdapter());
        Hive.registerAdapter(SalesOrderAdapter());
        Hive.registerAdapter(SalesOrderItemAdapter());
        Hive.registerAdapter(YarnSalesOrderAdapter());
        Hive.registerAdapter(YarnSalesOrderItemAdapter());
        Hive.registerAdapter(YarnInstallmentAdapter());
        Hive.registerAdapter(ReturnOrderAdapter());
        Hive.registerAdapter(ReturnOrderItemAdapter());

        final userDataSource = UserLocalDataSource();
        await userDataSource.init();
        await InvoiceLocalDataSource().init();
        
        // Initialize Yarn invoice data source
        await YarnInvoiceLocalDataSource().init();
        // Initialize Return Order data source
        await ReturnOrderLocalDataSource().init();
      } catch (e, stack) {
        debugPrint('Initialization Error: $e\n$stack');
        // Consider showing a fallback UI here if critical init fails
      }

      runApp(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
          child: const SalesOrderApp(isRegistered: true),
        ),
      );
    },
    (error, stack) {
      // Global Error Handling for Async Errors
      debugPrint('Async Error: $error\n$stack');
    },
  );
}

class SalesOrderApp extends StatelessWidget {
  const SalesOrderApp({super.key, required bool isRegistered});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Annex Group',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'EG'), // Arabic
          ],
          locale: const Locale('ar', 'EG'),
          home: const SplashScreen(),
        );
      },
    );
  }
}
