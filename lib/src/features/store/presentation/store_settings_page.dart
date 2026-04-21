import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../data/store_repository.dart';

class StoreSettingsPage extends ConsumerStatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  ConsumerState<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends ConsumerState<StoreSettingsPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _logoPath;
  bool _didInitFromDb = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String> _copyLogoToAppDir(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final logosDir = Directory(p.join(dir.path, 'logos'));
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    final ext = p.extension(sourcePath);
    final targetPath = p.join(
      logosDir.path,
      'store_logo_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final newPath = await _copyLogoToAppDir(picked.path);
    setState(() => _logoPath = newPath);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(storeRepositoryProvider);
      final store = StoreInfo(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        logoPath: _logoPath,
      );
      await repo.updateStore(store);
      ref.invalidate(storeInfoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saved)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final isArabic = locale.languageCode == 'ar';
    final storeAsync = ref.watch(storeInfoProvider);

    storeAsync.whenData((store) {
      if (_didInitFromDb) return;
      _didInitFromDb = true;
      _nameController.text = store.name;
      _descriptionController.text = store.description;
      _logoPath = store.logoPath;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.storeSettings),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: context.l10n.save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.storeSettings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(context.l10n.language),
                  subtitle: Text(isArabic ? context.l10n.arabic : context.l10n.english),
                  trailing: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'en',
                        label: Text(context.l10n.english),
                      ),
                      ButtonSegment(
                        value: 'ar',
                        label: Text(context.l10n.arabic),
                      ),
                    ],
                    selected: {locale.languageCode},
                    onSelectionChanged: (selection) {
                      final code = selection.first;
                      ref.read(localeControllerProvider.notifier).setLocale(Locale(code));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.storeInfo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: InkWell(
                      onTap: _pickLogo,
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 120,
                          height: 120,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: _logoPath == null
                              ? Icon(
                                  Icons.storefront,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                )
                              : Image.file(
                                  File(_logoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.broken_image_outlined,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(context.l10n.pickImage),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _logoPath == null
                            ? null
                            : () => setState(() => _logoPath = null),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(context.l10n.removeImage),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.storeName,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: context.l10n.storeDescription,
                      border: const OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(context.l10n.save),
                  ),
                  const SizedBox(height: 12),
                  storeAsync.when(
                    data: (_) => const SizedBox.shrink(),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text(
                      e.toString(),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

