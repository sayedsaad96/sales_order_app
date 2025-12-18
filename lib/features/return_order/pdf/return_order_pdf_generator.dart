import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import '../data/models/return_order.dart';

class ReturnOrderPdfGenerator {
  static Future<Uint8List> generate(ReturnOrder order) async {
    final pdf = pw.Document();

    // Load Font
    pw.Font arabicFont;
    try {
      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      arabicFont = pw.Font.ttf(fontData);
    } catch (e) {
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

    // Define Colors
    const primaryColor = PdfColor.fromInt(0xFFC62828); // Red
    const accentColor = PdfColor.fromInt(0xFFFFEBEE); // Light Red

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFont);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        textDirection: pw.TextDirection.rtl,
        header: (context) =>
            _buildHeaderRow(order, logoImage, primaryColor, accentColor),
        footer: (context) => _buildPageFooter(context),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),

            // --- Info Blocks Section ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Customer Info (Right in RTL)
                pw.Expanded(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(left: 10),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('بيانات العميل', primaryColor),
                        pw.SizedBox(height: 8),
                        _buildInfoRow('الاسم:', order.customerName),
                        _buildInfoRow('المنطقة:', order.region),
                        // Route combo
                        if ((order.routeFrom != null &&
                                order.routeFrom!.isNotEmpty) ||
                            (order.routeTo != null &&
                                order.routeTo!.isNotEmpty))
                          _buildInfoRow(
                            'خط السير:',
                            'من ${order.routeFrom ?? "-"} إلى ${order.routeTo ?? "-"}',
                          ),
                      ],
                    ),
                  ),
                ),

                // Return Details (Left in RTL)
                pw.Expanded(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(right: 10),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('تفاصيل المرتجع', primaryColor),
                        pw.SizedBox(height: 8),
                        _buildInfoRow(
                          'مسئول المرتجع:',
                          order.returnResponsible,
                        ),
                        _buildInfoRow(
                          'تاريخ المرتجع:',
                          intl.DateFormat(
                            'dd/MM/yyyy',
                          ).format(order.returnDate),
                        ),
                        if (order.deliveryDate != null)
                          _buildInfoRow(
                            'تاريخ التوصيل:',
                            intl.DateFormat(
                              'dd/MM/yyyy',
                            ).format(order.deliveryDate!),
                          ),
                        _buildInfoRow(
                          'تكلفة التوصيل:',
                          order.deliveryCostPayer,
                        ),
                        _buildInfoRow('سبب المرتجع:', order.returnReason),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // --- Items Table ---
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: PdfColors.grey200,
                  width: 0.5,
                ),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1), // Unit
                1: pw.FlexColumnWidth(1), // Qty
                2: pw.FlexColumnWidth(2.5), // Item Name
                3: pw.FlexColumnWidth(1.5), // Notes
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildTableHeader('الوحدة'),
                    _buildTableHeader('الكمية'),
                    _buildTableHeader('الصنف', align: pw.TextAlign.right),
                    _buildTableHeader('ملاحظات'),
                  ],
                ),
                // Rows
                ...order.items.asMap().entries.map((e) {
                  final index = e.key;
                  final item = e.value;
                  final isEven = index % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.white : accentColor,
                    ),
                    children: [
                      _buildTableCell(item.unit),
                      _buildTableCell(item.quantity.toString()),
                      _buildTableCell(item.item, align: pw.TextAlign.right),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: pw.TextField(
                          name: 'return_note_$index',
                          textStyle: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // --- Footer / Totals ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Spacer(flex: 2),

                // Totals (Left)
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(top: 20),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          decoration: const pw.BoxDecoration(
                            color: primaryColor,
                            borderRadius: pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'إجمالي الكمية',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              pw.Text(
                                order.totalQuantity.toStringAsFixed(2),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- Header Builder ---
  static pw.Widget _buildHeaderRow(
    ReturnOrder order,
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
            // --- Right Side ---
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'S/N: ${order.sn ?? "---"}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Center Side ---
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'طلب مرتجع',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  if (order.branch != null)
                    pw.Text(
                      order.branch!,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  pw.SizedBox(height: 2),
                  if (order.category != null)
                    pw.Text(
                      order.category!,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ),

            // --- Left Side ---
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      height: 60,
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

  // --- Footer Builder ---
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
          'صفحة ${context.pageNumber} من ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: color, width: 2)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: color,
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
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

  static pw.Widget _buildTableHeader(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }
}
