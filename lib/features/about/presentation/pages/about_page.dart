import 'package:flutter/material.dart';


import '../../../../core/widgets/pdf_viewer_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          children: [
            // PDF List Section
            _buildPdfTile(
              context,
              icon: Icons.maps_home_work,
              title:
                  'Company Profile', // Placeholder title, using Factory Price List as example content if generic file not valid
              assetPath:
                  'assets/docs/Company Profile.pdf', // Using existing asset for now
            ),
            const SizedBox(height: 10),
            _buildPdfTile(
              icon: Icons.workspace_premium,
              context,
              title: 'Aeko-Tex Certificate ', // Placeholder
              assetPath:
                  'assets/docs/Aeko-Tex.pdf', // Using existing asset for now
            ),
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
        trailing: const Icon(Icons.visibility),
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
}
