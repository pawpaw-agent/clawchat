package ai.openclaw.android.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import ai.openclaw.android.presentation.theme.GitHubSizes
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.theme.GitHubStatusOpen
import ai.openclaw.android.presentation.theme.GitHubStatusClosed
import ai.openclaw.android.presentation.theme.GitHubStatusMerged
import ai.openclaw.android.presentation.theme.GitHubStatusDraft
import ai.openclaw.android.presentation.theme.GitHubGreen500
import ai.openclaw.android.presentation.theme.GitHubRed500
import ai.openclaw.android.presentation.theme.GitHubPurple500
import ai.openclaw.android.presentation.theme.GitHubBlue500

/**
 * GitHub 风格徽章组件
 * 
 * 特征:
 * - 完全圆角 (20dp+)
 * - 紧凑内边距
 * - 多种状态/类型
 * - 支持自定义颜色
 */

enum class BadgeState {
    OPEN,
    CLOSED,
    MERGED,
    DRAFT
}

@Composable
fun GitHubBadge(
    text: String,
    modifier: Modifier = Modifier,
    backgroundColor: Color = MaterialTheme.colorScheme.surfaceVariant,
    textColor: Color = MaterialTheme.colorScheme.onSurfaceVariant,
    borderColor: Color? = null,
    size: BadgeSize = BadgeSize.MEDIUM
) {
    val shape = RoundedCornerShape(GitHubSizes.badgeRadius)
    val height = when (size) {
        BadgeSize.SMALL -> GitHubSizes.badgeHeightSmall
        BadgeSize.MEDIUM -> GitHubSizes.badgeHeight
        BadgeSize.LARGE -> 24.dp
    }
    
    Surface(
        color = backgroundColor,
        shape = shape,
        modifier = modifier
            .height(height)
            .then(if (borderColor != null) Modifier.border(1.dp, borderColor, shape) else Modifier)
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = GitHubSpacing.xs, vertical = GitHubSpacing.xxs),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = text,
                style = MaterialTheme.typography.labelSmall,
                color = textColor,
                maxLines = 1
            )
        }
    }
}

enum class BadgeSize {
    SMALL,
    MEDIUM,
    LARGE
}

/**
 * 状态徽章 - Open
 */
@Composable
fun StatusBadgeOpen(
    modifier: Modifier = Modifier,
    text: String = "Open"
) {
    GitHubBadge(
        text = text,
        modifier = modifier,
        backgroundColor = GitHubStatusOpen,
        textColor = Color.White
    )
}

/**
 * 状态徽章 - Closed
 */
@Composable
fun StatusBadgeClosed(
    modifier: Modifier = Modifier,
    text: String = "Closed"
) {
    GitHubBadge(
        text = text,
        modifier = modifier,
        backgroundColor = GitHubStatusClosed,
        textColor = Color.White
    )
}

/**
 * 状态徽章 - Merged
 */
@Composable
fun StatusBadgeMerged(
    modifier: Modifier = Modifier,
    text: String = "Merged"
) {
    GitHubBadge(
        text = text,
        modifier = modifier,
        backgroundColor = GitHubStatusMerged,
        textColor = Color.White
    )
}

/**
 * 状态徽章 - Draft
 */
@Composable
fun StatusBadgeDraft(
    modifier: Modifier = Modifier,
    text: String = "Draft"
) {
    GitHubBadge(
        text = text,
        modifier = modifier,
        backgroundColor = GitHubStatusDraft,
        textColor = Color.White
    )
}

/**
 * 语言徽章
 */
@Composable
fun LanguageBadge(
    language: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    GitHubBadge(
        text = language,
        modifier = modifier,
        backgroundColor = color.copy(alpha = 0.2f),
        textColor = color
    )
}

/**
 * 常用语言颜色
 */
object LanguageColors {
    val Kotlin = Color(0xFFA97BFF)
    val Java = Color(0xFFB07219)
    val JavaScript = Color(0xFFF1E05A)
    val TypeScript = Color(0xFF3178C6)
    val Python = Color(0xFF3572A5)
    val Go = Color(0xFF00ADD8)
    val Rust = Color(0xFFDEA584)
    val Swift = Color(0xFFEF394E)
    val Cpp = Color(0xFFF34B7D)
    val C = Color(0xFF555555)
    val Ruby = Color(0xFF701516)
    val PHP = Color(0xFF4F5D95)
    val Shell = Color(0xFF89E051)
    val HTML = Color(0xFFE34C26)
    val CSS = Color(0xFF563D7C)
}

/**
 * 带图标的徽章
 */
@Composable
fun IconBadge(
    text: String,
    iconContent: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    backgroundColor: Color = MaterialTheme.colorScheme.surfaceVariant,
    textColor: Color = MaterialTheme.colorScheme.onSurfaceVariant
) {
    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(GitHubSizes.badgeRadius),
        modifier = modifier.height(GitHubSizes.badgeHeight)
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = GitHubSpacing.xs, vertical = GitHubSpacing.xxs),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier.size(14.dp),
                contentAlignment = Alignment.Center
            ) {
                iconContent()
            }
            Text(
                text = text,
                style = MaterialTheme.typography.labelSmall,
                color = textColor,
                modifier = Modifier.padding(start = GitHubSpacing.xxs),
                maxLines = 1
            )
        }
    }
}
