import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(instance != null, 'AppLocalizations not found in context');
    return instance!;
  }

  String get appTitle => _t('appTitle');
  String get invoices => _t('invoices');
  String get items => _t('items');
  String get store => _t('store');
  String get storeSettings => _t('storeSettings');
  String get storeInfo => _t('storeInfo');
  String get storeName => _t('storeName');
  String get storeDescription => _t('storeDescription');
  String get storeLogo => _t('storeLogo');
  String get storeAddress => _t('storeAddress');
  String get phoneNumbers => _t('phoneNumbers');
  String get addPhone => _t('addPhone');
  String get editPhone => _t('editPhone');
  String get phoneNumber => _t('phoneNumber');
  String get noPhones => _t('noPhones');
  String get pickImage => _t('pickImage');
  String get removeImage => _t('removeImage');
  String get save => _t('save');
  String get saved => _t('saved');
  String get addItem => _t('addItem');
  String get editItem => _t('editItem');
  String get itemName => _t('itemName');
  String get itemPrice => _t('itemPrice');
  String get delete => _t('delete');
  String get cancel => _t('cancel');
  String get requiredField => _t('requiredField');
  String get invalidNumber => _t('invalidNumber');
  String get language => _t('language');
  String get english => _t('english');
  String get arabic => _t('arabic');

  String get invoiceListPlaceholder => _t('invoiceListPlaceholder');
  String get itemsPlaceholder => _t('itemsPlaceholder');
  String get storeSettingsPlaceholder => _t('storeSettingsPlaceholder');
  String get addInvoice => _t('addInvoice');
  String get noInvoices => _t('noInvoices');
  String get invoiceName => _t('invoiceName');
  String get invoiceDescription => _t('invoiceDescription');
  String get addItems => _t('addItems');
  String get quantity => _t('quantity');
  String get total => _t('total');
  String get printPdf => _t('printPdf');
  String get sharePdf => _t('sharePdf');

  String _t(String key) {
    final lang = locale.languageCode.toLowerCase();
    final map = (lang == 'ar') ? _ar : _en;
    return map[key] ?? _en[key] ?? key;
  }

  static const Map<String, String> _en = {
    'appTitle': 'Store & Invoice Manager',
    'invoices': 'Invoices',
    'items': 'Items',
    'store': 'Store',
    'storeSettings': 'Store Settings',
    'storeInfo': 'Store info',
    'storeName': 'Store name',
    'storeDescription': 'Description',
    'storeLogo': 'Logo',
    'storeAddress': 'Address',
    'phoneNumbers': 'Phone numbers',
    'addPhone': 'Add phone',
    'editPhone': 'Edit phone',
    'phoneNumber': 'Phone number',
    'noPhones': 'No phone numbers yet',
    'pickImage': 'Pick image',
    'removeImage': 'Remove image',
    'save': 'Save',
    'saved': 'Saved',
    'addItem': 'Add item',
    'editItem': 'Edit item',
    'itemName': 'Item name',
    'itemPrice': 'Price',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'requiredField': 'Required',
    'invalidNumber': 'Invalid number',
    'language': 'Language',
    'english': 'English',
    'arabic': 'Arabic',
    'invoiceListPlaceholder': 'Invoice list UI will be implemented next.',
    'itemsPlaceholder': 'Items CRUD UI will be implemented next.',
    'storeSettingsPlaceholder': 'Store settings form will be implemented next.',
    'addInvoice': 'New invoice',
    'noInvoices': 'No invoices yet',
    'invoiceName': 'Invoice name',
    'invoiceDescription': 'Invoice description',
    'addItems': 'Add items',
    'quantity': 'Quantity',
    'total': 'Total',
    'printPdf': 'Print PDF',
    'sharePdf': 'Share PDF',
  };

  static const Map<String, String> _ar = {
    'appTitle': 'إدارة المتجر والفواتير',
    'invoices': 'الفواتير',
    'items': 'المنتجات',
    'store': 'المتجر',
    'storeSettings': 'إعدادات المتجر',
    'storeInfo': 'بيانات المتجر',
    'storeName': 'اسم المتجر',
    'storeDescription': 'الوصف',
    'storeLogo': 'الشعار',
    'storeAddress': 'العنوان',
    'phoneNumbers': 'أرقام الهاتف',
    'addPhone': 'إضافة رقم',
    'editPhone': 'تعديل الرقم',
    'phoneNumber': 'رقم الهاتف',
    'noPhones': 'لا توجد أرقام هاتف بعد',
    'pickImage': 'اختيار صورة',
    'removeImage': 'إزالة الصورة',
    'save': 'حفظ',
    'saved': 'تم الحفظ',
    'addItem': 'إضافة منتج',
    'editItem': 'تعديل المنتج',
    'itemName': 'اسم المنتج',
    'itemPrice': 'السعر',
    'delete': 'حذف',
    'cancel': 'إلغاء',
    'requiredField': 'مطلوب',
    'invalidNumber': 'رقم غير صالح',
    'language': 'اللغة',
    'english': 'الإنجليزية',
    'arabic': 'العربية',
    'invoiceListPlaceholder': 'سيتم تنفيذ واجهة قائمة الفواتير لاحقًا.',
    'itemsPlaceholder': 'سيتم تنفيذ واجهة إدارة المنتجات لاحقًا.',
    'storeSettingsPlaceholder': 'سيتم تنفيذ نموذج إعدادات المتجر لاحقًا.',
    'addInvoice': 'فاتورة جديدة',
    'noInvoices': 'لا توجد فواتير بعد',
    'invoiceName': 'اسم الفاتورة',
    'invoiceDescription': 'وصف الفاتورة',
    'addItems': 'إضافة منتجات',
    'quantity': 'الكمية',
    'total': 'الإجمالي',
    'printPdf': 'طباعة PDF',
    'sharePdf': 'مشاركة PDF',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

