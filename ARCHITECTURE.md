# ClawChat 技术架构

> OpenClaw 移动端控制台架构设计

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    安卓手机 (浏览器/PWA)                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  ClawChat Web App                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───────────────┐  │  │
│  │  │  WebChat    │  │  Control UI │  │  AI 切换器    │  │  │
│  │  │   聊天界面   │  │   状态面板   │  │  智能体选择   │  │  │
│  │  └─────────────┘  └─────────────┘  └───────────────┘  │  │
│  │                                                        │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │              API Client Layer                    │  │  │
│  │  │  WebSocket Client  │  REST Client  │  Auth      │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ WebSocket + HTTP
                            │ (本地网络)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              OpenClaw Gateway (192.168.x.x:18789)            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  WebChat    │  │  Control    │  │  Agent              │  │
│  │  Endpoint   │  │  UI API     │  │  Router             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 技术栈

### 前端核心
| 技术 | 选型 | 理由 |
|------|------|------|
| **框架** | React 18 + Vite | 轻量快速，HMR 开发体验好 |
| **语言** | TypeScript | 类型安全，减少运行时错误 |
| **UI** | TailwindCSS + HeadlessUI | 移动端友好，自定义灵活 |
| **状态** | Zustand | 简单轻量，无样板代码 |
| **路由** | React Router v6 | 成熟稳定 |
| **HTTP** | Axios | 请求拦截，错误处理 |
| **WebSocket** | 原生 WebSocket | 轻量，无需额外依赖 |

### 开发工具
| 工具 | 用途 |
|------|------|
| ESLint + Prettier | 代码规范 |
| Vitest | 单元测试 |
| Playwright | E2E 测试 |
| Vite PWA Plugin | PWA 支持 |

---

## 目录结构

```
clawchat/
├── public/
│   ├── manifest.json       # PWA manifest
│   └── icons/              # PWA 图标
├── src/
│   ├── components/
│   │   ├── chat/           # 聊天相关组件
│   │   │   ├── ChatInput.tsx
│   │   │   ├── MessageList.tsx
│   │   │   ├── MessageBubble.tsx
│   │   │   └── AgentSwitcher.tsx
│   │   ├── control/        # Control UI 组件
│   │   │   ├── GatewayStatus.tsx
│   │   │   ├── AgentList.tsx
│   │   │   └── SessionList.tsx
│   │   ├── layout/         # 布局组件
│   │   │   ├── Header.tsx
│   │   │   ├── BottomNav.tsx
│   │   │   └── MobileLayout.tsx
│   │   └── ui/             # 通用 UI 组件
│   │       ├── Button.tsx
│   │       ├── Input.tsx
│   │       └── Loading.tsx
│   ├── hooks/
│   │   ├── useWebSocket.ts
│   │   ├── useGateway.ts
│   │   └── useAgents.ts
│   ├── stores/
│   │   ├── chatStore.ts
│   │   ├── gatewayStore.ts
│   │   └── settingsStore.ts
│   ├── services/
│   │   ├── api.ts
│   │   ├── websocket.ts
│   │   └── auth.ts
│   ├── pages/
│   │   ├── Chat.tsx
│   │   ├── Control.tsx
│   │   ├── Settings.tsx
│   │   └── Connection.tsx
│   ├── types/
│   │   ├── openclaw.ts
│   │   └── chat.ts
│   ├── utils/
│   │   ├── format.ts
│   │   └── storage.ts
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── index.html
├── vite.config.ts
├── tailwind.config.js
├── tsconfig.json
└── package.json
```

---

## 核心模块设计

### 1. 网关连接模块

```typescript
// stores/gatewayStore.ts
interface GatewayState {
  host: string;
  port: number;
  token: string;
  connected: boolean;
  connecting: boolean;
  error: string | null;
}

// 连接流程
1. 用户输入网关地址 (默认 192.168.x.x:18789)
2. 输入/选择认证 Token
3. 测试连接 (HTTP + WebSocket)
4. 保存配置到 localStorage
5. 建立持久连接
```

### 2. WebChat 模块

```typescript
// stores/chatStore.ts
interface ChatState {
  currentAgent: string;
  sessions: ChatSession[];
  messages: Message[];
  isLoading: boolean;
}

// 消息流程
1. 用户输入消息
2. 通过 WebSocket 发送到 Gateway
3. Gateway 路由到对应 Agent
4. 接收 Agent 响应
5. 更新消息列表
```

### 3. AI 切换模块

```typescript
// hooks/useAgents.ts
function useAgents() {
  const { agents, loading } = useGateway();
  
  const switchAgent = (agentId: string) => {
    // 1. 保存当前会话
    // 2. 切换到新 Agent
    // 3. 加载对应会话历史
    // 4. 建立新的 WebSocket 连接
  };
  
  return { agents, switchAgent, currentAgent };
}
```

### 4. WebSocket 服务

```typescript
// services/websocket.ts
class WebSocketService {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnects = 5;
  
  connect(url: string, token: string) {
    // 1. 建立连接
    // 2. 认证
    // 3. 心跳检测
    // 4. 断线重连
  }
  
  sendMessage(agentId: string, message: string) {
    // 发送消息到指定 Agent
  }
}
```

---

## API 接口

### OpenClaw Gateway API

| 端点 | 方法 | 用途 |
|------|------|------|
| `/ws` | WebSocket | 聊天消息 |
| `/gateway/status` | GET | 网关状态 |
| `/agents/list` | GET | Agent 列表 |
| `/sessions/list` | GET | 会话列表 |
| `/message/send` | POST | 发送消息 (备用) |

### WebSocket 消息格式

```typescript
// 发送
{
  type: "message",
  agent: "main",
  content: "你好",
  sessionId?: string
}

// 接收
{
  type: "message",
  agent: "main",
  content: "你好！有什么可以帮你？",
  timestamp: 1234567890,
  sessionId: "abc123"
}
```

---

## 安全设计

### 认证
- Token 存储在 localStorage (加密)
- 不存储明文密码
- 支持 Token 刷新

### 网络
- 仅支持本地网络 (HTTP)
- 可选配置 HTTPS
- CORS 由 Gateway 配置

### 数据
- 敏感数据本地存储
- 支持清除缓存
- PWA 离线缓存可控

---

## 性能优化

| 优化项 | 策略 |
|--------|------|
| 首屏加载 | 代码分割 + 懒加载 |
| 消息列表 | 虚拟滚动 (1000+ 消息) |
| 图片加载 | 懒加载 + 压缩 |
| WebSocket | 心跳检测 + 断线重连 |
| 缓存 | Service Worker + localStorage |

---

## 移动端适配

### 响应式断点
```css
/* 手机竖屏 */
@media (max-width: 640px) { }

/* 手机横屏/平板 */
@media (min-width: 641px) and (max-width: 1024px) { }

/* 桌面 */
@media (min-width: 1025px) { }
```

### 触摸优化
- 按钮最小 44x44px
- 禁用双击缩放
- 支持滑动手势

---

## PWA 配置

```json
// manifest.json
{
  "name": "ClawChat",
  "short_name": "ClawChat",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "icons": [...]
}
```

---

## 部署方案

### 方案 A: 静态托管 (推荐)
```bash
# 构建
npm run build

# 部署到任意静态服务器
# - Nginx
# - Caddy
# - Python http.server
# - 或者直接打开 dist/index.html
```

### 方案 B: 集成到 OpenClaw
```bash
# 将 dist 复制到 Gateway 静态目录
cp -r dist/* ~/.openclaw/gateway-static/
```

---

## 开发流程

```bash
# 1. 克隆仓库
git clone https://github.com/pawpaw-agent/clawchat

# 2. 安装依赖
npm install

# 3. 开发模式
npm run dev

# 4. 构建
npm run build

# 5. 预览
npm run preview
```

---

_版本：1.0_
_创建：2026-03-10_
_作者：architect agent_
