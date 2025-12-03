import 'package:flutter/material.dart';
import 'package:path/path.dart' hide context;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// =========================================================================

enum Priority { baixa, media, alta }

enum UnidadeOperacional { vendas, marketing, ti, financeiro, gerencia, outra }

class Task {
  final int? id;
  final String title;
  final String description;
  final Priority priority;
  final DateTime createdAt;
  final UnidadeOperacional operationalUnit;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.createdAt,
    required this.operationalUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'operationalUnit': operationalUnit.index,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      priority: Priority.values[map['priority'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      operationalUnit: UnidadeOperacional.values[map['operationalUnit'] as int],
    );
  }

  String get priorityString =>
      priority.toString().split('.').last.toUpperCase();

  String get operationalUnitString {
    String name = operationalUnit.toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1);
  }

  static Color getPriorityColor(Priority p) {
    switch (p) {
      case Priority.alta:
        return Colors.red;
      case Priority.media:
        return Colors.amber;
      case Priority.baixa:
        return Colors.green;
    }
  }
}

class DatabaseHelper {
  static final _databaseName = "202310314.db";
  static final _databaseVersion = 1;
  static final table = 'tasks';

  static final columnId = 'id';
  static final columnTitle = 'title';
  static final columnDescription = 'description';
  static final columnPriority = 'priority';
  static final columnCreatedAt = 'createdAt';
  static final columnOperationalUnit = 'operationalUnit';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnDescription TEXT NOT NULL,
            $columnPriority INTEGER NOT NULL,
            $columnCreatedAt INTEGER NOT NULL,
            $columnOperationalUnit INTEGER NOT NULL
          )
        ''');
      },
    );
  }
}

// ==================== MAIN =====================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.purpleAccent,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      // home: const TaskListScreen(),
    );
  }
}
