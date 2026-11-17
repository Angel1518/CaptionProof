import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/caption_models.dart';

class CaptionRepository {
  CaptionRepository({Database? testDb}) : _db = testDb;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'caption_proof.db'),
      version: 1,
      onCreate: createSchema,
    );
    return _db!;
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE proyectos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        format TEXT NOT NULL DEFAULT 'srt',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cues (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        index_order INTEGER NOT NULL,
        start_ms INTEGER NOT NULL,
        end_ms INTEGER NOT NULL,
        text TEXT NOT NULL
      )
    ''');
  }

  Future<List<ProyectoSubtitulo>> listProjects() async {
    final db = await database;
    final rows = await db.query('proyectos', orderBy: 'created_at DESC');
    return rows.map(ProyectoSubtitulo.fromMap).toList();
  }

  Future<List<Cue>> listCues() async {
    final db = await database;
    final rows = await db.query('cues', orderBy: 'index_order ASC');
    return rows.map(Cue.fromMap).toList();
  }

  Future<void> saveProjectWithCues({
    required ProyectoSubtitulo project,
    required List<Cue> cues,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('proyectos', project.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final c in cues) {
        await txn.insert('cues', c.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> upsertCue(Cue cue) async {
    final db = await database;
    await db.insert('cues', cue.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

