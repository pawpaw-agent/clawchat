# ClawChat 列表性能优化指南

## 概述

本次优化针对 ClawChat Flutter 移动客户端的列表滚动性能，目标：
- 消息列表滚动达到 60fps（Profile 模式测量）
- 1000 条消息时内存 < 200MB
- 会话列表支持分页加载（每页 20 条）
- 图片消息使用缓存

## 优化措施

### 1. 消息列表优化 (`message_list.dart`)

#### ListView 优化
- 使用 `RepaintBoundary` 隔离每个消息项的重绘
- 配置 `cacheExtent: 500` 预加载可见区域外的内容
- 启用 `addAutomaticKeepAlives` 保持列表项状态
- 启用 `addRepaintBoundaries` 优化重绘性能

#### DiffUtil 实现
```dart
final diffUtil = DiffUtil<Message>(
  idExtractor: (msg) => msg.id,
  contentComparator: (a, b) => _messagesEqual(a, b),
);
```
- 检测消息插入、删除、更新、移动操作
- 减少不必要的 Widget 重建

#### 滚动检测
- 检测用户主动滚动，避免自动滚动干扰
- 滚动到底部时重新启用自动滚动
- 新消息到达时智能滚动

#### 性能监控
```dart
final performanceMonitor = ScrollPerformanceMonitor();
performanceMonitor.recordFrame(listId, frameTime);
```

### 2. 会话列表优化 (`session_list_screen.dart`)

#### 分页加载
```dart
final paginationController = PaginationController<Session>(
  pageSize: 20,
  fetchPage: (page, size) => _fetchSessionsPage(page, size, false),
);
```

- 每页加载 20 条会话
- 滚动到底部前 200px 自动加载下一页
- 下拉刷新重置分页

#### 无限滚动检测
```dart
void _onScroll(ScrollController controller, bool isArchived) {
  final maxScroll = controller.position.maxScrollExtent;
  final currentScroll = controller.position.pixels;
  const threshold = 200.0;

  if (maxScroll - currentScroll <= threshold) {
    // 加载更多
  }
}
```

### 3. 工具类 (`list_optimizer.dart`)

#### DiffUtil
- 基于 ID 的列表对比算法
- 支持插入、删除、更新、移动操作
- O(n) 时间复杂度

#### ListItemCache
- LRU 缓存实现
- 默认缓存 50 个列表项
- 自动淘汰最少使用的项

#### ImageCacheConfig
- 配置图片缓存内存限制
- 默认分配 50MB 给图片缓存
- 支持低内存设备配置

#### PaginationController
- 管理分页状态
- 支持加载初始页、加载更多、刷新
- 自动检测是否还有更多数据

## 性能测试

### 运行单元测试
```bash
flutter test test/performance/list_performance_test.dart
```

### 运行 Widget 测试
```bash
flutter test test/widget/message_list_widget_test.dart
flutter test test/widget/session_list_widget_test.dart
```

### Profile 模式性能测量

1. 构建 Profile APK：
```bash
flutter build apk --profile
```

2. 安装到设备：
```bash
adb install build/app/outputs/flutter-apk/app-profile.apk
```

3. 使用 DevTools 测量：
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

4. 连接设备后测量：
   - FPS（目标：≥60fps）
   - Memory（目标：<200MB）
   - GPU 使用率
   - Widget 重建次数

### 使用性能脚本
```bash
cd /home/xsj/.openclaw/workspace-Clay/clawchat
./scripts/measure_performance.sh
```

## 配置选项

### 默认配置
```dart
ListOptimizationConfig.chatList
// useKeepAlive: true
// cacheExtent: 500.0
// maxCachedItems: 50
// imageCacheMB: 50
```

### 低内存配置
```dart
ListOptimizationConfig.lowMemory
// useKeepAlive: false
// cacheExtent: 250.0
// maxCachedItems: 25
// imageCacheMB: 25
```

## 验证清单

- [ ] 消息列表滚动 FPS ≥ 60
- [ ] 1000 条消息内存 < 200MB
- [ ] 会话列表分页正常工作
- [ ] 下拉刷新重置分页
- [ ] 无限滚动加载更多
- [ ] 图片缓存配置生效
- [ ] 单元测试通过
- [ ] Widget 测试通过
- [ ] Profile 模式测试通过

## 文件清单

| 文件 | 说明 |
|------|------|
| `lib/src/core/utils/list_optimizer.dart` | 列表优化工具类 |
| `lib/src/features/chat/message_list.dart` | 优化后的消息列表 |
| `lib/src/features/sessions/session_list_screen.dart` | 优化后的会话列表 |
| `test/performance/list_performance_test.dart` | 性能单元测试 |
| `test/widget/message_list_widget_test.dart` | 消息列表 Widget 测试 |
| `test/widget/session_list_widget_test.dart` | 会话列表 Widget 测试 |
| `scripts/measure_performance.sh` | 性能测量脚本 |

## 注意事项

1. **不要在 Debug 模式测量性能** - Debug 模式性能远低于 Profile/Release
2. **使用物理设备** - 模拟器性能不代表真实设备
3. **多次测试取平均值** - 避免单次测试偏差
4. **关注内存峰值** - 不仅看平均值，还要看峰值

## 后续优化建议

1. 实现消息虚拟化（只渲染可见项）
2. 添加图片懒加载和渐进式显示
3. 实现消息分页（历史消息按需加载）
4. 添加列表项回收池
5. 考虑使用 `Sliver` 替代 `ListView` 复杂场景