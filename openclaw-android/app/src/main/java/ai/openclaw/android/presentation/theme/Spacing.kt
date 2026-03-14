package ai.openclaw.android.presentation.theme

import androidx.compose.ui.unit.dp

/**
 * GitHub 间距系统
 * 基于 4dp 网格，确保视觉节奏统一
 */

object GitHubSpacing {
    // 极小间距
    val xxxs = 2.dp
    
    // 微小间距 (4dp 基准)
    val xxs = 4.dp
    
    // 小间距
    val xs = 8.dp
    
    // 中小间距
    val sm = 12.dp
    
    // 标准间距
    val md = 16.dp
    
    // 大间距
    val lg = 24.dp
    
    // 超大间距
    val xl = 32.dp
    
    // 极大间距
    val xxl = 48.dp
    
    // 特大间距
    val xxxl = 64.dp
}

/**
 * 常用间距组合
 */
object GitHubSpacingPresets {
    // 按钮内边距
    val buttonPadding = GitHubSpacing.sm
    
    // 卡片内边距
    val cardPadding = GitHubSpacing.md
    
    // 列表项内边距
    val listItemPadding = GitHubSpacing.sm
    
    // 页面边距
    val pageMargin = GitHubSpacing.md
    
    // 紧凑间距 (用于密集列表)
    val compact = GitHubSpacing.xs
    
    // 宽松间距 (用于内容分区)
    val relaxed = GitHubSpacing.lg
}

/**
 * 组件尺寸基准
 * - 按钮高度：40dp
 * - 输入框高度：40dp
 * - 徽章高度：20dp
 * - 头像尺寸：20/24/32/40dp
 */
object GitHubSizes {
    // 按钮高度
    val buttonHeight = 40.dp
    val buttonHeightSmall = 32.dp
    val buttonHeightLarge = 48.dp
    
    // 输入框高度
    val inputHeight = 40.dp
    
    // 徽章尺寸
    val badgeHeight = 20.dp
    val badgeHeightSmall = 16.dp
    
    // 头像尺寸
    val avatarXs = 20.dp
    val avatarSm = 24.dp
    val avatarMd = 32.dp
    val avatarLg = 40.dp
    val avatarXl = 48.dp
    
    // 图标尺寸
    val iconSm = 16.dp
    val iconMd = 20.dp
    val iconLg = 24.dp
    
    // 卡片圆角
    val cardRadius = 6.dp
    
    // 按钮圆角
    val buttonRadius = 6.dp
    
    // 徽章圆角 (完全圆角)
    val badgeRadius = 20.dp
}
