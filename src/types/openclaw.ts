// OpenClaw Gateway API 类型定义

export interface GatewayStatus {
  version: string
  state: 'active' | 'inactive' | 'error'
  pid?: number
  port: number
  bind: string
}

export interface AgentConfig {
  id: string
  name?: string
  workspace: string
  agentDir: string
  model: string
  identity?: {
    emoji?: string
  }
}

export interface ChatMessage {
  type: 'message'
  agent: string
  content: string
  timestamp: number
  sessionId?: string
  id?: string
}

export interface ChatRequest {
  type: 'message'
  agent: string
  content: string
  sessionId?: string
}

export interface SessionInfo {
  id: string
  agentId: string
  createdAt: number
  updatedAt: number
  messageCount: number
}

export interface APIResponse<T> {
  success: boolean
  data?: T
  error?: string
}
