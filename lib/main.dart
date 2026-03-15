import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'src/shared/widgets/highlight.dart';

void main() {
  // Initialize syntax highlighting languages
  initHighlightLanguages();
  
  runApp(
    const ProviderScope(
      child: ClawChatApp(),
    ),
  );
}