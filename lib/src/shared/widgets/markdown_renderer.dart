/// Markdown renderer with syntax highlighting support
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'highlight.dart';

/// Custom Markdown renderer with code block syntax highlighting
class MarkdownRenderer extends StatelessWidget {
  /// The Markdown content to render
  final String data;

  /// Custom stylesheet (optional)
  final MarkdownStyleSheet? styleSheet;

  /// Callback when a link is tapped
  final void Function(String, String, String)? onTapLink;

  /// Whether to make links selectable
  final bool selectable;

  /// Image directory for local images
  final String? imageDirectory;

  /// Whether to enable syntax highlighting
  final bool enableHighlight;

  /// Custom builders for specific element types
  final Map<String, MarkdownElementBuilder>? builders;

  /// Custom block syntax rules
  final List<md.BlockSyntax>? blockSyntaxes;

  /// Custom inline syntax rules
  final List<md.InlineSyntax>? inlineSyntaxes;

  /// Extension set to use
  final md.ExtensionSet? extensionSet;

  const MarkdownRenderer({
    super.key,
    required this.data,
    this.styleSheet,
    this.onTapLink,
    this.selectable = true,
    this.imageDirectory,
    this.enableHighlight = true,
    this.builders,
    this.blockSyntaxes,
    this.inlineSyntaxes,
    this.extensionSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyleSheet = _createDefaultStyleSheet(theme);

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: styleSheet ?? defaultStyleSheet,
      onTapLink: (text, href, title) {
        onTapLink?.call(text, href ?? '', title ?? '');
      },
      imageDirectory: imageDirectory,
      builders: builders ?? (enableHighlight ? _createBuilders(theme) : null),
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
      extensionSet: extensionSet ?? md.ExtensionSet.gitHubWeb,
    );
  }

  /// Create default style sheet based on theme
  MarkdownStyleSheet _createDefaultStyleSheet(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final codeBackground = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF5F5F5);

    return MarkdownStyleSheet(
      // Headings
      h1: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      h4: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      // Body text
      p: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.6,
      ),
      // Code
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        color: theme.colorScheme.primary,
        backgroundColor: codeBackground,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      // Blockquote
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16),
      // Lists
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      listIndent: 24,
      // Table
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      tableHeadAlign: TextAlign.left,
      tableBorder: TableBorder.all(
        color: theme.colorScheme.outline.withOpacity(0.3),
        width: 1,
      ),
      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      // Links
      a: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }

  /// Create custom builders for code blocks
  Map<String, MarkdownElementBuilder> _createBuilders(ThemeData theme) {
    return {
      'pre': _CodeBlockBuilder(theme),
    };
  }
}

/// Builder for code blocks with syntax highlighting
class _CodeBlockBuilder extends MarkdownElementBuilder {
  final ThemeData theme;

  _CodeBlockBuilder(this.theme);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';
    final code = element.textContent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerHighest
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: HighlightText(
          text: code,
          language: language,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}