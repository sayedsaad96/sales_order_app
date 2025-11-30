import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import '../data/models/sales_order.dart';

class PdfSalesOrderGenerator {
  static Future<pw.Document> generate(SalesOrder order) async {
    final pdf = pw.Document();

    // Load Font
    pw.Font arabicFont;
    try {
      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      arabicFont = pw.Font.ttf(fontData);
    } catch (e) {
      // Fallback
      arabicFont = pw.Font.courier();
    }

    // Load Logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFont);

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // S/N
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Text(
                      'S/N: ${order.sn ?? ""}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),

                  // Title
                  pw.Column(
                    children: [
                      pw.Text(
                        'طلب بيع',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Logo and Company Name
                  pw.Column(
                    children: [
                      if (logoImage != null)
                        pw.Image(logoImage, width: 80, height: 80),
                      pw.SizedBox(height: 5),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Branch Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('الفرع: ${order.branch ?? ""}'),
                  pw.SizedBox(width: 20),
                  pw.SizedBox(width: 20),
                  pw.Text('النوع: '),
                  ...order.orderTypes.map((t) => pw.Text('[$t] ')),
                ],
              ),
              pw.SizedBox(height: 20),

              // Info Columns
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Right Column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('اسم العميل:', order.customerName),
                        _buildInfoRow('المنطقة:', order.region),
                        _buildInfoRow(
                          'شامل التوصيل:',
                          order.deliveryIncluded ? 'نعم' : 'لا',
                        ),
                        _buildInfoRow(
                          'تاريخ التوصيل:',
                          order.deliveryDate != null
                              ? intl.DateFormat(
                                  'dd-MMM-yyyy',
                                ).format(order.deliveryDate!)
                              : '',
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Left Column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'التاريخ:',
                          intl.DateFormat(
                            'dd-MMM-yyyy',
                          ).format(order.orderDate),
                        ),
                        _buildInfoRow('مسؤول البيع:', order.salesResponsible),
                        _buildInfoRow('طريقة السداد:', order.paymentMethod),
                        _buildInfoRow('مكان التسليم:', order.deliveryPlace),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  4: pw.FlexColumnWidth(2), // الصنف
                  3: pw.FlexColumnWidth(1), // الكمية
                  2: pw.FlexColumnWidth(1), // الوحدة
                  1: pw.FlexColumnWidth(1), // السعر
                  0: pw.FlexColumnWidth(1), // القيمة
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1565C0),
                    ),
                    children: [
                      _buildHeaderCell('القيمة'),
                      _buildHeaderCell('السعر'),
                      _buildHeaderCell('الوحدة'),
                      _buildHeaderCell('الكمية'),
                      _buildHeaderCell('الصنف'),
                    ],
                  ),

                  // Data rows
                  ...order.items.map((item) {
                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                      ),
                      children: [
                        _buildCell(item.value.toStringAsFixed(2)),
                        _buildCell(item.price.toString()),
                        _buildCell(item.unit),
                        _buildCell(item.quantity.toString()),
                        _buildCell(item.itemName),
                      ],
                    );
                  }),

                  // Total row inside table
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1565C0),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          order.totalValue.toStringAsFixed(2),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      _buildCell(''),
                      _buildCell(''),
                      _buildCell(''),
                      // "الإجمالي" في أول خانة
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'الإجمالي',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Totals
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInfoRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              color: PdfColors.blue50,
              child: pw.Text(
                value ?? '',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }
}
