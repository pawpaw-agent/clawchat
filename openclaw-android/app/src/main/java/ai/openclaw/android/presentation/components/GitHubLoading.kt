package ai.openclaw.android.presentation.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.theme.GitHubSizes

/**
 * GitHub 风格加载组件
 * 
 * 包含:
 * - 加载指示器 (CircularProgressIndicator)
 * - 骨架屏 (Skeleton)
 */

/**
 * 标准加载指示器
 */
@Composable
fun GitHubLoadingIndicator(
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.primary,
    strokeWidth: Float = 3f
) {
    CircularProgressIndicator(
        modifier = modifier.size(48.dp),
        color = color,
        strokeWidth = strokeWidth.dp
    )
}

/**
 * 小尺寸加载指示器
 */
@Composable
fun GitHubLoadingIndicatorSmall(
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.primary
) {
    CircularProgressIndicator(
        modifier = modifier.size(24.dp),
        color = color,
        strokeWidth = 2.dp
    )
}

/**
 * 全屏幕加载
 */
@Composable
fun GitHubFullScreenLoading(
    modifier: Modifier = Modifier,
    message: String? = null
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(GitHubSpacing.md)
        ) {
            GitHubLoadingIndicator()
            message?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * 骨架屏 - 基础组件
 */
@Composable
fun SkeletonBlock(
    modifier: Modifier = Modifier,
    height: Float = 16f,
    width: Float = 100f,
    shape: RoundedCornerShape = RoundedCornerShape(4.dp)
) {
    val infiniteTransition = rememberInfiniteTransition(label = "skeleton")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.8f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "skeletonAlpha"
    )
    
    Box(
        modifier = modifier
            .width(width.dp)
            .height(height.dp)
            .clip(shape)
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = alpha))
    )
}

/**
 * 骨架屏 - 文本行
 */
@Composable
fun SkeletonTextLine(
    modifier: Modifier = Modifier,
    widthPercent: Float = 100f
) {
    SkeletonBlock(
        modifier = modifier.fillMaxWidth(widthPercent / 100f),
        height = 16f
    )
}

/**
 * 骨架屏 - 列表项
 */
@Composable
fun SkeletonListItem(
    modifier: Modifier = Modifier,
    showAvatar: Boolean = true,
    showTitle: Boolean = true,
    showSubtitle: Boolean = true,
    showDescription: Boolean = false
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(GitHubSpacing.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (showAvatar) {
            SkeletonBlock(
                modifier = Modifier.size(GitHubSizes.avatarMd),
                shape = RoundedCornerShape(GitHubSizes.badgeRadius)
            )
            Spacer(modifier = Modifier.width(GitHubSpacing.sm))
        }
        
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(GitHubSpacing.xs)
        ) {
            if (showTitle) {
                SkeletonTextLine(widthPercent = 60f)
            }
            if (showSubtitle) {
                SkeletonTextLine(widthPercent = 40f)
            }
            if (showDescription) {
                SkeletonTextLine(widthPercent = 80f)
            }
        }
    }
}

/**
 * 骨架屏 - 卡片
 */
@Composable
fun SkeletonCard(
    modifier: Modifier = Modifier,
    showHeader: Boolean = true,
    showContent: Boolean = true,
    showActions: Boolean = false
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(GitHubSpacing.md)
            .clip(RoundedCornerShape(GitHubSizes.cardRadius))
            .background(MaterialTheme.colorScheme.surface)
            .padding(GitHubSpacing.cardPadding),
        verticalArrangement = Arrangement.spacedBy(GitHubSpacing.sm)
    ) {
        if (showHeader) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                SkeletonTextLine(widthPercent = 50f)
                SkeletonBlock(
                    modifier = Modifier.size(24.dp),
                    shape = RoundedCornerShape(GitHubSizes.badgeRadius)
                )
            }
        }
        
        if (showContent) {
            SkeletonTextLine(widthPercent = 100f)
            SkeletonTextLine(widthPercent = 90f)
            SkeletonTextLine(widthPercent = 70f)
        }
        
        if (showActions) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End,
                verticalAlignment = Alignment.CenterVertically
            ) {
                SkeletonBlock(
                    modifier = Modifier
                        .height(GitHubSizes.buttonHeight)
                        .width(80.dp),
                    shape = RoundedCornerShape(GitHubSizes.buttonRadius)
                )
            }
        }
    }
}

/**
 * 骨架屏 - 列表
 */
@Composable
fun SkeletonList(
    modifier: Modifier = Modifier,
    itemCount: Int = 5,
    showAvatar: Boolean = true,
    showSubtitle: Boolean = true,
    showDescription: Boolean = false
) {
    LazyColumn(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(1.dp)
    ) {
        items(itemCount) { index ->
            SkeletonListItem(
                showAvatar = showAvatar,
                showSubtitle = showSubtitle,
                showDescription = showDescription
            )
            if (index < itemCount - 1) {
                androidx.compose.material3.Divider(
                    color = MaterialTheme.colorScheme.outlineVariant,
                    thickness = 1.dp
                )
            }
        }
    }
}

/**
 * 骨架屏 - 卡片列表
 */
@Composable
fun SkeletonCardList(
    modifier: Modifier = Modifier,
    itemCount: Int = 3
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(GitHubSpacing.md)
    ) {
        repeat(itemCount) {
            SkeletonCard()
        }
    }
}
