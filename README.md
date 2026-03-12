# ClawChat 🐾

> OpenClaw 移动端控制台 — 在安卓手机上使用和管理 OpenClaw

[![Version](https://img.shields.io/github/v/release/pawpaw-agent/clawchat)](https://github.com/pawpaw-agent/clawchat/releases)
[![License](https://img.shields.io/github/license/pawpaw-agent/clawchat)](https://github.com/pawpaw-agent/clawchat/blob/main/LICENSE)

---

## ✨ 特性

- 📱 **移动优先** - 专为安卓手机优化的界面
- 🔌 **双模式集成** - WebChat 聊天 + Control UI 管理
- 🤖 **AI 切换** - 快速切换不同 AI 智能体
- 🏠 **本地网络** - 无需公网，保护隐私
- ⚡ **PWA 支持** - 可安装到主屏幕，离线可用

---

## 📸 截图

_(待添加)_

---

## 🚀 快速开始

### 前置要求

- OpenClaw Gateway 2026.3.x 运行中
- 安卓手机 (Chrome 浏览器)
- 同一本地网络

### 1. 部署

#### 方案 A: 本地开发

```bash
# 克隆仓库
git clone https://github.com/pawpaw-agent/clawchat
cd clawchat

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 在手机浏览器访问 http://你的电脑 IP:5173
```

#### 方案 B: 生产构建

```bash
# 构建
npm run build

# 将 dist 目录部署到任意静态服务器
# 例如：Nginx, Caddy, Python http.server 等
```

#### 方案 C: 直接访问

如果你已经运行了 OpenClaw Gateway，可以直接访问：
```
http://你的网关 IP:18789
```

### 2. 配置

1. 打开 ClawChat
2. 进入 **设置** 页面
3. 输入网关地址 (例如：`192.168.1.100`)
4. 输入端口 (默认：`18789`)
5. 输入认证 Token (从 OpenClaw 配置获取)
6. 点击 **测试连接**

### 3. 安装 PWA (可选)

在 Chrome 浏览器中：
1. 点击右上角菜单
2. 选择 **安装应用** 或 **添加到主屏幕**
3. 确认安装

---

## 📖 使用指南

### 聊天

1. 点击底部 **聊天** 标签
2. 在顶部选择 AI 智能体
3. 输入消息并发送
4. 查看 AI 回复

### 控制台

1. 点击底部 **控制台** 标签
2. 查看网关状态
3. 管理智能体列表
4. 使用快捷操作

### 设置

- 配置网关连接
- 管理认证 Token
- 查看应用信息

---

## 🏗️ 技术栈

- **框架**: React 18 + Vite
- **语言**: TypeScript
- **UI**: TailwindCSS
- **状态管理**: Zustand
- **路由**: React Router v6
- **PWA**: vite-plugin-pwa

---

## 📁 项目结构

```
clawchat/
├── src/
│   ├── components/     # React 组件
│   ├── pages/          # 页面组件
│   ├── stores/         # Zustand 状态
│   ├── services/       # API 服务
│   ├── hooks/          # 自定义 Hooks
│   ├── types/          # TypeScript 类型
│   └── utils/          # 工具函数
├── public/             # 静态资源
├── index.html
├── package.json
└── vite.config.ts
```

---

## 🔧 开发

```bash
# 安装依赖
npm install

# 开发模式
npm run dev

# 构建生产版本
npm run build

# 预览生产版本
npm run preview

# 运行测试
npm test

# 代码检查
npm run lint
```

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

---

## 🙏 致谢

- [OpenClaw](https://github.com/openclaw/openclaw) - 强大的 AI 智能体框架
- [agency-agents-zh](https://github.com/jnMetaCode/agency-agents-zh) - AI 智能体团队

---

**Made with ❤️ by 爪爪科技**
