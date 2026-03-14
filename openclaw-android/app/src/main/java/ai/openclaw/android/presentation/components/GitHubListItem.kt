package ai.openclaw.android.presentation.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.theme.GitHubBorderMutedLight
import ai.openclaw.android.presentation.theme.GitHubBorderMutedDark

/**
 * GitHub 风格列表项组件
 * 
 * 特征:
 * - 紧凑间距 (1dp 分割线)
 * - 12-16dp 内边距
 * - 高信息密度
 * - 支持 leading/trailing 内容
 */

@Composable
fun GitHubListItem(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    description: String? = null,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingContent: @Composable (() -> Unit)? = null,
    onClick: (() -> Unit)? = null,
    showDivider: Boolean = true
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier)
            .padding(horizontal = GitHubSpacing.md, vertical = GitHubSpacing.sm)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Leading icon
            leadingIcon?.let {
                it()
                Spacer(modifier = Modifier.width(GitHubSpacing.sm))
            }
            
            // Content
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = androidx.compose.ui.text.font.FontWeight.Medium,
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                
                subtitle?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = GitHubSpacing.xxs),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                
                description?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.padding(top = GitHubSpacing.xs),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            
            // Trailing content
            trailingContent?.let {
                Spacer(modifier = Modifier.width(GitHubSpacing.xs))
                it()
            }
        }
    }
    
    if (showDivider) {
        androidx.compose.material3.Divider(
            modifier = Modifier.fillMaxWidth(),
            color = MaterialTheme.colorScheme.outlineVariant,
            thickness = 1.dp
        )
    }
}

/**
 * 列表项图标
 */
@Composable
fun ListItemIcon(
    icon: ImageVector,
    modifier: Modifier = Modifier,
    tint: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurfaceVariant
) {
    Icon(
        imageVector = icon,
        contentDescription = null,
        modifier = modifier.size(20.dp),
        tint = tint
    )
}

/**
 * 列表项头像
 */
@Composable
fun ListItemAvatar(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    androidx.compose.foundation.layout.Box(
        modifier = modifier.size(32.dp),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}

/**
 * 仓库列表项 (GitHub 风格示例)
 */
@Composable
fun RepositoryListItem(
    name: String,
    description: String?,
    language: String?,
    languageColor: androidx.compose.ui.graphics.Color,
    stars: String,
    forks: String,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    GitHubListItem(
        title = name,
        description = description,
        modifier = modifier,
        onClick = onClick,
        trailingContent = {
            Row(
                horizontalArrangement = Arrangement.spacedBy(GitHubSpacing.lg)
            ) {
                // Language badge
                if (language != null) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        androidx.compose.foundation.layout.Box(
                            modifier = Modifier
                                .size(12.dp)
                                .background(languageColor, androidx.compose.foundation.shape.CircleShape)
                        )
                        Text(
                            text = language,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(start = GitHubSpacing.xxs)
                        )
                    }
                }
                
                // Stars
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = androidx.compose.material.icons.Icons.Outlined.Star,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = stars,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(start = GitHubSpacing.xxs)
                    )
                }
                
                // Forks
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = androidx.compose.material.icons.Icons.Outlined.ContentCopy,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = forks,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(start = GitHubSpacing.xxs)
                    )
                }
            }
        }
    )
}
