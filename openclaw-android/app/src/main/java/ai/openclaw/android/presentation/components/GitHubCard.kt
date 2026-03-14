package ai.openclaw.android.presentation.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import ai.openclaw.android.presentation.theme.GitHubSizes
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.theme.GitHubBorderDefaultLight
import ai.openclaw.android.presentation.theme.GitHubBorderDefaultDark
import ai.openclaw.android.presentation.theme.GitHubBgSubtleLight
import ai.openclaw.android.presentation.theme.GitHubBgSubtleDark

/**
 * GitHub 风格卡片组件
 * 
 * 特征:
 * - 6dp 小圆角
 * - 1px 边框
 * - 16dp 内边距
 * - 可选点击态
 */

@Composable
fun GitHubCard(
    modifier: Modifier = Modifier,
    backgroundColor: Color = MaterialTheme.colorScheme.surface,
    onClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    val borderStroke = BorderStroke(
        1.dp,
        MaterialTheme.colorScheme.outlineVariant
    )
    
    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(GitHubSizes.cardRadius),
        border = borderStroke,
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier)
    ) {
        Column(
            modifier = Modifier.padding(GitHubSpacing.md)
        ) {
            content()
        }
    }
}

/**
 * 卡片头部组件
 */
@Composable
fun GitHubCardHeader(
    title: String,
    subtitle: String? = null,
    modifier: Modifier = Modifier,
    trailingContent: @Composable (() -> Unit)? = null
) {
    androidx.compose.foundation.layout.Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
    ) {
        androidx.compose.foundation.layout.Column(
            modifier = Modifier.weight(1f)
        ) {
            androidx.compose.material3.Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            subtitle?.let {
                androidx.compose.material3.Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = GitHubSpacing.xxs)
                )
            }
        }
        trailingContent?.let {
            it()
        }
    }
}

/**
 * 卡片分割线
 */
@Composable
fun GitHubCardDivider(
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.outlineVariant
) {
    androidx.compose.material3.Divider(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = GitHubSpacing.xs),
        color = color,
        thickness = 1.dp
    )
}

/**
 * 卡片内容区
 */
@Composable
fun GitHubCardContent(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    androidx.compose.foundation.layout.Box(
        modifier = modifier.padding(vertical = GitHubSpacing.xs)
    ) {
        content()
    }
}

/**
 * 卡片底部操作区
 */
@Composable
fun GitHubCardActions(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    androidx.compose.foundation.layout.Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = GitHubSpacing.sm),
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.End
    ) {
        content()
    }
}
