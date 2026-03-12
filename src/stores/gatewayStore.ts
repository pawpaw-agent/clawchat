import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export interface GatewayState {
  host: string
  port: number
  token: string
  connected: boolean
  connecting: boolean
  error: string | null
  agents: AgentInfo[]
}

export interface AgentInfo {
  id: string
  name?: string
  model?: string
  workspace?: string
}

interface GatewayActions {
  setConfig: (host: string, port: number, token: string) => void
  setConnected: (connected: boolean) => void
  setConnecting: (connecting: boolean) => void
  setError: (error: string | null) => void
  setAgents: (agents: AgentInfo[]) => void
  connect: () => Promise<boolean>
  disconnect: () => void
  testConnection: () => Promise<boolean>
  fetchAgents: () => Promise<void>
}

const initialState: GatewayState = {
  host: '',
  port: 18789,
  token: '',
  connected: false,
  connecting: false,
  error: null,
  agents: [],
}

export const useGatewayStore = create<GatewayState & GatewayActions>()(
  persist(
    (set, get) => ({
      ...initialState,

      setConfig: (host, port, token) =>
        set({ host, port, token, error: null }),

      setConnected: (connected) => set({ connected }),
      setConnecting: (connecting) => set({ connecting }),
      setError: (error) => set({ error }),
      setAgents: (agents) => set({ agents }),

      testConnection: async () => {
        const { host, port, token } = get()
        if (!host || !token) {
          set({ error: '请填写网关地址和 Token' })
          return false
        }

        set({ connecting: true, error: null })

        try {
          const url = `http://${host}:${port}`
          const response = await fetch(url, {
            method: 'GET',
            headers: {
              'Authorization': `Bearer ${token}`,
            },
          })

          if (response.ok) {
            set({ connected: true, connecting: false })
            return true
          } else {
            set({ 
              connected: false, 
              connecting: false, 
              error: `连接失败：${response.status}` 
            })
            return false
          }
        } catch (err) {
          set({ 
            connected: false, 
            connecting: false, 
            error: `无法连接到网关：${err instanceof Error ? err.message : '未知错误'}` 
          })
          return false
        }
      },

      connect: async () => {
        const success = await get().testConnection()
        if (success) {
          // 获取 Agent 列表
          await get().fetchAgents()
        }
        return success
      },

      disconnect: () => {
        set({ connected: false, agents: [] })
      },

      fetchAgents: async () => {
        const { host, port, token } = get()
        try {
          const response = await fetch(`http://${host}:${port}/agents/list`, {
            headers: {
              'Authorization': `Bearer ${token}`,
            },
          })
          if (response.ok) {
            const data = await response.json()
            set({ agents: data.agents || [] })
          }
        } catch (err) {
          console.error('Failed to fetch agents:', err)
        }
      },
    }),
    {
      name: 'gateway-config',
      partialize: (state) => ({
        host: state.host,
        port: state.port,
        token: state.token,
      }),
    }
  )
)
