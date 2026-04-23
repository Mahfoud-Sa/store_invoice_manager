import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/localization/app_localizations.dart';
import '../data/invoices_repository.dart';
import 'arabic_text.dart';

class InvoicePdfService {
  static Future<Uint8List> build(
    InvoiceDetails details,
    BuildContext context,
  ) async {
    final l10n = context.l10n;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    final fontData = await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
    );
    final ttf = pw.Font.ttf(fontData);

    final doc = pw.Document();
    final inv = details.invoice;
    final dateFmt = DateFormat.yMMMd(localeTag).add_jm();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(inv.createdAtMs);

    String money(int cents) {
      final amount = cents / 100.0;
      return NumberFormat.simpleCurrency(locale: localeTag).format(amount);
    }

    final isArabicLocale = localeTag.toLowerCase().startsWith('ar');

    pw.Widget txt(
      String s, {
      pw.TextStyle? style,
      pw.TextAlign? align,
      bool rtlIfArabic = true,
    }) {
      final shaped = rtlIfArabic ? shapeForPdf(s) : s;
      final isAr = containsArabic(s);
      final base = pw.Text(shaped, style: style, textAlign: align);
      if (!isAr) return base;
      return pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: base,
      );
    }

    pw.Widget header() {
      final logoPath = inv.storeLogoPath;
      final hasLogo = logoPath != null && File(logoPath).existsSync();
      final logo = hasLogo
          ? pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Image(
                pw.MemoryImage(File(logoPath).readAsBytesSync()),
                width: 56,
                height: 56,
                fit: pw.BoxFit.cover,
              ),
            )
          : pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text('S', style: pw.TextStyle(font: ttf)),
              ),
            );

      final leftBlock = pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            txt(
              inv.storeName,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (inv.storeDescription.trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: txt(
                  inv.storeDescription,
                  style: pw.TextStyle(font: ttf, fontSize: 11),
                ),
              ),
          ],
        ),
      );

      final rightBlock = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          txt(
            inv.name,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            dateFmt.format(createdAt),
            style: pw.TextStyle(
              font: ttf,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      );

      final children = [
        logo,
        pw.SizedBox(width: 12),
        leftBlock,
        pw.SizedBox(width: 12),
        rightBlock,
      ];
      final rowChildren = isArabicLocale
          ? children.reversed.toList()
          : children;

      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rowChildren,
      );
    }

    pw.Widget linesTable() {
      final rows = <pw.TableRow>[];

      // Header order: LTR -> Items | Quantity | Total, RTL -> Total | Quantity | Items
      final headerCells = isArabicLocale
          ? [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: txt(
                  l10n.total,
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  align: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: txt(
                  l10n.quantity,
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  align: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: txt(
                  l10n.items,
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ]
          : [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: txt(
                  l10n.items,
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: txt(
                  l10n.quantity,
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  align: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: txt(
                  l10n.total,
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  align: pw.TextAlign.right,
                ),
              ),
            ];

      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headerCells,
        ),
      );

      for (final l in details.lines) {
        final dataCells = isArabicLocale
            ? [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    money(l.lineTotalCents),
                    style: pw.TextStyle(font: ttf, fontSize: 11),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    '${l.quantity}',
                    style: pw.TextStyle(font: ttf, fontSize: 11),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: txt(
                    l.itemName,
                    style: pw.TextStyle(font: ttf, fontSize: 11),
                  ),
                ),
              ]
            : [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: txt(
                    l.itemName,
                    style: pw.TextStyle(font: ttf, fontSize: 11),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    '${l.quantity}',
                    style: pw.TextStyle(font: ttf, fontSize: 11),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    money(l.lineTotalCents),
                    style: pw.TextStyle(font: ttf, fontSize: 11),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ];

        rows.add(pw.TableRow(children: dataCells));
      }

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(5),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(3),
        },
        children: rows,
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          header(),
          pw.SizedBox(height: 16),
          if (inv.description.trim().isNotEmpty) ...[
            txt(
              '${l10n.invoiceDescription}: ${inv.description}',
              style: pw.TextStyle(font: ttf, fontSize: 11),
            ),
            pw.SizedBox(height: 12),
          ],
          linesTable(),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: isArabicLocale
                ? pw.Alignment.centerLeft
                : pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: isArabicLocale
                    ? [
                        pw.Text(
                          money(details.totalCents),
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        txt(
                          l10n.total,
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ]
                    : [
                        txt(
                          l10n.total,
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          money(details.totalCents),
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
