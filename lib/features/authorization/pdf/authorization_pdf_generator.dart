import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'package:printing/printing.dart';
import '../data/models/authorization_data.dart';

class AuthorizationPdfGenerator {
  static Future<pw.Document> generate(AuthorizationData data) async {
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

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);
    const primaryColor = PdfColor.fromInt(0xFF1565C0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(50),
        build: (context) {
          return pw.Stack(
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.3,
                    child: pw.Image(logoImage, width: 500),
                  ),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Placeholder for Company Info/Letterhead if needed
                      pw.Text(
                        'أنكـــس جـــــــروب',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'الحفناوى للنسيج الدائرى والتريكو والملابس الجاهزة',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(height: 60, child: pw.Image(logoImage)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Title
              pw.Text(
                'تفويض رسمي',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 12),

              // Date
              pw.Align(
                alignment: pw.Alignment.centerLeft, // Left because English date
                child: pw.Text(
                  'التاريخ: ${intl.DateFormat('yyyy/MM/dd').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
              pw.SizedBox(height: 30),

              // Body
              pw.Container(
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildText(
                      'السادة : ${data.organization}',
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    pw.SizedBox(height: 10),
                    _buildText('تحية طيبة وبعد،،،  '),
                    pw.SizedBox(height: 15),
                    _buildText(
                      'نفيد سيادتكم علماً بأن مصنع الحفناوى للنسيج الدائرى والتريكو والملابس الجاهزة',
                    ),
                    pw.SizedBox(height: 5),
                    pw.RichText(
                      textDirection: pw.TextDirection.rtl,
                      text: pw.TextSpan(
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        children: [
                          const pw.TextSpan(text: 'قد فوض السيد / '),
                          pw.TextSpan(
                            text: data.authorizedPersonName,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          const pw.TextSpan(text: '  حامل بطاقة رقم قومي / '),
                          pw.TextSpan(
                            text: data.nationalId,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    _buildText(
                      'وذلك لتمثيل المصنع لدينا والتعامل مع سيادتكم في كل ما يخص الشيكات، الأوراق، والمعاملات المالية، وله كامل الصلاحية في التوقيع، الاستلام، وإنهاء كافة الإجراءات المرتبطة بهذا الشأن.',
                    ),
                    pw.SizedBox(height: 15),
                    pw.RichText(
                      textDirection: pw.TextDirection.rtl,
                      text: pw.TextSpan(
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        children: [
                          const pw.TextSpan(
                            text: 'ويُعد هذا التفويض ساريا من تاريخ: ',
                          ),
                          pw.TextSpan(
                            text: intl.DateFormat(
                              'yyyy/MM/dd',
                            ).format(data.startDate),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          const pw.TextSpan(text: '  وحتى تاريخ: '),
                          pw.TextSpan(
                            text: intl.DateFormat(
                              'yyyy/MM/dd',
                            ).format(data.endDate),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          const pw.TextSpan(text: '،'),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    _buildText(
                      'ويُلغى بانتهاء مدته أو بموجب إخطار كتابي رسمي من المصنع، دون أدنى مسؤولية على سيادتكم.',
                    ),
                    pw.SizedBox(height: 20),
                    _buildText('وتفضلوا بقبول فائق الاحترام والتقدير ،،،'),
                  ],
                ),
              ),

              pw.Spacer(),
              // Footer / Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'المفوض',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 100,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'الختم والتوقيع',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 100,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Company Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Column(
                children: [
                  pw.Text(
                    'مصنع الحفناوى للنسيج الدائرى والتريكو والملابس الجاهزة',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'س.ت: 572-047-460', // Placeholder if not available
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'العنوان: 1 مكرم عبيد مدينة نصر القاهرة', // Placeholder
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                  pw.Text(
                    'Support@annexeg.com', // Placeholder
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildText(
    String text, {
    double fontSize = 12,
    pw.FontWeight? fontWeight,
  }) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: fontSize, fontWeight: fontWeight),
      textDirection: pw.TextDirection.rtl,
    );
  }
}
