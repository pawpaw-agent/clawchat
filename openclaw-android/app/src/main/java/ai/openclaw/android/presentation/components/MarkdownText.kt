package ai.openclaw.android.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Markdown renderer for chat messages
 * Supports: bold, italic, inline code, code blocks, links, lists, headings, blockquotes, strikethrough
 */
@Composable
fun MarkdownText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.onSurface
) {
    val blocks = parseMarkdownBlocks(text)
    
    Column(modifier = modifier) {
        blocks.forEach { block ->
            when (block) {
                is MarkdownBlock.CodeBlock -> CodeBlockView(block.code, block.language)
                is MarkdownBlock.Heading -> HeadingView(block.level, block.text)
                is MarkdownBlock.Blockquote -> BlockquoteView(block.text)
                is MarkdownBlock.ListBlock -> ListView(block.items, block.ordered)
                is MarkdownBlock.Paragraph -> {
                    Text(
                        text = block.annotatedString,
                        style = MaterialTheme.typography.bodyMedium,
                        color = color
                    )
                }
            }
        }
    }
}

/**
 * Markdown block types
 */
private sealed class MarkdownBlock {
    data class Paragraph(val annotatedString: AnnotatedString) : MarkdownBlock()
    data class CodeBlock(val code: String, val language: String) : MarkdownBlock()
    data class Heading(val level: Int, val text: AnnotatedString) : MarkdownBlock()
    data class Blockquote(val text: AnnotatedString) : MarkdownBlock()
    data class ListBlock(val items: List<AnnotatedString>, val ordered: Boolean) : MarkdownBlock()
}

/**
 * Parse markdown into blocks
 */
@Composable
private fun parseMarkdownBlocks(text: String): List<MarkdownBlock> {
    val blocks = mutableListOf<MarkdownBlock>()
    val codeBackground = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
    val lines = text.lines()
    var i = 0
    
    while (i < lines.size) {
        val line = lines[i]
        
        // Code block
        if (line.startsWith("```")) {
            val language = line.removePrefix("```").trim()
            val codeLines = mutableListOf<String>()
            i++
            while (i < lines.size && !lines[i].startsWith("```")) {
                codeLines.add(lines[i])
                i++
            }
            i++ // Skip closing ```
            blocks.add(MarkdownBlock.CodeBlock(codeLines.joinToString("\n"), language))
            continue
        }
        
        // Heading (### Title)
        val headingMatch = Regex("^(#{1,4})\\s+(.+)$").find(line)
        if (headingMatch != null) {
            val level = headingMatch.groupValues[1].length
            val text = headingMatch.groupValues[2]
            blocks.add(MarkdownBlock.Heading(level, parseInlineMarkdown(text, codeBackground)))
            i++
            continue
        }
        
        // Blockquote (> text)
        if (line.startsWith("> ")) {
            val quoteLines = mutableListOf<String>()
            while (i < lines.size && lines[i].startsWith("> ")) {
                quoteLines.add(lines[i].removePrefix("> "))
                i++
            }
            blocks.add(MarkdownBlock.Blockquote(parseInlineMarkdown(quoteLines.joinToString(" "), codeBackground)))
            continue
        }
        
        // Unordered list (- item or * item)
        if (line.matches("^[*-]\\s+.+$")) {
            val items = mutableListOf<AnnotatedString>()
            while (i < lines.size && lines[i].matches("^[*-]\\s+.+$")) {
                items.add(parseInlineMarkdown(lines[i].drop(2), codeBackground))
                i++
            }
            blocks.add(MarkdownBlock.ListBlock(items, ordered = false))
            continue
        }
        
        // Ordered list (1. item)
        if (line.matches("^\\d+\\.\\s+.+$")) {
            val items = mutableListOf<AnnotatedString>()
            while (i < lines.size && lines[i].matches("^\\d+\\.\\s+.+$")) {
                items.add(parseInlineMarkdown(lines[i].dropWhile { it != ' ' }.drop(1), codeBackground))
                i++
            }
            blocks.add(MarkdownBlock.ListBlock(items, ordered = true))
            continue
        }
        
        // Paragraph (accumulate until empty line or block start)
        if (line.isNotBlank()) {
            val paragraphLines = mutableListOf<String>()
            while (i < lines.size && lines[i].isNotBlank() && 
                   !lines[i].startsWith("```") && 
                   !lines[i].startsWith("> ") &&
                   !lines[i].matches("^[*-]\\s+.+$") &&
                   !lines[i].matches("^\\d+\\.\\s+.+$") &&
                   !lines[i].matches("^#{1,4}\\s+.+$")) {
                paragraphLines.add(lines[i])
                i++
            }
            val paragraphText = paragraphLines.joinToString("\n")
            blocks.add(MarkdownBlock.Paragraph(parseInlineMarkdown(paragraphText, codeBackground)))
            continue
        }
        
        // Empty line
        i++
    }
    
    return blocks
}

/**
 * Parse inline markdown (bold, italic, code, links, strikethrough)
 */
@Composable
private fun parseInlineMarkdown(text: String, codeBackground: Color): AnnotatedString {
    return buildAnnotatedString {
        var i = 0
        
        while (i < text.length) {
            // Inline code
            if (text[i] == '`' && i + 1 < text.length && text[i + 1] != '`') {
                val endIndex = text.indexOf('`', i + 1)
                if (endIndex != -1) {
                    withStyle(
                        SpanStyle(
                            fontFamily = FontFamily.Monospace,
                            fontSize = 13.sp,
                            background = codeBackground
                        )
                    ) {
                        append(text.substring(i + 1, endIndex))
                    }
                    i = endIndex + 1
                    continue
                }
            }
            
            // Strikethrough (~~text~~)
            if (i + 1 < text.length && text[i] == '~' && text[i + 1] == '~') {
                val endIndex = text.indexOf("~~", i + 2)
                if (endIndex != -1) {
                    withStyle(SpanStyle(textDecoration = androidx.compose.ui.text.style.TextDecoration.LineThrough)) {
                        append(text.substring(i + 2, endIndex))
                    }
                    i = endIndex + 2
                    continue
                }
            }
            
            // Bold (**)
            if (i + 1 < text.length && text[i] == '*' && text[i + 1] == '*') {
                val endIndex = text.indexOf("**", i + 2)
                if (endIndex != -1) {
                    withStyle(SpanStyle(fontWeight = FontWeight.Bold)) {
                        append(text.substring(i + 2, endIndex))
                    }
                    i = endIndex + 2
                    continue
                }
            }
            
            // Italic (*)
            if (text[i] == '*' && (i + 1 >= text.length || text[i + 1] != '*')) {
                val endIndex = text.indexOf('*', i + 1)
                if (endIndex != -1 && endIndex > i + 1) {
                    withStyle(SpanStyle(fontStyle = FontStyle.Italic)) {
                        append(text.substring(i + 1, endIndex))
                    }
                    i = endIndex + 1
                    continue
                }
            }
            
            // Link [text](url)
            if (text[i] == '[') {
                val textEnd = text.indexOf(']', i + 1)
                if (textEnd != -1 && textEnd + 1 < text.length && text[textEnd + 1] == '(') {
                    val urlEnd = text.indexOf(')', textEnd + 2)
                    if (urlEnd != -1) {
                        withStyle(
                            SpanStyle(
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.Medium
                            )
                        ) {
                            append(text.substring(i + 1, textEnd))
                        }
                        i = urlEnd + 1
                        continue
                    }
                }
            }
            
            // Newline handling
            if (text[i] == '\n') {
                append('\n')
                i++
                continue
            }
            
            append(text[i])
            i++
        }
    }
}

/**
 * Heading view
 */
@Composable
private fun HeadingView(level: Int, text: AnnotatedString) {
    val fontSize = when (level) {
        1 -> 24.sp
        2 -> 22.sp
        3 -> 20.sp
        else -> 18.sp
    }
    Text(
        text = text,
        style = MaterialTheme.typography.headlineSmall.copy(
            fontSize = fontSize,
            fontWeight = FontWeight.Bold
        ),
        modifier = Modifier.padding(vertical = 4.dp)
    )
}

/**
 * Blockquote view
 */
@Composable
private fun BlockquoteView(text: AnnotatedString) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
    ) {
        Box(
            modifier = Modifier
                .width(4.dp)
                .height(20.dp)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.5f))
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
            modifier = Modifier.weight(1f)
        )
    }
}

/**
 * List view
 */
@Composable
private fun ListView(items: List<AnnotatedString>, ordered: Boolean) {
    Column(modifier = Modifier.fillMaxWidth()) {
        items.forEachIndexed { index, item ->
            Row(modifier = Modifier.padding(vertical = 2.dp)) {
                Text(
                    text = if (ordered) "${index + 1}." else "•",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.width(24.dp)
                )
                Text(
                    text = item,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

/**
 * Code block view with background
 */
@Composable
private fun CodeBlockView(code: String, language: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .clip(MaterialTheme.shapes.small)
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            .padding(12.dp)
    ) {
        Text(
            text = code,
            style = MaterialTheme.typography.bodySmall.copy(
                fontFamily = FontFamily.Monospace,
                fontSize = 13.sp
            ),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}