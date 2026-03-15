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

  /// Callback when an image is tapped
  final void Function(String, String, String)? onTapImage;

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
    this.onTapImage,
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
      onTapLink: onTapLink,
      onTapImage: onTapImage,
      imageDirectory: imageDirectory,
      builders: builders ?? (enableHighlight ? _createBuilders(theme) : null),
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
      extensionSet: extensionSet ?? md.ExtensionSet.gitHubWeb,
      imageBuilder: _buildImage,
      checkboxBuilder: _buildCheckbox,
      bulletBuilder: _buildBullet,
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
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsetsDirectional.only(start: 16),
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
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
        width: 1,
      ),
      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  /// Create custom element builders for syntax highlighting
  Map<String, MarkdownElementBuilder> _createBuilders(ThemeData theme) {
    return {
      'pre': _CodeBlockBuilder(theme),
      'code': _InlineCodeBuilder(theme),
    };
  }

  /// Custom image builder
  Widget _buildImage(Uri uri, String title, String alt) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        uri.toString(),
        errorBuilder: (context, error, stackTrace) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    alt.isNotEmpty ? alt : 'Failed to load image',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Custom checkbox builder
  Widget _buildCheckbox(bool checked) {
    return Icon(
      checked ? Icons.check_box : Icons.check_box_outline_blank,
      size: 20,
    );
  }

  /// Custom bullet builder for lists
  Widget? _buildBullet(int index, bool isOrdered) {
    if (isOrdered) {
      return Text('${index + 1}.');
    }
    return const Text('•');
  }
}

/// Builder for code blocks with syntax highlighting
class _CodeBlockBuilder extends MarkdownElementBuilder {
  final ThemeData theme;

  _CodeBlockBuilder(this.theme);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final language = element.attributes['language'] ?? '';
    final code = element.textContent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerHighest
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language header
          if (language.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHigh
                    : const Color(0xFFE0E0E0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.code,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    language.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: HighlightText(
              text: code,
              language: language,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Builder for inline code
class _InlineCodeBuilder extends MarkdownElementBuilder {
  final ThemeData theme;

  _InlineCodeBuilder(this.theme);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return null; // Let default builder handle inline code
  }
}