import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'package:printing/printing.dart';
import '../data/models/yarn_sales_order.dart';

class YarnPdfGenerator {
  static Future<pw.Document> generate(YarnSalesOrder order) async {
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

    // Define Colors
    // Define Colors
    const primaryColor = PdfColor.fromInt(0xFF009688); // Colors.teal
    const accentColor = PdfColor.fromInt(0xFFE0F2F1); // Colors.teal[50]
    const lightGrey = PdfColor.fromInt(0xFFEEEEEE);

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);
    final numberFormat = intl.NumberFormat('#,###.##', 'en_US');

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
                        _buildInfoRow('اسم للتواصل:', order.contactName),
                        _buildInfoRow('رقم للتواصل:', order.mobileNumber),
                        _buildInfoRow('المنطقة:', order.region),
                        _buildInfoRow('مكان التسليم:', order.deliveryPlace),
                      ],
                    ),
                  ),
                ),

                // Order Details (Left in RTL)
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
                        _buildSectionHeader('تفاصيل الطلب', primaryColor),
                        pw.SizedBox(height: 8),
                        _buildInfoRow('مسئول البيع:', order.salesResponsible),
                        _buildInfoRow('طريقة السداد:', order.paymentMethod),
                        _buildInfoRow(
                          'تاريخ الطلب:',
                          intl.DateFormat('dd/MM/yyyy').format(order.orderDate),
                        ),
                        _buildInfoRow(
                          'تاريخ التسليم:',
                          order.deliveryDate != null
                              ? intl.DateFormat(
                                  'dd/MM/yyyy',
                                ).format(order.deliveryDate!)
                              : '-',
                        ),
                        _buildInfoRow(
                          'تعديل الكمية:',
                          order.editQuantity ?? 'الكمية المحددة',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // --- Items Table ---
            if (order.items.isNotEmpty) ...[
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    color: PdfColors.grey200,
                    width: 0.5,
                  ),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                ),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: pw.FlexColumnWidth(1), // Total
                  1: pw.FlexColumnWidth(1), // Price
                  2: pw.FlexColumnWidth(1), // Unit
                  3: pw.FlexColumnWidth(1), // Qty
                  4: pw.FlexColumnWidth(3), // Description
                  5: pw.FlexColumnWidth(2), // Comment
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryColor),
                    children: [
                      _buildTableHeader('القيمة'),
                      _buildTableHeader('السعر'),
                      _buildTableHeader('الوحدة'),
                      _buildTableHeader('الكمية'),
                      _buildTableHeader('الصنف', align: pw.TextAlign.center),
                      _buildTableHeader('تعليق'),
                    ],
                  ),
                  // Rows
                  ...order.items.asMap().entries.map((e) {
                    final index = e.key;
                    final item = e.value;
                    final isEven = index % 2 == 0;
                    final rowColor = isEven ? PdfColors.white : PdfColors.grey50;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: rowColor,
                      ),
                      children: [
                        _buildEditableTableCell(
                          numberFormat.format(item.value),
                          'value_$index',
                          backgroundColor: rowColor,
                        ),
                        _buildEditableTableCell(
                          numberFormat.format(item.price),
                          'price_$index',
                          backgroundColor: rowColor,
                        ),
                        _buildTableCell(item.unit),
                        _buildEditableTableCell(
                          numberFormat.format(item.quantity),
                          'quantity_$index',
                          backgroundColor: rowColor,
                        ),
                        _buildTableCell(item.description, align: pw.TextAlign.center),
                        _buildEditableTableCell(
                          '',
                          'comment_$index',
                          backgroundColor: rowColor,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // --- Footer / Totals ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Notes (Right, takes up available space)
                if (order.notes != null && order.notes!.isNotEmpty)
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(top: 20, left: 20),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: lightGrey,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _fixArabic('ملاحظات:'),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _fixArabic(order.notes!),
                            style: const pw.TextStyle(fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  )
                else
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
                                'الإجمـــالي',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              pw.Container(
                                width: 85,
                                child: pw.TextField(
                                  name: 'total_value',
                                  value: numberFormat.format(order.totalValue),
                                  textStyle: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 14,
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

            // --- Payment Schedule Section ---
            // Show installments only if there are any with data
            ...(() {
              if (order.installments.isEmpty) return [];

              final validInstallments = order.installments
                  .where(
                    (inst) => inst.duration.isNotEmpty || inst.value.isNotEmpty,
                  )
                  .toList();

              if (validInstallments.isEmpty) return [];

              return [
                pw.SizedBox(height: 30),
                _buildSectionHeader(
                  'طريقة السداد في حالة تعدد الدفعات',
                  primaryColor,
                ),
                pw.SizedBox(height: 10),

                // Split into two columns if more than 8 installments
                if (validInstallments.length <= 8)
                  // Single column for 8 or fewer installments
                  pw.Column(
                    children: validInstallments.asMap().entries.map((entry) {
                      return _buildInstallmentRow(
                        entry.key + 1,
                        entry.value.duration,
                        entry.value.value,
                      );
                    }).toList(),
                  )
                else
                  // Two columns for more than 8 installments
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left column (first half)
                      pw.Expanded(
                        child: pw.Column(
                          children: validInstallments
                              .take((validInstallments.length / 2).ceil())
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                                return _buildInstallmentRow(
                                  entry.key + 1,
                                  entry.value.duration,
                                  entry.value.value,
                                );
                              })
                              .toList(),
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      // Right column (second half)
                      pw.Expanded(
                        child: pw.Column(
                          children: validInstallments
                              .skip((validInstallments.length / 2).ceil())
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                                final actualIndex =
                                    entry.key +
                                    (validInstallments.length / 2).ceil();
                                return _buildInstallmentRow(
                                  actualIndex + 1,
                                  entry.value.duration,
                                  entry.value.value,
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
                  ),
              ];
            })(),
          ];
        },
      ),
    );

    return pdf;
  }

  // --- Header Builder ---
  static pw.Widget _buildHeaderRow(
    YarnSalesOrder order,
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
                  pw.SizedBox(height: 2),
                  // Delivery Responsibility below branch
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        _fixArabic('مسئولية التوصيل: '),
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
                          _fixArabic(order.deliveryResponsibility),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Yarn Sales Order',
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
            width: 80,
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


  static pw.Widget _buildInstallmentRow(
    int number,
    String duration,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 50,
            child: pw.Text(
              _fixArabic('القيمة $number'),
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(
                _fixArabic(duration),
                style: const pw.TextStyle(fontSize: 8),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(
                _fixArabic(value),
                style: const pw.TextStyle(fontSize: 8),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fixArabic(String text) {
    return text;
  }

}
