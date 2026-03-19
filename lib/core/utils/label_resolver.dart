/// Resolves a label from a multi-language map using the fallback chain:
/// firmware_lang → "en" → first_available → fallbackId.
///
/// Returns a [ResolvedLabel] containing the resolved text and whether
/// a fallback was used.
class ResolvedLabel {
  final String text;
  final bool isFallback;

  const ResolvedLabel(this.text, {this.isFallback = false});
}

ResolvedLabel resolveLabel(
  Map<String, String> labels,
  String lang, {
  required String fallbackId,
}) {
  // 1. Requested language
  final primary = labels[lang];
  if (primary != null) return ResolvedLabel(primary);

  // 2. English fallback
  final en = labels['en'];
  if (en != null) return ResolvedLabel(en, isFallback: true);

  // 3. First available language
  if (labels.isNotEmpty) {
    return ResolvedLabel(labels.values.first, isFallback: true);
  }

  // 4. ID as last resort
  return ResolvedLabel(fallbackId, isFallback: true);
}
