import 'dart:convert';

/// Builds a tiny Illustrator-style SVG icon from branch app metadata.
/// Output is typically under ~1KB — ideal for Firestore data-URL storage.
class BranchIconGenerator {
  BranchIconGenerator._();

  static String toDataUrl({
    required String name,
    required String description,
  }) {
    final svg = buildSvg(name: name, description: description);
    final b64 = base64Encode(utf8.encode(svg));
    return 'data:image/svg+xml;base64,$b64';
  }

  static String buildSvg({
    required String name,
    required String description,
  }) {
    final seed = _hash('${name.trim()}|${description.trim()}');
    final letter = _escapeXml(_monogram(name));
    final palette = _palette(seed);
    final motif = seed % 4;

    final accentShape = switch (motif) {
      0 => // orbit ring
        '<circle cx="96" cy="32" r="14" fill="none" stroke="${palette.accent}" stroke-width="3"/>'
            '<circle cx="96" cy="32" r="4" fill="${palette.accent}"/>',
      1 => // chevron
        '<path d="M78 88 L96 70 L114 88" fill="none" stroke="${palette.accent}" stroke-width="4" stroke-linecap="square"/>'
            '<path d="M78 102 L96 84 L114 102" fill="none" stroke="${palette.accent}" stroke-width="3" stroke-linecap="square" opacity="0.55"/>',
      2 => // node graph
        '<circle cx="86" cy="86" r="5" fill="${palette.accent}"/>'
            '<circle cx="108" cy="74" r="4" fill="${palette.accent}" opacity="0.8"/>'
            '<circle cx="104" cy="100" r="3.5" fill="${palette.accent}" opacity="0.65"/>'
            '<path d="M86 86 L108 74 L104 100 Z" fill="none" stroke="${palette.accent}" stroke-width="2" opacity="0.7"/>',
      _ => // bars
        '<rect x="82" y="78" width="8" height="28" rx="2" fill="${palette.accent}" opacity="0.55"/>'
            '<rect x="94" y="66" width="8" height="40" rx="2" fill="${palette.accent}"/>'
            '<rect x="106" y="86" width="8" height="20" rx="2" fill="${palette.accent}" opacity="0.75"/>',
    };

    return '''
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128" fill="none">
  <rect x="10" y="12" width="104" height="104" rx="22" fill="${palette.offset}"/>
  <rect x="6" y="6" width="104" height="104" rx="22" fill="${palette.plate}" stroke="${palette.stroke}" stroke-width="3"/>
  <rect x="18" y="18" width="80" height="80" rx="16" stroke="${palette.inner}" stroke-width="2" opacity="0.55"/>
  <text x="34" y="78" font-family="Segoe UI, Helvetica, Arial, sans-serif" font-size="48" font-weight="800" fill="${palette.letter}">$letter</text>
  $accentShape
</svg>'''.trim().replaceAll(RegExp(r'\n\s*'), '');
  }

  static String _monogram(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${_firstGrapheme(parts[0]).toUpperCase()}'
          '${_firstGrapheme(parts[1]).toUpperCase()}';
    }
    final first = _firstGrapheme(cleaned);
    if (_isAsciiLetter(first) && cleaned.runes.length >= 2) {
      final second = String.fromCharCode(cleaned.runes.elementAt(1));
      if (_isAsciiLetter(second)) {
        return '${first.toUpperCase()}${second.toUpperCase()}';
      }
    }
    return first.toUpperCase();
  }

  static String _firstGrapheme(String value) {
    if (value.isEmpty) return '?';
    return String.fromCharCode(value.runes.first);
  }

  static bool _isAsciiLetter(String s) {
    if (s.isEmpty) return false;
    final c = s.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static int _hash(String input) {
    var h = 2166136261;
    for (final unit in utf8.encode(input)) {
      h ^= unit;
      h = (h * 16777619) & 0x7fffffff;
    }
    return h;
  }

  static _Palette _palette(int seed) {
    const plates = [
      '#0E1624',
      '#122033',
      '#0B1A22',
      '#161B2E',
      '#101820',
    ];
    const accents = [
      '#1CE8B5',
      '#5AB4FF',
      '#7EE0C8',
      '#4CC9F0',
      '#9BE7C4',
    ];
    const letters = [
      '#F2F6FC',
      '#E8EEF8',
      '#DCE7F5',
    ];
    final plate = plates[seed % plates.length];
    final accent = accents[(seed ~/ 7) % accents.length];
    final letter = letters[(seed ~/ 13) % letters.length];
    return _Palette(
      plate: plate,
      offset: _mixHex(accent, 0.22),
      stroke: accent,
      inner: accents[(seed ~/ 3) % accents.length],
      accent: accent,
      letter: letter,
    );
  }

  static String _mixHex(String hex, double alpha) {
    final c = hex.replaceFirst('#', '');
    final r = int.parse(c.substring(0, 2), radix: 16);
    final g = int.parse(c.substring(2, 4), radix: 16);
    final b = int.parse(c.substring(4, 6), radix: 16);
    final rr = (r * alpha + 10 * (1 - alpha)).round().clamp(0, 255);
    final gg = (g * alpha + 16 * (1 - alpha)).round().clamp(0, 255);
    final bb = (b * alpha + 28 * (1 - alpha)).round().clamp(0, 255);
    return '#${rr.toRadixString(16).padLeft(2, '0')}'
        '${gg.toRadixString(16).padLeft(2, '0')}'
        '${bb.toRadixString(16).padLeft(2, '0')}';
  }
}

class _Palette {
  const _Palette({
    required this.plate,
    required this.offset,
    required this.stroke,
    required this.inner,
    required this.accent,
    required this.letter,
  });

  final String plate;
  final String offset;
  final String stroke;
  final String inner;
  final String accent;
  final String letter;
}
