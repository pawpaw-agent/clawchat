package ai.openclaw.android.presentation.theme

import android.app.Application
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 主题模式
 */
enum class ThemeMode {
    LIGHT,
    DARK,
    SYSTEM
}

/**
 * 状态颜色（深色模式友好）
 */
object StatusColors {
    // 连接状态颜色
    val Connected = Color(0xFF4CAF50)
    val Connecting = Color(0xFFFFC107)
    val Error = Color(0xFFF44336)
    val Warning = Color(0xFFFF9800)
    val Disconnected = Color(0xFF9E9E9E)
    
    // 审批风险颜色
    val RiskHigh = Color(0xFFEF5350)
    val RiskMedium = Color(0xFFFFA726)
    val RiskLow = Color(0xFF66BB6A)
}

/**
 * 主题设置 ViewModel
 */
@HiltViewModel
class ThemeViewModel @Inject constructor(
    application: Application
) : AndroidViewModel(application) {
    
    private val _themeMode = MutableStateFlow(ThemeMode.SYSTEM)
    val themeMode: StateFlow<ThemeMode> = _themeMode.asStateFlow()
    
    fun setThemeMode(mode: ThemeMode) {
        viewModelScope.launch {
            _themeMode.value = mode
        }
    }
    
    fun isDarkTheme(systemInDarkTheme: Boolean): Boolean {
        return when (_themeMode.value) {
            ThemeMode.LIGHT -> false
            ThemeMode.DARK -> true
            ThemeMode.SYSTEM -> systemInDarkTheme
        }
    }
}

// ==================== GitHub 主题配色 ====================

/**
 * GitHub Dark Dimmed 配色方案
 * 深色背景使用 #0D1117 而非纯黑，降低视觉疲劳
 */
private val GitHubDarkColorScheme = darkColorScheme(
    // 主色调 - GitHub Blue
    primary = GitHubBlue400,
    onPrimary = Color.White,
    primaryContainer = GitHubBlue500,
    onPrimaryContainer = Color.White,
    
    // 次要色 - GitHub Purple
    secondary = GitHubPurple400,
    onSecondary = Color.White,
    secondaryContainer = GitHubPurple500,
    onSecondaryContainer = Color.White,
    
    // 第三色 - GitHub Green
    tertiary = GitHubGreen500,
    onTertiary = Color.White,
    tertiaryContainer = GitHubGreen600,
    onTertiaryContainer = Color.White,
    
    // 错误色 - GitHub Red
    error = GitHubRed500,
    onError = Color.White,
    errorContainer = GitHubRed600,
    onErrorContainer = Color.White,
    
    // 背景色 - Dark Dimmed
    background = GitHubBgDefaultDark,
    onBackground = GitHubTextDefaultDark,
    
    // 表面色
    surface = GitHubBgSubtleDark,
    onSurface = GitHubTextDefaultDark,
    surfaceVariant = GitHubBgMutedDark,
    onSurfaceVariant = GitHubTextMutedDark,
    
    // 边框/分割线
    outline = GitHubBorderDefaultDark,
    outlineVariant = GitHubBorderMutedDark,
    
    // 其他
    scrim = Color.Black,
    inverseSurface = GitHubTextDefaultDark,
    inverseOnSurface = GitHubBgDefaultDark,
    inversePrimary = GitHubBlue500,
    
    // 表面色调
    surfaceTint = GitHubBlue400,
    surfaceBright = GitHubBgElevatedDark,
    surfaceDim = GitHubBgDefaultDark,
    surfaceContainer = GitHubBgSubtleDark,
    surfaceContainerHigh = GitHubBgMutedDark,
    surfaceContainerHighest = GitHubBgElevatedDark,
    surfaceContainerLow = GitHubBgSubtleDark,
    surfaceContainerLowest = GitHubBgDefaultDark
)

/**
 * GitHub Light 配色方案
 */
private val GitHubLightColorScheme = lightColorScheme(
    // 主色调 - GitHub Blue
    primary = GitHubBlue500,
    onPrimary = Color.White,
    primaryContainer = GitHubBlue300,
    onPrimaryContainer = Color.White,
    
    // 次要色 - GitHub Purple
    secondary = GitHubPurple500,
    onSecondary = Color.White,
    secondaryContainer = GitHubPurple500,
    onSecondaryContainer = Color.White,
    
    // 第三色 - GitHub Green
    tertiary = GitHubGreen600,
    onTertiary = Color.White,
    tertiaryContainer = GitHubGreen500,
    onTertiaryContainer = Color.White,
    
    // 错误色 - GitHub Red
    error = GitHubRed600,
    onError = Color.White,
    errorContainer = GitHubRed500,
    onErrorContainer = Color.White,
    
    // 背景色 - 纯白
    background = GitHubBgDefaultLight,
    onBackground = GitHubTextDefaultLight,
    
    // 表面色
    surface = GitHubBgSubtleLight,
    onSurface = GitHubTextDefaultLight,
    surfaceVariant = GitHubBgMutedLight,
    onSurfaceVariant = GitHubTextMutedLight,
    
    // 边框/分割线
    outline = GitHubBorderDefaultLight,
    outlineVariant = GitHubBorderMutedLight,
    
    // 其他
    scrim = Color.Black,
    inverseSurface = GitHubTextDefaultLight,
    inverseOnSurface = GitHubBgDefaultLight,
    inversePrimary = GitHubBlue400,
    
    // 表面色调
    surfaceTint = GitHubBlue500,
    surfaceBright = GitHubBgDefaultLight,
    surfaceDim = GitHubBgSubtleLight,
    surfaceContainer = GitHubBgSubtleLight,
    surfaceContainerHigh = GitHubBgMutedLight,
    surfaceContainerHighest = GitHubBgMutedLight,
    surfaceContainerLow = GitHubBgSubtleLight,
    surfaceContainerLowest = GitHubBgDefaultLight
)

// GitHubTypography is imported from Type.kt

/**
 * OpenClaw 主题
 * 
 * @param darkTheme 系统深色模式状态
 * @param themeMode 主题模式 (LIGHT/DARK/SYSTEM)
 * @param content 内容
 */
@Composable
fun OpenClawTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    themeMode: ThemeMode = ThemeMode.SYSTEM,
    content: @Composable () -> Unit
) {
    // 根据主题模式决定是否使用深色
    val isDark = when (themeMode) {
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
        ThemeMode.SYSTEM -> darkTheme
    }
    
    // 选择配色方案
    val colorScheme = if (isDark) GitHubDarkColorScheme else GitHubLightColorScheme

    // 状态栏适配
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? android.app.Activity)?.window ?: return@SideEffect
            window.statusBarColor = colorScheme.surface.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !isDark
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = GitHubTypography,
        content = content
    )
}
