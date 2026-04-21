import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../data/invoices_repository.dart';
import '../services/invoice_pdf_service.dart';

class InvoiceDetailsPage extends ConsumerWidget {
  const InvoiceDetailsPage({super.key, required this.invoiceId});

  final int invoiceId;

  String _formatMoney(BuildContext context, int cents) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final amount = cents / 100.0;
    return NumberFormat.simpleCurrency(locale: locale).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(invoiceDetailsProvider(invoiceId));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMd(locale).add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.invoices),
        actions: [
          IconButton(
            onPressed: () async {
              final details = detailsAsync.valueOrNull;
              if (details == null) return;
              final bytes = await InvoicePdfService.build(details, context);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
            icon: const Icon(Icons.print_outlined),
            tooltip: context.l10n.printPdf,
          ),
          IconButton(
            onPressed: () async {
              final details = detailsAsync.valueOrNull;
              if (details == null) return;
              final bytes = await InvoicePdfService.build(details, context);
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'invoice_${details.invoice.id}.pdf',
              );
            },
            icon: const Icon(Icons.share_outlined),
            tooltip: context.l10n.sharePdf,
          ),
        ],
      ),
      body: detailsAsync.when(
        data: (details) {
          final inv = details.invoice;
          final createdAt = DateTime.fromMillisecondsSinceEpoch(inv.createdAtMs);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: inv.storeLogoPath == null
                              ? Icon(
                                  Icons.storefront,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                )
                              : Image.file(
                                  File(inv.storeLogoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.broken_image_outlined,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.storeName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (inv.storeDescription.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(inv.storeDescription),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(inv.name),
                  subtitle: Text(dateFmt.format(createdAt)),
                ),
              ),
              if (inv.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(inv.description),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.l10n.items,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...details.lines.map((l) {
                return Card(
                  child: ListTile(
                    title: Text(l.itemName),
                    subtitle: Text('${context.l10n.quantity}: ${l.quantity}'),
                    trailing: Text(_formatMoney(context, l.lineTotalCents)),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(context.l10n.total),
                  trailing: Text(
                    _formatMoney(context, details.totalCents),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

