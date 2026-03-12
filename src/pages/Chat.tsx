import { useState, useEffect, useRef } from 'react'
import { useGatewayStore } from '../stores/gatewayStore'
import { useChatStore } from '../stores/chatStore'
import { wsService } from '../services/websocket'
import AgentSwitcher from '../components/chat/AgentSwitcher'
import MessageList from '../components/chat/MessageList'
import ChatInput from '../components/chat/ChatInput'

export default function Chat() {
  const { connected, agents } = useGatewayStore()
  const { messages, isLoading, currentAgent } = useChatStore()
  const [input, setInput] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const handleSend = async () => {
    if (!input.trim() || !connected || isLoading) return

    try {
      await wsService.sendMessage(input.trim())
      setInput('')
    } catch (err) {
      console.error('Failed to send message:', err)
    }
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  if (!connected) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8 text-center">
        <div className="text-6xl mb-4">🔌</div>
        <h2 className="text-xl font-semibold mb-2">未连接到网关</h2>
        <p className="text-gray-500 mb-4">请先在设置中配置网关地址</p>
        <a
          href="/settings"
          className="px-6 py-3 bg-primary-500 text-white rounded-lg font-medium"
        >
          去设置
        </a>
      </div>
    )
  }

  return (
    <div className="flex flex-col h-full">
      {/* 头部 - Agent 切换 */}
      <header className="flex-shrink-0 px-4 py-3 border-b border-gray-200 dark:border-dark-border">
        <AgentSwitcher agents={agents} currentAgent={currentAgent} />
      </header>

      {/* 消息列表 */}
      <div className="flex-1 overflow-y-auto">
        <MessageList messages={messages} isLoading={isLoading} />
        <div ref={messagesEndRef} />
      </div>

      {/* 输入区域 */}
      <footer className="flex-shrink-0 p-4 border-t border-gray-200 dark:border-dark-border">
        <ChatInput
          value={input}
          onChange={setInput}
          onSend={handleSend}
          onKeyPress={handleKeyPress}
          disabled={!connected || isLoading}
          placeholder="输入消息..."
        />
      </footer>
    </div>
  )
}
