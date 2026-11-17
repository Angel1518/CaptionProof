import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/caption_controller.dart';
import '../services/subtitle_engine.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  Future<void> _importDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    String format = 'srt';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Importar subtítulos'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['srt', 'vtt', 'txt'],
                      withData: true,
                    );
                    if (picked == null || picked.files.isEmpty) return;
                    final f = picked.files.first;
                    final raw = f.bytes != null
                        ? String.fromCharCodes(f.bytes!)
                        : (f.path != null
                            ? await File(f.path!).readAsString()
                            : '');
                    setLocal(() {
                      titleCtrl.text = f.name;
                      textCtrl.text = raw;
                      format =
                          (f.extension ?? 'srt').toLowerCase() == 'vtt'
                              ? 'vtt'
                              : 'srt';
                    });
                  },
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Elegir archivo .srt / .vtt'),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título')),
                const SizedBox(height: 10),
                TextField(
                  controller: textCtrl,
                  maxLines: 6,
                  minLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Contenido SRT/VTT',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Validar')),
          ],
        ),
      ),
    );
    if (ok == true && textCtrl.text.trim().isNotEmpty) {
      final proj =
          await ref.read(captionControllerProvider.notifier).importSubtitles(
                title: titleCtrl.text,
                rawContent: textCtrl.text,
                format: format,
              );
      if (context.mounted) context.push('/projects/${proj.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(captionControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CaptionProof')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importDialog(context, ref),
        icon: const Icon(Icons.subtitles_outlined),
        label: const Text('Importar'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text('Subtítulos revisados, no solo generados',
                    style: theme.textTheme.bodyMedium),
              ),
            ),
            if (data.projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.closed_caption_outlined,
                            size: 52, color: theme.colorScheme.primary),
                        const SizedBox(height: 12),
                        Text('Sin archivos SRT/VTT importados',
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                sliver: SliverList.separated(
                  itemCount: data.projects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final proj = data.projects[i];
                    final cues = data.cues
                        .where((c) => c.projectId == proj.id)
                        .toList();
                    final issues = SubtitleEngine.validate(cues);
                    return TweenAnimationBuilder<double>(
                      duration: AppMotion.duration(
                          context, Duration(milliseconds: 180 + (i.clamp(0, 6) * 35))),
                      curve: AppMotion.curve(context),
                      tween: Tween(begin: 0, end: 1),
                      builder: (ctx, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - t)),
                          child: child,
                        ),
                      ),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            child: Icon(Icons.subtitles_outlined,
                                color: theme.colorScheme.primary),
                          ),
                          title: Text(proj.title,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${cues.length} cues · ${issues.length} incidencias'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/projects/${proj.id}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

