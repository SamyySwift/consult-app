import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { animate, motion, useInView, useMotionValue, useMotionValueEvent } from 'motion/react'
import { BellRing, ChevronLeft, ChevronRight, CreditCard, Pause, Phone, Play, ShieldCheck } from 'lucide-react'
import Reveal from './Reveal.jsx'
import { highlights } from '../content.js'
import { nearest, project, spring, springFlick, springGentle } from '../lib/motion.js'

const AUTOPLAY_MS = 5000

export default function Highlights() {
  return (
    <section id="safety" data-nav="light" className="overflow-hidden bg-mist py-28 text-ink md:py-40">
      <div className="shell">
        <Reveal className="flex flex-wrap items-end justify-between gap-6">
          <div className="max-w-2xl">
            <p className="eyebrow text-brand">Safety, built in</p>
            <h2 className="display-lg mt-3">Every trip, covered.</h2>
          </div>
          <p className="max-w-sm text-ink-2">Checks, records and people you can reach — on every booking, at every speed.</p>
        </Reveal>
      </div>
      <Gallery />
    </section>
  )
}

/**
 * A horizontal gallery that tracks the pointer 1:1, projects a flick's momentum
 * to choose where to land, hands the release velocity to the settling spring,
 * and rubber-bands at the ends. While on screen it also advances one card at a
 * time, holding while the pointer rests on it or it has keyboard focus.
 */
function Gallery() {
  const viewport = useRef(null)
  const track = useRef(null)
  const x = useMotionValue(0)
  const [snaps, setSnaps] = useState([0])
  const [index, setIndex] = useState(0)
  const min = snaps[snaps.length - 1]

  const [playing, setPlaying] = useState(() => !window.matchMedia('(prefers-reduced-motion: reduce)').matches)
  const [hovered, setHovered] = useState(false)
  const [focused, setFocused] = useState(false)
  const inView = useInView(viewport, { amount: 0.5 })
  const running = playing && !hovered && !focused && inView

  useLayoutEffect(() => {
    const measure = () => {
      const cards = [...track.current.children]
      const first = cards[0].offsetLeft
      const maxScroll = Math.max(0, track.current.scrollWidth - viewport.current.clientWidth)
      const points = cards.map((c) => -Math.min(c.offsetLeft - first, maxScroll))
      setSnaps([...new Set(points)])
    }
    measure()
    const ro = new ResizeObserver(measure)
    ro.observe(viewport.current)
    return () => ro.disconnect()
  }, [])

  // Card sizes change across breakpoints, so stay on the same card when they do.
  useLayoutEffect(() => {
    x.jump(snaps[Math.min(index, snaps.length - 1)])
  }, [snaps])

  useMotionValueEvent(x, 'change', (v) => {
    const i = snaps.indexOf(nearest(snaps, v))
    setIndex((prev) => (prev === i ? prev : i))
  })

  const settle = useCallback(
    (target, velocity = 0) => {
      const flicked = Math.abs(velocity) > 400
      animate(x, target, { ...(flicked ? springFlick : spring), velocity })
    },
    [x],
  )

  const go = (dir) => {
    const next = Math.min(snaps.length - 1, Math.max(0, index + dir))
    settle(snaps[next])
  }

  // Wraps back to the first card after the last.
  const advance = () => animate(x, snaps[(index + 1) % snaps.length], springGentle)

  // Two-finger trackpad swipes move the gallery directly, then it settles.
  useEffect(() => {
    const el = viewport.current
    let timer
    const onWheel = (e) => {
      if (Math.abs(e.deltaX) <= Math.abs(e.deltaY)) return
      e.preventDefault()
      x.stop()
      x.set(Math.min(0, Math.max(min, x.get() - e.deltaX)))
      clearTimeout(timer)
      timer = setTimeout(() => settle(nearest(snaps, x.get())), 120)
    }
    el.addEventListener('wheel', onWheel, { passive: false })
    return () => {
      el.removeEventListener('wheel', onWheel)
      clearTimeout(timer)
    }
  }, [x, min, snaps, settle])

  const onKeyDown = (e) => {
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      go(1)
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault()
      go(-1)
    }
  }

  return (
    <div className="mt-14 md:mt-20">
      <div
        ref={viewport}
        role="region"
        aria-roledescription="carousel"
        aria-label="What every trip includes"
        tabIndex={0}
        onKeyDown={onKeyDown}
        onPointerEnter={() => setHovered(true)}
        onPointerLeave={() => setHovered(false)}
        onFocus={(e) => setFocused(e.currentTarget.matches(':focus-visible'))}
        onBlur={() => setFocused(false)}
        className="cursor-grab outline-none active:cursor-grabbing focus-visible:ring-2 focus-visible:ring-brand"
      >
        <motion.ul
          ref={track}
          drag="x"
          dragConstraints={{ left: min, right: 0 }}
          dragElastic={0.12}
          dragMomentum={false}
          onDragStart={() => x.stop()}
          onDragEnd={(_, info) => {
            const projected = x.get() + project(info.velocity.x)
            settle(nearest(snaps, projected), info.velocity.x)
          }}
          style={{ x, touchAction: 'pan-y' }}
          className="flex w-max gap-5 pl-[max(1.25rem,calc((100vw_-_var(--shell-width))/2_+_2rem))] pr-5 select-none sm:pr-8 max-sm:pl-5 lg:[--card-w:min(calc(var(--shell-width)_-_4rem),calc(100vw_-_10rem))] lg:pl-[calc((100vw_-_var(--card-w))/2)] lg:pr-[calc((100vw_-_var(--card-w))/2)]"
        >
          {highlights.map((h, i) => (
            <li
              key={h.id}
              aria-roledescription="slide"
              aria-label={`${i + 1} of ${highlights.length}: ${h.eyebrow}`}
              className="w-[84vw] shrink-0 sm:w-[372px] lg:w-(--card-w)"
            >
              <Card item={h} />
            </li>
          ))}
        </motion.ul>
      </div>

      <div className="shell mt-8 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <PaddleButton label={playing ? 'Pause autoplay' : 'Play autoplay'} onClick={() => setPlaying((p) => !p)}>
            {playing ? <Pause className="h-4 w-4" fill="currentColor" /> : <Play className="h-4 w-4" fill="currentColor" />}
          </PaddleButton>
          <div className="flex gap-1.5" aria-hidden="true">
            {snaps.map((s, i) => (
              <span
                key={s}
                className={`relative h-1.5 overflow-hidden rounded-full bg-ink/25 transition-all duration-300 ${i === index ? 'w-6' : 'w-1.5'}`}
              >
                {/* The fill doubles as the timer: the next card comes when it completes */}
                {i === index && (
                  <span
                    className="absolute inset-0 origin-left rounded-full bg-ink"
                    style={
                      playing && snaps.length > 1
                        ? { animation: `gallery-progress ${AUTOPLAY_MS}ms linear forwards`, animationPlayState: running ? 'running' : 'paused' }
                        : undefined
                    }
                    onAnimationEnd={advance}
                  />
                )}
              </span>
            ))}
          </div>
        </div>
        <div className="flex gap-3">
          <PaddleButton label="Previous" onClick={() => go(-1)} disabled={index === 0}>
            <ChevronLeft className="h-5 w-5" />
          </PaddleButton>
          <PaddleButton label="Next" onClick={() => go(1)} disabled={index === snaps.length - 1}>
            <ChevronRight className="h-5 w-5" />
          </PaddleButton>
        </div>
      </div>
    </div>
  )
}

function PaddleButton({ label, onClick, disabled, children }) {
  return (
    <button
      type="button"
      aria-label={label}
      onClick={onClick}
      disabled={disabled}
      className="pressable grid h-11 w-11 place-items-center rounded-full bg-hairline/70 text-ink hover:bg-hairline disabled:opacity-35 disabled:active:scale-100"
    >
      {children}
    </button>
  )
}

function Card({ item }) {
  const Visual = visuals[item.id]
  const photo = Boolean(item.image)
  const dark = photo || item.tone === 'dark'
  return (
    <article
      className={`relative flex h-[520px] flex-col overflow-hidden rounded-[28px] lg:grid lg:h-[620px] lg:grid-cols-[minmax(0,5fr)_minmax(0,6fr)] lg:rounded-[32px] ${dark ? 'bg-night text-snow' : 'bg-paper text-ink'}`}
    >
      {photo && (
        <>
          <picture className="absolute inset-0">
            {item.imageWide && <source media="(min-width: 1024px)" srcSet={item.imageWide} />}
            <img
              src={item.image}
              alt=""
              draggable="false"
              className="h-full w-full object-cover"
              style={{ objectPosition: item.imagePosition }}
              loading="lazy"
            />
          </picture>
          <div className="absolute inset-0 bg-gradient-to-b from-black/80 via-black/25 to-black/60 lg:bg-gradient-to-r lg:from-black/85 lg:via-black/45 lg:to-black/15" />
        </>
      )}
      {/* Stacked on small screens; side by side on wide ones, text anchored low like a poster */}
      <div className="relative p-7 md:p-8 lg:flex lg:flex-col lg:justify-end lg:p-12">
        <p className="text-[0.9375rem] font-semibold text-brand lg:text-[1.0625rem]">{item.eyebrow}</p>
        <h3 className="title mt-2 lg:headline lg:mt-3">{item.title}</h3>
        <p className={`mt-3 text-[0.9375rem] lg:mt-4 lg:max-w-[26rem] lg:text-[1.0625rem] ${photo ? 'text-snow/80' : dark ? 'text-fog' : 'text-ink-2'}`}>
          {item.body}
        </p>
      </div>
      {/* Over a photo the visual keeps to the corner so the subject stays clear */}
      <div className={`relative mt-auto lg:mt-0 lg:grid lg:p-8 ${photo ? 'lg:items-end lg:justify-items-end' : 'lg:place-items-center'}`}>
        <div className="w-full lg:max-w-[440px] lg:[zoom:1.2]">
          <Visual />
        </div>
      </div>
    </article>
  )
}

// ---- Small visuals, one per card ----

function Chip({ children, className = '' }) {
  return (
    <span className={`glass-panel inline-flex items-center gap-2 rounded-full px-3.5 py-2 text-[0.8125rem] font-medium text-snow ${className}`}>
      <span className="grid h-4 w-4 place-items-center rounded-full bg-brand text-[0.625rem] font-bold text-black">✓</span>
      {children}
    </span>
  )
}

function DriversVisual() {
  return (
    <div className="flex flex-col items-start gap-2 p-7 md:p-8">
      <Chip>NIN verified</Chip>
      <Chip>Driver’s licence on file</Chip>
      <Chip>Next of kin recorded</Chip>
    </div>
  )
}

// Crops of the carrier photo standing in for pickup shots, each with its capture time.
const inspectionShots = [
  ['60% 45%', '10:41'],
  ['72% 30%', '10:41'],
  ['52% 68%', '10:42'],
  ['66% 75%', '10:42'],
]

function InspectionVisual() {
  return (
    <div className="px-7 pb-7 md:px-8 md:pb-8">
      <div className="grid grid-cols-2 gap-2">
        {inspectionShots.map(([pos, time]) => (
          <div
            key={pos}
            className="relative aspect-[4/3] rounded-xl bg-graphite"
            style={{ backgroundImage: 'url(/images/carrier-1200.webp)', backgroundSize: '280%', backgroundPosition: pos }}
          >
            <span className="absolute bottom-1.5 left-1.5 rounded-md bg-black/60 px-1.5 py-0.5 text-[0.6875rem] font-medium tabular-nums text-white">
              {time}
            </span>
          </div>
        ))}
      </div>
      <div className="mt-2 flex items-center gap-3 rounded-xl bg-white/8 px-3 py-2.5">
        <span className="h-2 w-2 rounded-full bg-brand" />
        <span className="flex h-4 flex-1 items-center gap-[3px]">
          {[5, 10, 14, 7, 12, 16, 9, 6, 13, 15, 8, 6, 12, 9, 5, 8, 11, 7].map((h, i) => (
            <span key={i} className="w-[3px] rounded-full bg-white/55" style={{ height: h }} />
          ))}
        </span>
        <span className="caption text-fog">Voice note · 0:14</span>
      </div>
    </div>
  )
}

function CallVisual() {
  return (
    <div className="mx-7 mb-7 flex flex-col items-center overflow-hidden rounded-[22px] bg-slate px-6 pb-7 pt-8 text-snow ring-1 ring-white/8 md:mx-8 md:mb-8">
      <span className="grid h-16 w-16 place-items-center rounded-full bg-white/10 text-[1.25rem] font-semibold">AD</span>
      <p className="mt-3 font-semibold">Your driver</p>
      <p className="text-[0.875rem] text-fog">Arriving in 30 minutes</p>
      <span className="relative mt-5 grid h-14 w-14 place-items-center rounded-full bg-brand text-black">
        <span className="live-ping absolute inset-0 rounded-full bg-brand" />
        <Phone className="relative h-6 w-6" aria-hidden="true" />
      </span>
    </div>
  )
}

function LiveVisual() {
  return (
    <div className="px-7 pb-7 md:px-8 md:pb-8">
      <div className="glass-panel rounded-[22px] p-2.5">
        <svg viewBox="0 0 320 200" className="w-full rounded-[16px] bg-night" aria-hidden="true">
          <g stroke="#1f1f22" strokeWidth="9" fill="none" strokeLinecap="round">
            <path d="M-10 60 L330 36" />
            <path d="M-10 150 C90 140 170 180 330 130" />
            <path d="M70 -10 L96 210" />
            <path d="M230 -10 C220 80 250 150 240 210" />
          </g>
          <path id="live-route" d="M40 180 C60 130 90 120 150 128 S230 90 250 30" fill="none" stroke="#00c853" strokeWidth="9" opacity="0.18" strokeLinecap="round" />
          <motion.path
            d="M40 180 C60 130 90 120 150 128 S230 90 250 30"
            fill="none"
            stroke="#00c853"
            strokeWidth="3.5"
            strokeLinecap="round"
            initial={{ pathLength: 0 }}
            whileInView={{ pathLength: 0.62 }}
            viewport={{ once: true }}
            transition={{ duration: 2, ease: [0.28, 0.11, 0.32, 1] }}
          />
          <circle cx="40" cy="180" r="6" fill="#fff" stroke="#00c853" strokeWidth="3" />
          <circle cx="250" cy="30" r="6" fill="#00c853" />
        </svg>
        <p className="flex items-center justify-between px-1.5 pb-0.5 pt-2.5 text-[0.875rem]">
          <span className="font-semibold">Arrives in about 1 hr 25 min</span>
          <span className="text-fog">with current traffic</span>
        </p>
      </div>
    </div>
  )
}

function InsuranceVisual() {
  return (
    <div className="px-7 pb-7 md:px-8 md:pb-8">
      <div className="glass-panel flex items-center gap-5 rounded-[22px] p-5">
        <ShieldCheck className="h-16 w-16 shrink-0 text-brand" strokeWidth={1.25} aria-hidden="true" />
        <ul className="space-y-1.5 text-[0.875rem] text-snow/85">
          <li>Accidents</li>
          <li>Theft &amp; vandalism</li>
          <li>Weather damage</li>
        </ul>
      </div>
    </div>
  )
}

function HandoverVisual() {
  return (
    <div className="p-7 md:p-8">
      <div className="glass-panel rounded-[18px] p-4">
        <p className="caption uppercase tracking-[0.08em] text-fog">Recipient signature</p>
        <svg viewBox="0 0 280 80" className="mt-1 h-16 w-full" aria-hidden="true">
          <motion.path
            d="M8 58c14-30 26-44 32-36s-12 40-4 42 18-40 30-38-6 34 4 34 16-26 26-24-2 22 8 20 14-20 24-18 4 16 14 14 22-12 36-10 40 2 62-4"
            fill="none"
            stroke="#fff"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            initial={{ pathLength: 0 }}
            whileInView={{ pathLength: 1 }}
            viewport={{ once: true, amount: 1 }}
            transition={{ duration: 1.6, ease: 'easeInOut', delay: 0.2 }}
          />
        </svg>
        <p className="mt-1 flex items-center justify-between border-t border-white/15 pt-2 text-[0.8125rem]">
          <span className="font-medium">Proof of handover</span>
          <span className="text-brand">Saved</span>
        </p>
      </div>
    </div>
  )
}

function PaymentsVisual() {
  return (
    <div className="px-7 pb-7 md:px-8 md:pb-8">
      <div className="rounded-[20px] bg-mist p-5">
        <div className="flex items-center justify-between">
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-ink text-snow">
            <CreditCard className="h-5 w-5" aria-hidden="true" />
          </span>
          <span className="rounded-full bg-brand px-2.5 py-1 text-[0.75rem] font-semibold text-black">Paid</span>
        </div>
        <p className="mt-5 text-[2rem] font-semibold tracking-[-0.03em]">₦150,000</p>
        <p className="text-[0.875rem] text-ink-2">Express · Enclosed transport</p>
        <p className="caption mt-4 border-t border-hairline pt-3 text-ink-3">Processed securely by Paystack</p>
      </div>
    </div>
  )
}

// Newest first, as in a notification stack.
const alerts = [
  ['Out for delivery', 'Almost there!'],
  ['In transit', 'Your vehicle is on its way.'],
  ['Vehicle picked up', 'Your driver has collected your vehicle.'],
]

function AlertsVisual() {
  return (
    <div className="space-y-2 px-5 pb-7 md:px-6 md:pb-8">
      {alerts.map(([title, body], i) => (
        <motion.div
          key={title}
          initial={{ opacity: 0, y: 16, scale: 0.96 }}
          whileInView={{ opacity: 1 - i * 0.18, y: 0, scale: 1 - i * 0.02 }}
          viewport={{ once: true, amount: 0.6 }}
          transition={{ ...spring, delay: 0.15 * (alerts.length - i) }}
          className="flex items-start gap-3 rounded-[18px] bg-white/8 p-3.5"
        >
          <span className="grid h-9 w-9 shrink-0 place-items-center rounded-[10px] bg-night text-brand">
            <BellRing className="h-4 w-4" aria-hidden="true" />
          </span>
          <span className="text-[0.8125rem] leading-snug">
            <span className="flex justify-between gap-2 font-semibold">
              {title}
              <span className="font-normal text-fog">{i === 0 ? 'now' : `${i * 2}h ago`}</span>
            </span>
            <span className="text-fog">{body}</span>
          </span>
        </motion.div>
      ))}
    </div>
  )
}

const visuals = {
  drivers: DriversVisual,
  inspection: InspectionVisual,
  call: CallVisual,
  live: LiveVisual,
  insurance: InsuranceVisual,
  handover: HandoverVisual,
  payments: PaymentsVisual,
  alerts: AlertsVisual,
}
