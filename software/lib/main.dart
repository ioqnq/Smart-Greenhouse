import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'settings.dart';

void main() {
  runApp(const MyApp());
}

/// Root app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NavigationExample(),
    );
  }
}

/// Navigation bar wrapper
class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentPageIndex == 0 ? 'Dashboard' : 'Configure',
        ),
        backgroundColor: const Color.fromARGB(255, 0, 170, 170),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        indicatorColor: const Color.fromARGB(200, 0, 170, 170),
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Config',
          ),
        ],
      ),

      // Switch between pages
      body: [
        const Dashboard(),
        const Settings(),
      ][currentPageIndex],
    );
  }
}
