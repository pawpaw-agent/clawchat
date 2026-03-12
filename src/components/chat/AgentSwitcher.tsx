import { useChatStore } from '../../stores/chatStore'
import type { AgentInfo } from '../../stores/gatewayStore'

interface Props {
  agents: AgentInfo[]
  currentAgent: string
}

export default function AgentSwitcher({ agents, currentAgent }: Props) {
  const { setCurrentAgent } = useChatStore()

  const getAgentName = (agent: AgentInfo) => {
    return agent.name || agent.id
  }

  return (
    <div className="flex items-center justify-between">
      <div className="flex items-center space-x-2">
        <span className="text-lg">🤖</span>
        <select
          value={currentAgent}
          onChange={(e) => setCurrentAgent(e.target.value)}
          className="px-3 py-2 bg-gray-100 dark:bg-dark-surface rounded-lg font-medium text-sm border-0 focus:ring-2 focus:ring-primary-500"
        >
          {agents.map((agent) => (
            <option key={agent.id} value={agent.id}>
              {getAgentName(agent)}
            </option>
          ))}
          {agents.length === 0 && (
            <option value="main">Main</option>
          )}
        </select>
      </div>
      <div className="text-xs text-gray-500">
        {agents.length} 个智能体
      </div>
    </div>
  )
}
