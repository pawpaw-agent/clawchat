# Clawchat 签名配置

## 覆盖安装说明

为了确保新版本 APK 可以直接覆盖安装，需要使用**相同的签名**。

### CI 构建

GitHub Actions 每次构建会自动生成固定的 debug keystore：
- Keystore: `keystores/debug.keystore`
- Password: `android`
- Alias: `androiddebugkey`

**CI 构建的 APK 签名一致**，可以直接覆盖安装。

### 本地开发

本地开发需要生成相同的 keystore：

```bash
cd openclaw-android
mkdir -p keystores

keytool -genkey -v \
  -keystore keystores/debug.keystore \
  -storepass android \
  -alias androiddebugkey \
  -keypass android \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Clawchat Debug,O=OpenClaw,C=CN"
```

生成后，本地构建的 APK 与 CI 构建的 APK 签名一致，可以互相覆盖安装。

### 版本号管理

- `versionCode`: 递增整数，用于 Play Store 判断版本先后
- `versionName`: 用户可见的版本号（如 "0.1.0"）

覆盖安装要求：
- 签名一致 ✅
- `applicationId` 一致 ✅（固定为 `ai.openclaw.android`）
- `versionCode` 不低于已安装版本（或开启允许降级）

### 注意事项

1. **不要提交 keystore 到仓库**（已在 .gitignore 中排除）
2. 如需发布 Release 版本，建议创建独立的 release keystore 并存入 GitHub Secrets