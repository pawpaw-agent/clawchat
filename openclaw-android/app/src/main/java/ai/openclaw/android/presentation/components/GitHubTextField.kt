package ai.openclaw.android.presentation.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import ai.openclaw.android.presentation.theme.GitHubSizes
import ai.openclaw.android.presentation.theme.GitHubBlue500
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.theme.GitHubRed600

/**
 * GitHub 风格输入框组件
 * 
 * 特征:
 * - 固定高度 40dp
 * - 6dp 圆角
 * - 聚焦时蓝色边框
 * - 支持前缀/后缀图标
 */

@Composable
fun GitHubTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    label: String? = null,
    placeholder: String? = null,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
    singleLine: Boolean = true,
    maxLines: Int = if (singleLine) 1 else Int.MAX_VALUE,
    enabled: Boolean = true,
    readOnly: Boolean = false,
    isError: Boolean = false,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    onSubmitted: ((String) -> Unit)? = null
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier
            .fillMaxWidth()
            .height(GitHubSizes.inputHeight),
        label = label?.let { { Text(it) } },
        placeholder = placeholder?.let { { Text(it) } },
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        singleLine = singleLine,
        maxLines = maxLines,
        enabled = enabled,
        readOnly = readOnly,
        isError = isError,
        visualTransformation = visualTransformation,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        onKeyEvent = { 
            if (it.nativeKeyEvent.action == android.view.KeyEvent.ACTION_DOWN &&
                it.nativeKeyEvent.keyCode == android.view.KeyEvent.KEYCODE_ENTER) {
                onSubmitted?.invoke(value)
                true
            } else {
                false
            }
        },
        shape = RoundedCornerShape(GitHubSizes.buttonRadius),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = if (isError) GitHubRed600 else GitHubBlue500,
            unfocusedBorderColor = MaterialTheme.colorScheme.outline,
            focusedLabelColor = if (isError) GitHubRed600 else GitHubBlue500,
            unfocusedLabelColor = MaterialTheme.colorScheme.onSurfaceVariant,
            focusedLeadingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
            unfocusedLeadingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
            focusedTrailingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
            unfocusedTrailingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
            focusedPlaceholderColor = MaterialTheme.colorScheme.onSurfaceVariant,
            unfocusedPlaceholderColor = MaterialTheme.colorScheme.onSurfaceVariant,
            focusedTextColor = MaterialTheme.colorScheme.onSurface,
            unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
            disabledTextColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f),
            disabledBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.38f),
            disabledLabelColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f),
            disabledPlaceholderColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f),
            errorBorderColor = GitHubRed600,
            errorLabelColor = GitHubRed600,
            errorPlaceholderColor = GitHubRed600,
            errorLeadingIconColor = GitHubRed600,
            errorTrailingIconColor = GitHubRed600,
            errorTextColor = MaterialTheme.colorScheme.onErrorContainer,
            errorContainerColor = MaterialTheme.colorScheme.errorContainer,
            focusedContainerColor = MaterialTheme.colorScheme.surface,
            unfocusedContainerColor = MaterialTheme.colorScheme.surface
        ),
        textStyle = LocalTextStyle.current.copy(
            fontSize = androidx.compose.ui.unit.TextUnit.Unspecified,
            style = MaterialTheme.typography.bodyLarge
        )
    )
}

/**
 * 搜索输入框 (GitHub 风格)
 */
@Composable
fun GitHubSearchField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "Search...",
    onSearch: (String) -> Unit = {}
) {
    GitHubTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier,
        placeholder = placeholder,
        leadingIcon = {
            Icon(
                imageVector = androidx.compose.material.icons.Icons.Outlined.Search,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        },
        singleLine = true,
        onSubmitted = onSearch
    )
}
