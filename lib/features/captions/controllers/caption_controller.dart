import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/caption_repository.dart';
import '../models/caption_models.dart';
import '../services/subtitle_engine.dart';

final captionRepositoryProvider = Provider<CaptionRepository>(
  (ref) => CaptionRepository(),
);

class CaptionState {
  const CaptionState({this.projects = const [], this.cues = const []});
  final List<ProyectoSubtitulo> projects;
  final List<Cue> cues;
}

class CaptionController extends AsyncNotifier<CaptionState> {
  @override
  Future<CaptionState> build() async => _loadAll();

  CaptionRepository get _repo => ref.read(captionRepositoryProvider);

  Future<CaptionState> _loadAll() async => CaptionState(
        projects: await _repo.listProjects(),
        cues: await _repo.listCues(),
      );

  Future<ProyectoSubtitulo> importSubtitles({
    required String title,
    required String rawContent,
    String format = 'srt',
  }) async {
    final now = DateTime.now();
    final id = 'sub_${now.microsecondsSinceEpoch}';
    final project = ProyectoSubtitulo(
      id: id,
      title: title.trim().isEmpty ? 'Subtítulos' : title.trim(),
      format: format,
      createdAt: now,
    );
    final cues = SubtitleEngine.parse(projectId: id, raw: rawContent);
    await _repo.saveProjectWithCues(project: project, cues: cues);
    state = AsyncData(await _loadAll());
    return project;
  }

  Future<void> updateCue(Cue cue) async {
    await _repo.upsertCue(cue);
    state = AsyncData(await _loadAll());
  }
}

final captionControllerProvider =
    AsyncNotifierProvider<CaptionController, CaptionState>(
  CaptionController.new,
);

