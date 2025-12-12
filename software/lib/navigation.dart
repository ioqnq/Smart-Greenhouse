import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'settings.dart';
import 'constants/colors.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight, 
      appBar: AppBar(
        title: Text(
          currentPageIndex == 0 ? 'Dashboard' : 'Configure',
        ),
        backgroundColor: AppColors.primary, 
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        indicatorColor: AppColors.primary,
        backgroundColor: AppColors.primaryDark,
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
            label: 'Configure',
          ),
        ],
      ),

      body: [
        const Dashboard(),
        const Settings(),
      ][currentPageIndex],
    );
  }
}
