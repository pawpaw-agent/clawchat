package ai.openclaw.android.presentation.screen

import ai.openclaw.android.domain.model.ChannelConnectionStatus
import ai.openclaw.android.domain.model.ChannelStatus
import ai.openclaw.android.presentation.viewmodel.ChannelListViewModel
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChannelListScreen(
    viewModel: ChannelListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showQrDialog by remember { mutableStateOf(false) }
    var selectedChannel by remember { mutableStateOf<String?>(null) }
    
    LaunchedEffect(uiState.selectedQrCode) {
        if (uiState.selectedQrCode != null) {
            showQrDialog = true
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Channels") },
                actions = {
                    IconButton(onClick = { viewModel.syncChannels() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            if (uiState.isLoading && uiState.channels.isEmpty()) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (uiState.channels.isEmpty()) {
                Column(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        Icons.Default.LinkOff,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.outline
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("No channels configured", color = MaterialTheme.colorScheme.outline)
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(vertical = 8.dp)
                ) {
                    items(uiState.channels, key = { it.channel }) { channel ->
                        ChannelItem(
                            channel = channel,
                            onQrClick = {
                                selectedChannel = channel.channel
                                viewModel.getQrCode(channel.channel)
                            },
                            onDisconnect = { viewModel.disconnect(channel.channel) },
                            onReconnect = { viewModel.reconnect(channel.channel) }
                        )
                    }
                }
            }
            
            if (uiState.isRefreshing) {
                LinearProgressIndicator(
                    modifier = Modifier
                        .fillMaxWidth()
                        .align(Alignment.TopCenter)
                )
            }
        }
    }
    
    // QR Code Dialog
    if (showQrDialog && uiState.selectedQrCode != null) {
        AlertDialog(
            onDismissRequest = {
                showQrDialog = false
                viewModel.clearQrCode()
            },
            title = { Text("Scan QR Code") },
            text = {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        "Scan this QR code with your messaging app:",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    // QR code placeholder (would use QR renderer in production)
                    Card(
                        modifier = Modifier.size(200.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant
                        )
                    ) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "QR Code",
                                style = MaterialTheme.typography.labelLarge
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        selectedChannel ?: "",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.outline
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    showQrDialog = false
                    viewModel.clearQrCode()
                }) {
                    Text("Done")
                }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChannelItem(
    channel: ChannelStatus,
    onQrClick: () -> Unit,
    onDisconnect: () -> Unit,
    onReconnect: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                StatusIndicator(channel.status)
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = channel.label ?: channel.channel,
                        style = MaterialTheme.typography.titleMedium
                    )
                    channel.provider?.let { provider ->
                        Text(
                            text = provider,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.outline
                        )
                    }
                }
                
                SuggestionChip(
                    onClick = {},
                    label = { Text(channel.channel) },
                    modifier = Modifier.height(28.dp)
                )
            }
            
            channel.error?.let { error ->
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = error,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (channel.status == ChannelConnectionStatus.NEEDS_QR) {
                    Button(onClick = onQrClick) {
                        Icon(Icons.Default.QrCode, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Show QR")
                    }
                } else if (channel.status == ChannelConnectionStatus.CONNECTED) {
                    OutlinedButton(onClick = onDisconnect) {
                        Icon(Icons.Default.LinkOff, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Disconnect")
                    }
                } else {
                    Button(onClick = onReconnect) {
                        Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Reconnect")
                    }
                }
            }
        }
    }
}

@Composable
private fun StatusIndicator(status: ChannelConnectionStatus) {
    val color = when (status) {
        ChannelConnectionStatus.CONNECTED -> Color(0xFF4CAF50)
        ChannelConnectionStatus.CONNECTING -> Color(0xFFFFC107)
        ChannelConnectionStatus.ERROR -> Color(0xFFF44336)
        ChannelConnectionStatus.NEEDS_QR, ChannelConnectionStatus.NEEDS_LOGIN -> Color(0xFFFF9800)
        ChannelConnectionStatus.DISCONNECTED -> Color(0xFF9E9E9E)
    }
    
    Surface(
        modifier = Modifier.size(12.dp),
        shape = MaterialTheme.shapes.small,
        color = color
    ) {}
}