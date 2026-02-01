
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:annex_sales_order/features/authorization/data/models/authorization_data.dart';
import 'package:annex_sales_order/features/authorization/pdf/authorization_pdf_generator.dart';

void main() {
  test('Authorization PDF Generation Test', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    final data = AuthorizationData(
      authorizedPersonName: 'Test User',
      nationalId: '12345678901234',
      organization: 'Test Org',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    final pdf = await AuthorizationPdfGenerator.generate(data);
    final bytes = await pdf.save();

    expect(bytes.length, greaterThan(0));
    
    final file = File('test_auth.pdf');
    await file.writeAsBytes(bytes);
  });
}
