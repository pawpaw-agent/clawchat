package ai.openclaw.android.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import ai.openclaw.android.presentation.screen.*

sealed class Screen(val route: String) {
    object Connect : Screen("connect")
    object Sessions : Screen("sessions")
    object Chat : Screen("chat/{sessionKey}") {
        fun createRoute(sessionKey: String) = "chat/$sessionKey"
    }
    object Pairing : Screen("pairing/{requestId}") {
        fun createRoute(requestId: String) = "pairing/$requestId"
    }
    object Channels : Screen("channels")
    object Nodes : Screen("nodes")
    object Approvals : Screen("approvals")
    object Config : Screen("config")
    object Settings : Screen("settings")
}

@Composable
fun AppNavigation(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Screen.Connect.route
    ) {
        composable(Screen.Connect.route) {
            ConnectScreen(
                onNavigateToPairing = { requestId ->
                    navController.navigate(Screen.Pairing.createRoute(requestId))
                },
                onNavigateToSessions = {
                    navController.navigate(Screen.Sessions.route) {
                        popUpTo(Screen.Connect.route) { inclusive = true }
                    }
                }
            )
        }
        
        composable(Screen.Sessions.route) {
            SessionListScreen(
                onNavigateToChat = { sessionKey ->
                    navController.navigate(Screen.Chat.createRoute(sessionKey))
                }
            )
        }
        
        composable(Screen.Chat.route) { backStackEntry ->
            ChatScreen(
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
        
        composable(Screen.Pairing.route) { backStackEntry ->
            PairingScreen(
                requestId = backStackEntry.arguments?.getString("requestId") ?: "",
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
        
        composable(Screen.Channels.route) {
            ChannelListScreen()
        }
        
        composable(Screen.Nodes.route) {
            NodeListScreen()
        }
        
        composable(Screen.Approvals.route) {
            ApprovalListScreen()
        }
        
        composable(Screen.Config.route) {
            ConfigScreen()
        }
        
        composable(Screen.Settings.route) {
            SettingsScreen(
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
    }
}