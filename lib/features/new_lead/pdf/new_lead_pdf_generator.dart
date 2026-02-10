import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/new_lead.dart';

class NewLeadPdfGenerator {
  static Future<pw.Document> generate(NewLead lead) async {
    final pdf = pw.Document();

    // Load fonts
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

    // Load logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }

    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold);
    const primaryColor = PdfColor.fromInt(0xFF1565C0);
    const boxColor = PdfColor.fromInt(0xFFD1E9F6);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Header with Logo and Title
                  _buildHeader(logoImage),
                  pw.SizedBox(height: 10),

                  // Account Manager Section
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1565C0),
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'مدير الحساب',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Expanded(
                          child: pw.Center(
                            child: pw.Text(
                              lead.accountManager,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                        ),
                        pw.Text(
                          'ACCOUNT MANAGER',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          textDirection: pw.TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Customer General Info Section
                  _buildSectionHeader(
                    'CUSTOMER GENERAL INFO',
                    'معلومات العميل العامة',
                  ),
                  _buildInfoTable(lead, boxColor),
                  pw.SizedBox(height: 10),

                  // Customer's Products Section
                  _buildSectionHeader("CUSTOMER'S PRODUCTS", 'منتجات العميل'),
                  _buildProductsTable(lead, boxColor, primaryColor),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(pw.MemoryImage? logoImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Spacer to balance the logo and center the title
          pw.SizedBox(width: 60),
          pw.Text(
            'NEW LEAD',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1565C0),
            ),
          ),
          if (logoImage != null)
            pw.Container(height: 60, width: 60, child: pw.Image(logoImage))
          else
            pw.SizedBox(width: 60),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String titleEn, String titleAr) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1565C0),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            titleAr,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            titleEn,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textDirection: pw.TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoTable(NewLead lead, PdfColor boxColor) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1.5),
        },
        children: [
          _buildTableRow(
            'ACCOUNT NAME / اسم الحساب',
            lead.accountName,
            boxColor,
          ),
          _buildTableRow(
            'MAIN CONTACT NAME / جهة الاتصال',
            lead.mainContactName,
            boxColor,
          ),
          _buildTableRow('CITY / المدينة', lead.city, boxColor),
          _buildTableRow('ZONE / المنطقة', lead.zone, boxColor),
          _buildTableRowWithRating('SIZE / الحجم', lead.size, boxColor),
          _buildTableRowWithRating(
            'CREDIT SCORE / تقييم الائتمان',
            lead.creditScoreAssessment,
            boxColor,
          ),
          _buildTableRow(
            'CUSTOMER TYPE / نوع العميل',
            lead.customerType != null
                ? '${lead.customerType!.label} / ${lead.customerType!.labelArabic}'
                : '-',
            boxColor,
          ),
          _buildTableRow('PHONE NO / رقم الهاتف', lead.phoneNo, boxColor),
          _buildTableRow(
            'ADDRESS / العنوان',
            lead.addressGpsLocation,
            boxColor,
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(
    String label,
    String value,
    PdfColor boxColor,
  ) {
    // Split label into English and Arabic parts
    final parts = label.split(' / ');
    final englishLabel = parts.isNotEmpty ? parts[0] : label;
    final arabicLabel = parts.length > 1 ? parts[1] : '';

    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: pw.Alignment.center, // Center Value
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 9),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: boxColor,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center, // Center Labels
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                arabicLabel,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                englishLabel,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.ltr,
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildTableRowWithRating(
    String label,
    Rating? rating,
    PdfColor boxColor,
  ) {
    // Split label into English and Arabic parts
    final parts = label.split(' / ');
    final englishLabel = parts.isNotEmpty ? parts[0] : label;
    final arabicLabel = parts.length > 1 ? parts[1] : '';

    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          alignment: pw.Alignment.center, // Center Rating
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center, // Center Rating Row
            children: [
              _buildRatingBox('A', rating == Rating.a),
              pw.SizedBox(width: 8),
              _buildRatingBox('B', rating == Rating.b),
              pw.SizedBox(width: 8),
              _buildRatingBox('C', rating == Rating.c),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: boxColor,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center, // Center Labels
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                arabicLabel,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                englishLabel,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.ltr,
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildRatingBox(String label, bool isSelected) {
    return pw.Container(
      width: 18,
      height: 18,
      decoration: pw.BoxDecoration(
        color: isSelected
            ? const PdfColor.fromInt(0xFF1565C0)
            : PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey600, width: 1),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Center(
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: isSelected ? PdfColors.white : PdfColors.black,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildProductsTable(
    NewLead lead,
    PdfColor boxColor,
    PdfColor primaryColor,
  ) {
    final products = lead.products;

    // Filter to only selected products
    final selectedProducts = products.entries
        .where((e) => e.value.selected)
        .toList();

    // If no products selected, show a message
    if (selectedProducts.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        ),
        child: pw.Center(
          child: pw.Text(
            'No products selected / لم يتم اختيار منتجات',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      );
    }

    // Build product rows for selected products only
    final List<pw.TableRow> productRows = [];
    for (int index = 0; index < selectedProducts.length; index++) {
      final productName = selectedProducts[index].key;
      final selection = selectedProducts[index].value;
      final arabicName = NewLead.productNamesArabic[productName] ?? '';
      final isEven = index % 2 == 0;

      productRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? boxColor : PdfColors.white,
          ),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  _buildRatingBox('A', selection.priority == Rating.a),
                  pw.SizedBox(width: 4),
                  _buildRatingBox('B', selection.priority == Rating.b),
                  pw.SizedBox(width: 4),
                  _buildRatingBox('C', selection.priority == Rating.c),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center, // Center Product Names
                children: [
                  pw.Text(
                    arabicName,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    productName,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                    textDirection: pw.TextDirection.ltr,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Header row
    final headerRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: primaryColor),
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'PRIORITY / الأولوية',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'PRODUCT / المنتج',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center, // Center Header
          ),
        ),
      ],
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.5), // Priority
          1: const pw.FlexColumnWidth(2), // Product Name
        },
        children: [headerRow, ...productRows],
      ),
    );
  }
}
