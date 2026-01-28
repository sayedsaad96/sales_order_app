import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import 'package:annex_sales_order/features/user/data/models/user_model.dart';
import 'package:annex_sales_order/features/sales_order/presentation/pages/sales_order_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _userDataSource = UserLocalDataSource();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = UserModel(
          fullName: _nameController.text,
          mobileNumber: _mobileController.text,
          email: _emailController.text.isNotEmpty
              ? _emailController.text
              : null,
        );
        await _userDataSource.saveUser(user);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SalesOrderPage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ في التسجيل: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل مستخدم جديد')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Text(
                      'مرحباً بك في أنكس جروب',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم بالكامل',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(CupertinoIcons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'برجاء إدخال الاسم';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الموبايل',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(CupertinoIcons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'برجاء إدخال رقم الموبايل';
                        }
                        if (value.length < 11) {
                          return 'رقم الموبايل غير صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(CupertinoIcons.mail),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _register,
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'All rights reserved © Annex Group 2026\n Developed by Sayed Saad',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
