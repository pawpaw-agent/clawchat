/// Syntax highlighting utilities
library;

import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as highlight;

/// Initialize supported languages for syntax highlighting
/// Note: highlight package auto-registers languages when imported
void initHighlightLanguages() {
  // No-op: languages are auto-registered by the highlight package
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
      'keyword': const TextStyle(color: Color(0xFFC792EA)), // Purple
      'built_in': const TextStyle(color: Color(0xFF82AAFF)), // Blue
      'type': const TextStyle(color: Color(0xFFFFCB6B)), // Yellow
      'literal': const TextStyle(color: Color(0xFFF78C6C)), // Orange
      'number': const TextStyle(color: Color(0xFFF78C6C)), // Orange
      'operator': const TextStyle(color: Color(0xFF89DDFF)), // Cyan
      'punctuation': TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      'property': const TextStyle(color: Color(0xFFFFCB6B)), // Yellow
      'regexp': const TextStyle(color: Color(0xFF89DDFF)), // Cyan
      'string': const TextStyle(color: Color(0xFFC3E88D)), // Green
      'char.escape': const TextStyle(color: Color(0xFF89DDFF)), // Cyan
      'subst': const TextStyle(color: Color(0xFFF78C6C)), // Orange
      'symbol': const TextStyle(color: Color(0xFF82AAFF)), // Blue
      'variable': const TextStyle(color: Color(0xFFFFCB6B)), // Yellow
      'variable.language': const TextStyle(color: Color(0xFFC792EA)), // Purple
      'variable.constant': const TextStyle(color: Color(0xFFF78C6C)), // Orange
      'title': const TextStyle(color: Color(0xFF82AAFF)), // Blue
      'title.class': const TextStyle(color: Color(0xFFFFCB6B)), // Yellow
      'title.function': const TextStyle(color: Color(0xFF82AAFF)), // Blue
      'params': TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
      'comment': const TextStyle(
        color: Color(0xFF546E7A), // Grey
        fontStyle: FontStyle.italic,
      ),
      'doctag': const TextStyle(color: Color(0xFFC792EA)), // Purple
      'meta': const TextStyle(color: Color(0xFF82AAFF)), // Blue
      'meta.prompt': const TextStyle(color: Color(0xFF546E7A)), // Grey
      'meta.keyword': const TextStyle(color: Color(0xFFC792EA)), // Purple
      'meta.string': const TextStyle(color: Color(0xFFC3E88D)), // Green
      'section': const TextStyle(color: Color(0xFF82AAFF)), // Blue
      'tag': const TextStyle(color: Color(0xFFFF5370)), // Red
      'name': const TextStyle(color: Color(0xFFFFCB6B)), // Yellow
      'attr': const TextStyle(color: Color(0xFFFFCB6B)), // Yellow
      'attribute': const TextStyle(color: Color(0xFFC792EA)), // Purple
      'bullet': const TextStyle(color: Color(0xFF89DDFF)), // Cyan
      'code': const TextStyle(color: Color(0xFFC3E88D)), // Green
      'emphasis': const TextStyle(fontStyle: FontStyle.italic),
      'strong': const TextStyle(fontWeight: FontWeight.bold),
      'formula': const TextStyle(color: Color(0xFF89DDFF)), // Cyan
      'link': const TextStyle(color: Color(0xFF82AAFF)), // Blue
      'quote': const TextStyle(color: Color(0xFF546E7A)), // Grey
      'selector-tag': const TextStyle(color: Color(0xFFFF5370)), // Red
      'selector-id': const TextStyle(color: Color(0xFF82AAFF)), // Blue
      'selector-class': const TextStyle(color: Color(0xFFC3E88D)), // Green
      'selector-attr': const TextStyle(color: Color(0xFFFFCB6B)), // Yellow
      'selector-pseudo': const TextStyle(color: Color(0xFFC792EA)), // Purple
      'addition': const TextStyle(color: Color(0xFFC3E88D)), // Green
      'deletion': const TextStyle(color: Color(0xFFFF5370)), // Red
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
      'keyword': const TextStyle(color: Color(0xFF7B1FA2)), // Purple
      'built_in': const TextStyle(color: Color(0xFF1565C0)), // Blue
      'type': const TextStyle(color: Color(0xFFF57C00)), // Orange
      'literal': const TextStyle(color: Color(0xFFD32F2F)), // Red
      'number': const TextStyle(color: Color(0xFFD32F2F)), // Red
      'operator': const TextStyle(color: Color(0xFF00897B)), // Teal
      'punctuation': TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      'property': const TextStyle(color: Color(0xFFF57C00)), // Orange
      'regexp': const TextStyle(color: Color(0xFF00897B)), // Teal
      'string': const TextStyle(color: Color(0xFF388E3C)), // Green
      'char.escape': const TextStyle(color: Color(0xFF00897B)), // Teal
      'subst': const TextStyle(color: Color(0xFFD32F2F)), // Red
      'symbol': const TextStyle(color: Color(0xFF1565C0)), // Blue
      'variable': const TextStyle(color: Color(0xFFF57C00)), // Orange
      'variable.language': const TextStyle(color: Color(0xFF7B1FA2)), // Purple
      'variable.constant': const TextStyle(color: Color(0xFFD32F2F)), // Red
      'title': const TextStyle(color: Color(0xFF1565C0)), // Blue
      'title.class': const TextStyle(color: Color(0xFFF57C00)), // Orange
      'title.function': const TextStyle(color: Color(0xFF1565C0)), // Blue
      'params': TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
      'comment': const TextStyle(
        color: Color(0xFF9E9E9E), // Grey
        fontStyle: FontStyle.italic,
      ),
      'doctag': const TextStyle(color: Color(0xFF7B1FA2)), // Purple
      'meta': const TextStyle(color: Color(0xFF1565C0)), // Blue
      'meta.prompt': const TextStyle(color: Color(0xFF9E9E9E)), // Grey
      'meta.keyword': const TextStyle(color: Color(0xFF7B1FA2)), // Purple
      'meta.string': const TextStyle(color: Color(0xFF388E3C)), // Green
      'section': const TextStyle(color: Color(0xFF1565C0)), // Blue
      'tag': const TextStyle(color: Color(0xFFD32F2F)), // Red
      'name': const TextStyle(color: Color(0xFFF57C00)), // Orange
      'attr': const TextStyle(color: Color(0xFFF57C00)), // Orange
      'attribute': const TextStyle(color: Color(0xFF7B1FA2)), // Purple
      'bullet': const TextStyle(color: Color(0xFF00897B)), // Teal
      'code': const TextStyle(color: Color(0xFF388E3C)), // Green
      'emphasis': const TextStyle(fontStyle: FontStyle.italic),
      'strong': const TextStyle(fontWeight: FontWeight.bold),
      'formula': const TextStyle(color: Color(0xFF00897B)), // Teal
      'link': const TextStyle(color: Color(0xFF1565C0)), // Blue
      'quote': const TextStyle(color: Color(0xFF9E9E9E)), // Grey
      'selector-tag': const TextStyle(color: Color(0xFFD32F2F)), // Red
      'selector-id': const TextStyle(color: Color(0xFF1565C0)), // Blue
      'selector-class': const TextStyle(color: Color(0xFF388E3C)), // Green
      'selector-attr': const TextStyle(color: Color(0xFFF57C00)), // Orange
      'selector-pseudo': const TextStyle(color: Color(0xFF7B1FA2)), // Purple
      'addition': const TextStyle(color: Color(0xFF388E3C)), // Green
      'deletion': const TextStyle(color: Color(0xFFD32F2F)), // Red
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
      final nodeClassName = node.className;
      if (node.children?.isEmpty ?? true) {
        // Leaf node - has text
        final text = node.toString();
        spans.add(TextSpan(
          text: text,
          style: theme[nodeClassName]?.merge(style) ?? style,
        ));
      } else {
        // Has children
        spans.add(TextSpan(
          style: theme[nodeClassName] ?? style,
          children: [_convertNodes(node.children!, theme)],
        ));
      }
    }

    return TextSpan(children: spans, style: style);
  }
}