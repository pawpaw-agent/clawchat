/// Session list screen (placeholder)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
      ),
      body: const Center(
        child: Text('Session list - Coming soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new session
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}