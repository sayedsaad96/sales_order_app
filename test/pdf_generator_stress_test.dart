import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:annex_sales_order/features/sales_order/data/models/sales_order.dart';
import 'package:annex_sales_order/features/sales_order/pdf/pdf_generator.dart';
import 'package:annex_sales_order/features/sales_order/data/models/yarn_sales_order.dart';
import 'package:annex_sales_order/features/sales_order/pdf/yarn_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock RootBundle to avoid asset loading issues
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      return null; // Return null to simulate asset not found, triggering fallback
    });
  });

  group('PDF Generation Stress Test', () {
    test('Generate General Sales Order PDF with 250 items', () async {
      final items = List.generate(250, (index) {
        return SalesOrderItem(
          itemName: 'Item $index',
          quantity: 1,
          price: 10.0,
          unit: 'pcs',
          category: 'General',
          // Assuming these fields exist based on standard usage, checking validity later
          // Value is usually calculated but let's see if model requires it
          // Based on pdf_generator.dart: item.value, item.price, item.unit, item.quantity, item.itemName
        );
      });

      final order = SalesOrder(
        customerName: 'Stress Test Customer',
        items: items,
        orderDate: DateTime.now(),
        // Required fields based on observation
        region: 'Test Region',
        deliveryIncluded: true,
        deliveryPlace: 'Warehouse',
        salesResponsible: 'Tester',
        paymentMethod: 'Cash',
        orderTypes: ['Type A'],
        // Assuming totalValue is a field or we need to pass it? 
        // Usually calculated or required. Let's try filling reasonable defaults.
        // If it's a getter, we don't pass it. If it's a field we do.
        // Looking at pdf_generator line 273: order.totalValue.toStringAsFixed(2)
        // It's likely a getter or field. I'll guess it's a field or computed.
        // Since I can't see the model, I'll rely on the fact that usually these are passed or calculated.
        // If compilation fails I will fix.
      );

      final pdf = await PdfSalesOrderGenerator.generate(order);
      final bytes = await pdf.save();
      expect(bytes.length, greaterThan(0));
    });

    test('Generate Yarn Sales Order PDF with 250 items', () async {
      final items = List.generate(250, (index) {
        return YarnSalesOrderItem(
          description: 'Yarn Item $index',
          quantity: 100,
          price: 5.5,
          unit: 'kg',
          // other fields?
        );
      });

      final order = YarnSalesOrder(
        customerName: 'Yarn Test Customer',
        items: items,
        orderDate: DateTime.now(),
        contactName: 'Contact',
        mobileNumber: '123456789',
        region: 'Region',
        deliveryPlace: 'Place',
        salesResponsible: 'Salesman',
        paymentMethod: 'Bank',
        deliveryResponsibility: 'Company',
        installments: [],
      );

      final pdf = await YarnPdfGenerator.generate(order);
      final bytes = await pdf.save();
      expect(bytes.length, greaterThan(0));
    });
  });
}
