import 'package:flutter/material.dart';
import 'models/bank_account.dart';
import 'models/book.dart';
import 'models/library.dart';
import 'models/magazine.dart';
import 'models/user.dart';
import 'screens/todo_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) => IPhoneFrame(child: child!),
      home: const TodoScreen(),
    );
  }
}

/// Draws an iPhone 17 (402 x 874) around the app.
class IPhoneFrame extends StatelessWidget {
  final Widget child;
  const IPhoneFrame({super.key, required this.child});

  static const double screenW = 402;
  static const double screenH = 874;
  static const double statusBarH = 54;
  static const double homeBarH = 34;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Material(
      color: const Color(0xFF111111),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          // Scales the whole phone down if the window is small
          child: FittedBox(
            fit: BoxFit.contain,
            child: Stack(
              children: [
                // Phone body + screen
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(66),
                      border: Border.all(
                        color: const Color(0xFF4A4A4C),
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(56),
                      child: SizedBox(
                        width: screenW,
                        height: screenH,
                        child: Stack(
                          children: [
                            // The real app, with safe-area space reserved
                            MediaQuery(
                              data: mq.copyWith(
                                size: const Size(screenW, screenH),
                                padding: const EdgeInsets.only(
                                  top: statusBarH,
                                  bottom: homeBarH,
                                ),
                              ),
                              child: child,
                            ),
                            const _StatusBar(),
                            const _DynamicIsland(),
                            const _HomeIndicator(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Side buttons
                const _SideButton(left: true, top: 150, height: 34), // action
                const _SideButton(left: true, top: 215, height: 62), // vol up
                const _SideButton(left: true, top: 290, height: 62), // vol down
                const _SideButton(left: false, top: 240, height: 100), // power
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: IPhoneFrame.statusBarH,
      child: Padding(
        padding: EdgeInsets.fromLTRB(36, 8, 30, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
            Row(
              children: [
                Icon(Icons.signal_cellular_alt, size: 18, color: Colors.black),
                SizedBox(width: 5),
                Icon(Icons.wifi, size: 18, color: Colors.black),
                SizedBox(width: 5),
                // Charging battery (green with a bolt)
                Icon(Icons.battery_charging_full,
                    size: 24, color: Color(0xFF30D158)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 11,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 124,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B1A2E), // camera lens
                  border: Border.all(
                    color: const Color(0xFF1C2F4A),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 140,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final bool left;
  final double top;
  final double height;
  const _SideButton({
    required this.left,
    required this.top,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: top,
      child: Container(
        width: 4,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4A4C),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
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