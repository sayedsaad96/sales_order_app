import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/sales_order/presentation/pages/sales_order_page.dart';
import 'features/sales_order/data/datasources/invoice_local_data_source.dart';
import 'features/sales_order/data/models/sales_order.dart';
import 'features/user/data/datasources/user_local_data_source.dart';
import 'features/user/data/models/user_model.dart';
import 'features/user/presentation/pages/registration_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(SalesOrderAdapter());
  Hive.registerAdapter(SalesOrderItemAdapter());
  
  final userDataSource = UserLocalDataSource();
  await userDataSource.init();
  await InvoiceLocalDataSource().init();
  
  runApp(SalesOrderApp(isRegistered: userDataSource.isUserRegistered()));
}

class SalesOrderApp extends StatelessWidget {
  final bool isRegistered;
  const SalesOrderApp({super.key, required this.isRegistered});

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
      home: isRegistered ? const SalesOrderPage() : const RegistrationPage(),
    );
  }
}
