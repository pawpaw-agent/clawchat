import { Outlet, useLocation, useNavigate } from 'react-router-dom'

export default function MobileLayout() {
  const location = useLocation()
  const navigate = useNavigate()

  const isActive = (path: string) => {
    return location.pathname === path
  }

  return (
    <div className="flex flex-col h-full bg-white dark:bg-dark-bg">
      {/* 主内容区 */}
      <main className="flex-1 overflow-hidden">
        <Outlet />
      </main>

      {/* 底部导航 */}
      <nav className="flex-shrink-0 border-t border-gray-200 dark:border-dark-border safe-area-pb">
        <div className="flex justify-around items-center h-16">
          <NavItem
            icon="💬"
            label="聊天"
            active={isActive('/')}
            onClick={() => navigate('/')}
          />
          <NavItem
            icon="📊"
            label="控制台"
            active={isActive('/control')}
            onClick={() => navigate('/control')}
          />
          <NavItem
            icon="⚙️"
            label="设置"
            active={isActive('/settings')}
            onClick={() => navigate('/settings')}
          />
        </div>
      </nav>
    </div>
  )
}

function NavItem({
  icon,
  label,
  active,
  onClick,
}: {
  icon: string
  label: string
  active: boolean
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      className={`flex flex-col items-center justify-center w-full h-full space-y-1 ${
        active ? 'text-primary-500' : 'text-gray-400'
      }`}
    >
      <span className="text-xl">{icon}</span>
      <span className="text-xs font-medium">{label}</span>
    </button>
  )
}
