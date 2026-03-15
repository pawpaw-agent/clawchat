# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-15

### Added
- Phase 1: MVP 核心功能
  - 会话列表页面
  - 对话页面
  - 消息持久化（Isar）
  - 流式响应 + Markdown 渲染
- Phase 2: 体验优化
  - Android 前台服务保活
  - 网络切换自动重连
  - 性能优化（DiffUtil、分页、缓存）
  - 统一错误处理
- Phase 3: 高级功能
  - 节点管理页面
  - 执行审批工作流
  - 设置页面
- 启动流程优化
  - 首次启动引导
  - Gateway 配置页面
  - 设备配对流程
- 边界条件修复
  - 数据库未初始化保护
  - WebSocket 竞态条件修复
  - 消息长度限制

### Security
- 移除 FCM（保持直连架构）
- 实现前台服务 + WorkManager 轮询

### Dependencies
- flutter_riverpod ^2.4.9
- web_socket_channel ^3.0.1
- connectivity_plus ^5.0.2
- isar ^3.1.0+1
- flutter_secure_storage ^9.0.0
- shared_preferences ^2.2.2