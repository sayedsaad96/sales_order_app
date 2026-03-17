import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import '../data/models/tax_invoice_request.dart';

class TaxInvoicePdfGenerator {
  static Future<pw.Document> generate(TaxInvoiceRequest request) async {
    final pdf = pw.Document();

    pw.Font arabicFont;
    pw.Font arabicFontBold;
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      arabicFont = pw.Font.ttf(fontData);
      arabicFontBold = pw.Font.ttf(fontBoldData);
    } catch (e) {
      arabicFont = pw.Font.courier();
      arabicFontBold = pw.Font.courierBold();
    }

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);
    const boxColor = PdfColor.fromInt(0xFFD1E9F6);
    final dateFormat = intl.DateFormat('yyyy/MM/dd');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo top left
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: logoImage != null
                    ? pw.Container(height: 60, child: pw.Image(logoImage))
                    : pw.SizedBox(height: 60),
              ),

              pw.SizedBox(height: 10),

              // Title centered
              pw.Text(
                'TAX INVOICE REQUEST',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Main Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  _buildMockupRow(
                    'كود العميل ساب',
                    request.sapCustomerCode,
                    boxColor,
                  ),
                  _buildMockupRow(
                    'أسم العميل بالبطاقة الضريبية',
                    request.customerNameOnTaxCard,
                    boxColor,
                  ),
                  _buildMockupRow(
                    'رقم البطاقة الضريبية',
                    request.taxCardNumber ?? 'مرفق صورة البطاقة الضريبية',
                    boxColor,
                  ),
                  _buildMockupRow('الصنف', request.itemName, boxColor),
                  _buildMockupRow(
                    'الكمية',
                    '${request.quantity?.toString() ?? ''} ${request.unit ?? ''}',
                    boxColor,
                  ),
                  _buildMockupRow(
                    'السعر',
                    request.unitPrice?.toString() ?? '',
                    boxColor,
                  ),

                  // Row for Dates with "التاريخ" label
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: pw.Text(
                                'من',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              decoration: const pw.BoxDecoration(
                                color: boxColor,
                              ),
                              child: pw.Text(
                                request.fromDate != null
                                    ? dateFormat.format(request.fromDate!)
                                    : '',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: pw.Text(
                                'إلى',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              decoration: const pw.BoxDecoration(
                                color: boxColor,
                              ),
                              child: pw.Text(
                                request.toDate != null
                                    ? dateFormat.format(request.toDate!)
                                    : '',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text(
                          'التاريخ',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Total with checkboxes
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: const pw.BoxDecoration(
                                color: boxColor,
                              ),
                              child: pw.Text(
                                (request.totalAfterTax ??
                                        request.totalBeforeTax ??
                                        0)
                                    .toString(),
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Spacer(),
                            pw.Text(
                              'بعد الضريبة',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                            pw.SizedBox(width: 5),
                            _buildCheckbox(
                              request.totalAfterTax != null &&
                                  request.totalAfterTax! > 0,
                            ),
                            pw.SizedBox(width: 20),
                            pw.Text(
                              'قبل الضريبة',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                            pw.SizedBox(width: 5),
                            _buildCheckbox(
                              request.totalBeforeTax != null &&
                                  request.totalBeforeTax! > 0,
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text(
                          'أجمالي قيمة الفاتورة',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Additional Info Section
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'معلومات أضافيه :',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.all(8),
                      padding: const pw.EdgeInsets.all(10),
                      width: double.infinity,
                      height: 100,
                      decoration: const pw.BoxDecoration(color: boxColor),
                      child: pw.Text(
                        request.additionalInfo ?? '',
                        style: const pw.TextStyle(fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(
                        child: pw.Text(
                          'ملحوظة في حالة وجود صورة البطاقه الضريبيه لا يهم رقم البطاقه الضريبيه',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.TableRow _buildMockupRow(
    String label,
    String value,
    PdfColor boxColor,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          height: 35,
          margin: const pw.EdgeInsets.all(5),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: pw.BoxDecoration(color: boxColor),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
        pw.Container(
          height: 35,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCheckbox(bool checked) {
    return pw.Container(
      width: 15,
      height: 15,
      decoration: pw.BoxDecoration(
        color: checked ? const PdfColor.fromInt(0xFFD1E9F6) : PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey, width: 1),
      ),
      child: checked
          ? pw.Center(
              child: pw.Text(
                'v', // Use 'v' but style it to look like a checkmark if needed, or stick to 'v' for safety
                style: pw.TextStyle(
                  font: pw.Font.helvetica(),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
            )
          : pw.SizedBox(),
    );
  }
}
