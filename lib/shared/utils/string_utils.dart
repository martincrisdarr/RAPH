class StringUtils {
  /// Formatea una dirección al formato Title Case (ej: "pERU 140" -> "Peru 140")
  /// respetando caracteres multibyte en español, acentos, números y puntuaciones.
  /// No modifica URLs o enlaces de mapas (ej. http:// o https://).
  static String? formatearDireccion(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // Normalizar espacios múltiples
    final normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    final lower = normalized.toLowerCase();
    return lower.replaceAllMapped(
      RegExp(r'(?:^|[^\p{L}\p{N}])\p{L}', unicode: true),
      (m) => m.group(0)!.toUpperCase(),
    );
  }
}
