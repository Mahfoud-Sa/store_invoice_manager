import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;

bool containsArabic(String text) {
  for (final rune in text.runes) {
    if (rune >= 0x0600 && rune <= 0x06FF) return true; // Arabic
    if (rune >= 0x0750 && rune <= 0x077F) return true; // Arabic Supplement
    if (rune >= 0x08A0 && rune <= 0x08FF) return true; // Arabic Extended-A
    if (rune >= 0xFB50 && rune <= 0xFDFF)
      return true; // Arabic Presentation Forms-A
    if (rune >= 0xFE70 && rune <= 0xFEFF)
      return true; // Arabic Presentation Forms-B
  }
  return false;
}

String shapeForPdf(String text) {
  if (!containsArabic(text)) return text;
  // Reshape Arabic glyphs for proper presentation forms. Do NOT force a
  // logical->visual reorder here; the PDF rendering should use
  // `Directionality(textDirection: rtl)` so bidi reordering is applied
  // at layout time instead of reversing the string, which can cause
  // words to appear in reverse order.
  final reshaped = ArabicReshaper().reshape(text);
  return reshaped;
}
