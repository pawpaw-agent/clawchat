package ai.openclaw.android.presentation.navigation

import ai.openclaw.android.R
import ai.openclaw.android.presentation.screen.*
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController

sealed class MainTab(val route: String, val titleRes: Int, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    object Sessions : MainTab("sessions", R.string.nav_sessions, Icons.Default.Chat)
    object Dashboard : MainTab("dashboard", R.string.nav_manage, Icons.Default.Dashboard)
    object Settings : MainTab("settings", R.string.nav_settings, Icons.Default.Settings)
}

@Composable
fun MainNavigation(
    navController: NavHostController = rememberNavController()
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                listOf(
                    MainTab.Sessions,
                    MainTab.Dashboard,
                    MainTab.Settings
                ).forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = stringResource(tab.titleRes)) },
                        label = { Text(stringResource(tab.titleRes)) },
                        selected = currentRoute == tab.route,
                        onClick = {
                            if (currentRoute != tab.route) {
                                navController.navigate(tab.route) {
                                    popUpTo(navController.graph.startDestinationId) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = MainTab.Sessions.route,
            modifier = Modifier.padding(padding)
        ) {
            composable(MainTab.Sessions.route) {
                SessionListScreen(
                    onNavigateToChat = { sessionKey ->
                        navController.navigate("chat/$sessionKey")
                    }
                )
            }
            
            composable(MainTab.Dashboard.route) {
                DashboardScreen(
                    onNavigateToApprovals = {
                        navController.navigate("approvals")
                    },
                    onNavigateToChannels = {
                        navController.navigate("channels")
                    }
                )
            }
            
            composable(MainTab.Settings.route) {
                SettingsScreen(
                    onNavigateBack = { }
                )
            }
            
            // Detail screens (full screen, no bottom bar)
            composable("chat/{sessionKey}") { backStackEntry ->
                ChatScreen(
                    onNavigateBack = {
                        navController.popBackStack()
                    }
                )
            }
            
            composable("approvals") {
                ApprovalListScreen()
            }
            
            composable("channels") {
                ChannelListScreen()
            }
        }
    }
}