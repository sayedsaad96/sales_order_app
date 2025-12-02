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
              pw.SizedBox(height: 10),
              // Items Tables
              ...(() {
                final groupedItems = <String, List<SalesOrderItem>>{};
                for (var item in order.items) {
                  final cat = item.category ?? order.category ?? '';
                  groupedItems.putIfAbsent(cat, () => []).add(item);
                }

                return groupedItems.entries.map((entry) {
                  final category = entry.key;
                  final items = entry.value;

                  return pw.Column(
                    children: [
                      if (category.isNotEmpty)
                        pw.Container(
                          alignment: pw.Alignment.centerRight,
                          padding: const pw.EdgeInsets.only(bottom: 5, top: 10),
                          child: pw.Text(
                            'التصنيف: $category',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ),
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
                          ...items.map((item) {
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
                        ],
                      ),
                    ],
                  );
                });
              })(),

              pw.SizedBox(height: 10),

              // Notes Section
              if (order.notes != null && order.notes!.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    color: PdfColors.blue50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ملاحظات:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        order.notes!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),

              pw.SizedBox(height: 20),

              // Grand Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      color: PdfColor.fromInt(0xFF1565C0),
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'الإجمالي',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            order.totalValue.toStringAsFixed(2),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
