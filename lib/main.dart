import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/sales_order/presentation/pages/sales_order_page.dart';

void main() {
  runApp(const SalesOrderApp());
}

class SalesOrderApp extends StatelessWidget {
  const SalesOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Order App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo', // Will use if available, otherwise fallback
        useMaterial3: false,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'), // Arabic
      ],
      locale: const Locale('ar', 'EG'),
      home: const SalesOrderPage(),
    );
  }
}
