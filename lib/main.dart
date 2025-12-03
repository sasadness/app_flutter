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

  // ============== CRUD =================================

  Future<int> insert(Task task) async {
    Database db = await instance.database;
    return await db.insert(table, task.toMap());
  }

  Future<List<Task>> queryAllTasks() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      orderBy: "$columnId DESC",
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<int> update(Task task) async {
    Database db = await instance.database;
    return await db.update(
      table,
      task.toMap(),
      where: '$columnId = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}

// =========================================================================

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({Key? key, this.task}) : super(key: key);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late Priority _selectedPriority;
  late UnidadeOperacional _selectedUnit;

  @override
  void initState() {
    super.initState();
    _title = widget.task?.title ?? '';
    _description = widget.task?.description ?? '';
    _selectedPriority = widget.task?.priority ?? Priority.media;
    _selectedUnit = widget.task?.operationalUnit ?? UnidadeOperacional.ti;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nova Tarefa' : 'Editar Tarefa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Título obrigatório' : null,
                onSaved: (v) => _title = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.length < 5) ? 'Mínimo 5 caracteres' : null,
                onSaved: (v) => _description = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: Priority.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.toString().split('.').last.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedPriority = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UnidadeOperacional>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unidade Operacional',
                ),
                items: UnidadeOperacional.values.map((u) {
                  final label = u.toString().split('.').last;
                  return DropdownMenuItem(
                    value: u,
                    child: Text(label[0].toUpperCase() + label.substring(1)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedUnit = v!),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.task == null ? 'SALVAR' : 'ATUALIZAR'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    final Task newTask = Task(
                      id: widget.task?.id,
                      title: _title,
                      description: _description,
                      priority: _selectedPriority,
                      createdAt: widget.task?.createdAt ?? DateTime.now(),
                      operationalUnit: _selectedUnit,
                    );

                    final dbHelper = DatabaseHelper.instance;
                    if (newTask.id == null) {
                      await dbHelper.insert(newTask);
                    } else {
                      await dbHelper.update(newTask);
                    }

                    if (!mounted) return;

                    Navigator.pop(context, true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//==================================================================

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = dbHelper.queryAllTasks();
  }

  void _refreshTaskList() {
    setState(() {
      _tasksFuture = dbHelper.queryAllTasks();
    });
  }

  String _formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return "$day/$month/$year às $hour:$minute";
  }

  void _navigateAndEditTask(Task? task) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskFormScreen(task: task)),
    );
    if (result == true) _refreshTaskList();
  }

  void _deleteTask(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Tarefa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await dbHelper.delete(id);
      _refreshTaskList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Tarefas')),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final tasks = snapshot.data!;
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Task.getPriorityColor(task.priority),
                      radius: 10,
                    ),
                    title: Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Unidade: ${task.operationalUnitString} | ${_formatDate(task.createdAt)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () => _navigateAndEditTask(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTask(task.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Nenhuma tarefa cadastrada.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndEditTask(null),
        child: const Icon(Icons.add),
      ),
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
      home: const TaskListScreen(),
    );
  }
}
