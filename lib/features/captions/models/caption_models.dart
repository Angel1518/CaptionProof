class ProyectoSubtitulo {
  const ProyectoSubtitulo({
    required this.id,
    required this.title,
    required this.format,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String format; // 'srt' | 'vtt'
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'format': format,
        'created_at': createdAt.toIso8601String(),
      };

  factory ProyectoSubtitulo.fromMap(Map<String, dynamic> map) =>
      ProyectoSubtitulo(
        id: map['id'] as String,
        title: map['title'] as String,
        format: map['format'] as String? ?? 'srt',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class Cue {
  const Cue({
    required this.id,
    required this.projectId,
    required this.indexOrder,
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  final String id;
  final String projectId;
  final int indexOrder;
  final int startMs;
  final int endMs;
  final String text;

  Cue copyWith({int? startMs, int? endMs, String? text}) => Cue(
        id: id,
        projectId: projectId,
        indexOrder: indexOrder,
        startMs: startMs ?? this.startMs,
        endMs: endMs ?? this.endMs,
        text: text ?? this.text,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'project_id': projectId,
        'index_order': indexOrder,
        'start_ms': startMs,
        'end_ms': endMs,
        'text': text,
      };

  factory Cue.fromMap(Map<String, dynamic> map) => Cue(
        id: map['id'] as String,
        projectId: map['project_id'] as String,
        indexOrder: map['index_order'] as int,
        startMs: map['start_ms'] as int,
        endMs: map['end_ms'] as int,
        text: map['text'] as String,
      );
}

class Incidencia {
  const Incidencia({
    required this.cueId,
    required this.code,
    required this.message,
  });

  final String cueId;
  final String code;
  final String message;
}

