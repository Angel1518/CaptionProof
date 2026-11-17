import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/caption_controller.dart';
import '../models/caption_models.dart';
import '../services/subtitle_engine.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String projectId;

  Future<void> _editCueDialog(
    BuildContext context,
    WidgetRef ref,
    Cue cue,
  ) async {
    final textCtrl = TextEditingController(text: cue.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar cue ${cue.indexOrder + 1}'),
        content: TextField(
          controller: textCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Texto del subtítulo'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(captionControllerProvider.notifier)
          .updateCue(cue.copyWith(text: textCtrl.text.trim()));
    }
  }

  Future<void> _exportSubtitles(
    BuildContext context,
    ProyectoSubtitulo proj,
    List<Cue> cues,
    bool asVtt,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final content = asVtt
          ? SubtitleEngine.exportVtt(cues)
          : SubtitleEngine.exportSrt(cues);
      final file = File(p.join(
        dir.path,
        '${proj.id}.${asVtt ? 'vtt' : 'srt'}',
      ));
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], subject: proj.title);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(captionControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Revisión de subtítulos')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final proj =
              data.projects.where((p) => p.id == projectId).firstOrNull;
          if (proj == null) {
            return const Center(child: Text('Proyecto no encontrado.'));
          }
          final cues =
              data.cues.where((c) => c.projectId == proj.id).toList();
          final issues = SubtitleEngine.validate(cues);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(proj.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text('${cues.length} cues · ${issues.length} incidencias detectadas',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        _exportSubtitles(context, proj, cues, false),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Exportar .srt'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _exportSubtitles(context, proj, cues, true),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Exportar .vtt'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...cues.map((c) {
                final cueIssues =
                    issues.where((i) => i.cueId == c.id).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        '${SubtitleEngine.formatMs(c.startMs)} → ${SubtitleEngine.formatMs(c.endMs)}',
                        style: theme.textTheme.labelLarge,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(c.text, style: theme.textTheme.bodyLarge),
                          if (cueIssues.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: cueIssues
                                  .map((iss) => Chip(
                                        label: Text(iss.message),
                                        backgroundColor: theme
                                            .colorScheme.errorContainer
                                            .withValues(alpha: 0.6),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _editCueDialog(context, ref, c),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

