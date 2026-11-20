import 'library_item.dart';

class Book extends LibraryItem {
  final int? pageCount;
  final String? isbn;

  Book({
    required super.title,
    super.author,
    super.publishDate,
    this.pageCount,
    this.isbn,
  });

  @override
  String describe() =>
      'Book · ${author ?? 'Unknown author'} · '
          '${pageCount != null ? '$pageCount pages' : 'pages unknown'} · '
          'ISBN ${isbn ?? 'N/A'}';
}