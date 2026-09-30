import { useMemo, useRef, useState } from 'react'
import { motion, useReducedMotion, useTransform } from 'motion/react'
import { MAP_HEIGHT, MAP_WIDTH, OUTLINE, STATES, project } from '../data/nigeria.js'
import { cities, routes } from '../content.js'

const GREEN = '#00c853'

/** A gentle arc between two cities, bowing to the left of travel. */
function arc(fromKey, toKey) {
  const [x1, y1] = project(cities[fromKey].at)
  const [x2, y2] = project(cities[toKey].at)
  const dx = x2 - x1
  const dy = y2 - y1
  const len = Math.hypot(dx, dy)
  const bow = Math.min(90, len * 0.16)
  const cx = (x1 + x2) / 2 + (dy / len) * bow
  const cy = (y1 + y2) / 2 - (dx / len) * bow
  return `M${x1.toFixed(1)},${y1.toFixed(1)} Q${cx.toFixed(1)},${cy.toFixed(1)} ${x2.toFixed(1)},${y2.toFixed(1)}`
}

/**
 * Nigeria's 36 states and the FCT, the network of common routes, and one live
 * trip whose progress (0–1) is driven from outside.
 */
export default function NigeriaMap({ trip, progress }) {
  const reduce = useReducedMotion()
  const [hovered, setHovered] = useState(null)
  const activePath = useRef(null)
  const network = useMemo(() => routes.map(([a, b]) => ({ id: `${a}-${b}`, d: arc(a, b) })), [])
  const tripPath = useMemo(() => arc(trip.from, trip.to), [trip])

  const point = (p, axis) => {
    const el = activePath.current
    if (!el) return 0
    return el.getPointAtLength(el.getTotalLength() * p)[axis]
  }
  const vx = useTransform(progress, (p) => point(p, 'x'))
  const vy = useTransform(progress, (p) => point(p, 'y'))

  return (
    <div className="relative">
      <p aria-live="polite" className="pointer-events-none mb-3 text-[0.8125rem] font-medium text-fog sm:absolute sm:left-0 sm:top-0 sm:mb-0">
        {hovered ?? 'Nigeria · 36 states + FCT'}
      </p>
      <svg
        viewBox={`0 0 ${MAP_WIDTH} ${MAP_HEIGHT}`}
        className="h-auto w-full"
        role="img"
        aria-label={`Map of Nigeria showing Carpital's delivery network, with a live trip from ${cities[trip.from].name} to ${cities[trip.to].name}`}
        onPointerLeave={() => setHovered(null)}
      >
        <defs>
          <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="6" />
          </filter>
          <radialGradient id="map-sheen" cx="35%" cy="70%" r="75%">
            <stop offset="0%" stopColor="#1c1c1f" />
            <stop offset="100%" stopColor="#111113" />
          </radialGradient>
        </defs>

        <g>
          {STATES.map((s) => (
            <path
              key={s.name}
              d={s.d}
              fill={hovered === s.name ? '#232327' : 'url(#map-sheen)'}
              stroke="#2c2c30"
              strokeWidth="1"
              vectorEffect="non-scaling-stroke"
              onPointerEnter={() => setHovered(s.name)}
              className="transition-[fill] duration-200"
            />
          ))}
        </g>
        <path d={OUTLINE} fill="none" stroke="#45454a" strokeWidth="1.5" vectorEffect="non-scaling-stroke" pointerEvents="none" />

        <g pointerEvents="none">
          {network.map((r, i) => (
            <motion.path
              key={r.id}
              d={r.d}
              fill="none"
              stroke={GREEN}
              strokeOpacity="0.28"
              strokeWidth="1.5"
              strokeLinecap="round"
              vectorEffect="non-scaling-stroke"
              initial={reduce ? false : { pathLength: 0 }}
              whileInView={{ pathLength: 1 }}
              viewport={{ once: true, amount: 0.4 }}
              transition={{ duration: 1.4, ease: [0.28, 0.11, 0.32, 1], delay: 0.2 + i * 0.05 }}
            />
          ))}

          {/* Active trip: the route lights up behind the vehicle */}
          <path ref={activePath} d={tripPath} fill="none" stroke="none" />
          <motion.path d={tripPath} fill="none" stroke={GREEN} strokeWidth="8" strokeLinecap="round" filter="url(#glow)" opacity="0.55" style={{ pathLength: progress }} />
          <motion.path d={tripPath} fill="none" stroke={GREEN} strokeWidth="3" strokeLinecap="round" style={{ pathLength: progress }} />
          <path d={tripPath} fill="none" stroke="#f5f5f7" strokeOpacity="0.35" strokeWidth="1.5" strokeDasharray="2 8" strokeLinecap="round" />

          {Object.entries(cities).map(([key, c]) => {
            const [x, y] = project(c.at)
            const isEnd = key === trip.from || key === trip.to
            return (
              <g key={key} transform={`translate(${x.toFixed(1)} ${y.toFixed(1)})`}>
                {isEnd && <circle r="16" fill={GREEN} opacity="0.18" />}
                <circle r={isEnd ? 6.5 : 4.5} fill={isEnd ? GREEN : '#f5f5f7'} stroke="#0d0d0e" strokeWidth="2" />
                <text
                  x="12"
                  y="6"
                  fontSize={isEnd ? 21 : 17}
                  fontWeight={isEnd ? 600 : 500}
                  fill={isEnd ? '#f5f5f7' : '#8e8e93'}
                  // On phones the map is ~⅓ scale, so trip labels grow to stay legible.
                  className={isEnd ? 'max-sm:[font-size:44px]' : 'max-sm:hidden'}
                  style={{ paintOrder: 'stroke', stroke: '#0d0d0e', strokeWidth: 4, strokeLinejoin: 'round' }}
                >
                  {c.name}
                </text>
              </g>
            )
          })}

          <motion.g style={{ x: vx, y: vy }}>
            <circle r="18" fill={GREEN} opacity="0.22" />
            <circle r="8" fill="#fff" stroke={GREEN} strokeWidth="4" />
          </motion.g>
        </g>
      </svg>
    </div>
  )
}
