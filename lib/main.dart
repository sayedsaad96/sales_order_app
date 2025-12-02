import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/sales_order/data/datasources/invoice_local_data_source.dart';
import 'features/sales_order/data/models/sales_order.dart';
import 'features/user/data/datasources/user_local_data_source.dart';
import 'features/user/data/models/user_model.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(SalesOrderAdapter());
  Hive.registerAdapter(SalesOrderItemAdapter());

  final userDataSource = UserLocalDataSource();
  await userDataSource.init();
  await InvoiceLocalDataSource().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SalesOrderApp(isRegistered: true),
    ),
  );
}

class SalesOrderApp extends StatelessWidget {
  const SalesOrderApp({super.key, required bool isRegistered});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Annex Sales',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
