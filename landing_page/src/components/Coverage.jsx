import { useEffect, useRef, useState } from 'react'
import { animate, motion, useInView, useMotionValue, useMotionValueEvent, useReducedMotion } from 'motion/react'
import { Check } from 'lucide-react'
import NigeriaMap from './NigeriaMap.jsx'
import Reveal from './Reveal.jsx'
import { cities, sampleTrips, timeline } from '../content.js'
import { spring } from '../lib/motion.js'

const TRIP_SECONDS = 8
const PAUSE_MS = 1800

function stageAt(p) {
  if (p >= 1) return 4
  if (p > 0.88) return 3
  if (p > 0.03) return 2
  return 1
}

// ETA rounded to 5-minute steps so the card isn't re-rendered every frame.
const statusAt = (p, trip) => ({ stage: stageAt(p), eta: Math.ceil((trip.etaMin * (1 - p)) / 5) * 5 })

function formatEta(min) {
  if (min <= 0) return 'Arriving now'
  const h = Math.floor(min / 60)
  const m = min % 60
  return `Arrives in about ${h ? `${h} hr ` : ''}${m} min`
}

export default function Coverage() {
  const stage = useRef(null)
  const inView = useInView(stage, { amount: 0.35 })
  const reduce = useReducedMotion()
  const [tripIndex, setTripIndex] = useState(0)
  const [autoplay, setAutoplay] = useState(true)
  const progress = useMotionValue(reduce ? 0.6 : 0)
  const trip = sampleTrips[tripIndex]

  const [status, setStatus] = useState(() => statusAt(progress.get(), trip))
  useMotionValueEvent(progress, 'change', (p) => {
    const next = statusAt(p, trip)
    setStatus((prev) => (prev.stage === next.stage && prev.eta === next.eta ? prev : next))
  })

  useEffect(() => {
    if (reduce) {
      progress.set(0.6)
      setStatus(statusAt(0.6, sampleTrips[tripIndex]))
      return
    }
    if (!inView) return
    let timer
    progress.set(0)
    const controls = animate(progress, 1, {
      duration: TRIP_SECONDS,
      ease: [0.45, 0, 0.3, 1],
      onComplete: () => {
        if (autoplay) timer = setTimeout(() => setTripIndex((i) => (i + 1) % sampleTrips.length), PAUSE_MS)
      },
    })
    return () => {
      controls.stop()
      clearTimeout(timer)
    }
  }, [tripIndex, inView, reduce, autoplay, progress])

  const choose = (i) => {
    setAutoplay(false)
    setTripIndex(i)
  }

  return (
    <section id="coverage" className="bg-night py-28 text-snow md:py-40">
      <div className="shell">
        <Reveal className="max-w-3xl">
          <p className="eyebrow text-brand">Coverage &amp; live tracking</p>
          <h2 className="display-lg mt-3">
            Anywhere in Nigeria.
            <br />
            <span className="text-fog">Visible every kilometre.</span>
          </h2>
          <p className="lede mt-6 max-w-2xl text-fog">
            From Lagos to Maiduguri, Port Harcourt to Sokoto — we collect and deliver door to door across the country, and you follow every trip on a live map.
          </p>
        </Reveal>

        <Reveal amount={0.15} className="mt-14 md:mt-20">
          <div ref={stage} className="grid overflow-hidden rounded-[32px] border border-white/10 bg-coal lg:grid-cols-[minmax(0,1fr)_380px]">
            <div className="p-5 sm:p-10">
              <NigeriaMap trip={trip} progress={progress} />
            </div>

            <aside aria-label="Sample trip" className="flex flex-col border-t border-white/10 p-6 sm:p-8 lg:border-l lg:border-t-0">
              <p className="flex items-center gap-2 text-[0.8125rem] font-semibold text-brand">
                <span className="relative flex h-2 w-2">
                  <span className="live-ping absolute inset-0 rounded-full bg-brand" />
                  <span className="relative h-2 w-2 rounded-full bg-brand" />
                </span>
                Live trip
              </p>
              <p className="title mt-3">
                {cities[trip.from].name} → {cities[trip.to].name}
              </p>
              <p className="mt-1 text-[0.9375rem] text-fog">
                {trip.vehicle} · {trip.service}
              </p>
              <p className="mt-5 text-[1.3125rem] font-semibold tracking-[-0.02em] tabular-nums" aria-live="off">
                {status.stage === 4 ? 'Delivered safely' : formatEta(status.eta)}
              </p>

              <ol className="mt-6 space-y-3.5">
                {timeline.map((label, i) => {
                  const done = i < status.stage || status.stage === 4
                  const current = i === status.stage && status.stage !== 4
                  return (
                    <li key={label} className="flex items-center gap-3 text-[0.9375rem]">
                      <span
                        className={`grid h-5 w-5 shrink-0 place-items-center rounded-full transition-colors duration-300 ${
                          done ? 'bg-brand text-black' : current ? 'bg-brand/20 ring-2 ring-brand' : 'bg-white/10'
                        }`}
                      >
                        {done && <Check className="h-3 w-3" strokeWidth={3.5} aria-hidden="true" />}
                      </span>
                      <span className={done || current ? 'text-snow' : 'text-fog/70'}>{label}</span>
                      {current && <span className="ml-auto text-[0.75rem] font-medium text-brand">Now</span>}
                    </li>
                  )
                })}
              </ol>

              <div role="radiogroup" aria-label="Choose a sample trip" className="mt-8 flex flex-wrap gap-2 border-t border-white/10 pt-6 lg:mt-auto">
                {sampleTrips.map((t, i) => {
                  const selected = i === tripIndex
                  return (
                    <button
                      key={`${t.from}-${t.to}`}
                      type="button"
                      role="radio"
                      aria-checked={selected}
                      onClick={() => choose(i)}
                      className={`pressable relative rounded-full px-3.5 py-2 text-[0.8125rem] font-medium ${
                        selected ? 'text-black' : 'text-snow/80 hover:text-snow'
                      }`}
                    >
                      {selected && <motion.span layoutId="trip-thumb" transition={spring} className="absolute inset-0 rounded-full bg-brand" />}
                      {!selected && <span className="absolute inset-0 rounded-full ring-1 ring-white/15" />}
                      <span className="relative">
                        {cities[t.from].name} → {cities[t.to].name}
                      </span>
                    </button>
                  )
                })}
              </div>
            </aside>
          </div>
        </Reveal>

        <dl className="mt-16 grid gap-10 sm:grid-cols-3 md:mt-24">
          {[
            ['1–2 days', 'Fastest delivery between cities, with White Glove.'],
            ['30 min', 'Heads-up call from your driver before every pickup.'],
            ['Live', 'GPS tracking on every trip, from pickup to handover.'],
          ].map(([stat, label], i) => (
            <Reveal key={stat} delay={i * 0.08} className="border-t border-white/15 pt-6">
              <dt className="text-[3rem] font-semibold leading-none tracking-[-0.045em] md:text-[3.5rem]">{stat}</dt>
              <dd className="mt-3 max-w-[18rem] text-fog">{label}</dd>
            </Reveal>
          ))}
        </dl>
      </div>
    </section>
  )
}
