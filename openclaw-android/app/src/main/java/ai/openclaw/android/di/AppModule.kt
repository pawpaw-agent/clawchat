package ai.openclaw.android.di

import ai.openclaw.android.core.crypto.DeviceIdentityManager
import ai.openclaw.android.core.crypto.SecureTokenStorage
import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.data.repository.AuthRepository
import android.content.Context
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideJson(): Json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder()
        .addInterceptor(
            HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            }
        )
        .pingInterval(java.time.Duration.ofSeconds(30))
        .build()

    @Provides
    @Singleton
    fun provideGatewayClient(
        okHttpClient: OkHttpClient,
        json: Json
    ): GatewayClient = GatewayClient(okHttpClient, json)

    @Provides
    @Singleton
    fun provideSecureTokenStorage(
        @ApplicationContext context: Context
    ): SecureTokenStorage = SecureTokenStorage(context)

    @Provides
    @Singleton
    fun provideDeviceIdentityManager(
        @ApplicationContext context: Context,
        secureTokenStorage: SecureTokenStorage
    ): DeviceIdentityManager = DeviceIdentityManager(context, secureTokenStorage)

    @Provides
    @Singleton
    fun provideAuthRepository(
        gatewayClient: GatewayClient,
        deviceIdentityManager: DeviceIdentityManager,
        secureTokenStorage: SecureTokenStorage
    ): AuthRepository = AuthRepository(gatewayClient, deviceIdentityManager, secureTokenStorage)

    @Provides
    @Singleton
    fun provideApplicationScope(): CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
}