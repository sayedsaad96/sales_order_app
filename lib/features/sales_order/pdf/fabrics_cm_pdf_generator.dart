import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'package:printing/printing.dart';
import '../data/models/fabrics_cm_sales_order.dart';

class FabricsCmPdfGenerator {
  // Define Column Widths
  static const tableColumnWidths = {
    0: pw.FixedColumnWidth(100), // اسم شركة الغزل
    1: pw.FixedColumnWidth(85), // طول الغرزه
    2: pw.FixedColumnWidth(40), // الجوج
    3: pw.FixedColumnWidth(45), // البوصه
    4: pw.FlexColumnWidth(3), // مواصفة القماش
    5: pw.FixedColumnWidth(55), // الكميه (كجم)
  };

  static Future<pw.Document> generate(FabricsCmSalesOrder order) async {
    final pdf = pw.Document();

    pw.Font arabicFont;
    pw.Font arabicFontBold;
    try {
      arabicFont = await PdfGoogleFonts.cairoRegular();
      arabicFontBold = await PdfGoogleFonts.cairoBold();
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

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);
    final numberFormat = intl.NumberFormat('#,###.##', 'en_US');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        textDirection: pw.TextDirection.rtl,
        header: (context) {
          if (context.pageNumber == 1) {
            return _buildHeaderRow(order, logoImage, primaryColor, accentColor);
          } else {
            return pw.Column(children: [
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: tableColumnWidths,
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryColor),
                    children: [
                      _buildTableHeader('اسم شركة الغزل', '(مصنعيات فقط)'),
                      _buildTableHeader(
                          'طول الغرزه', '(وزن المتر مربع قبل الصباغه)'),
                      _buildTableHeader('الجوج'),
                      _buildTableHeader('البوصه'),
                      _buildTableHeader('مواصفة القماش'),
                      _buildTableHeader('الكميه', '(كجم)'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
            ]);
          }
        },
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
                              ? intl.DateFormat('yyyy-MM-dd')
                                  .format(order.deliveryDate!)
                              : '-',
                        ),
                        _buildInfoRow('نوع الطلب:', order.orderType),
                        _buildInfoRow(
                          'التاريخ:',
                          intl.DateFormat('yyyy-MM-dd')
                              .format(order.orderDate),
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
              columnWidths: tableColumnWidths,
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildTableHeader('اسم شركة الغزل', '(مصنعيات فقط)'),
                    _buildTableHeader(
                        'طول الغرزه', '(وزن المتر مربع قبل الصباغه)'),
                    _buildTableHeader('الجوج'),
                    _buildTableHeader('البوصه'),
                    _buildTableHeader('مواصفة القماش'),
                    _buildTableHeader('الكميه', '(كجم)'),
                  ],
                ),
                // Rows
                ...order.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isEven = index % 2 == 0;
                  final rowColor = isEven ? PdfColors.white : PdfColors.grey100;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: rowColor,
                    ),
                    children: [
                      _buildTableCell(item.spinningCompany ?? ''),
                      _buildTableCell(
                          numberFormat.format(item.stitchLength ?? 0.0)),
                      _buildTableCell((item.gauge ?? 0).toString()),
                      _buildTableCell(
                          numberFormat.format(item.widthInches ?? 0.0)),
                      _buildTableCell(
                        'نوع الغزل: ${item.yarnType ?? ''}\n'
                        'نمرة الغزل: ${item.yarnCount ?? ''}\n'
                        'نوع القماش: ${item.fabricType ?? ''}\n'
                        'نسبة الليكرا: ${item.lycraPercentage ?? 0.0}%\n'
                        'نمرة الليكرا: ${item.lycraNumber ?? ''}',
                      ),
                      _buildEditableTableCell(
                        numberFormat.format(item.quantity),
                        'quantity_$index',
                        backgroundColor: rowColor,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 10),
            
            // Global pricing params summary
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 10),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPriceParamItem('سعر الغزل', order.yarnPrice ?? 0.0, numberFormat),
                  _buildVerticalDivider(),
                  _buildPriceParamItem('سعر الليكرا', order.lycraPrice ?? 0.0, numberFormat),
                  _buildVerticalDivider(),
                  _buildPriceParamItem('المصنعية', order.manufacturingPrice ?? 0.0, numberFormat),
                ],
              ),
            ),

            // Totals Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey200),
                  ),
                  child: pw.Column(
                    children: [
                      _buildTotalRow('إجمالي السعر', order.baseTotal, numberFormat),
                      if (order.wasteTotal > 0) ...[
                        pw.SizedBox(height: 5),
                        _buildTotalRow('الهالك (2%)', order.wasteTotal, numberFormat, color: PdfColors.red),
                      ],
                      pw.Divider(color: primaryColor, thickness: 1),
                      _buildTotalRow('الإجمالي النهائي', order.totalValue, numberFormat, isBold: true, color: primaryColor),
                    ],
                  ),
                ),
              ],
            ),
            if (order.notes != null && (order.notes?.isNotEmpty ?? false)) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                _fixArabic('ملاحظات:'),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                _fixArabic(order.notes ?? ''),
                style: const pw.TextStyle(fontSize: 10),
                textDirection: pw.TextDirection.rtl,
              ),
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
            // --- Right Side (Visual Right) ---
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
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 60,
                          height: 12,
                          child: pw.TextField(
                            name: 'sn',
                            value: order.sn ?? "---",
                            textStyle: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                              font: pw.Font.helvetica(),
                            ),
                            backgroundColor: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'S/N: ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Center Side ---
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'طلب بيع',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  if (order.branch != null && (order.branch?.isNotEmpty ?? false))
                    pw.Text(
                      _fixArabic(order.branch ?? ''),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  pw.SizedBox(height: 10), // Space for missing delivery info
                  pw.Text(
                    'Fabrics & CM Sales Order',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),

            // --- Left Side (Visual Left) ---
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
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
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

  static pw.Widget _buildEditableTableCell(
    String initialValue,
    String fieldName, {
    PdfColor? backgroundColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.TextField(
        name: fieldName,
        value: initialValue,
        textStyle: pw.TextStyle(
          font: pw.Font.helvetica(),
          fontSize: 10,
        ),
        backgroundColor: backgroundColor ?? PdfColors.white,
      ),
    );
  }


  static pw.Widget _buildPriceParamItem(String label, double value, intl.NumberFormat format) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          _fixArabic(label),
          style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF757575)),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          format.format(value),
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF37474F)),
        ),
      ],
    );
  }

  static pw.Widget _buildVerticalDivider() {
    return pw.Container(
      height: 20,
      width: 1,
      color: PdfColors.grey300,
      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
    );
  }

  static pw.Widget _buildTotalRow(String label, double value, intl.NumberFormat format, {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          _fixArabic(label),
          style: pw.TextStyle(
            fontSize: isBold ? 12 : 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColor.fromInt(0xFF424242),
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          format.format(value),
          style: pw.TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  static String _fixArabic(String text) {
    return text;
  }
}
