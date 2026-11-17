import 'package:caption_proof/core/theme/app_theme.dart';
import 'package:caption_proof/features/captions/controllers/caption_controller.dart';
import 'package:caption_proof/features/captions/data/caption_repository.dart';
import 'package:caption_proof/features/captions/models/caption_models.dart';
import 'package:caption_proof/features/captions/services/subtitle_engine.dart';
import 'package:caption_proof/features/captions/ui/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  test('SubtitleEngine parses SRT, detects overlap/CPS/length, and exports VTT', () {
    const sampleSrt = '''
1
00:00:01,000 --> 00:00:03,000
Hola mundo

2
00:00:02,500 --> 00:00:03,000
Esta es una línea extremadamente larga que supera los cuarenta y dos caracteres claramente
''';
    final cues = SubtitleEngine.parse(projectId: 'p1', raw: sampleSrt);
    expect(cues.length, 2);

    final issues = SubtitleEngine.validate(cues);
    expect(issues.map((i) => i.code), contains('OVERLAP'));
    expect(issues.map((i) => i.code), contains('HIGH_CPS'));
    expect(issues.map((i) => i.code), contains('LINE_TOO_LONG'));

    final vtt = SubtitleEngine.exportVtt(cues);
    expect(vtt, startsWith('WEBVTT'));
    expect(vtt, contains('00:00:01.000 --> 00:00:03.000'));
  });

  testWidgets('ProjectsScreen renders without overflow at 320px and 200% TextScaler', (tester) async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: CaptionRepository.createSchema,
    );
    final repo = CaptionRepository(testDb: db);
    await repo.saveProjectWithCues(
      project: ProyectoSubtitulo(
        id: 's_long',
        title: 'Sub_${'C' * 100}',
        format: 'srt',
        createdAt: DateTime(2026, 11, 17),
      ),
      cues: const [],
    );

    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [captionRepositoryProvider.overrideWithValue(repo)],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: AppTheme.light(accent: const Color(0xFF4338CA)),
            home: const ProjectsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
    await db.close();
  });
}

