/// Node list screen (placeholder)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NodeListScreen extends ConsumerStatefulWidget {
  const NodeListScreen({super.key});

  @override
  ConsumerState<NodeListScreen> createState() => _NodeListScreenState();
}

class _NodeListScreenState extends ConsumerState<NodeListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nodes'),
      ),
      body: const Center(
        child: Text('Node list - Coming soon'),
      ),
    );
  }
}