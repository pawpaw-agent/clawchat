/// Syntax highlighting utilities
library;

import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/xml.dart';

/// Initialize supported languages for syntax highlighting
void initHighlightLanguages() {
  highlight.registerLanguage('dart', dart);
  highlight.registerLanguage('python', python);
  highlight.registerLanguage('javascript', javascript);
  highlight.registerLanguage('typescript', typescript);
  highlight.registerLanguage('json', json);
  highlight.registerLanguage('yaml', yaml);
  highlight.registerLanguage('bash', bash);
  highlight.registerLanguage('sh', bash);
  highlight.registerLanguage('markdown', markdown);
  highlight.registerLanguage('md', markdown);
  highlight.registerLanguage('sql', sql);
  highlight.registerLanguage('xml', xml);
  highlight.registerLanguage('html', xml);
}

/// Widget that displays syntax-highlighted text
class HighlightText extends StatelessWidget {
  /// The source text to highlight
  final String text;

  /// Programming language for highlighting (auto-detect if empty)
  final String language;

  /// Text style for the code
  final TextStyle? style;

  /// Custom theme for syntax highlighting
  final Map<String, TextStyle>? theme;

  const HighlightText({
    super.key,
    required this.text,
    this.language = '',
    this.style,
    this.theme,
  });

  /// Default dark theme for syntax highlighting
  static Map<String, TextStyle> darkTheme(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {
      'root': TextStyle(
        color: colorScheme.onSurface,
        backgroundColor: Colors.transparent,
      ),
      'keyword': TextStyle(color: const Color(0xFFC792EA)), // Purple
      'built_in': TextStyle(color: const Color(0xFF82AAFF)), // Blue
      'type': TextStyle(color: const Color(0xFFFFCB6B)), // Yellow
      'literal': TextStyle(color: const Color(0xFFF78C6C)), // Orange
      'number': TextStyle(color: const Color(0xFFF78C6C)), // Orange
      'operator': TextStyle(color: const Color(0xFF89DDFF)), // Cyan
      'punctuation': TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
      'property': TextStyle(color: const Color(0xFFFFCB6B)), // Yellow
      'regexp': TextStyle(color: const Color(0xFF89DDFF)), // Cyan
      'string': TextStyle(color: const Color(0xFFC3E88D)), // Green
      'char.escape': TextStyle(color: const Color(0xFF89DDFF)), // Cyan
      'subst': TextStyle(color: const Color(0xFFF78C6C)), // Orange
      'symbol': TextStyle(color: const Color(0xFF82AAFF)), // Blue
      'variable': TextStyle(color: const Color(0xFFFFCB6B)), // Yellow
      'variable.language': TextStyle(color: const Color(0xFFC792EA)), // Purple
      'variable.constant': TextStyle(color: const Color(0xFFF78C6C)), // Orange
      'title': TextStyle(color: const Color(0xFF82AAFF)), // Blue
      'title.class': TextStyle(color: const Color(0xFFFFCB6B)), // Yellow
      'title.function': TextStyle(color: const Color(0xFF82AAFF)), // Blue
      'params': TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8)),
      'comment': TextStyle(
        color: const Color(0xFF546E7A), // Grey
        fontStyle: FontStyle.italic,
      ),
      'doctag': TextStyle(color: const Color(0xFFC792EA)), // Purple
      'meta': TextStyle(color: const Color(0xFF82AAFF)), // Blue
      'meta.prompt': TextStyle(color: const Color(0xFF546E7A)), // Grey
      'meta.keyword': TextStyle(color: const Color(0xFFC792EA)), // Purple
      'meta.string': TextStyle(color: const Color(0xFFC3E88D)), // Green
      'section': TextStyle(color: const Color(0xFF82AAFF)), // Blue
      'tag': TextStyle(color: const Color(0xFFFF5370)), // Red
      'name': TextStyle(color: const Color(0xFFFFCB6B)), // Yellow
      'attr': TextStyle(color: const Color(0xFFFFCB6B)), // Yellow
      'attribute': TextStyle(color: const Color(0xFFC792EA)), // Purple
      'bullet': TextStyle(color: const Color(0xFF89DDFF)), // Cyan
      'code': TextStyle(color: const Color(0xFFC3E88D)), // Green
      'emphasis': TextStyle(fontStyle: FontStyle.italic),
      'strong': TextStyle(fontWeight: FontWeight.bold),
      'formula': TextStyle(color: const Color(0xFF89DDFF)), // Cyan
      'link': TextStyle(color: const Color(0xFF82AAFF)), // Blue
      'quote': TextStyle(color: const Color(0xFF546E7A)), // Grey
      'selector-tag': TextStyle(color: const Color(0xFFFF5370)), // Red
      'selector-id': TextStyle(color: const Color(0xFF82AAFF)), // Blue
      'selector-class': TextStyle(color: const Color(0xFFC3E88D)), // Green
      'selector-attr': TextStyle(color: const Color(0xFFFFCB6B)), // Yellow
      'selector-pseudo': TextStyle(color: const Color(0xFFC792EA)), // Purple
      'addition': TextStyle(color: const Color(0xFFC3E88D)), // Green
      'deletion': TextStyle(color: const Color(0xFFFF5370)), // Red
    };
  }

  /// Default light theme for syntax highlighting
  static Map<String, TextStyle> lightTheme(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {
      'root': TextStyle(
        color: colorScheme.onSurface,
        backgroundColor: Colors.transparent,
      ),
      'keyword': TextStyle(color: const Color(0xFF7B1FA2)), // Purple
      'built_in': TextStyle(color: const Color(0xFF1565C0)), // Blue
      'type': TextStyle(color: const Color(0xFFF57C00)), // Orange
      'literal': TextStyle(color: const Color(0xFFD32F2F)), // Red
      'number': TextStyle(color: const Color(0xFFD32F2F)), // Red
      'operator': TextStyle(color: const Color(0xFF00897B)), // Teal
      'punctuation': TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
      'property': TextStyle(color: const Color(0xFFF57C00)), // Orange
      'regexp': TextStyle(color: const Color(0xFF00897B)), // Teal
      'string': TextStyle(color: const Color(0xFF388E3C)), // Green
      'char.escape': TextStyle(color: const Color(0xFF00897B)), // Teal
      'subst': TextStyle(color: const Color(0xFFD32F2F)), // Red
      'symbol': TextStyle(color: const Color(0xFF1565C0)), // Blue
      'variable': TextStyle(color: const Color(0xFFF57C00)), // Orange
      'variable.language': TextStyle(color: const Color(0xFF7B1FA2)), // Purple
      'variable.constant': TextStyle(color: const Color(0xFFD32F2F)), // Red
      'title': TextStyle(color: const Color(0xFF1565C0)), // Blue
      'title.class': TextStyle(color: const Color(0xFFF57C00)), // Orange
      'title.function': TextStyle(color: const Color(0xFF1565C0)), // Blue
      'params': TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8)),
      'comment': TextStyle(
        color: const Color(0xFF9E9E9E), // Grey
        fontStyle: FontStyle.italic,
      ),
      'doctag': TextStyle(color: const Color(0xFF7B1FA2)), // Purple
      'meta': TextStyle(color: const Color(0xFF1565C0)), // Blue
      'meta.prompt': TextStyle(color: const Color(0xFF9E9E9E)), // Grey
      'meta.keyword': TextStyle(color: const Color(0xFF7B1FA2)), // Purple
      'meta.string': TextStyle(color: const Color(0xFF388E3C)), // Green
      'section': TextStyle(color: const Color(0xFF1565C0)), // Blue
      'tag': TextStyle(color: const Color(0xFFD32F2F)), // Red
      'name': TextStyle(color: const Color(0xFFF57C00)), // Orange
      'attr': TextStyle(color: const Color(0xFFF57C00)), // Orange
      'attribute': TextStyle(color: const Color(0xFF7B1FA2)), // Purple
      'bullet': TextStyle(color: const Color(0xFF00897B)), // Teal
      'code': TextStyle(color: const Color(0xFF388E3C)), // Green
      'emphasis': TextStyle(fontStyle: FontStyle.italic),
      'strong': TextStyle(fontWeight: FontWeight.bold),
      'formula': TextStyle(color: const Color(0xFF00897B)), // Teal
      'link': TextStyle(color: const Color(0xFF1565C0)), // Blue
      'quote': TextStyle(color: const Color(0xFF9E9E9E)), // Grey
      'selector-tag': TextStyle(color: const Color(0xFFD32F2F)), // Red
      'selector-id': TextStyle(color: const Color(0xFF1565C0)), // Blue
      'selector-class': TextStyle(color: const Color(0xFF388E3C)), // Green
      'selector-attr': TextStyle(color: const Color(0xFFF57C00)), // Orange
      'selector-pseudo': TextStyle(color: const Color(0xFF7B1FA2)), // Purple
      'addition': TextStyle(color: const Color(0xFF388E3C)), // Green
      'deletion': TextStyle(color: const Color(0xFFD32F2F)), // Red
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightTheme = theme ?? (isDark ? darkTheme(context) : lightTheme(context));

    // Try to highlight with specified language, fall back to auto-detect
    highlight.Result? result;
    if (language.isNotEmpty) {
      try {
        result = highlight.highlight.parse(text, language: language);
      } catch (_) {
        // Language not supported, fall back to auto-detect
        result = null;
      }
    }

    result ??= highlight.highlight.parse(text, autoDetection: true);

    return RichText(
      text: _convertNodes(result.nodes ?? [], highlightTheme),
    );
  }

  /// Convert highlight nodes to TextSpan
  TextSpan _convertNodes(List<highlight.Node> nodes, Map<String, TextStyle> theme) {
    List<TextSpan> spans = [];

    for (final node in nodes) {
      if (node is highlight.TextNode) {
        spans.add(TextSpan(
          text: node.text,
          style: theme['root']?.merge(style) ?? style,
        ));
      } else if (node is highlight.ElementNode) {
        spans.add(TextSpan(
          style: theme[node.className] ?? style,
          children: node.children != null
              ? [_convertNodes(node.children!, theme)]
              : null,
        ));
      }
    }

    return TextSpan(children: spans, style: style);
  }
}