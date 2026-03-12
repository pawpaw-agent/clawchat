import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useGatewayStore } from '../stores/gatewayStore'
import { wsService } from '../services/websocket'

export default function Connection() {
  const navigate = useNavigate()
  const { connect } = useGatewayStore()

  useEffect(() => {
    const initConnection = async () => {
      const { host, token } = useGatewayStore.getState()
      
      if (!host || !token) {
        navigate('/settings')
        return
      }

      const success = await connect()
      
      if (success) {
        await wsService.connect()
        navigate('/')
      }
    }

    initConnection()
  }, [navigate])

  return (
    <div className="flex flex-col items-center justify-center h-full p-8">
      <div className="w-16 h-16 border-4 border-primary-500 border-t-transparent rounded-full animate-spin mb-4" />
      <h2 className="text-xl font-semibold mb-2">正在连接网关...</h2>
      <p className="text-gray-500 text-center">
        如果长时间无响应，请检查网关地址是否正确
      </p>
    </div>
  )
}
