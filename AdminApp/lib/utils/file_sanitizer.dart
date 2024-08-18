
String sanitizeFilename(String filename) {
  RegExp illegalCharacters = RegExp(r'[/\\?%*:|"<>]');
  String sanitized = filename.replaceAll(illegalCharacters, '');
  return sanitized;
}
