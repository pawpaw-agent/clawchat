package ai.openclaw.android.presentation.screen

import ai.openclaw.android.R
import ai.openclaw.android.domain.model.Message
import ai.openclaw.android.domain.model.MessageRole
import ai.openclaw.android.presentation.components.GitHubBadge
import ai.openclaw.android.presentation.components.GitHubButton
import ai.openclaw.android.presentation.components.GitHubCard
import ai.openclaw.android.presentation.components.GitHubTextField
import ai.openclaw.android.presentation.components.MarkdownText
import ai.openclaw.android.presentation.theme.GitHubSpacing
import ai.openclaw.android.presentation.viewmodel.ChatViewModel
import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    onNavigateBack: () -> Unit,
    viewModel: ChatViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()
    val context = LocalContext.current
    
    // Speech recognizer state
    var isListening by remember { mutableStateOf(false) }
    var speechRecognizer: SpeechRecognizer? by remember { mutableStateOf(null) }
    
    // Permission launcher for audio
    val audioPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (!isGranted) {
            Toast.makeText(context, context.getString(R.string.chat_audio_permission_denied), Toast.LENGTH_SHORT).show()
        }
    }
    
    // Initialize speech recognizer
    DisposableEffect(Unit) {
        val recognizer = SpeechRecognizer.createSpeechRecognizer(context)
        val intent = android.content.Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "zh-CN")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }
        
        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: android.os.Bundle?) {
                isListening = true
            }
            
            override fun onBeginningOfSpeech() {}
            
            override fun onRmsChanged(rmsdB: Float) {}
            
            override fun onBufferReceived(buffer: ByteArray?) {}
            
            override fun onEndOfSpeech() {
                isListening = false
            }
            
            override fun onError(error: Int) {
                isListening = false
                val errorMsg = when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                    SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                    SpeechRecognizer.ERROR_NETWORK -> "Network error"
                    SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                    else -> "Error: $error"
                }
                Toast.makeText(context, errorMsg, Toast.LENGTH_SHORT).show()
            }
            
            override fun onResults(results: android.os.Bundle?) {
                isListening = false
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                matches?.firstOrNull()?.let { text ->
                    viewModel.updateInputText(text)
                }
            }
            
            override fun onPartialResults(partialResults: android.os.Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                matches?.firstOrNull()?.let { text ->
                    viewModel.updateInputText(text)
                }
            }
            
            override fun onEvent(eventType: Int, params: android.os.Bundle?) {}
        })
        
        speechRecognizer = recognizer
        
        onDispose {
            recognizer.destroy()
        }
    }
    
    // Image picker launcher
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        uri?.let {
            viewModel.sendImageMessage(it)
        }
    }
    
    // Pending image preview dialog
    if (uiState.pendingImageUri != null) {
        AlertDialog(
            onDismissRequest = { viewModel.clearPendingImage() },
            title = { Text(stringResource(R.string.chat_send_image)) },
            text = {
                Column {
                    Text(stringResource(R.string.chat_send_image_desc))
                    Spacer(modifier = Modifier.height(GitHubSpacing.md))
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    uiState.pendingImageUri?.let { viewModel.sendImageMessage(it) }
                }) {
                    Text(stringResource(R.string.chat_send))
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.clearPendingImage() }) {
                    Text(stringResource(R.string.settings_cancel))
                }
            }
        )
    }
    
    // Auto-scroll to bottom when entering chat or new message arrives
    LaunchedEffect(Unit, uiState.messages.size) {
        if (uiState.messages.isNotEmpty()) {
            listState.scrollToItem(uiState.messages.size - 1)
        }
    }
    
    // Scroll to bottom on new message during streaming
    LaunchedEffect(uiState.messages.lastOrNull()?.content) {
        if (uiState.messages.isNotEmpty() && uiState.isStreaming) {
            listState.scrollToItem(uiState.messages.size - 1)
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        uiState.agentEmoji?.let { emoji ->
                            Text(text = emoji, style = MaterialTheme.typography.titleMedium)
                            Spacer(modifier = Modifier.width(GitHubSpacing.xs))
                        }
                        Text(
                            text = uiState.agentName ?: stringResource(R.string.chat_title),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = stringResource(R.string.chat_back))
                    }
                },
                actions = {
                    if (uiState.isStreaming) {
                        IconButton(onClick = { viewModel.abort() }) {
                            Icon(Icons.Default.Stop, contentDescription = stringResource(R.string.chat_stop), tint = MaterialTheme.colorScheme.error)
                        }
                    }
                },
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
        ) {
            // Offline status banner
            if (!uiState.isOnline || uiState.connectionStatus != null) {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = if (uiState.isOnline) {
                        MaterialTheme.colorScheme.primaryContainer
                    } else {
                        MaterialTheme.colorScheme.errorContainer
                    }
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = GitHubSpacing.md, vertical = GitHubSpacing.xs),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = if (uiState.isOnline) Icons.Default.Cloud else Icons.Default.CloudOff,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp),
                            tint = if (uiState.isOnline) {
                                MaterialTheme.colorScheme.onPrimaryContainer
                            } else {
                                MaterialTheme.colorScheme.onErrorContainer
                            }
                        )
                        Spacer(modifier = Modifier.width(GitHubSpacing.xs))
                        Text(
                            text = uiState.connectionStatus ?: if (uiState.isOnline) "Online" else stringResource(R.string.chat_offline),
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (uiState.isOnline) {
                                MaterialTheme.colorScheme.onPrimaryContainer
                            } else {
                                MaterialTheme.colorScheme.onErrorContainer
                            }
                        )
                    }
                }
            }
            
            // Messages list
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                state = listState,
                contentPadding = PaddingValues(vertical = GitHubSpacing.xs),
                verticalArrangement = Arrangement.spacedBy(GitHubSpacing.xs)
            ) {
                // Load more history indicator
                if (uiState.hasMoreHistory) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(GitHubSpacing.xs),
                            contentAlignment = Alignment.Center
                        ) {
                            TextButton(onClick = { viewModel.loadMoreHistory() }) {
                                if (uiState.isLoadingHistory) {
                                    CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                                } else {
                                    Text(stringResource(R.string.chat_load_more))
                                }
                            }
                        }
                    }
                }
                
                items(
                    items = uiState.messages,
                    key = { it.id },
                    contentType = { if (it.role == MessageRole.USER) "user" else "assistant" }
                ) { message ->
                    MessageBubble(
                        message = message,
                        onCopy = { text ->
                            val clipboard = context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                            val clip = android.content.ClipData.newPlainText("message", text)
                            clipboard.setPrimaryClip(clip)
                            Toast.makeText(context, context.getString(R.string.chat_message_copied), Toast.LENGTH_SHORT).show()
                        },
                        onDelete = { messageId ->
                            viewModel.deleteMessage(messageId)
                        }
                    )
                }
                
                // Streaming indicator
                if (uiState.isSending) {
                    item {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = GitHubSpacing.md),
                            horizontalArrangement = Arrangement.Start
                        ) {
                            GitHubCard {
                                Row(
                                    modifier = Modifier.padding(GitHubSpacing.sm),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(16.dp),
                                        strokeWidth = 2.dp
                                    )
                                    Spacer(modifier = Modifier.width(GitHubSpacing.xs))
                                    Text(
                                        stringResource(R.string.chat_thinking),
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            // Input area
            MessageInput(
                text = uiState.inputText,
                isSending = uiState.isSending || uiState.isStreaming,
                isListening = isListening,
                onTextChange = { viewModel.updateInputText(it) },
                onSend = { viewModel.sendMessage() },
                onAttach = {
                    imagePickerLauncher.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                    )
                },
                onMicClick = {
                    if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)
                        == PackageManager.PERMISSION_GRANTED
                    ) {
                        if (isListening) {
                            speechRecognizer?.stopListening()
                        } else {
                            val intent = android.content.Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "zh-CN")
                                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                            }
                            speechRecognizer?.startListening(intent)
                        }
                    } else {
                        audioPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                    }
                },
                shouldFocus = true
            )
        }
    }
    
    uiState.error?.let { error ->
        LaunchedEffect(error) {
            // Show snackbar
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MessageBubble(
    message: Message,
    onCopy: (String) -> Unit = {},
    onDelete: (String) -> Unit = {}
) {
    val isUser = message.role == MessageRole.USER
    var showMenu by remember { mutableStateOf(false) }
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = GitHubSpacing.md),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
    ) {
        Box {
            GitHubCard(
                modifier = Modifier
                    .fillMaxWidth(0.85f)
                    .clip(
                        RoundedCornerShape(
                            topStart = 16.dp,
                            topEnd = 16.dp,
                            bottomStart = if (isUser) 16.dp else 4.dp,
                            bottomEnd = if (isUser) 4.dp else 16.dp
                        )
                    )
                    .combinedClickable(
                        onClick = {},
                        onLongClick = { showMenu = true }
                    ),
                backgroundColor = if (isUser) {
                    MaterialTheme.colorScheme.primaryContainer
                } else {
                    MaterialTheme.colorScheme.surfaceVariant
                }
            ) {
                Column(
                    modifier = Modifier.padding(GitHubSpacing.sm)
                ) {
                    // Role indicator
                    GitHubBadge(
                        text = message.role.name.lowercase().replaceFirstChar { it.uppercase() },
                        backgroundColor = if (isUser) {
                            MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                        } else {
                            MaterialTheme.colorScheme.surfaceVariant
                        },
                        textColor = if (isUser) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        }
                    )
                    
                    Spacer(modifier = Modifier.height(GitHubSpacing.xxs))
                    
                    // Message content with Markdown rendering
                    MarkdownText(
                        text = message.content.ifEmpty { "..." },
                        color = if (isUser) {
                            MaterialTheme.colorScheme.onPrimaryContainer
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        }
                    )
                    
                    // Timestamp
                    Text(
                        text = formatMessageTime(message.timestamp),
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isUser) {
                            MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.5f)
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        },
                        modifier = Modifier
                            .padding(top = GitHubSpacing.xxs)
                            .align(Alignment.End)
                    )
                    
                    // Streaming indicator
                    if (message.isStreaming) {
                        Row(
                            modifier = Modifier.padding(top = GitHubSpacing.xxs),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(12.dp),
                                strokeWidth = 1.5.dp
                            )
                            Spacer(modifier = Modifier.width(GitHubSpacing.xxs))
                            Text(
                                stringResource(R.string.chat_streaming),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.outline
                            )
                        }
                    }
                    
                    // Error indicator
                    message.error?.let { error ->
                        Row(
                            modifier = Modifier.padding(top = GitHubSpacing.xxs),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Error,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = MaterialTheme.colorScheme.error
                            )
                            Spacer(modifier = Modifier.width(GitHubSpacing.xxs))
                            Text(
                                text = error,
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }
            
            // Long press menu
            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.chat_message_copy)) },
                    onClick = {
                        showMenu = false
                        onCopy(message.content)
                    },
                    leadingIcon = {
                        Icon(Icons.Default.ContentCopy, contentDescription = null)
                    }
                )
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.chat_message_delete)) },
                    onClick = {
                        showMenu = false
                        onDelete(message.id)
                    },
                    leadingIcon = {
                        Icon(Icons.Default.Delete, contentDescription = null, tint = MaterialTheme.colorScheme.error)
                    },
                    colors = MenuDefaults.itemColors(
                        textColor = MaterialTheme.colorScheme.error
                    )
                )
            }
        }
    }
}

@Composable
private fun MessageInput(
    text: String,
    isSending: Boolean,
    isListening: Boolean,
    onTextChange: (String) -> Unit,
    onSend: () -> Unit,
    onAttach: () -> Unit = {},
    onMicClick: () -> Unit = {},
    shouldFocus: Boolean = false
) {
    val focusRequester = remember { FocusRequester() }
    
    LaunchedEffect(shouldFocus) {
        if (shouldFocus) {
            kotlinx.coroutines.delay(300)
            focusRequester.requestFocus()
        }
    }
    
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shadowElevation = 8.dp,
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(GitHubSpacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Attachment button
            IconButton(onClick = onAttach) {
                Icon(Icons.Default.AttachFile, contentDescription = stringResource(R.string.chat_attach))
            }
            
            // Text field
            GitHubTextField(
                value = text,
                onValueChange = onTextChange,
                modifier = Modifier
                    .weight(1f)
                    .focusRequester(focusRequester),
                placeholder = stringResource(R.string.chat_input_hint),
                maxLines = 4
            )
            
            // Microphone button
            IconButton(
                onClick = onMicClick,
                colors = IconButtonDefaults.iconButtonColors(
                    contentColor = if (isListening) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant
                )
            ) {
                if (isListening) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        Icons.Default.Mic,
                        contentDescription = stringResource(R.string.chat_voice_input)
                    )
                }
            }
            
            Spacer(modifier = Modifier.width(GitHubSpacing.xxs))
            
            // Send button
            GitHubButton(
                text = "",
                onClick = onSend,
                enabled = text.isNotBlank() && !isSending,
                isLoading = isSending,
                variant = ai.openclaw.android.presentation.components.GitHubButtonVariant.PRIMARY
            ) {
                if (isSending) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        Icons.AutoMirrored.Filled.Send,
                        contentDescription = stringResource(R.string.chat_send),
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun formatMessageTime(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val calendar = Calendar.getInstance()
    calendar.timeInMillis = timestamp
    
    val messageCalendar = Calendar.getInstance()
    messageCalendar.timeInMillis = timestamp
    
    return when {
        calendar.get(Calendar.YEAR) == messageCalendar.get(Calendar.YEAR) &&
        calendar.get(Calendar.DAY_OF_YEAR) == messageCalendar.get(Calendar.DAY_OF_YEAR) -> {
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(timestamp))
        }
        calendar.get(Calendar.YEAR) == messageCalendar.get(Calendar.YEAR) &&
        calendar.get(Calendar.DAY_OF_YEAR) - messageCalendar.get(Calendar.DAY_OF_YEAR) == 1 -> {
            "Yesterday " + SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(timestamp))
        }
        calendar.get(Calendar.YEAR) == messageCalendar.get(Calendar.YEAR) -> {
            SimpleDateFormat("MMM dd HH:mm", Locale.getDefault()).format(Date(timestamp))
        }
        else -> {
            SimpleDateFormat("yyyy/MM/dd HH:mm", Locale.getDefault()).format(Date(timestamp))
        }
    }
}
