import 'package:flutter/material.dart';
import '../api/todo_api.dart';
import '../models/todo.dart';
import '../widgets/todo_tile.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _api = TodoApi();
  final _input = TextEditingController();
  final _items = <Todo>[];
  final _log = <String>[];
  String? _filter;
  String? _error;
  bool _loading = false;
  int _nextLocalId = 1000;

  int get _doneCount => _items.where((t) => t.completed).length;

  @override
  void initState() {
    super.initState();
    // Task I step 6: two separate but identical todos
    const a = Todo(
      userId: 1,
      id: 1,
      title: 'delectus aut autem',
      completed: false,
    );
    final b = Todo.fromJson(a.toJson());
    debugPrint('a == b: ${a == b}, identical: ${identical(a, b)}');
    _load();
  }

  void _addLog(String message) {
    if (!mounted) return;
    final time = DateTime.now().toIso8601String().substring(11, 23);
    setState(() => _log.add('$time  $message'));
  }

  Future<void> _load({String path = '/todos'}) async {
    setState(() {
      _loading = true;
      _error = null;
      _log.clear();
    });
    _addLog('GET $path');
    try {
      final todos = await _api.fetchTodos(path: path, onLog: _addLog);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(todos);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = describeError(e);
        _loading = false;
      });
    }
  }

  void _toggle(Todo t) {
    final i = _items.indexWhere((x) => x.id == t.id);
    if (i == -1) return;
    setState(() {
      _items[i] = t.copyWith(completed: !t.completed);
    });
  }

  void _add() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.add(Todo(
        userId: 1,
        id: _nextLocalId++,
        title: text,
        completed: false,
      ));
    });
    _input.clear();
  }

  Future<void> _showAddDialog() async {
    _input.clear();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New todo'),
        content: TextField(
          controller: _input,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'What needs doing?'),
          onSubmitted: (_) {
            _add();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _add();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _onDismissed(Todo todo) {
    final index = _items.indexWhere((x) => x.id == todo.id);
    if (index == -1) return;
    setState(() {
      _items.removeAt(index);
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${todo.title}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => setState(() {
            final at = index > _items.length ? _items.length : index;
            _items.insert(at, todo);
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Widget _buildList(List<Todo> visible) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(child: Text(_error ?? 'No todos'));
    }
    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (context, i) {
        final todo = visible[i];
        return Dismissible(
          key: ValueKey(todo.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _onDismissed(todo),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: TodoTile(
            todo: todo,
            onChanged: (_) => _toggle(todo),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _filter?.toLowerCase();
    final visible = q == null
        ? _items
        : _items.where((t) => t.title.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Todos ($_doneCount/${_items.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload /todos',
            onPressed: _loading ? null : () => _load(),
          ),
          IconButton(
            icon: const Icon(Icons.wifi_off),
            tooltip: 'Test invalid path (/nope)',
            onPressed: _loading ? null : () => _load(path: '/nope'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Filter',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _filter = v.isEmpty ? null : v),
              ),
            ),
            Expanded(child: _buildList(visible)),
            _LogPanel(lines: _log, error: _error),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 168),
        child: FloatingActionButton(
          onPressed: _showAddDialog,
          tooltip: 'Add todo',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// The retry log shown on screen, as a rounded dark card.
class _LogPanel extends StatelessWidget {
  final List<String> lines;
  final String? error;

  const _LogPanel({required this.lines, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error == null ? 'Retry log' : 'Retry log · last error: $error',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, i) => Text(
                lines[i],
                style: TextStyle(
                  color: lines[i].contains('failed')
                      ? Colors.redAccent
                      : Colors.greenAccent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}