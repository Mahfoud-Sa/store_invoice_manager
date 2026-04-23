import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../data/items_repository.dart';

class ItemsPage extends ConsumerStatefulWidget {
  const ItemsPage({super.key});

  @override
  ConsumerState<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends ConsumerState<ItemsPage> {
  String _query = '';

  String _formatMoney(BuildContext context, int cents) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final amount = cents / 100.0;
    final formatted = NumberFormat.currency(
      locale: locale,
      symbol: 'ر.ي',
      decimalDigits: 0,
    ).format(amount);
    final isArabic = locale.startsWith('ar');
    // Show both English and Arabic currency names for Yemeni Rial
    return isArabic ? '$formatted ($amount YER)' : '$formatted';
  }

  Future<void> _openUpsertDialog({Item? item}) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(
      text: item == null ? '' : (item.priceCents / 100).toString(),
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? l10n.addItem : l10n.editItem),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.itemName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return l10n.requiredField;
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: l10n.itemPrice,
                    border: const OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return l10n.requiredField;
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) return l10n.invalidNumber;
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    if (!formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final priceDouble = double.parse(
      priceController.text.trim().replaceAll(',', '.'),
    );
    final cents = (priceDouble * 100).round();

    final repo = ref.read(itemsRepositoryProvider);
    if (item == null) {
      await repo.createItem(name: name, priceCents: cents);
    } else {
      await repo.updateItem(id: item.id, name: name, priceCents: cents);
    }
    ref.invalidate(itemsProvider);
  }

  Future<void> _deleteItem(Item item) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.delete),
          content: Text(item.name),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(itemsRepositoryProvider).deleteItem(item.id);
    ref.invalidate(itemsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.items)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUpsertDialog(),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addItem),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                hintText: 'Search',
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items
                          .where((i) => i.name.toLowerCase().contains(_query))
                          .toList(growable: false);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No items'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(_formatMoney(context, item.priceCents)),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openUpsertDialog(item: item),
                            tooltip: context.l10n.editItem,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteItem(item),
                            tooltip: context.l10n.delete,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
