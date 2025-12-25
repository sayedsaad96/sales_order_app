import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:annex_sales_order/core/widgets/pdf_viewer_page.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/about/presentation/pages/bank_accounts_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String companyProfilePath = 'https://drive.google.com/uc?export=download&id=1vcvDDa3IKFkj0bm4O8KtFngDs0si7GBY';
  static const String aekoTexPath = 'https://drive.google.com/uc?export=download&id=1kPG4Hi-5sLrQH6PdJ-AeMYhgd0OvsW6W';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(CupertinoIcons.list_dash),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: const Text('About Us'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              children: [
                // PDF List Section
                _buildPdfTile(
                  context,
                  icon: CupertinoIcons.building_2_fill,
                  title:
                      'Company Profile', // Placeholder title, using Factory Price List as example content if generic file not valid
                  assetPath:
                      companyProfilePath, // Using existing asset for now
                ),
                const SizedBox(height: 10),
                _buildPdfTile(
                  icon: CupertinoIcons.shield_fill,
                  context,
                  title: 'Aeko-Tex Certificate ', // Placeholder
                  assetPath:
                      aekoTexPath, // Using existing asset for now
                ),
                const SizedBox(height: 10),
                _buildBankAccountTile(context),
                const SizedBox(height: 25),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfTile(
    BuildContext context, {
    required String title,
    required String assetPath,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(CupertinoIcons.eye),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PdfViewerPage(title: title, assetPath: assetPath),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBankAccountTile(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(CupertinoIcons.money_dollar_circle, color: Colors.red),
        title: const Text(
          'Bank Accounts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('الحسابات البنكية'),
        trailing: const Icon(CupertinoIcons.chevron_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BankAccountsPage()),
          );
        },
      ),
    );
  }
}
