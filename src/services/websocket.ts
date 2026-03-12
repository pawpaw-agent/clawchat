import { useGatewayStore } from '../stores/gatewayStore'
import { useChatStore, type Message } from '../stores/chatStore'

export class WebSocketService {
  private ws: WebSocket | null = null
  private reconnectAttempts = 0
  private maxReconnects = 5
  private reconnectDelay = 1000
  private heartbeatInterval: number | null = null
  private messageQueue: any[] = []

  connect(): Promise<boolean> {
    return new Promise((resolve) => {
      const { host, port, token } = useGatewayStore.getState()

      if (!host || !token) {
        resolve(false)
        return
      }

      const url = `ws://${host}:${port}/ws?token=${token}`

      try {
        this.ws = new WebSocket(url)

        this.ws.onopen = () => {
          console.log('WebSocket connected')
          this.reconnectAttempts = 0
          useGatewayStore.getState().setConnected(true)
          this.startHeartbeat()
          this.flushMessageQueue()
          resolve(true)
        }

        this.ws.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data)
            this.handleMessage(data)
          } catch (err) {
            console.error('Failed to parse message:', err)
          }
        }

        this.ws.onerror = (error) => {
          console.error('WebSocket error:', error)
          useGatewayStore.getState().setError('WebSocket 连接错误')
        }

        this.ws.onclose = (event) => {
          console.log('WebSocket closed:', event.code, event.reason)
          useGatewayStore.getState().setConnected(false)
          this.stopHeartbeat()
          
          if (!event.wasClean && this.reconnectAttempts < this.maxReconnects) {
            this.scheduleReconnect()
          }
        }
      } catch (err) {
        console.error('Failed to create WebSocket:', err)
        resolve(false)
      }
    })
  }

  private handleMessage(data: any) {
    const { addMessage } = useChatStore.getState()

    if (data.type === 'message') {
      const message: Message = {
        id: data.id || Date.now().toString(),
        role: 'assistant',
        content: data.content,
        timestamp: data.timestamp || Date.now(),
        agent: data.agent,
        sessionId: data.sessionId,
      }
      addMessage(message)
      useChatStore.getState().setLoading(false)
    } else if (data.type === 'error') {
      useChatStore.getState().setError(data.message)
      useChatStore.getState().setLoading(false)
    }
  }

  sendMessage(content: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const { currentAgent } = useChatStore.getState()
      const { connected } = useGatewayStore.getState()

      if (!connected || !this.ws) {
        reject(new Error('未连接到网关'))
        return
      }

      const message = {
        type: 'message',
        agent: currentAgent,
        content,
        timestamp: Date.now(),
      }

      // 添加用户消息到聊天
      const userMessage: Message = {
        id: Date.now().toString(),
        role: 'user',
        content,
        timestamp: Date.now(),
        agent: currentAgent,
      }
      useChatStore.getState().addMessage(userMessage)
      useChatStore.getState().setLoading(true)

      try {
        this.ws.send(JSON.stringify(message))
        resolve()
      } catch (err) {
        // 连接断开时加入队列
        this.messageQueue.push(message)
        reject(err)
      }
    })
  }

  private scheduleReconnect() {
    this.reconnectAttempts++
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1)
    
    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`)
    
    setTimeout(() => {
      this.connect()
    }, delay)
  }

  private flushMessageQueue() {
    while (this.messageQueue.length > 0 && this.ws) {
      const message = this.messageQueue.shift()
      this.ws.send(JSON.stringify(message))
    }
  }

  private startHeartbeat() {
    this.heartbeatInterval = window.setInterval(() => {
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ type: 'ping' }))
      }
    }, 30000) // 30 秒心跳
  }

  private stopHeartbeat() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
      this.heartbeatInterval = null
    }
  }

  disconnect() {
    this.stopHeartbeat()
    if (this.ws) {
      this.ws.close()
      this.ws = null
    }
  }
}

export const wsService = new WebSocketService()
