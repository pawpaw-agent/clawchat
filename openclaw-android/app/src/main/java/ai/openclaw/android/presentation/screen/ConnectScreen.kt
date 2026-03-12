package ai.openclaw.android.presentation.screen

import ai.openclaw.android.R
import ai.openclaw.android.core.network.ConnectionState
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
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
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

            Spacer(modifier = Modifier.height(8.dp))

            // 连接状态指示
            ConnectionStatusCard(
                connectionState = uiState.connectionState,
                isConnected = uiState.isConnected
            )

            // Gateway URL 输入
            OutlinedTextField(
                value = uiState.gatewayUrl,
                onValueChange = { viewModel.updateGatewayUrl(it) },
                label = { Text(stringResource(R.string.connect_gateway_url)) },
                placeholder = { Text("ws://192.168.1.100:3000/ws") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                enabled = !uiState.isConnecting && !uiState.isConnected,
                leadingIcon = {
                    Icon(Icons.Default.Link, contentDescription = null)
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri)
            )

            // Token 输入（可选）
            var tokenVisible by remember { mutableStateOf(false) }
            OutlinedTextField(
                value = uiState.token,
                onValueChange = { viewModel.updateToken(it) },
                label = { Text(stringResource(R.string.connect_token)) },
                placeholder = { Text(stringResource(R.string.connect_token_hint)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
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
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Error,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.width(8.dp))
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
                Button(
                    onClick = { viewModel.disconnect() },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Icon(Icons.Default.LinkOff, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(stringResource(R.string.connect_disconnect))
                }
            } else {
                Button(
                    onClick = { viewModel.connect() },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !uiState.isConnecting && uiState.gatewayUrl.isNotBlank()
                ) {
                    if (uiState.isConnecting) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(R.string.connect_connecting))
                    } else {
                        Icon(Icons.Default.Link, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(R.string.connect_button))
                    }
                }
            }

            // 连接成功信息
            uiState.helloOk?.let { helloOk ->
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = stringResource(R.string.connect_status_connected),
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "${stringResource(R.string.connect_protocol)} ${helloOk.protocol}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        helloOk.auth?.deviceToken?.let {
                            Text(
                                text = stringResource(R.string.connect_device_token_received),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // 帮助信息
            Text(
                text = stringResource(R.string.connect_help),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
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

    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = statusColor
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = statusText,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}