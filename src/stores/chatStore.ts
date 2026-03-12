import { create } from 'zustand'

export interface Message {
  id: string
  role: 'user' | 'assistant' | 'system'
  content: string
  timestamp: number
  agent?: string
  sessionId?: string
}

export interface ChatSession {
  id: string
  agentId: string
  agentName?: string
  lastMessage: string
  lastMessageTime: number
  messageCount: number
}

interface ChatState {
  currentAgent: string
  sessions: ChatSession[]
  messages: Message[]
  isLoading: boolean
  error: string | null
}

interface ChatActions {
  setCurrentAgent: (agentId: string) => void
  setSessions: (sessions: ChatSession[]) => void
  addMessage: (message: Message) => void
  setMessages: (messages: Message[]) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  clearMessages: () => void
  deleteSession: (sessionId: string) => void
}

const initialState: ChatState = {
  currentAgent: 'main',
  sessions: [],
  messages: [],
  isLoading: false,
  error: null,
}

export const useChatStore = create<ChatState & ChatActions>((set) => ({
  ...initialState,

  setCurrentAgent: (agentId) => {
    set({ currentAgent: agentId })
    // 切换 Agent 时加载对应会话
    // TODO: 从存储或 API 加载历史消息
  },

  setSessions: (sessions) => set({ sessions }),

  addMessage: (message) =>
    set((state) => ({
      messages: [...state.messages, message],
    })),

  setMessages: (messages) => set({ messages }),

  setLoading: (loading) => set({ isLoading: loading }),

  setError: (error) => set({ error }),

  clearMessages: () => set({ messages: [] }),

  deleteSession: (sessionId) =>
    set((state) => ({
      sessions: state.sessions.filter((s) => s.id !== sessionId),
    })),
}))
