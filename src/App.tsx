import { Routes, Route } from 'react-router-dom'
import MobileLayout from './components/layout/MobileLayout'
import Chat from './pages/Chat'
import Control from './pages/Control'
import Settings from './pages/Settings'
import Connection from './pages/Connection'

function App() {
  return (
    <Routes>
      <Route path="/" element={<MobileLayout />}>
        <Route index element={<Chat />} />
        <Route path="control" element={<Control />} />
        <Route path="settings" element={<Settings />} />
      </Route>
      <Route path="connection" element={<Connection />} />
    </Routes>
  )
}

export default App
