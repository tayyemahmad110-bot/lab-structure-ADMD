import 'package:flutter/material.dart';
import 'models/bank_account.dart';
import 'models/book.dart';
import 'models/library.dart';
import 'models/magazine.dart';
import 'models/user.dart';
import 'screens/todo_screen.dart';
import 'widgets/iphone_frame.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'lab TAIEM ahmad',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const PhoneScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) =>
          IPhoneFrame(child: child ?? const SizedBox.shrink()),
      home: const TodoScreen(),
    );
  }
}

class Lab2Page extends StatelessWidget {
  const Lab2Page({super.key});

  @override
  Widget build(BuildContext context) {
    // Task I
    final users = [
      User(name: 'Ana', age: 21, email: 'ana@example.com'),
      User(name: 'Bogdan', age: 30),
      User(name: 'Carmen'), // all optionals null
    ];

    // Task II
    final accounts = [
      BankAccount(holderName: 'Ana', bankBranch: 'Bucharest', balance: 120.5)
        ..initializeAccount('RO49AAAA1B31007593840000'),
      BankAccount(holderName: 'Bogdan')..initializeAccount('RO12BBBB0000'),
      BankAccount(holderName: 'Carmen'), // never initialized
    ];

    // Task III
    final library = Library();
    final book = Book(
      title: 'Dart in Action',
      author: 'Chris Buckett',
      publishDate: DateTime.now().subtract(const Duration(days: 100)),
      pageCount: 400,
    );
    final mag = Magazine(title: 'Tech Monthly'); // most fields null
    library.addItem(book);
    library.addItem(mag);
    library.addItem(book); // rejected: duplicate
    library.borrowItem(book, users.first);
    library.borrowItem(book, users[1]); // rejected: already borrowed

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Lab 2 - TAIEM ahmad'),
      ),
      body: ListView(
        children: [
          const _Header('Users'),
          for (final u in users)
            ListTile(
              title: Text(u.name),
              subtitle: Text(
                'Age: ${u.getDisplayAge()}\n'
                    'Email: ${u.email ?? 'Not provided'}',
              ),
            ),
          const _Header('Bank accounts'),
          for (final a in accounts)
            ListTile(
              title: Text(a.holderName),
              subtitle: Text(
                '${a.displayNumber}\n'
                    'Branch: ${a.bankBranch ?? 'N/A'} · '
                    'Balance: ${a.balance.toStringAsFixed(2)}',
              ),
            ),
          const _Header('Library'),
          for (final i in library.items)
            ListTile(
              title: Text(i.title),
              subtitle: Text(
                '${i.describe()}\n'
                    '${i.isBorrowed ? 'Borrowed by ${i.borrower?.name} until ${i.dueDate?.toIso8601String().substring(0, 10)}' : 'Available'}',
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}