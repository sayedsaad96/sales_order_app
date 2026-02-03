import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:annex_sales_order/core/providers/theme_provider.dart';
import 'package:annex_sales_order/core/theme/app_theme.dart';
import 'package:annex_sales_order/features/sales_order/data/datasources/invoice_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/data/datasources/yarn_invoice_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/data/models/sales_order.dart';
import 'package:annex_sales_order/features/sales_order/data/models/yarn_sales_order.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import 'package:annex_sales_order/features/user/data/models/user_model.dart';
import 'package:annex_sales_order/features/splash/presentation/pages/splash_screen.dart';
import 'package:annex_sales_order/features/return_order/data/models/return_order.dart';
import 'package:annex_sales_order/features/return_order/data/datasources/return_order_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/data/models/fabrics_cm_sales_order.dart';
import 'package:annex_sales_order/features/sales_order/data/models/quotation.dart'; // Quotation Model
import 'package:annex_sales_order/features/sales_order/data/datasources/quotation_local_data_source.dart';
import 'package:annex_sales_order/features/sales_order/data/datasources/fabrics_cm_invoice_local_data_source.dart';
import 'package:annex_sales_order/core/services/update_notification_service.dart';
import 'package:annex_sales_order/features/customer_list/data/models/customer.dart';
import 'package:annex_sales_order/features/customer_list/data/datasources/customer_local_data_source.dart';
import 'package:annex_sales_order/features/authorization/data/models/authorized_person.dart';
import 'package:annex_sales_order/features/authorization/data/datasources/authorization_local_data_source.dart';


void main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global Error Handling for Flutter Framework Errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter Error: ${details.exception}');
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to me
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformDispatcher Error: $error\n$stack');
        return true;
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
        
        // Register Fabrics & CM adapters
        Hive.registerAdapter(FabricsCmSalesOrderAdapter());
        Hive.registerAdapter(FabricsCmLineItemAdapter());

        // Register Quotation adapters
        Hive.registerAdapter(QuotationAdapter());
        Hive.registerAdapter(QuotationItemAdapter());

        final userDataSource = UserLocalDataSource();
        await userDataSource.init();
        await InvoiceLocalDataSource().init();
        
        // Initialize Yarn invoice data source
        await YarnInvoiceLocalDataSource().init();
        // Initialize Return Order data source
        await ReturnOrderLocalDataSource().init();
        // Initialize Fabrics & CM data source
        await FabricsCmInvoiceLocalDataSource().init();
        
        // Initialize Quotation data source
        await QuotationLocalDataSource().init();


        // Initialize Notification Service (Background checks)
        await UpdateNotificationService().init();

        // Initialize Customer data source
        Hive.registerAdapter(CustomerAdapter());
        await CustomerLocalDataSource().init();

        // Initialize Authorization data source
        Hive.registerAdapter(AuthorizedPersonAdapter());
        await AuthorizationLocalDataSource().init();
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
