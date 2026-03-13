package ai.openclaw.android.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
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
 * Supports: bold, italic, inline code, code blocks, links
 */
@Composable
fun MarkdownText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.onSurface
) {
    // Parse and render markdown
    val blocks = parseMarkdownBlocks(text)
    
    Column(modifier = modifier) {
        blocks.forEach { block ->
            when (block) {
                is MarkdownBlock.CodeBlock -> {
                    CodeBlockView(block.code, block.language)
                }
                is MarkdownBlock.Text -> {
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
    data class Text(val annotatedString: AnnotatedString) : MarkdownBlock()
    data class CodeBlock(val code: String, val language: String) : MarkdownBlock()
}

/**
 * Parse markdown into blocks
 */
@Composable
private fun parseMarkdownBlocks(text: String): List<MarkdownBlock> {
    val blocks = mutableListOf<MarkdownBlock>()
    val codeBackground = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
    
    var i = 0
    val currentText = StringBuilder()
    
    while (i < text.length) {
        // Check for code block (```)
        if (i + 2 < text.length && text[i] == '`' && text[i + 1] == '`' && text[i + 2] == '`') {
            // Flush current text
            if (currentText.isNotEmpty()) {
                blocks.add(MarkdownBlock.Text(parseInlineMarkdown(currentText.toString(), codeBackground)))
                currentText.clear()
            }
            
            val endIndex = text.indexOf("```", i + 3)
            if (endIndex != -1) {
                val codeStart = i + 3
                val firstNewline = text.indexOf('\n', codeStart)
                val (language, code) = if (firstNewline != -1 && firstNewline < endIndex) {
                    text.substring(codeStart, firstNewline).trim() to text.substring(firstNewline + 1, endIndex)
                } else {
                    "" to text.substring(codeStart, endIndex)
                }
                
                blocks.add(MarkdownBlock.CodeBlock(code, language))
                i = endIndex + 3
                continue
            }
        }
        
        currentText.append(text[i])
        i++
    }
    
    // Flush remaining text
    if (currentText.isNotEmpty()) {
        blocks.add(MarkdownBlock.Text(parseInlineMarkdown(currentText.toString(), codeBackground)))
    }
    
    return blocks
}

/**
 * Parse inline markdown (bold, italic, code, links)
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
            
            append(text[i])
            i++
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