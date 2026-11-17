import '../models/caption_models.dart';

class SubtitleEngine {
  static final RegExp _timeLine = RegExp(
    r'(\d{1,2}:)?(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{1,2}:)?(\d{2}):(\d{2})[,.](\d{3})',
  );

  static int _toMs(String? hRaw, String mRaw, String sRaw, String msRaw) {
    final h = int.tryParse((hRaw ?? '0').replaceAll(':', '')) ?? 0;
    final m = int.tryParse(mRaw) ?? 0;
    final s = int.tryParse(sRaw) ?? 0;
    final ms = int.tryParse(msRaw) ?? 0;
    return ((h * 3600) + (m * 60) + s) * 1000 + ms;
  }

  static String formatMs(int ms, {bool vtt = false}) {
    final safe = ms < 0 ? 0 : ms;
    final h = safe ~/ 3600000;
    final m = (safe % 3600000) ~/ 60000;
    final s = (safe % 60000) ~/ 1000;
    final rem = safe % 1000;
    final sep = vtt ? '.' : ',';
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}$sep'
        '${rem.toString().padLeft(3, '0')}';
  }

  static List<Cue> parse({
    required String projectId,
    required String raw,
  }) {
    final blocks = raw
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n\s*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty && !b.startsWith('WEBVTT'))
        .toList();

    final cues = <Cue>[];
    for (final block in blocks) {
      final lines = block.split('\n');
      int timeIdx = -1;
      RegExpMatch? match;
      for (var i = 0; i < lines.length; i++) {
        final m = _timeLine.firstMatch(lines[i]);
        if (m != null) {
          timeIdx = i;
          match = m;
          break;
        }
      }
      if (match == null || timeIdx < 0) continue;

      final startMs = _toMs(
        match.group(1),
        match.group(2)!,
        match.group(3)!,
        match.group(4)!,
      );
      final endMs = _toMs(
        match.group(5),
        match.group(6)!,
        match.group(7)!,
        match.group(8)!,
      );
      final text = lines.sublist(timeIdx + 1).join('\n').trim();
      final idx = cues.length;
      cues.add(
        Cue(
          id: '${projectId}_cue_$idx',
          projectId: projectId,
          indexOrder: idx,
          startMs: startMs,
          endMs: endMs,
          text: text,
        ),
      );
    }
    return cues;
  }

  static List<Incidencia> validate(List<Cue> cues) {
    final issues = <Incidencia>[];
    for (var i = 0; i < cues.length; i++) {
      final c = cues[i];
      if (c.startMs >= c.endMs) {
        issues.add(Incidencia(
          cueId: c.id,
          code: 'TIME_ORDER',
          message: 'Inicio >= fin en cue ${i + 1}.',
        ));
      }
      if (i + 1 < cues.length && c.endMs > cues[i + 1].startMs) {
        issues.add(Incidencia(
          cueId: c.id,
          code: 'OVERLAP',
          message: 'Solapamiento con el siguiente subtítulo.',
        ));
      }
      final durationSec = (c.endMs - c.startMs) / 1000.0;
      final chars = c.text.replaceAll('\n', '').length;
      if (durationSec > 0 && (chars / durationSec) > 20.0) {
        issues.add(Incidencia(
          cueId: c.id,
          code: 'HIGH_CPS',
          message:
              'Lectura rápida (${(chars / durationSec).toStringAsFixed(1)} car/s > 20).',
        ));
      }
      final lines = c.text.split('\n');
      if (lines.length > 2) {
        issues.add(Incidencia(
          cueId: c.id,
          code: 'TOO_MANY_LINES',
          message: 'Más de 2 líneas (${lines.length}).',
        ));
      }
      if (lines.any((l) => l.length > 42)) {
        issues.add(Incidencia(
          cueId: c.id,
          code: 'LINE_TOO_LONG',
          message: 'Línea superior a 42 caracteres.',
        ));
      }
    }
    return issues;
  }

  static String exportSrt(List<Cue> cues) {
    final buf = StringBuffer();
    for (var i = 0; i < cues.length; i++) {
      final c = cues[i];
      buf
        ..writeln('${i + 1}')
        ..writeln('${formatMs(c.startMs)} --> ${formatMs(c.endMs)}')
        ..writeln(c.text)
        ..writeln();
    }
    return buf.toString();
  }

  static String exportVtt(List<Cue> cues) {
    final buf = StringBuffer()..writeln('WEBVTT\n');
    for (final c in cues) {
      buf
        ..writeln(
            '${formatMs(c.startMs, vtt: true)} --> ${formatMs(c.endMs, vtt: true)}')
        ..writeln(c.text)
        ..writeln();
    }
    return buf.toString();
  }
}

