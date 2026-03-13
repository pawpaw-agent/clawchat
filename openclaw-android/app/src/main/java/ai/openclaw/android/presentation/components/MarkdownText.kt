package ai.openclaw.android.presentation.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.sp

/**
 * Simple Markdown renderer for chat messages
 * Supports: bold, italic, code, code blocks, links
 */
@Composable
fun MarkdownText(
    text: String,
    modifier: Modifier = Modifier,
    color: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurface
) {
    val annotatedString = parseMarkdown(text)
    
    Text(
        text = annotatedString,
        style = MaterialTheme.typography.bodyMedium,
        color = color,
        modifier = modifier
    )
}

/**
 * Parse markdown text to AnnotatedString
 */
@Composable
private fun parseMarkdown(text: String): AnnotatedString {
    val codeBackground = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
    
    return buildAnnotatedString {
        var i = 0
        val length = text.length
        
        while (i < length) {
            // Check for code block (```)
            if (i + 2 < length && text[i] == '`' && text[i + 1] == '`' && text[i + 2] == '`') {
                val endIndex = text.indexOf("```", i + 3)
                if (endIndex != -1) {
                    // Extract language hint if present (first line after ```)
                    val codeStart = i + 3
                    val firstNewline = text.indexOf('\n', codeStart)
                    val code = if (firstNewline != -1 && firstNewline < endIndex) {
                        text.substring(firstNewline + 1, endIndex)
                    } else {
                        text.substring(codeStart, endIndex)
                    }
                    
                    // Push code block style
                    withStyle(
                        SpanStyle(
                            fontFamily = FontFamily.Monospace,
                            fontSize = 13.sp,
                            background = codeBackground
                        )
                    ) {
                        append(code)
                    }
                    i = endIndex + 3
                    continue
                }
            }
            
            // Check for inline code (`)
            if (text[i] == '`' && (i + 1 < length && text[i + 1] != '`')) {
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
            
            // Check for bold (**)
            if (i + 1 < length && text[i] == '*' && text[i + 1] == '*') {
                val endIndex = text.indexOf("**", i + 2)
                if (endIndex != -1) {
                    withStyle(SpanStyle(fontWeight = FontWeight.Bold)) {
                        append(text.substring(i + 2, endIndex))
                    }
                    i = endIndex + 2
                    continue
                }
            }
            
            // Check for italic (*)
            if (text[i] == '*' && (i + 1 >= length || text[i + 1] != '*')) {
                val endIndex = text.indexOf('*', i + 1)
                if (endIndex != -1 && endIndex > i + 1) {
                    withStyle(SpanStyle(fontStyle = FontStyle.Italic)) {
                        append(text.substring(i + 1, endIndex))
                    }
                    i = endIndex + 1
                    continue
                }
            }
            
            // Check for link [text](url)
            if (text[i] == '[') {
                val textEnd = text.indexOf(']', i + 1)
                if (textEnd != -1 && textEnd + 1 < length && text[textEnd + 1] == '(') {
                    val urlEnd = text.indexOf(')', textEnd + 2)
                    if (urlEnd != -1) {
                        val linkText = text.substring(i + 1, textEnd)
                        withStyle(
                            SpanStyle(
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.Medium
                            )
                        ) {
                            append(linkText)
                        }
                        i = urlEnd + 1
                        continue
                    }
                }
            }
            
            // Default: append character
            append(text[i])
            i++
        }
    }
}