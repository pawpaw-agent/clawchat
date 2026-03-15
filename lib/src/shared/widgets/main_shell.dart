/// Main shell with bottom navigation bar
/// Provides navigation between Chat, Sessions, Nodes, and Settings
library;

import 'package:flutter/material.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/sessions/session_list_screen.dart';
import '../../features/nodes/node_list_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Main shell widget with bottom navigation
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      const ChatScreen(),
      const SessionListScreen(),
      const NodeListScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Nodes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}