import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:annex_sales_order/features/user/data/models/user_model.dart';
import 'package:file_picker/file_picker.dart';

class BusinessCardService {
  Future<void> shareAsImage(GlobalKey globalKey) async {
    try {
      final boundary = globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/business_card.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My Digital Business Card',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }

  Future<void> saveToGallery(GlobalKey globalKey, BuildContext context) async {
    try {
      final boundary = globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final fileName = "business_card_${DateTime.now().millisecondsSinceEpoch}.png";

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop Saving
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ بطاقة العمل',
          fileName: fileName,
          type: FileType.image,
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(pngBytes);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم الحفظ بنجاح: $result'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        return;
      }

      // Mobile Saving
      // Request permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: fileName.replaceAll('.png', ''), // ImageGallerySaver adds extension
      );

      if (context.mounted) {
        if (result['isSuccess'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ البطاقة في المعرض بنجاح')),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء حفظ البطاقة')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
      }
    }
  }

  Future<void> shareAsPdf(UserModel user, {Uint8List? logoBytes}) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                   if (logoBytes != null)
                      pw.Container(
                        height: 100,
                        width: 100,
                        child: pw.Image(pw.MemoryImage(logoBytes)),
                      ),
                  pw.SizedBox(height: 20),
                  pw.Text(user.fullName, style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text("Sales Representative", style: const pw.TextStyle(fontSize: 24)), // Placeholder Job Title
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text("Mobile: ${user.mobileNumber}", style: const pw.TextStyle(fontSize: 18)),
                    ]
                  ),
                  if (user.email != null && user.email!.isNotEmpty)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                       pw.Text("Email: ${user.email}", style: const pw.TextStyle(fontSize: 18)),
                    ]
                  ),
                  pw.SizedBox(height: 30),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'BEGIN:VCARD\nVERSION:3.0\nFN:${user.fullName}\nTEL:${user.mobileNumber}\nEMAIL:${user.email ?? ""}\nEND:VCARD',
                    width: 100,
                    height: 100,
                  ),
                ],
              ),
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/business_card.pdf');
      await file.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My Digital Business Card (PDF)',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  Future<void> shareVCard(UserModel user) async {
    try {
      final vCard = [
        'BEGIN:VCARD',
        'VERSION:3.0',
        'N:;${user.fullName};;;',
        'FN:${user.fullName}',
        'TEL;TYPE=CELL:${user.mobileNumber}',
        if (user.email != null && user.email!.isNotEmpty) 'EMAIL;TYPE=WORK:${user.email}',
        'END:VCARD'
      ].join('\n');

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${user.fullName.replaceAll(' ', '_')}.vcf');
      await file.writeAsString(vCard);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My Contact Info',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing vCard: $e');
    }
  }
}
