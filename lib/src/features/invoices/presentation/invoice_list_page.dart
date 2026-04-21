import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../data/invoices_repository.dart';
import 'invoice_details_page.dart';
import 'invoice_editor_page.dart';

class InvoiceListPage extends ConsumerWidget {
  const InvoiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMd(locale).add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.invoices),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InvoiceEditorPage()),
          );
          ref.invalidate(invoicesProvider);
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addInvoice),
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(child: Text(context.l10n.noInvoices));
          }
          return ListView.separated(
            itemCount: invoices.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final inv = invoices[index];
              final createdAt = DateTime.fromMillisecondsSinceEpoch(inv.createdAtMs);
              return ListTile(
                title: Text(inv.name),
                subtitle: Text(dateFmt.format(createdAt)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailsPage(invoiceId: inv.id),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

