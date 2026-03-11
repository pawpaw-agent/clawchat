package ai.openclaw.android.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import ai.openclaw.android.presentation.screen.ChatScreen
import ai.openclaw.android.presentation.screen.ConnectScreen
import ai.openclaw.android.presentation.screen.PairingScreen
import ai.openclaw.android.presentation.screen.SessionListScreen

sealed class Screen(val route: String) {
    object Connect : Screen("connect")
    object Sessions : Screen("sessions")
    object Chat : Screen("chat/{sessionKey}") {
        fun createRoute(sessionKey: String) = "chat/$sessionKey"
    }
    object Pairing : Screen("pairing/{requestId}") {
        fun createRoute(requestId: String) = "pairing/$requestId"
    }
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
            val sessionKey = backStackEntry.arguments?.getString("sessionKey") ?: ""
            ChatScreen(
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
        
        composable(Screen.Pairing.route) { backStackEntry ->
            val requestId = backStackEntry.arguments?.getString("requestId") ?: ""
            PairingScreen(
                requestId = requestId,
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
    }
}