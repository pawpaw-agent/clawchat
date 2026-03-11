package ai.openclaw.android.presentation.screen

import ai.openclaw.android.data.repository.PairingState
import ai.openclaw.android.presentation.viewmodel.PairingViewModel
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PairingScreen(
    requestId: String,
    onNavigateBack: () -> Unit,
    viewModel: PairingViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(requestId) {
        viewModel.initialize(requestId)
    }

    // 处理配对成功
    LaunchedEffect(uiState.isApproved) {
        if (uiState.isApproved) {
            kotlinx.coroutines.delay(2000)
            onNavigateBack()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Device Pairing") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
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
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // 状态图标
            when (uiState.pairingState) {
                is PairingState.Waiting -> {
                    Icon(
                        imageVector = Icons.Default.Devices,
                        contentDescription = null,
                        modifier = Modifier.size(100.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
                is PairingState.Approved -> {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        modifier = Modifier.size(100.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
                is PairingState.Rejected -> {
                    Icon(
                        imageVector = Icons.Default.Cancel,
                        contentDescription = null,
                        modifier = Modifier.size(100.dp),
                        tint = MaterialTheme.colorScheme.error
                    )
                }
                is PairingState.Error -> {
                    Icon(
                        imageVector = Icons.Default.Error,
                        contentDescription = null,
                        modifier = Modifier.size(100.dp),
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }

            // 标题
            Text(
                text = when (uiState.pairingState) {
                    is PairingState.Waiting -> "Waiting for Approval"
                    is PairingState.Approved -> "Device Paired!"
                    is PairingState.Rejected -> "Pairing Rejected"
                    is PairingState.Error -> "Pairing Failed"
                },
                style = MaterialTheme.typography.headlineMedium
            )

            // 说明文字
            Text(
                text = when (uiState.pairingState) {
                    is PairingState.Waiting -> "Please approve this device on your Gateway CLI to continue."
                    is PairingState.Approved -> "Your device has been successfully paired with the Gateway."
                    is PairingState.Rejected -> "The pairing request was rejected. Please try again."
                    is PairingState.Error -> (uiState.pairingState as PairingState.Error).message
                },
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )

            // 配对码显示
            if (uiState.pairingState is PairingState.Waiting && uiState.pairingCode.isNotEmpty()) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Pairing Code",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = uiState.pairingCode,
                            style = MaterialTheme.typography.displayMedium,
                            fontFamily = FontFamily.Monospace,
                            color = MaterialTheme.colorScheme.onSecondaryContainer
                        )
                    }
                }

                // CLI 命令提示
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Run this command on your Gateway:",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "openclaw device approve ${uiState.pairingCode}",
                            style = MaterialTheme.typography.bodyMedium,
                            fontFamily = FontFamily.Monospace,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            // Request ID
            if (uiState.requestId.isNotEmpty()) {
                Text(
                    text = "Request ID: ${uiState.requestId.take(8)}...",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                )
            }

            // 重试按钮
            if (uiState.pairingState is PairingState.Rejected || 
                uiState.pairingState is PairingState.Error) {
                Button(
                    onClick = { viewModel.retry() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Default.Refresh, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Retry Pairing")
                }
            }

            // 加载指示器
            if (uiState.pairingState is PairingState.Waiting) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Waiting for approval...",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                }
            }

            // 成功指示器
            if (uiState.isApproved) {
                LinearProgressIndicator(
                    progress = { 1f },
                    modifier = Modifier.fillMaxWidth()
                )
                Text(
                    text = "Redirecting...",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}