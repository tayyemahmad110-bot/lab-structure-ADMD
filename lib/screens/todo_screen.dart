import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../widgets/todo_tile.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _items = <Todo>[
    Todo('Buy milk'),
    Todo('Finish Lab 3'),
    Todo('Call mom'),
  ];
  final _input = TextEditingController();
  String? _filter;

  int get _doneCount {
    var done = 0;
    for (var i = 0; i < _items.length; i++) {
      // BUG 1
      // for (var i = 0; i <= _items.length; i++) {
      done += _items[i].done ? 1 : 0;
    }
    return done;
  }

  void _toggle(Todo t) {
    setState(() {
      t.done = !t.done;
    });

    // BUG 2
    // t.done = !t.done;
  }

  void _add() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.add(Todo(text));
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
    final index = _items.indexOf(todo);
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
          onPressed: () => setState(() => _items.insert(index, todo)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filter == null
        ? _items
        : _items
        .where((t) => t.title.toLowerCase().contains(_filter!.toLowerCase()))
        .toList();

    // BUG 3
    // final visible = _items.where((t) => t.title.contains(_filter!)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Todos ($_doneCount/${_items.length} done)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Filter',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v.isEmpty ? null : v),
            ),
          ),
          Expanded(
            child: ListView.builder(
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}