package ai.openclaw.android.presentation.theme

import androidx.compose.ui.graphics.Color

/**
 * GitHub Primer 颜色系统
 * 参考：https://primer.style/primitives/colors
 */

// ==================== 主色调 (Accent Colors) ====================

// Blue - 主要交互色
val GitHubBlue500 = Color(0xFF0969DA)  // Light mode accent
val GitHubBlue400 = Color(0xFF2F81F7)  // Dark mode accent
val GitHubBlue300 = Color(0xFF58A6FF)  // Hover state

// Green - 成功状态
val GitHubGreen600 = Color(0xFF1A7F37) // Light mode success
val GitHubGreen500 = Color(0xFF3FB950) // Dark mode success
val GitHubGreen400 = Color(0xFF4AC260) // Hover state

// Red - 危险/错误
val GitHubRed600 = Color(0xFFD1242F)   // Light mode danger
val GitHubRed500 = Color(0xFFF85149)   // Dark mode danger
val GitHubRed400 = Color(0xFFFF6A61)   // Hover state

// Purple - 强调色 (Copilot 等)
val GitHubPurple500 = Color(0xFF8250DF) // Light mode accent
val GitHubPurple400 = Color(0xFFA371F7) // Dark mode accent

// Yellow - 警告
val GitHubYellow600 = Color(0xFF9A6700) // Light mode warning
val GitHubYellow500 = Color(0xFFD29922) // Dark mode warning

// Coral - 特殊强调
val GitHubCoral500 = Color(0xFFDB6D28)
val GitHubCoral400 = Color(0xFFF78166)

// ==================== 背景色 (Background Colors) ====================

// Light mode backgrounds
val GitHubBgDefaultLight = Color(0xFFFFFFFF)
val GitHubBgSubtleLight = Color(0xFFF6F8FA)
val GitHubBgMutedLight = Color(0xFFF3F4F6)

// Dark mode backgrounds (Dark Dimmed)
val GitHubBgDefaultDark = Color(0xFF0D1117)
val GitHubBgSubtleDark = Color(0xFF161B22)
val GitHubBgMutedDark = Color(0xFF21262D)
val GitHubBgElevatedDark = Color(0xFF21262D)

// ==================== 边框色 (Border Colors) ====================

// Light mode borders
val GitHubBorderDefaultLight = Color(0xFFD0D7DE)
val GitHubBorderMutedLight = Color(0xFFDFE1E5)
val GitHubBorderSubtleLight = Color(0xFFEAECEF)

// Dark mode borders
val GitHubBorderDefaultDark = Color(0xFF30363D)
val GitHubBorderMutedDark = Color(0xFF21262D)
val GitHubBorderSubtleDark = Color(0xFF30363D)

// ==================== 文字颜色 (Text Colors) ====================

// Light mode text
val GitHubTextDefaultLight = Color(0xFF1F2328)
val GitHubTextMutedLight = Color(0xFF656D76)
val GitHubTextSubtleLight = Color(0xFF8C959F)

// Dark mode text
val GitHubTextDefaultDark = Color(0xFFE6EDF3)
val GitHubTextMutedDark = Color(0xFF8D96A0)
val GitHubTextSubtleDark = Color(0xFF6E7681)

// ==================== 功能色 (Functional Colors) ====================

// 链接颜色
val GitHubLinkLight = Color(0xFF0969DA)
val GitHubLinkDark = Color(0xFF4493F8)

// 代码块背景
val GitHubCodeBgLight = Color(0xFFF6F8FA)
val GitHubCodeBgDark = Color(0xFF161B22)

// 选中态
val GitHubSelectedLight = Color(0xFF0969DA)
val GitHubSelectedDark = Color(0xFF1F6FEB)

// ==================== 状态色 (Status Colors) ====================

// Open/Merged 状态
val GitHubStatusOpen = Color(0xFF3FB950)
val GitHubStatusClosed = Color(0xFFF85149)
val GitHubStatusMerged = Color(0xFFA371F7)
val GitHubStatusDraft = Color(0xFF8B949E)

// 风险等级
val GitHubRiskHigh = Color(0xFFDA3633)
val GitHubRiskMedium = Color(0xFFD29922)
val GitHubRiskLow = Color(0xFF238636)
