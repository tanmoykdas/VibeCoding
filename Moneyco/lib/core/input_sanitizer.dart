class InputSanitizer {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');
  static final RegExp _multiWhitespace = RegExp(r'\s+');

  static String sanitizeText(String value, {required int maxLength}) {
    final cleaned = value
        .replaceAll(_controlChars, ' ')
        .replaceAll('<', '‹')
        .replaceAll('>', '›');

    final normalized = cleaned.trim().replaceAll(_multiWhitespace, ' ');
    final runes = normalized.runes.toList(growable: false);

    if (runes.length <= maxLength) {
      return normalized;
    }

    return String.fromCharCodes(runes.take(maxLength));
  }
}
