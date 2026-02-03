import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import '../data/models/return_order.dart';

class ReturnOrderPdfGenerator {
  // Define Column Widths
  static const tableColumnWidths = {
    0: pw.FlexColumnWidth(1), // Unit
    1: pw.FlexColumnWidth(1), // Qty
    2: pw.FlexColumnWidth(4), // Item Name
  };

  static Future<Uint8List> generate(ReturnOrder order) async {
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

    // Define Colors
    const primaryColor = PdfColor.fromInt(0xFFC62828); // Red
    const accentColor = PdfColor.fromInt(0xFFFFEBEE); // Light Red

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);
    final numberFormat = intl.NumberFormat('#,###.##');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: 15,
        ),
        textDirection: pw.TextDirection.rtl,
        header: (context) {
          if (context.pageNumber == 1) {
            return _buildHeaderRow(order, logoImage, primaryColor, accentColor);
          } else {
            return pw.Column(children: [
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    color: PdfColors.grey200,
                    width: 0.5,
                  ),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                ),
                columnWidths: tableColumnWidths,
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: primaryColor),
                    children: [
                      _buildTableHeader('الوحدة'),
                      _buildTableHeader('الكمية'),
                      _buildTableHeader(
                        'الصنف',
                        align: pw.TextAlign.center,
                      ),
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
            // --- Info Blocks Section ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Customer Info (Right in RTL)
                pw.Expanded(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(left: 5),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('بيانات العميل', primaryColor),
                        pw.SizedBox(height: 4),
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
                    margin: const pw.EdgeInsets.only(right: 5),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('تفاصيل المرتجع', primaryColor),
                        pw.SizedBox(height: 4),
                        _buildInfoRow(
                          'مسئول المرتجع:',
                          order.returnResponsible,
                        ),
                        _buildInfoRow(
                          'تاريخ المرتجع:',
                          intl.DateFormat('dd/MM/yyyy').format(
                            order.returnDate,
                          ),
                        ),
                        if (order.deliveryDate != null)
                          _buildInfoRow(
                            'تاريخ التوصيل:',
                            intl.DateFormat('dd/MM/yyyy').format(
                              order.deliveryDate!,
                            ),
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
            ...(() {
              final groupedItems = <String, List<ReturnOrderItem>>{};
              for (var item in order.items) {
                final cat = item.category ?? order.category ?? 'عام';
                groupedItems.putIfAbsent(cat, () => []).add(item);
              }

              return groupedItems.entries.expand((groupEntry) {
                final category = groupEntry.key;
                final items = groupEntry.value;

                return [
                  if (groupedItems.length > 1 ||
                      (category != 'عام' && category.isNotEmpty))
                    pw.Container(
                      padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
                      child: pw.Text(
                        'تصنيف: $category',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  pw.Table(
                    border: pw.TableBorder(
                      horizontalInside: pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 0.5,
                      ),
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                    ),
                    defaultVerticalAlignment:
                        pw.TableCellVerticalAlignment.middle,
                    columnWidths: tableColumnWidths,
                    children: [
                      // Header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: primaryColor),
                        children: [
                          _buildTableHeader('الوحدة'),
                          _buildTableHeader('الكمية'),
                          _buildTableHeader(
                            'الصنف',
                            align: pw.TextAlign.center,
                          ),
                        ],
                      ),
                      // Rows
                      ...items.asMap().entries.map((e) {
                        final index = e.key;
                        final item = e.value;
                        final isEven = index % 2 == 0;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: isEven ? PdfColors.white : accentColor,
                          ),
                          children: [
                            _buildEditableTableCell(
                              item.unit,
                              'unit_${category}_$index',
                              backgroundColor:
                                  isEven ? PdfColors.white : accentColor,
                              font: arabicFont,
                            ),
                            _buildEditableTableCell(
                              numberFormat.format(item.quantity),
                              'quantity_${category}_$index',
                              backgroundColor:
                                  isEven ? PdfColors.white : accentColor,
                            ),
                            _buildTableCell(
                              item.item,
                              align: pw.TextAlign.center,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                ];
              }).toList();
            })(),

            pw.SizedBox(height: 20),

            // --- Footer / Totals ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Spacer(flex: 1),
                // Totals (Left)
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(top: 20),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
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
                                  fontSize: 12,
                                ),
                              ),
                              pw.Container(
                                width: 70, // Reduced from 85 to ensure it fits
                                child: pw.TextField(
                                  name: 'total_quantity',
                                  value: numberFormat.format(
                                    order.totalQuantity,
                                  ),
                                  textStyle: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                    font: pw.Font.helvetica(),
                                  ),
                                  backgroundColor: primaryColor,
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

            if (order.notes != null && (order.notes?.isNotEmpty ?? false)) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ملاحظات:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: primaryColor,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      _fixArabic(order.notes ?? ''),
                      style: const pw.TextStyle(fontSize: 10),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
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
                    'طلب مرتجع',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  if (order.branch != null && (order.branch?.isNotEmpty ?? false))
                    pw.Text(
                      _fixArabic(order.branch ?? ''),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  pw.SizedBox(height: 2),
                  if (order.category != null && (order.category?.isNotEmpty ?? false))
                    pw.Text(
                      _fixArabic(order.category ?? ''),
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  pw.SizedBox(height: 2),
                  // Delivery Cost Payer
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        _fixArabic('تكلفة التوصيل على: '),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          _fixArabic(order.deliveryCostPayer),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Left Side ---
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      height: 40,
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
          fontSize: 10,
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
                fontSize: 8,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? '-',
              style: const pw.TextStyle(fontSize: 8),
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
        _fixArabic(text),
        textAlign: align,
        textDirection: pw.TextDirection.rtl,
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
        _fixArabic(text),
        textAlign: align,
        textDirection: pw.TextDirection.rtl,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildEditableTableCell(
    String initialValue,
    String fieldName, {
    PdfColor? backgroundColor,
    pw.Font? font,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.TextField(
        name: fieldName,
        value: initialValue,
        textStyle: pw.TextStyle(
          font: font ?? pw.Font.helvetica(),
          fontSize: 10,
        ),
        backgroundColor: backgroundColor ?? PdfColors.white,
      ),
    );
  }

  static String _fixArabic(String text) {
    return text;
  }
}
