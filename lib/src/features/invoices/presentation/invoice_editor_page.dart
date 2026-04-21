import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../items/data/items_repository.dart';
import '../data/invoices_repository.dart';
import 'invoice_details_page.dart';

class InvoiceEditorPage extends ConsumerStatefulWidget {
  const InvoiceEditorPage({super.key});

  @override
  ConsumerState<InvoiceEditorPage> createState() => _InvoiceEditorPageState();
}

class _InvoiceEditorPageState extends ConsumerState<InvoiceEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _query = '';
  final Map<int, int> _qtyByItemId = {}; // itemId -> quantity
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatMoney(BuildContext context, int cents) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final amount = cents / 100.0;
    return NumberFormat.simpleCurrency(locale: locale).format(amount);
  }

  int _totalCents(List<Item> items) {
    var total = 0;
    for (final item in items) {
      final q = _qtyByItemId[item.id] ?? 0;
      total += q * item.priceCents;
    }
    return total;
  }

  Future<void> _save(List<Item> items) async {
    if (!_formKey.currentState!.validate()) return;

    final selected = <NewInvoiceLine>[];
    for (final item in items) {
      final q = _qtyByItemId[item.id] ?? 0;
      if (q <= 0) continue;
      selected.add(
        NewInvoiceLine(
          itemId: item.id,
          itemName: item.name,
          quantity: q,
          priceCents: item.priceCents,
        ),
      );
    }

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addItems)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(invoicesRepositoryProvider);
      final invoiceId = await repo.createInvoice(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        lines: selected,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InvoiceDetailsPage(invoiceId: invoiceId),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setQty(int itemId, int qty) {
    final next = qty < 0 ? 0 : qty;
    setState(() {
      if (next == 0) {
        _qtyByItemId.remove(itemId);
      } else {
        _qtyByItemId[itemId] = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addInvoice),
        actions: [
          IconButton(
            onPressed: _saving
                ? null
                : () async {
                    final items = itemsAsync.valueOrNull ?? const <Item>[];
                    await _save(items);
                  },
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: l10n.save,
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          final filtered = _query.isEmpty
              ? items
              : items
                  .where(
                    (i) => i.name.toLowerCase().contains(_query.toLowerCase()),
                  )
                  .toList(growable: false);

          final total = _totalCents(items);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.invoiceName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.requiredField;
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.invoiceDescription,
                        border: const OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  hintText: 'Search',
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.addItems,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No items')),
                )
              else
                ...filtered.map((item) {
                  final qty = _qtyByItemId[item.id] ?? 0;
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(_formatMoney(context, item.priceCents)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _setQty(item.id, qty - 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '$qty',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _setQty(item.id, qty + 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(l10n.total),
                  trailing: Text(
                    _formatMoney(context, total),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(items),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(l10n.save),
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

