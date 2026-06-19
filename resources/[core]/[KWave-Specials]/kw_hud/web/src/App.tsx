import { useState, useEffect } from 'react'
import './index.css'

interface Status {
  health: number
  armor: number
  hunger: number
  thirst: number
  voice: number // 1-3
  isTalking: boolean
}

interface VehicleInfo {
  speed: number
  rpm: number
  gear: number
  seatbelt: boolean
}

function App() {
  const [showHud, setShowHud] = useState(false)
  const [showVeh, setShowVeh] = useState(false)
  
  const [status, setStatus] = useState<Status>({
    health: 100,
    armor: 0,
    hunger: 100,
    thirst: 100,
    voice: 2,
    isTalking: false
  })

  const [veh, setVeh] = useState<VehicleInfo>({
    speed: 0,
    rpm: 0,
    gear: 0,
    seatbelt: false
  })

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data

      if (action === 'displayHud') {
        setShowHud(data.display)
      } else if (action === 'updateStatus') {
        setStatus(prev => ({ ...prev, ...data }))
      } else if (action === 'showCarHud') {
        setShowVeh(true)
      } else if (action === 'hideCarHud') {
        setShowVeh(false)
      } else if (action === 'updateCarHud') {
        setVeh(prev => ({ ...prev, ...data }))
      }
    }

    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])

  if (!showHud) return null

  return (
    <div id="app">
      {/* Player Status HUD */}
      <div className="hud-container" style={{ opacity: showHud ? 1 : 0 }}>
        
        <div className="hud-item" style={{ opacity: status.isTalking ? 1 : 0.5 }}>
          <span className="material-symbols-rounded hud-icon">mic</span>
          <div className="hud-bar-bg">
            <div className="hud-bar-fill" style={{ width: `${(status.voice / 3) * 100}%` }}></div>
          </div>
        </div>

        <div className="hud-item">
          <span className="material-symbols-rounded hud-icon">favorite</span>
          <div className="hud-bar-bg">
            <div className="hud-bar-fill" style={{ width: `${status.health}%` }}></div>
          </div>
        </div>

        {status.armor > 0 && (
          <div className="hud-item">
            <span className="material-symbols-rounded hud-icon">shield</span>
            <div className="hud-bar-bg">
              <div className="hud-bar-fill" style={{ width: `${status.armor}%` }}></div>
            </div>
          </div>
        )}

        <div className="hud-item">
          <span className="material-symbols-rounded hud-icon">restaurant</span>
          <div className="hud-bar-bg">
            <div className="hud-bar-fill" style={{ width: `${status.hunger}%` }}></div>
          </div>
        </div>

        <div className="hud-item">
          <span className="material-symbols-rounded hud-icon">water_drop</span>
          <div className="hud-bar-bg">
            <div className="hud-bar-fill" style={{ width: `${status.thirst}%` }}></div>
          </div>
        </div>

      </div>

      {/* Vehicle Speedometer */}
      {showVeh && (
        <>
          <div className="speedometer">
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '4px' }}>
              <span className="speed-value">{Math.round(veh.speed)}</span>
              <span className="speed-unit">KMH</span>
            </div>
            <div className="rpm-bar-bg">
              <div 
                className="hud-bar-fill" 
                style={{ 
                  width: `${veh.rpm * 100}%`,
                  backgroundColor: veh.rpm > 0.85 ? '#ff5555' : 'var(--fg)' 
                }}
              ></div>
            </div>
          </div>

        </>
      )}
    </div>
  )
}

export default App
