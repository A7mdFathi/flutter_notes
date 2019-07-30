import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note_model.dart';

class NoteDatabase {
  String path;
  NoteDatabase._();

  static final NoteDatabase db = NoteDatabase._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    //if database is null first time create
    _database = await init();
    return _database;
  }

  init() async {
    String path = await getDatabasesPath();
    path = join(path, 'notes.db');
    print('Entered path $path');

    return await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute("""
      CREATE TABLE Notes(_id INTEGER PRIMARY KEY,
      title TEXT,
      content TEXT,
      date TEXT,
      isImportant INTEGER);
      """);
      print('new Table created at $path');
    });
  }

  Future<List<NoteModel>> getNotesFromDB() async {
    final db = await database;
    List<NoteModel> noteList = [];
    List<Map> maps = await db.query(
      'Notes',
      columns: ['_id', 'title', 'content', 'date', 'isImportant'],
    );

    if (maps.length > 0) {
      maps.forEach((map) {
        noteList.add(NoteModel.fromMap(map));
      });
    }

    return noteList;
  }

  updateNoteInDB(NoteModel updateNote) async {
    final db = await database;
    await db.update('Notes', updateNote.toMap(),
        where: '_id = ?', whereArgs: [updateNote.id]);
    print('Note Updated: ${updateNote.title}');
  }

  deleteNoteInDB(NoteModel deletedNote) async {
    final db = await database;
    await db.delete('Notes', where: '_id=?', whereArgs: [deletedNote.id]);
    print('note deleted');
  }

  Future<NoteModel> addNoteInDB(NoteModel newNote) async {
    final db = await database;
    if (newNote.title.trim().isEmpty) newNote.title = 'Untitled Note';
    int id = await db.transaction((transaction) {
      transaction.rawInsert(
          'INSERT INTO Notes(title,content,date,isImportant) VALUES ("${newNote.title}","${newNote.content}","${newNote.date.toIso8601String()}","${newNote.isImportant == true ? 1 : 0}");');
    });
    newNote.id = id;
    print('Note added: ${newNote.title}');
    return newNote;
  }
}
