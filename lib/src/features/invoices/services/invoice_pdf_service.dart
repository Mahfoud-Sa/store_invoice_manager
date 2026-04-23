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
    final isArabicLocale = localeTag.toLowerCase().startsWith('ar');

    final fontData = await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
    );
    final ttf = pw.Font.ttf(fontData);

    final doc = pw.Document();
    final inv = details.invoice;

    final dateFmt = DateFormat.yMMMd(localeTag).add_jm();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(inv.createdAtMs);

    // ✅ FIXED currency
    String money(int cents) {
      final amount = cents / 100.0;

      if (isArabicLocale) {
        return NumberFormat.currency(
          locale: 'ar',
          symbol: 'ر.ي',
          decimalDigits: 0,
        ).format(amount);
      }

      return NumberFormat.simpleCurrency(locale: localeTag).format(amount);
    }

    // ✅ FIXED text builder
    pw.Widget txt(
      String s, {
      pw.TextStyle? style,
      pw.TextAlign? align,
      bool forceLtr = false,
    }) {
      final shaped = shapeForPdf(s);

      final widget = pw.Text(
        shaped,
        style: style,
        textAlign:
            align ?? (isArabicLocale ? pw.TextAlign.right : pw.TextAlign.left),
      );

      return pw.Directionality(
        textDirection: forceLtr
            ? pw.TextDirection.ltr
            : (isArabicLocale ? pw.TextDirection.rtl : pw.TextDirection.ltr),
        child: widget,
      );
    }

    // ================= HEADER =================
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
          txt(
            dateFmt.format(createdAt),
            style: pw.TextStyle(
              font: ttf,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            forceLtr: true,
            align: pw.TextAlign.right,
          ),
        ],
      );

      return pw.Row(
        children: isArabicLocale
            ? [
                rightBlock,
                pw.SizedBox(width: 12),
                leftBlock,
                pw.SizedBox(width: 12),
                logo,
              ]
            : [
                logo,
                pw.SizedBox(width: 12),
                leftBlock,
                pw.SizedBox(width: 12),
                rightBlock,
              ],
      );
    }

    // ================= TABLE =================
    pw.Widget linesTable() {
      final rows = <pw.TableRow>[];

      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: isArabicLocale
              ? [
                  txt(
                    l10n.total,
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  txt(
                    l10n.quantity,
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  txt(
                    l10n.items,
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ]
              : [
                  txt(
                    l10n.items,
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  txt(
                    l10n.quantity,
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  txt(
                    l10n.total,
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
        ),
      );

      for (final l in details.lines) {
        rows.add(
          pw.TableRow(
            children: isArabicLocale
                ? [
                    txt(money(l.lineTotalCents), forceLtr: true),
                    txt('${l.quantity}', forceLtr: true),
                    txt(l.itemName),
                  ]
                : [
                    txt(l.itemName),
                    txt('${l.quantity}', forceLtr: true),
                    txt(money(l.lineTotalCents), forceLtr: true),
                  ],
          ),
        );
      }

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: rows,
      );
    }

    // ================= CONTENT =================
    final pageContent = [
      header(),
      pw.SizedBox(height: 16),

      if (inv.description.trim().isNotEmpty)
        txt(
          '${l10n.invoiceDescription}: ${inv.description}',
          style: pw.TextStyle(font: ttf, fontSize: 11),
        ),

      pw.SizedBox(height: 12),
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
                    txt(money(details.totalCents), forceLtr: true),
                    pw.SizedBox(width: 12),
                    txt(l10n.total),
                  ]
                : [
                    txt(l10n.total),
                    pw.SizedBox(width: 12),
                    txt(money(details.totalCents), forceLtr: true),
                  ],
          ),
        ),
      ),
    ];

    // ================= PAGE =================
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Directionality(
            textDirection: isArabicLocale
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
            child: pw.Column(children: pageContent),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
