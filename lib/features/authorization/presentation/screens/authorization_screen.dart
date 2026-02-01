import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../data/models/authorization_data.dart';
import '../../pdf/authorization_pdf_generator.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';

class AuthorizationPdfScreen extends StatefulWidget {
  const AuthorizationPdfScreen({super.key});

  @override
  State<AuthorizationPdfScreen> createState() => _AuthorizationPdfScreenState();
}

class _AuthorizationPdfScreenState extends State<AuthorizationPdfScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _organizationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  void _generatePdf() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار تاريخ البداية والنهاية')),
        );
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية'),
          ),
        );
        return;
      }

      final data = AuthorizationData(
        authorizedPersonName: _nameController.text,
        nationalId: _nationalIdController.text,
        organization: _organizationController.text,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      // Generate PDF
      // We need to save it to a file or pass bytes.
      // PdfViewerPage expects an assetPath, but handles http.
      // It also has logic to load from file if we change it, but currently it seems to handle asset or http.
      // Wait, PdfViewerPage implementation:
      // if (assetPath.startsWith('http')) ... else rootBundle.load(assetPath)
      // This is a limitation. I should probably add a way to pass bytes directly or modify PdfViewerPage or create a temporary file.
      // However, the user said "Use existing Architecture".
      // Let's check `PdfViewerPage` again.
      // It accepts `assetPath`.
      // The `printing` package `PdfPreview` widget accepts a build callback `build: (format) => bytes`.
      // So I can just navigate to a new page that uses `PdfPreview` directly directly passing my generator.
      // Or I can create a modified viewer page.
      // Given the constraints, I will create a simple internal Preview Page or push a MaterialPageRoute with PdfPreview.

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('PDF Preview'),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(CupertinoIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: PdfPreview(
              build: (format) async {
                final pdf = await AuthorizationPdfGenerator.generate(data);
                return pdf.save();
              },
              canChangeOrientation: false,
              canChangePageFormat: false,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء تفويض رسمي'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(CupertinoIcons.list_dash),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المفوض',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nationalIdController,
                    decoration: const InputDecoration(
                      labelText: 'الرقم القومي',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _organizationController,
                    decoration: const InputDecoration(
                      labelText: 'الجهة المفوض لها',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'بداية التفويض',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _startDate == null
                                  ? 'اختر التاريخ'
                                  : DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_startDate!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'نهاية التفويض',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _endDate == null
                                  ? 'اختر التاريخ'
                                  : DateFormat('yyyy-MM-dd').format(_endDate!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _generatePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('إنشاء PDF'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
