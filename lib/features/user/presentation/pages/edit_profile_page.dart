import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import 'package:annex_sales_order/features/user/data/models/user_model.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/user/presentation/pages/business_card_screen.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _userDataSource = UserLocalDataSource();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _userDataSource.getUser();
    if (user != null) {
      _nameController.text = user.fullName;
      _mobileController.text = user.mobileNumber;
      _emailController.text = user.email ?? '';
      _jobTitleController.text = user.jobTitle ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = UserModel(
          fullName: _nameController.text,
          mobileNumber: _mobileController.text,
          email: _emailController.text.isNotEmpty ? _emailController.text : null,
          jobTitle: _jobTitleController.text.isNotEmpty ? _jobTitleController.text : null,
        );
        await _userDataSource.saveUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
          );
          Navigator.pop(context); // Return to previous screen (Settings/Drawer)
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في التحديث: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
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
                    const Icon(CupertinoIcons.person_crop_circle_fill, size: 80, color: Colors.blue),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم بالكامل',
                        border: OutlineInputBorder(),
                        prefixIcon:  Icon(CupertinoIcons.person),
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
                        prefixIcon:  Icon(CupertinoIcons.phone),
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
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _jobTitleController,
                      decoration: const InputDecoration(
                        labelText: 'المسمى الوظيفي (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(CupertinoIcons.briefcase),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text(
                          'حفظ التعديلات',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: const Icon(CupertinoIcons.qrcode),
                        label: const Text(
                          'مشاركة الكارت الشخصي',
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                           // Construct a temporary user object from current form state or loaded data
                           // Note: Using current loaded data from _userDataSource or current controllers if valid
                           // Ideally we should save first or use the saved data. 
                           // For safety, let's use the data from controllers if valid, or just pass the current user if saved.
                           
                           // But simpler: just pass the user object if exists.
                           // We need to fetch the user again or reuse logic.
                           // Let's reuse _loadUserData logic but we need the object.
                           
                           final user = _userDataSource.getUser();
                           if (user != null) {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusinessCardScreen(user: user),
                                ),
                              );
                           } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('يرجى حفظ البيانات أولاً')),
                              );
                           }
                        },
                      ),
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
