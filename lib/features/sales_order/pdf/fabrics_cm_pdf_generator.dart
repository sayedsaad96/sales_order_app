import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import '../data/models/fabrics_cm_sales_order.dart';

class FabricsCmPdfGenerator {
  static Future<pw.Document> generate(FabricsCmSalesOrder order) async {
    final pdf = pw.Document();

    // Load Font
    pw.Font arabicFont;
    pw.Font arabicFontBold;
    try {
      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      arabicFont = pw.Font.ttf(fontData);
      final fontDataBold = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
      arabicFontBold = pw.Font.ttf(fontDataBold);
    } catch (e) {
      arabicFont = pw.Font.courier();
      arabicFontBold = pw.Font.courierBold();
    }

    // Load Logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }

    const primaryColor = PdfColor.fromInt(0xFF3F51B5); // Indigo
    const accentColor = PdfColor.fromInt(0xFFF3E5F5); // Light Purple
    const lightGrey = PdfColor.fromInt(0xFFEEEEEE);

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4, 
        margin: const pw.EdgeInsets.all(20),
        textDirection: pw.TextDirection.rtl,
        header: (context) =>
            _buildHeaderRow(order, logoImage, primaryColor, accentColor),
        footer: (context) => _buildPageFooter(context),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),
            // Header Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      children: [
                        _buildInfoRow('اسم العميل:', order.customerName),
                        _buildInfoRow('مسئول البيع:', order.salesResponsible),
                        _buildInfoRow('طريقة السداد:', order.paymentMethod),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      children: [
                        _buildInfoRow(
                          'تاريخ التوصيل:',
                          order.deliveryDate != null
                              ? intl.DateFormat(
                                  'yyyy-MM-dd',
                                ).format(order.deliveryDate!)
                              : '-',
                        ),
                        _buildInfoRow('نوع الطلب:', order.orderType),
                        _buildInfoRow(
                          'التاريخ:',
                          intl.DateFormat('yyyy-MM-dd').format(order.orderDate),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: pw.FixedColumnWidth(55), // السعر
                1: pw.FixedColumnWidth(100), // اسم شركة الغزل
                2: pw.FixedColumnWidth(85), // طول الغرزه
                3: pw.FixedColumnWidth(40), // الجوج
                4: pw.FixedColumnWidth(45), // البوصه
                5: pw.FlexColumnWidth(3), // مواصفة القماش
                6: pw.FixedColumnWidth(55), // الكميه (كجم)
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildTableHeader('السعر'),
                    _buildTableHeader('اسم شركة الغزل', '(مصنعيات فقط)'),
                    _buildTableHeader('طول الغرزه', '(وزن المتر مربع قبل الصباغه)'),
                    _buildTableHeader('الجوج'),
                    _buildTableHeader('البوصه'),
                    _buildTableHeader('مواصفة القماش'),
                    _buildTableHeader('الكميه', '(كجم)'),
                  ],
                ),
                // Rows
                ...order.items.map((item) {
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.white),
                    children: [
                       _buildTableCell(item.price.toString()),
                       _buildTableCell(item.spinningCompany),
                       _buildTableCell(item.stitchLength.toString()),
                       _buildTableCell(item.gauge.toString()),
                       _buildTableCell(item.widthInches.toString()),
                       _buildTableCell(
                         'نوع الغزل: ${item.yarnType}\n'
                         'نمرة الغزل: ${item.yarnCount}\n'
                         'نوع القماش: ${item.fabricType}\n'
                         'نسبة الليكرا: ${item.lycraPercentage}%\n'
                         'نمرة الليكرا: ${item.lycraNumber}'
                       ),
                       _buildTableCell(item.quantity.toString()),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 10),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: lightGrey,
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'الإجمالي الكلي: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        order.totalValue.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                'ملاحظات:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(order.notes!),
            ],
            pw.SizedBox(height: 30),
          ];
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _buildHeaderRow(
    FabricsCmSalesOrder order,
    pw.MemoryImage? logoImage,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Right Side (Visual Right in RTL) - S/N
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'S/N: ${order.sn ?? "---"}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Center - Title
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Fabrics & CM Sales Order',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  if (order.branch != null)
                     pw.Text(
                      _fixArabic(order.branch!),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                ],
              ),
            ),
            // Left Side (Visual Left) - Logo
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      height: 50,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'شكراً لتعاملكم معنا',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? '-',
              style: const pw.TextStyle(fontSize: 10),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String title, [String? subTitle]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            _fixArabic(title),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (subTitle != null)
            pw.Text(
              _fixArabic(subTitle),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        _fixArabic(text),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static String _fixArabic(String text) {
    return text; 
  }
}
