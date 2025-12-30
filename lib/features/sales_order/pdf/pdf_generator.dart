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
    const primaryColor = PdfColor.fromInt(0xFF1565C0); // Blue
    const accentColor = PdfColor.fromInt(0xFFE3F2FD); // Light Blue

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);
    final numberFormat = intl.NumberFormat('#,###.##');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(top: 30, left: 30, right: 30, bottom: 20),
        textDirection: pw.TextDirection.rtl,
        header: (context) =>
            _buildHeaderRow(order, logoImage, primaryColor, accentColor),
        footer: (context) => _buildPageFooter(context),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),

            // --- Info Blocks Section (First page only naturally) ---
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
                        _buildInfoRow(
                          'شامل التوصيل:',
                          order.deliveryIncluded ? 'نعم' : 'لا',
                        ),
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
                        // Use helper for Date to match style
                        _buildInfoRow(
                          'تاريخ الطلب:',
                          intl.DateFormat('dd/MM/yyyy').format(order.orderDate),
                        ),
                        _buildInfoRow(
                          'تاريخ التوصيل:',
                          order.deliveryDate != null
                              ? intl.DateFormat(
                                  'dd/MM/yyyy',
                                ).format(order.deliveryDate!)
                              : '-',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),

            // --- Valid Items Logic with Orphan Protection ---
            ...(() {
              final groupedItems = <String, List<SalesOrderItem>>{};
              // Default category if none
              for (var item in order.items) {
                // Ensure we group logically. Use "عام" if both are null.
                final cat = item.category ?? order.category ?? 'عام';
                groupedItems.putIfAbsent(cat, () => []).add(item);
              }

              return groupedItems.entries.expand((entry) {
                final category = entry.key;
                final items = entry.value;

                return [
                  if (groupedItems.length > 1 ||
                      (category != 'عام' && category.isNotEmpty))
                    pw.Container(
                      padding: const pw.EdgeInsets.only(top: 5, bottom: 5),
                      child: pw.Center(
                        child: pw.Text(
                          'تصنيف: $category',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  // Table
                  pw.Table(
                    border: pw.TableBorder(
                      horizontalInside: pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 0.5,
                      ),
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                    ),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2), // Total (Value)
                      1: pw.FlexColumnWidth(1.5), // Price
                      2: pw.FlexColumnWidth(1.5), // Unit
                      3: pw.FlexColumnWidth(1.5), // Qty
                      4: pw.FlexColumnWidth(3), // Item Name
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
                          _buildTableHeader('الصنف', align: pw.TextAlign.right),
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
                            _buildTableCell(numberFormat.format(item.value)),
                            _buildTableCell(numberFormat.format(item.price)),
                            _buildTableCell(item.unit),
                            _buildTableCell(numberFormat.format(item.quantity)),
                            _buildTableCell(
                              item.itemName,
                              align: pw.TextAlign.right,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ];
              });
            })(),

            pw.SizedBox(height: 20),

            // --- Footer / Totals (Flows after table) ---
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
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ملاحظات:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            order.notes!,
                            style: const pw.TextStyle(fontSize: 10),
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
                              pw.Text(
                                numberFormat.format(order.totalValue),
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

    return pdf;
  }

  static pw.Widget _buildHeaderRow(
    SalesOrder order,
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
                          _fixArabic(
                            order.deliveryIncluded ? 'الشركة' : 'العميل',
                          ),
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
                    'Sales Order',
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

  static String _fixArabic(String text) {
    return text;
  }
}
