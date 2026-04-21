import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;

bool containsArabic(String text) {
  for (final rune in text.runes) {
    if (rune >= 0x0600 && rune <= 0x06FF) return true; // Arabic
    if (rune >= 0x0750 && rune <= 0x077F) return true; // Arabic Supplement
    if (rune >= 0x08A0 && rune <= 0x08FF) return true; // Arabic Extended-A
    if (rune >= 0xFB50 && rune <= 0xFDFF) return true; // Arabic Presentation Forms-A
    if (rune >= 0xFE70 && rune <= 0xFEFF) return true; // Arabic Presentation Forms-B
  }
  return false;
}

String shapeForPdf(String text) {
  if (!containsArabic(text)) return text;
  final reshaped = ArabicReshaper().reshape(text);
  // Ensure RTL visual order when mixed with numbers/latin.
  return String.fromCharCodes(bidi.logicalToVisual(reshaped));
}

