package ai.openclaw.android.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import ai.openclaw.android.data.local.dao.GatewayConfigDao
import ai.openclaw.android.data.local.dao.MessageDao
import ai.openclaw.android.data.local.dao.SessionDao
import ai.openclaw.android.data.local.entity.GatewayConfigEntity
import ai.openclaw.android.data.local.entity.MessageEntity
import ai.openclaw.android.data.local.entity.SessionEntity

@Database(
    entities = [
        SessionEntity::class,
        MessageEntity::class,
        GatewayConfigEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun sessionDao(): SessionDao
    abstract fun messageDao(): MessageDao
    abstract fun gatewayConfigDao(): GatewayConfigDao
}