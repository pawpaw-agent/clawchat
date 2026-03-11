package ai.openclaw.android.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import ai.openclaw.android.presentation.screen.ConnectScreen
import ai.openclaw.android.presentation.screen.PairingScreen

sealed class Screen(val route: String) {
    object Connect : Screen("connect")
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