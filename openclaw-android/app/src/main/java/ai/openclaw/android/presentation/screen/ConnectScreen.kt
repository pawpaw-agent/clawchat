package ai.openclaw.android.presentation.screen

import ai.openclaw.android.R
import ai.openclaw.android.core.network.ConnectionState
import ai.openclaw.android.presentation.components.GitHubButton
import ai.openclaw.android.presentation.components.GitHubButtonVariant
import ai.openclaw.android.presentation.components.GitHubCard
import ai.openclaw.android.presentation.components.GitHubCardHeader
import ai.openclaw.android.presentation.components.GitHubTextField
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.viewmodel.ConnectViewModel
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConnectScreen(
    onNavigateToPairing: (String) -> Unit,
    onNavigateToSessions: () -> Unit = {},
    viewModel: ConnectViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // 处理配对导航
    LaunchedEffect(uiState.pairingRequestId) {
        uiState.pairingRequestId?.let { requestId ->
            onNavigateToPairing(requestId)
        }
    }
    
    // 处理连接成功导航
    LaunchedEffect(uiState.isConnected) {
        if (uiState.isConnected) {
            onNavigateToSessions()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.connect_title)) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(GitHubSpacing.md)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(GitHubSpacing.md)
        ) {
            // Logo / 标题
            Icon(
                imageVector = Icons.Default.Cloud,
                contentDescription = null,
                modifier = Modifier.size(80.dp),
                tint = MaterialTheme.colorScheme.primary
            )

            Text(
                text = stringResource(R.string.connect_to_gateway),
                style = MaterialTheme.typography.headlineMedium
            )

            Spacer(modifier = Modifier.height(GitHubSpacing.xs))

            // 连接状态指示
            ConnectionStatusCard(
                connectionState = uiState.connectionState,
                isConnected = uiState.isConnected
            )

            // Gateway URL 输入
            GitHubTextField(
                value = uiState.gatewayUrl,
                onValueChange = { viewModel.updateGatewayUrl(it) },
                label = stringResource(R.string.connect_gateway_url),
                placeholder = "ws://192.168.1.100:3000/ws",
                enabled = !uiState.isConnecting && !uiState.isConnected,
                leadingIcon = {
                    Icon(Icons.Default.Link, contentDescription = null)
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri)
            )

            // Token 输入（可选）
            var tokenVisible by remember { mutableStateOf(false) }
            GitHubTextField(
                value = uiState.token,
                onValueChange = { viewModel.updateToken(it) },
                label = stringResource(R.string.connect_token),
                placeholder = stringResource(R.string.connect_token_hint),
                enabled = !uiState.isConnecting && !uiState.isConnected,
                visualTransformation = if (tokenVisible) VisualTransformation.None else PasswordVisualTransformation(),
                leadingIcon = {
                    Icon(Icons.Default.Key, contentDescription = null)
                },
                trailingIcon = {
                    IconButton(onClick = { tokenVisible = !tokenVisible }) {
                        Icon(
                            imageVector = if (tokenVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                            contentDescription = stringResource(if (tokenVisible) R.string.connect_hide_token else R.string.connect_show_token)
                        )
                    }
                }
            )

            // 错误信息
            uiState.errorMessage?.let { error ->
                GitHubCard(
                    backgroundColor = MaterialTheme.colorScheme.errorContainer
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Error,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.width(GitHubSpacing.xs))
                        Text(
                            text = error,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.weight(1f)
                        )
                        IconButton(onClick = { viewModel.clearError() }) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = stringResource(R.string.connect_dismiss),
                                tint = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                }
            }

            // 操作按钮
            if (uiState.isConnected) {
                GitHubButton(
                    text = stringResource(R.string.connect_disconnect),
                    onClick = { viewModel.disconnect() },
                    modifier = Modifier.fillMaxWidth(),
                    variant = GitHubButtonVariant.DANGER,
                    leadingIcon = {
                        Icon(Icons.Default.LinkOff, contentDescription = null)
                    }
                )
            } else {
                GitHubButton(
                    text = if (uiState.isConnecting) stringResource(R.string.connect_connecting) else stringResource(R.string.connect_button),
                    onClick = { viewModel.connect() },
                    modifier = Modifier.fillMaxWidth(),
                    variant = GitHubButtonVariant.PRIMARY,
                    enabled = !uiState.isConnecting && uiState.gatewayUrl.isNotBlank(),
                    isLoading = uiState.isConnecting,
                    leadingIcon = if (!uiState.isConnecting) {
                        { Icon(Icons.Default.Link, contentDescription = null) }
                    } else null
                )
            }

            // 连接成功信息
            uiState.helloOk?.let { helloOk ->
                GitHubCard {
                    GitHubCardHeader(
                        title = stringResource(R.string.connect_status_connected),
                        trailingContent = {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    )
                    Spacer(modifier = Modifier.height(GitHubSpacing.xs))
                    Text(
                        text = "${stringResource(R.string.connect_protocol)} ${helloOk.protocol}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    helloOk.auth?.deviceToken?.let {
                        Spacer(modifier = Modifier.height(GitHubSpacing.xxs))
                        Text(
                            text = stringResource(R.string.connect_device_token_received),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(GitHubSpacing.xl))

            // 帮助信息
            Text(
                text = stringResource(R.string.connect_help),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ConnectionStatusCard(
    connectionState: ConnectionState?,
    isConnected: Boolean
) {
    val (statusText, statusColor, icon) = when (connectionState) {
        is ConnectionState.Disconnected -> Triple(stringResource(R.string.connect_status_disconnected), MaterialTheme.colorScheme.outline, Icons.Default.CloudOff)
        is ConnectionState.Connecting -> Triple(stringResource(R.string.connect_connecting), MaterialTheme.colorScheme.tertiary, Icons.Default.CloudSync)
        is ConnectionState.ChallengeReceived -> Triple(stringResource(R.string.dashboard_authenticating), MaterialTheme.colorScheme.tertiary, Icons.Default.Key)
        is ConnectionState.Authenticating -> Triple(stringResource(R.string.dashboard_authenticating), MaterialTheme.colorScheme.tertiary, Icons.Default.Key)
        is ConnectionState.Connected -> Triple(stringResource(R.string.connect_status_connected), MaterialTheme.colorScheme.primary, Icons.Default.CloudDone)
        is ConnectionState.Error -> Triple(stringResource(R.string.connect_status_error), MaterialTheme.colorScheme.error, Icons.Default.Error)
        null -> Triple(stringResource(R.string.connect_status_ready), MaterialTheme.colorScheme.outline, Icons.Default.Cloud)
    }

    GitHubCard {
        Row(
            modifier = Modifier
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = statusColor
            )
            Spacer(modifier = Modifier.width(GitHubSpacing.xs))
            Text(
                text = statusText,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
