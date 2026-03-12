package ai.openclaw.android.presentation.screen

import ai.openclaw.android.core.network.ConnectionState
import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.data.repository.ApprovalRepository
import ai.openclaw.android.data.repository.ChannelRepository
import ai.openclaw.android.domain.model.ApprovalAction
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DashboardUiState(
    val gatewayStatus: String = "Disconnected",
    val onlineChannels: Int = 0,
    val totalChannels: Int = 0,
    val pendingApprovals: Int = 0,
    val isLoading: Boolean = false
)

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val gatewayClient: GatewayClient,
    private val channelRepository: ChannelRepository,
    private val approvalRepository: ApprovalRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()
    
    init {
        loadDashboard()
    }
    
    private fun loadDashboard() {
        viewModelScope.launch {
            // 监听 Gateway 连接状态
            gatewayClient.connectionState.collect { state ->
                _uiState.value = _uiState.value.copy(
                    gatewayStatus = when (state) {
                        is ConnectionState.Connected -> "Connected"
                        is ConnectionState.Connecting -> "Connecting..."
                        is ConnectionState.ChallengeReceived -> "Authenticating..."
                        is ConnectionState.Authenticating -> "Authenticating..."
                        is ConnectionState.Error -> "Error: ${state.message}"
                        ConnectionState.Disconnected -> "Disconnected"
                    }
                )
            }
        }
        
        viewModelScope.launch {
            // 监听渠道状态
            channelRepository.channels.collect { channels ->
                val online = channels.count { it.status.name == "CONNECTED" }
                _uiState.value = _uiState.value.copy(
                    onlineChannels = online,
                    totalChannels = channels.size
                )
            }
        }
        
        viewModelScope.launch {
            // 监听审批队列
            approvalRepository.pendingApprovals.collect { approvals ->
                _uiState.value = _uiState.value.copy(
                    pendingApprovals = approvals.size
                )
            }
        }
        
        // 刷新数据
        refresh()
    }
    
    fun refresh() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            channelRepository.syncChannels()
            approvalRepository.syncPendingApprovals()
            _uiState.value = _uiState.value.copy(isLoading = false)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    onNavigateToApprovals: () -> Unit = {},
    onNavigateToChannels: () -> Unit = {},
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Management") },
                actions = {
                    IconButton(onClick = { viewModel.refresh() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Gateway Status Card
            item {
                StatusCard(
                    title = "Gateway Status",
                    value = uiState.gatewayStatus,
                    icon = Icons.Default.Cloud,
                    color = when {
                        uiState.gatewayStatus == "Connected" -> MaterialTheme.colorScheme.primary
                        uiState.gatewayStatus.startsWith("Error") -> MaterialTheme.colorScheme.error
                        else -> MaterialTheme.colorScheme.outline
                    }
                )
            }
            
            // Channels Summary Card
            item {
                SummaryCard(
                    title = "Channels",
                    value = "${uiState.onlineChannels}/${uiState.totalChannels} online",
                    icon = Icons.Default.Link,
                    onClick = onNavigateToChannels
                )
            }
            
            // Approvals Card
            item {
                SummaryCard(
                    title = "Pending Approvals",
                    value = if (uiState.pendingApprovals > 0) "${uiState.pendingApprovals} pending" else "No pending",
                    icon = Icons.Default.CheckCircle,
                    badge = if (uiState.pendingApprovals > 0) uiState.pendingApprovals else null,
                    onClick = onNavigateToApprovals
                )
            }
            
            // Quick Actions
            item {
                Text(
                    text = "Quick Actions",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary
                )
            }
            
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    QuickActionButton(
                        icon = Icons.Default.Sync,
                        label = "Sync All",
                        onClick = { viewModel.refresh() },
                        modifier = Modifier.weight(1f)
                    )
                    QuickActionButton(
                        icon = Icons.Default.Settings,
                        label = "Settings",
                        onClick = { },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
        
        if (uiState.isLoading) {
            LinearProgressIndicator(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp)
            )
        }
    }
}

@Composable
private fun StatusCard(
    title: String,
    value: String,
    icon: ImageVector,
    color: androidx.compose.ui.graphics.Color
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(56.dp),
                shape = MaterialTheme.shapes.medium,
                color = color.copy(alpha = 0.1f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = color,
                        modifier = Modifier.size(32.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = value,
                    style = MaterialTheme.typography.headlineSmall,
                    color = color
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SummaryCard(
    title: String,
    value: String,
    icon: ImageVector,
    badge: Int? = null,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(32.dp)
                )
                if (badge != null && badge > 0) {
                    Badge(
                        containerColor = MaterialTheme.colorScheme.error,
                        modifier = Modifier.offset(x = 20.dp, y = (-8).dp)
                    ) {
                        Text(badge.toString())
                    }
                }
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = value,
                    style = MaterialTheme.typography.titleLarge
                )
            }
            
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.outline
            )
        }
    }
}

@Composable
private fun QuickActionButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
    ) {
        Icon(icon, contentDescription = null)
        Spacer(modifier = Modifier.width(8.dp))
        Text(label)
    }
}