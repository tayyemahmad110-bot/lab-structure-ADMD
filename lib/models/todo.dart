class Todo {
  static int _nextId = 0;

  final int id; // unique, used as the Dismissible key
  String title;
  bool done;

  Todo(this.title, {this.done = false}) : id = _nextId++;
}