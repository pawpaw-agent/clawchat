package ai.openclaw.android.presentation.navigation

import ai.openclaw.android.presentation.screen.*
import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

sealed class Screen(val route: String) {
    object Connect : Screen("connect")
    object Main : Screen("main")
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
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Connect.route) { inclusive = true }
                    }
                }
            )
        }
        
        composable(Screen.Main.route) {
            MainNavigation()
        }
        
        composable(Screen.Pairing.route) { backStackEntry ->
            PairingScreen(
                requestId = backStackEntry.arguments?.getString("requestId") ?: "",
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
    }
}