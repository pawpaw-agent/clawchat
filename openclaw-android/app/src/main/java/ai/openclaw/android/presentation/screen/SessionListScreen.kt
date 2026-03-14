package ai.openclaw.android.presentation.screen

import ai.openclaw.android.R
import ai.openclaw.android.domain.model.Session
import ai.openclaw.android.presentation.components.GitHubBadge
import ai.openclaw.android.presentation.components.GitHubButton
import ai.openclaw.android.presentation.components.GitHubCard
import ai.openclaw.android.presentation.components.GitHubListItem
import ai.openclaw.android.presentation.components.GitHubSearchField
import ai.openclaw.android.presentation.components.ListItemIcon
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.viewmodel.SessionListViewModel
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SessionListScreen(
    onNavigateToChat: (String) -> Unit,
    viewModel: SessionListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    var searchText by remember { mutableStateOf("") }
    
    // Filter sessions by search text
    val filteredSessions = remember(uiState.sessions, searchText) {
        if (searchText.isBlank()) {
            uiState.sessions
        } else {
            uiState.sessions.filter { session ->
                session.label?.contains(searchText, ignoreCase = true) == true ||
                session.key.contains(searchText, ignoreCase = true) ||
                session.channel?.contains(searchText, ignoreCase = true) == true
            }
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.sessions_title)) },
                actions = {
                    IconButton(onClick = { viewModel.syncSessions() }) {
                        Icon(Icons.Default.Refresh, contentDescription = stringResource(R.string.dashboard_refresh))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showCreateDialog = true },
                containerColor = MaterialTheme.colorScheme.primary,
                shape = MaterialTheme.shapes.medium
            ) {
                Icon(Icons.Default.Add, contentDescription = stringResource(R.string.sessions_new))
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Search bar
            GitHubSearchField(
                value = searchText,
                onValueChange = { searchText = it },
                placeholder = stringResource(R.string.sessions_search_hint),
                modifier = Modifier.padding(GitHubSpacing.md),
                onSearch = {}
            )
            
            // Session list
            Box(modifier = Modifier.weight(1f)) {
                if (uiState.isLoading && uiState.sessions.isEmpty()) {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                } else if (filteredSessions.isEmpty()) {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            if (searchText.isNotEmpty()) Icons.Default.SearchOff else Icons.Default.ChatBubbleOutline,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.outline
                        )
                        Spacer(modifier = Modifier.height(GitHubSpacing.md))
                        Text(
                            text = if (searchText.isNotEmpty()) stringResource(R.string.sessions_no_results) else stringResource(R.string.sessions_no_sessions),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.outline
                        )
                        if (searchText.isEmpty()) {
                            Spacer(modifier = Modifier.height(GitHubSpacing.sm))
                            GitHubButton(
                                text = stringResource(R.string.sessions_create),
                                onClick = { showCreateDialog = true },
                                variant = ai.openclaw.android.presentation.components.GitHubButtonVariant.SECONDARY,
                                leadingIcon = {
                                    Icon(Icons.Default.Add, contentDescription = null)
                                }
                            )
                        }
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(vertical = GitHubSpacing.xs)
                    ) {
                        items(filteredSessions, key = { it.key }) { session ->
                            SessionItem(
                                session = session,
                                onClick = { onNavigateToChat(session.key) },
                                onDelete = { viewModel.deleteSession(session.key) },
                                onReset = { viewModel.resetSession(session.key) }
                            )
                        }
                    }
                }
                
                // Pull-to-refresh indicator
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
    
    // Error snackbar
    uiState.error?.let { error ->
        LaunchedEffect(error) {
            // Show snackbar
        }
    }
    
    // Create session dialog
    if (showCreateDialog) {
        CreateSessionDialog(
            onDismiss = { showCreateDialog = false },
            onCreate = { label ->
                viewModel.createSession(label) { key ->
                    showCreateDialog = false
                    onNavigateToChat(key)
                }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SessionItem(
    session: Session,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    onReset: () -> Unit
) {
    var showDeleteConfirm by remember { mutableStateOf(false) }
    var showResetConfirm by remember { mutableStateOf(false) }
    var showMenu by remember { mutableStateOf(false) }
    
    GitHubCard(
        onClick = onClick,
        modifier = Modifier.padding(horizontal = GitHubSpacing.md, vertical = GitHubSpacing.xxs)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon
            ListItemIcon(
                icon = Icons.Default.Chat,
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.width(GitHubSpacing.sm))
            
            // Content
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = session.displayName,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    color = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(GitHubSpacing.xxs))
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "${session.messageCount} ${stringResource(R.string.sessions_messages)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    session.channel?.let { channel ->
                        Spacer(modifier = Modifier.width(GitHubSpacing.xs))
                        GitHubBadge(
                            text = channel,
                            backgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                            textColor = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                Spacer(modifier = Modifier.height(GitHubSpacing.xxs))
                Text(
                    text = formatTimestamp(session.updatedAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            // More options menu
            Box {
                IconButton(onClick = { showMenu = true }) {
                    Icon(
                        Icons.Default.MoreVert,
                        contentDescription = stringResource(R.string.sessions_more_options),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                DropdownMenu(
                    expanded = showMenu,
                    onDismissRequest = { showMenu = false }
                ) {
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.sessions_reset)) },
                        onClick = {
                            showMenu = false
                            showResetConfirm = true
                        },
                        leadingIcon = {
                            Icon(
                                Icons.Default.Refresh,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    )
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.sessions_delete)) },
                        onClick = {
                            showMenu = false
                            showDeleteConfirm = true
                        },
                        leadingIcon = {
                            Icon(
                                Icons.Default.Delete,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    )
                }
            }
        }
    }
    
    // Delete confirmation dialog
    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text(stringResource(R.string.sessions_delete_title)) },
            text = { Text(stringResource(R.string.sessions_delete_desc)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteConfirm = false
                        onDelete()
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text(stringResource(R.string.sessions_delete))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirm = false }) {
                    Text(stringResource(R.string.settings_cancel))
                }
            }
        )
    }
    
    // Reset confirmation dialog
    if (showResetConfirm) {
        AlertDialog(
            onDismissRequest = { showResetConfirm = false },
            title = { Text(stringResource(R.string.sessions_reset_title)) },
            text = { Text(stringResource(R.string.sessions_reset_desc)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showResetConfirm = false
                        onReset()
                    }
                ) {
                    Text(stringResource(R.string.sessions_reset))
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetConfirm = false }) {
                    Text(stringResource(R.string.settings_cancel))
                }
            }
        )
    }
}

@Composable
private fun CreateSessionDialog(
    onDismiss: () -> Unit,
    onCreate: (String?) -> Unit
) {
    var label by remember { mutableStateOf("") }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.sessions_new)) },
        text = {
            OutlinedTextField(
                value = label,
                onValueChange = { label = it },
                label = { Text(stringResource(R.string.sessions_label_optional)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
        },
        confirmButton = {
            TextButton(onClick = { onCreate(label.ifEmpty { null }) }) {
                Text(stringResource(R.string.settings_gateway_add))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.settings_cancel))
            }
        }
    )
}

@Composable
private fun formatTimestamp(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp
    
    return when {
        diff < 60000 -> stringResource(R.string.sessions_just_now)
        diff < 3600000 -> "${diff / 60000} ${stringResource(R.string.sessions_min_ago)}"
        diff < 86400000 -> SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(timestamp))
        else -> SimpleDateFormat("MMM dd", Locale.getDefault()).format(Date(timestamp))
    }
}
