
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'package:annex_sales_order/features/sales_order/data/models/quotation.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';

class QuotationPdfGenerator {
  static Future<pw.Document> generate(Quotation quotation) async {
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

    const primaryColor = PdfColor.fromInt(0xFF2C3E50); // Dark Blue/Grey Professional
    const headerColor = PdfColor.fromInt(0xFF1ABC9C); // Teal
    const accentColor = PdfColor.fromInt(0xFFE8F6F3); // Very Light Teal

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);
    final numberFormat = intl.NumberFormat('#,###.##');
    final dateFormat = intl.DateFormat('yyyy-MM-dd');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4, 
        margin: const pw.EdgeInsets.all(24),
        textDirection: pw.TextDirection.rtl,
        header: (context) => _buildProfessionalHeader(quotation, logoImage, primaryColor, headerColor),
        footer: (context) => _buildProfessionalFooter(context, primaryColor),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            
            // Welcome Section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: headerColor, width: 4)),
                color: PdfColors.grey50
              ),
              child: pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                     pw.Text(
                         'السادة / ${quotation.customerName ?? "المحترمين"}',
                         style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)
                     ),
                     pw.SizedBox(height: 5),
                     pw.Text(
                         'تحية طيبة وبعد،\nيسرنا في شركة Annex Group أن نقدم لكم عرض السعر التالي، آملين أن ينال إعجابكم وتطلعاتكم. نحن نلتزم دائماً بتقديم أجود الخامات وأفضل الأسعار لشركائنا.',
                         style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700, lineSpacing: 1.5),
                     ),
                 ]
              ),
            ),
            pw.SizedBox(height: 20),

            // Info Grid
            pw.Row(
               children: [
                   pw.Expanded(child: _buildInfoCard('رقم العرض', quotation.sn ?? '####', primaryColor)),
                   pw.SizedBox(width: 10),
                   pw.Expanded(child: _buildInfoCard('تاريخ العرض', dateFormat.format(quotation.date), primaryColor)),
               ]
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: pw.FixedColumnWidth(60), // Total
                1: pw.FixedColumnWidth(50), // Price
                2: pw.FixedColumnWidth(50), // Qty
                3: pw.FixedColumnWidth(50), // Unit
                4: pw.FlexColumnWidth(3),   // Description
                5: pw.FixedColumnWidth(25), // #
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildTableHeader('الإجمالي'),
                    _buildTableHeader('السعر'),
                    _buildTableHeader('الكمية'),
                    _buildTableHeader('الوحدة'),
                    _buildTableHeader('البيان والمواصفات'),
                    _buildTableHeader('م'),
                  ],
                ),
                ...quotation.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isEven = index % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.white : accentColor,
                    ),
                    children: [
                       _buildTableCell(numberFormat.format(item.value), isBold: true),
                       _buildTableCell(numberFormat.format(item.calculateUnitPrice)),
                       _buildTableCell(numberFormat.format(item.quantity)),
                       _buildTableCell(item.unit ?? (item.type == 'fabric' ? 'كجم' : '')),
                       _buildTableCell(_buildItemDescription(item), alignRight: true),
                       _buildTableCell('${index + 1}'),
                    ],
                  );
                }),
              ],
            ),

            // Validity and Terms
            if (quotation.validUntil != null || (quotation.termsAndConditions != null && quotation.termsAndConditions!.isNotEmpty)) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey300)
                    ),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                            if (quotation.validUntil != null)
                                pw.Row(
                                    children: [
                                        pw.Text('هذا العرض صالح حتى: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                                        pw.Text(dateFormat.format(quotation.validUntil!)),
                                    ]
                                ),
                            if (quotation.validUntil != null && quotation.termsAndConditions != null && quotation.termsAndConditions!.isNotEmpty)
                                pw.SizedBox(height: 10),
                            if (quotation.termsAndConditions != null && quotation.termsAndConditions!.isNotEmpty)
                                pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                        pw.Text('الشروط والأحكام:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                                        pw.SizedBox(height: 4),
                                        pw.Text(quotation.termsAndConditions!, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.2)),
                                    ]
                                ),
                        ]
                    )
                ),
            ],

            pw.SizedBox(height: 15),

            // Footer Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('إجمالي البنود:'),
                          pw.Text('${quotation.items.length}'),
                        ],
                      ),
                      if (quotation.wasteTotal > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('الهالك (2%):'),
                            pw.Text(numberFormat.format(quotation.wasteTotal)),
                          ],
                        ),
                      ],
                      pw.Divider(color: headerColor),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: pw.BoxDecoration(
                          color: headerColor,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'الإجمالي:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                            ),
                            pw.Text(
                              '${numberFormat.format(quotation.totalValue)} EGP',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 12
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4)
                  ),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                           pw.Text('ملاحظات:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                           pw.Divider(color: PdfColors.grey300),
                           pw.Text(quotation.notes!, style: const pw.TextStyle(fontSize: 10)),
                      ]
                  )
              ),
            ],
            
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
                child: pw.Text('شكرا لثقتكم بشركة Annex Group', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor))
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  static String _buildItemDescription(QuotationItem item) {
      if (item.type == 'standard') {
          return '${item.itemName ?? "بند عام"}${item.description != null && item.description!.isNotEmpty ? " - ${item.description}" : ""}';
      } else if (item.type == 'yarn') {
          return item.description ?? 'غزل';
      } else if (item.type == 'fabric') {
          final parts = <String>[];
          if (item.fabricType != null) parts.add('قماش: ${item.fabricType}');
          if (item.yarnType != null) parts.add('غزل: ${item.yarnType}');
          if (item.yarnCount != null) parts.add('نمرة: ${item.yarnCount}');
          if (item.spinningCompany != null) parts.add('شركة: ${item.spinningCompany}');
          if (item.lycraPercentage != null) parts.add('ليكرا: ${item.lycraPercentage}%');
          if (item.widthInches != null) parts.add('عرض: ${item.widthInches}"');
          if (item.gauge != null) parts.add('G: ${item.gauge}');
          
          return parts.isEmpty ? "قماش مخصص" : parts.join(' - ');
      }
      return 'بند غير معروف';
  }

  static pw.Widget _buildProfessionalHeader(
    Quotation quotation,
    pw.MemoryImage? logoImage,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                         pw.Text('عرض سعر', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                         pw.Text('Quotation', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                    ]
                ),
                if (logoImage != null)
                    pw.Container(
                        height: 60,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                else
                    pw.Text('ANNEX Group', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            ]
        )
    );
  }

  static pw.Widget _buildProfessionalFooter(pw.Context context, PdfColor color) {
    // Fetch user details locally
    // Since Pdf widgets build synchronously, we rely on the synchronous getUser from Hive
    // Note: Hive box must be open, which is ensured by app initialization.
    final user = UserLocalDataSource().getUser();
    final email = (user?.email != null && user!.email!.isNotEmpty) ? user.email! : 'sales@annexeg.com';

    return pw.Container(
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Column(
            children: [
                 pw.Divider(color: color, thickness: 1),
                 pw.SizedBox(height: 5),
                 pw.Row(
                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                     children: [
                          pw.Text('Annex Group', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
                          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                          pw.Text(email, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                     ]
                 )
            ]
        )
    );
  }

  static pw.Widget _buildInfoCard(String label, String value, PdfColor color) {
      return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                  pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.SizedBox(height: 2),
                  pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
              ]
          )
      );
  }

  static pw.Widget _buildTableHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        title,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool alignRight = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal
        ),
      ),
    );
  }
}
