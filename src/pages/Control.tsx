import { useEffect, useState } from 'react'
import { useGatewayStore } from '../stores/gatewayStore'

export default function Control() {
  const { host, port, connected, agents } = useGatewayStore()
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (connected) {
      fetchGatewayInfo()
    }
  }, [connected])

  const fetchGatewayInfo = async () => {
    setLoading(true)
    try {
      await fetch(`http://${host}:${port}`, {
        headers: {
          'Authorization': `Bearer ${useGatewayStore.getState().token}`,
        },
      })
    } catch (err) {
      console.error('Failed to fetch gateway info:', err)
    } finally {
      setLoading(false)
    }
  }

  if (!connected) {
    return (
      <div className="flex flex-col items-center justify-center h-full">
        <div className="text-6xl mb-4">🔌</div>
        <h2 className="text-xl font-semibold mb-2">未连接</h2>
        <p className="text-gray-500">请先连接网关</p>
      </div>
    )
  }

  return (
    <div className="p-4 space-y-6 overflow-y-auto h-full">
      {/* 网关状态 */}
      <section className="bg-gray-50 dark:bg-dark-surface rounded-xl p-4">
        <h2 className="text-lg font-semibold mb-4 flex items-center">
          <span className="mr-2">🖥️</span> 网关状态
        </h2>
        <div className="space-y-3">
          <StatusRow label="地址" value={`${host}:${port}`} />
          <StatusRow 
            label="状态" 
            value={connected ? '✅ 已连接' : '❌ 未连接'}
            valueClass={connected ? 'text-green-500' : 'text-red-500'}
          />
          <StatusRow label="Agent 数量" value={agents.length.toString()} />
        </div>
      </section>

      {/* Agent 列表 */}
      <section className="bg-gray-50 dark:bg-dark-surface rounded-xl p-4">
        <h2 className="text-lg font-semibold mb-4 flex items-center">
          <span className="mr-2">🤖</span> 智能体列表
        </h2>
        {loading ? (
          <div className="text-center text-gray-400 py-4">加载中...</div>
        ) : (
          <div className="space-y-2">
            {agents.map((agent) => (
              <div
                key={agent.id}
                className="flex items-center justify-between p-3 bg-white dark:bg-dark-bg rounded-lg"
              >
                <div>
                  <div className="font-medium">{agent.name || agent.id}</div>
                  <div className="text-xs text-gray-500">{agent.model || '-'}</div>
                </div>
                <span className="text-xs px-2 py-1 bg-green-100 text-green-700 rounded-full">
                  活跃
                </span>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* 快捷操作 */}
      <section className="bg-gray-50 dark:bg-dark-surface rounded-xl p-4">
        <h2 className="text-lg font-semibold mb-4 flex items-center">
          <span className="mr-2">⚡</span> 快捷操作
        </h2>
        <div className="grid grid-cols-2 gap-3">
          <ActionButton label="刷新状态" onClick={fetchGatewayInfo} />
          <ActionButton label="查看日志" onClick={() => window.open(`http://${host}:${port}/logs`, '_blank')} />
          <ActionButton label="会话管理" onClick={() => window.open(`http://${host}:${port}/sessions`, '_blank')} />
          <ActionButton label="网关设置" onClick={() => window.open(`http://${host}:${port}/settings`, '_blank')} />
        </div>
      </section>
    </div>
  )
}

function StatusRow({ label, value, valueClass = '' }: { label: string; value: string; valueClass?: string }) {
  return (
    <div className="flex justify-between items-center">
      <span className="text-gray-500">{label}</span>
      <span className={`font-medium ${valueClass}`}>{value}</span>
    </div>
  )
}

function ActionButton({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="px-4 py-3 bg-white dark:bg-dark-bg rounded-lg font-medium text-sm active:scale-95 transition-transform border border-gray-200 dark:border-dark-border"
    >
      {label}
    </button>
  )
}
