import { useState } from 'react'
import { useGatewayStore } from '../stores/gatewayStore'
import { wsService } from '../services/websocket'

export default function Settings() {
  const { host, port, token, connected, setConfig, connect, disconnect } = useGatewayStore()
  
  const [tempHost, setTempHost] = useState(host)
  const [tempPort, setTempPort] = useState(port.toString())
  const [tempToken, setTempToken] = useState(token)
  const [testing, setTesting] = useState(false)
  const [testResult, setTestResult] = useState<string | null>(null)

  const handleSave = () => {
    setConfig(tempHost, parseInt(tempPort) || 18789, tempToken)
    setTestResult('配置已保存')
    setTimeout(() => setTestResult(null), 2000)
  }

  const handleTest = async () => {
    setTesting(true)
    setTestResult(null)
    
    setConfig(tempHost, parseInt(tempPort) || 18789, tempToken)
    const success = await connect()
    
    setTestResult(success ? '✅ 连接成功' : '❌ 连接失败')
    setTesting(false)
    
    if (success) {
      wsService.connect()
    }
  }

  const handleDisconnect = () => {
    disconnect()
    wsService.disconnect()
    setTestResult('已断开连接')
  }

  return (
    <div className="p-4 space-y-6 overflow-y-auto h-full">
      {/* 连接配置 */}
      <section className="bg-gray-50 dark:bg-dark-surface rounded-xl p-4">
        <h2 className="text-lg font-semibold mb-4 flex items-center">
          <span className="mr-2">🔌</span> 网关配置
        </h2>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              网关地址
            </label>
            <input
              type="text"
              value={tempHost}
              onChange={(e) => setTempHost(e.target.value)}
              placeholder="192.168.x.x"
              className="w-full px-4 py-3 bg-white dark:bg-dark-bg border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
            <p className="text-xs text-gray-500 mt-1">本地网络中的 OpenClaw 网关 IP</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              端口
            </label>
            <input
              type="number"
              value={tempPort}
              onChange={(e) => setTempPort(e.target.value)}
              placeholder="18789"
              className="w-full px-4 py-3 bg-white dark:bg-dark-bg border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              认证 Token
            </label>
            <input
              type="password"
              value={tempToken}
              onChange={(e) => setTempToken(e.target.value)}
              placeholder="输入 Token"
              className="w-full px-4 py-3 bg-white dark:bg-dark-bg border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
            <p className="text-xs text-gray-500 mt-1">OpenClaw 网关认证 Token</p>
          </div>
        </div>

        {/* 测试结果 */}
        {testResult && (
          <div className={`mt-4 p-3 rounded-lg text-sm ${
            testResult.includes('✅') ? 'bg-green-100 text-green-700' :
            testResult.includes('❌') ? 'bg-red-100 text-red-700' :
            'bg-blue-100 text-blue-700'
          }`}>
            {testResult}
          </div>
        )}

        {/* 操作按钮 */}
        <div className="mt-6 space-y-3">
          <button
            onClick={handleTest}
            disabled={testing}
            className="w-full px-4 py-3 bg-primary-500 text-white rounded-lg font-medium disabled:opacity-50"
          >
            {testing ? '测试中...' : connected ? '重新连接' : '测试连接'}
          </button>
          
          <button
            onClick={handleSave}
            className="w-full px-4 py-3 bg-gray-200 dark:bg-dark-border text-gray-700 dark:text-gray-300 rounded-lg font-medium"
          >
            保存配置
          </button>

          {connected && (
            <button
              onClick={handleDisconnect}
              className="w-full px-4 py-3 bg-red-100 text-red-600 rounded-lg font-medium"
            >
              断开连接
            </button>
          )}
        </div>
      </section>

      {/* 关于 */}
      <section className="bg-gray-50 dark:bg-dark-surface rounded-xl p-4">
        <h2 className="text-lg font-semibold mb-4 flex items-center">
          <span className="mr-2">ℹ️</span> 关于
        </h2>
        <div className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
          <div className="flex justify-between">
            <span>应用</span>
            <span>ClawChat</span>
          </div>
          <div className="flex justify-between">
            <span>版本</span>
            <span>1.0.0</span>
          </div>
          <div className="flex justify-between">
            <span>GitHub</span>
            <a 
              href="https://github.com/pawpaw-agent/clawchat" 
              target="_blank"
              className="text-primary-500"
            >
              pawpaw-agent/clawchat
            </a>
          </div>
        </div>
      </section>
    </div>
  )
}
