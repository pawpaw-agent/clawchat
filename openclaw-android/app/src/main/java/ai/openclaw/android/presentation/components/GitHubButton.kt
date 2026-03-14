package ai.openclaw.android.presentation.components

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import ai.openclaw.android.presentation.theme.GitHubSizes
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.theme.GitHubBlue500
import ai.openclaw.android.presentation.theme.GitHubBlue400
import ai.openclaw.android.presentation.theme.GitHubRed600
import ai.openclaw.android.presentation.theme.GitHubRed500
import ai.openclaw.android.presentation.theme.GitHubBgSubtleDark
import ai.openclaw.android.presentation.theme.GitHubBgSubtleLight

/**
 * GitHub 风格按钮组件
 * 
 * 特征:
 * - 固定高度 40dp
 * - 小圆角 6dp
 * - 4dp 网格内边距
 * - 多种变体 (Primary/Secondary/Danger/Ghost)
 */

enum class GitHubButtonVariant {
    PRIMARY,
    SECONDARY,
    DANGER,
    GHOST
}

@Composable
fun GitHubButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    variant: GitHubButtonVariant = GitHubButtonVariant.PRIMARY,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null
) {
    val contentColor = when (variant) {
        GitHubButtonVariant.PRIMARY -> Color.White
        GitHubButtonVariant.SECONDARY -> MaterialTheme.colorScheme.onSurface
        GitHubButtonVariant.DANGER -> Color.White
        GitHubButtonVariant.GHOST -> GitHubBlue500
    }
    
    val containerColor = when (variant) {
        GitHubButtonVariant.PRIMARY -> GitHubBlue500
        GitHubButtonVariant.SECONDARY -> MaterialTheme.colorScheme.surfaceVariant
        GitHubButtonVariant.DANGER -> GitHubRed600
        GitHubButtonVariant.GHOST -> Color.Transparent
    }
    
    val disabledContainerColor = when (variant) {
        GitHubButtonVariant.PRIMARY -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
        GitHubButtonVariant.SECONDARY -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)
        GitHubButtonVariant.DANGER -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
        GitHubButtonVariant.GHOST -> Color.Transparent
    }
    
    val disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
    
    when (variant) {
        GitHubButtonVariant.GHOST -> {
            TextButton(
                onClick = onClick,
                modifier = modifier.height(GitHubSizes.buttonHeight),
                enabled = enabled && !isLoading,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = if (enabled) contentColor else disabledContentColor,
                    disabledContentColor = disabledContentColor
                ),
                shape = RoundedCornerShape(GitHubSizes.buttonRadius),
                contentPadding = PaddingValues(horizontal = GitHubSpacing.md, vertical = GitHubSpacing.xs)
            ) {
                ButtonContent(isLoading, leadingIcon, trailingIcon, text)
            }
        }
        GitHubButtonVariant.SECONDARY -> {
            OutlinedButton(
                onClick = onClick,
                modifier = modifier.height(GitHubSizes.buttonHeight),
                enabled = enabled && !isLoading,
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = if (enabled) contentColor else disabledContentColor,
                    disabledContentColor = disabledContentColor,
                    disabledBorderColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
                ),
                shape = RoundedCornerShape(GitHubSizes.buttonRadius),
                contentPadding = PaddingValues(horizontal = GitHubSpacing.md, vertical = GitHubSpacing.xs)
            ) {
                ButtonContent(isLoading, leadingIcon, trailingIcon, text)
            }
        }
        else -> {
            Button(
                onClick = onClick,
                modifier = modifier.height(GitHubSizes.buttonHeight),
                enabled = enabled && !isLoading,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (enabled) containerColor else disabledContainerColor,
                    contentColor = if (enabled) contentColor else disabledContentColor,
                    disabledContainerColor = disabledContainerColor,
                    disabledContentColor = disabledContentColor
                ),
                shape = RoundedCornerShape(GitHubSizes.buttonRadius),
                contentPadding = PaddingValues(horizontal = GitHubSpacing.md, vertical = GitHubSpacing.xs)
            ) {
                ButtonContent(isLoading, leadingIcon, trailingIcon, text)
            }
        }
    }
}

@Composable
private fun ButtonContent(
    isLoading: Boolean,
    leadingIcon: @Composable (() -> Unit)?,
    trailingIcon: @Composable (() -> Unit)?,
    text: String
) {
    if (isLoading) {
        CircularProgressIndicator(
            modifier = Modifier.size(GitHubSizes.iconMd),
            strokeWidth = 2.dp,
            color = MaterialTheme.colorScheme.onPrimary
        )
    } else {
        leadingIcon?.let {
            it()
        }
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier
                .then(if (leadingIcon != null) Modifier else Modifier)
        )
        trailingIcon?.let {
            it()
        }
    }
}

/**
 * 快捷按钮变体
 */
@Composable
fun GitHubPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false
) {
    GitHubButton(
        text = text,
        onClick = onClick,
        modifier = modifier,
        variant = GitHubButtonVariant.PRIMARY,
        enabled = enabled,
        isLoading = isLoading
    )
}

@Composable
fun GitHubSecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false
) {
    GitHubButton(
        text = text,
        onClick = onClick,
        modifier = modifier,
        variant = GitHubButtonVariant.SECONDARY,
        enabled = enabled,
        isLoading = isLoading
    )
}

@Composable
fun GitHubDangerButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false
) {
    GitHubButton(
        text = text,
        onClick = onClick,
        modifier = modifier,
        variant = GitHubButtonVariant.DANGER,
        enabled = enabled,
        isLoading = isLoading
    )
}

@Composable
fun GitHubGhostButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false
) {
    GitHubButton(
        text = text,
        onClick = onClick,
        modifier = modifier,
        variant = GitHubButtonVariant.GHOST,
        enabled = enabled,
        isLoading = isLoading
    )
}
