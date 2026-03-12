package ai.openclaw.android.presentation.screen

import ai.openclaw.android.R
import ai.openclaw.android.domain.model.NodeStatus
import ai.openclaw.android.presentation.viewmodel.NodeListViewModel
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NodeListScreen(
    viewModel: NodeListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.nodes_title)) },
                actions = {
                    IconButton(onClick = { viewModel.syncNodes() }) {
                        Icon(Icons.Default.Refresh, contentDescription = stringResource(R.string.nodes_refresh))
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
            if (uiState.isLoading && uiState.nodes.isEmpty()) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (uiState.nodes.isEmpty()) {
                Column(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        Icons.Default.Dns,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.outline
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(stringResource(R.string.nodes_no_nodes), color = MaterialTheme.colorScheme.outline)
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(vertical = 8.dp)
                ) {
                    items(uiState.nodes, key = { it.nodeId }) { node ->
                        NodeItem(node = node)
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
}

@Composable
private fun NodeItem(node: NodeStatus) {
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
                Surface(
                    modifier = Modifier.size(12.dp),
                    shape = MaterialTheme.shapes.small,
                    color = if (node.online) Color(0xFF4CAF50) else Color(0xFF9E9E9E)
                ) {}
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = node.label ?: node.nodeId.take(8),
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = if (node.online) stringResource(R.string.nodes_online) else stringResource(R.string.nodes_offline),
                        style = MaterialTheme.typography.bodySmall,
                        color = if (node.online) Color(0xFF4CAF50) else MaterialTheme.colorScheme.outline
                    )
                }
                
                Text(
                    text = if (node.online) "●" else "○",
                    style = MaterialTheme.typography.titleLarge,
                    color = if (node.online) Color(0xFF4CAF50) else MaterialTheme.colorScheme.outline
                )
            }
            
            if (node.capabilities.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    node.capabilities.take(3).forEach { cap ->
                        SuggestionChip(
                            onClick = {},
                            label = { Text(cap, style = MaterialTheme.typography.labelSmall) },
                            modifier = Modifier.height(24.dp)
                        )
                    }
                    if (node.capabilities.size > 3) {
                        Text(
                            "+${node.capabilities.size - 3}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.outline,
                            modifier = Modifier.align(Alignment.CenterVertically)
                        )
                    }
                }
            }
            
            node.model?.let { model ->
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "${stringResource(R.string.nodes_model)} $model",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline
                )
            }
        }
    }
}