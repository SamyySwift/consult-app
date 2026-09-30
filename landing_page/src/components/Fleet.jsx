import { Fragment, useEffect, useRef } from 'react'
import { motion, useInView, useReducedMotion, useScroll, useTransform } from 'motion/react'
import Reveal from './Reveal.jsx'

const points = [
  ['Open multi-car carriers', 'Professional carriers for everyday moves between cities.'],
  ['Enclosed carriers', 'Fully covered transport for luxury, classic and brand-new vehicles.'],
  ['Partner fleets', 'Every driver is registered with a partner logistics company, so each job has a team behind it.'],
]

const lines = ['Real carriers.', 'Real roads.']

const lede =
  'Your car doesn’t travel with a stranger. It rides with professional carriers and drivers who know Nigeria’s highways — and whose every stop you can see.'

// A long, soft landing for type sliding out of its mask.
const easeOut = [0.22, 1, 0.36, 1]

// Tiled film grain: gives the footage texture and hides its upscaling.
const grain =
  "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='180' height='180'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E\")"

const smoothstep = (t) => t * t * (3 - 2 * t)
const clamp01 = (t) => Math.min(1, Math.max(0, t))

export default function Fleet() {
  const section = useRef(null)
  const video = useRef(null)
  const reduce = useReducedMotion()
  const inView = useInView(section)

  // Plays whenever any of the section is on screen, never for reduced motion.
  useEffect(() => {
    const v = video.current
    if (inView && !reduce) v.play().catch(() => {})
    else v.pause()
  }, [inView, reduce])

  // Arriving: a portrait frame, the shape of the footage itself, opens out to the full screen.
  const { scrollYProgress: arrive } = useScroll({ target: section, offset: ['start end', 'start start'] })
  // Pinned: the footage holds still and dims while the copy scrolls over it.
  const { scrollYProgress: pinned } = useScroll({ target: section, offset: ['start start', 'end end'] })

  const clipPath = useTransform(arrive, (p) => {
    if (reduce) return 'none'
    const t = 1 - smoothstep(clamp01((p - 0.2) / 0.8))
    const w = window.innerWidth
    const h = window.innerHeight
    const top = h * 0.1
    const side = Math.max(16, (w - (h - top * 2) * (9 / 16)) / 2)
    return `inset(${t * top}px ${t * side}px round ${t * 36}px)`
  })
  const zoom = useTransform(arrive, [0.2, 1], reduce ? [1, 1] : [1.3, 1])
  // A function, not a range: Motion hands range-mapped opacity to the native scroll timeline,
  // which fades back to 0 past the end of a pinned section instead of holding.
  const dim = useTransform(pinned, (p) => 0.72 * smoothstep(clamp01((p - 0.1) / 0.45)))
  const route = useTransform(pinned, [0, 0.45], [0, 1])

  return (
    <section ref={section} aria-labelledby="fleet-title" className="relative bg-night text-snow">
      <div className="sticky top-0 h-svh overflow-hidden">
        <motion.div className="absolute inset-0 overflow-hidden bg-graphite" style={{ clipPath }}>
          {/* Taller than the screen so the clip's bottom edge never shows the source watermark */}
          <motion.video
            ref={video}
            style={{ scale: zoom }}
            className="absolute inset-x-0 top-0 h-[118%] w-full object-cover object-[50%_40%]"
            src="/video/on-the-road.mp4"
            poster="/video/on-the-road-poster.jpg"
            muted
            loop
            playsInline
            preload="metadata"
            aria-hidden="true"
          />
          <div className="absolute inset-x-0 top-0 h-48 bg-gradient-to-b from-black/60 to-transparent" />
          <div className="absolute inset-x-0 bottom-0 h-3/4 bg-gradient-to-t from-black/90 via-black/45 to-transparent" />
          <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_45%,rgb(0_0_0/0.55)_100%)]" />
          <motion.div className="absolute inset-0 bg-black" style={{ opacity: dim }} />
          <div aria-hidden="true" className="absolute inset-0 opacity-[0.18] mix-blend-overlay" style={{ backgroundImage: grain }} />
        </motion.div>
      </div>

      <div className="relative -mt-[100svh]">
        {/* First screen: the title rests on the road */}
        <div className="shell flex min-h-svh flex-col justify-end pb-10 pt-32 md:pb-14">
          <Reveal as="p" y={12} amount={1} className="glass-panel inline-flex items-center gap-2.5 self-start rounded-full py-2 pl-3 pr-4 text-[0.9375rem] font-semibold">
            <span className="relative grid h-2 w-2 place-items-center" aria-hidden="true">
              <span className="live-ping absolute inset-0 rounded-full bg-brand" />
              <span className="relative h-2 w-2 rounded-full bg-brand" />
            </span>
            On the road
          </Reveal>
          {/* Triggered on the heading: the lines themselves start clipped, so they never register as in view */}
          <motion.h2
            id="fleet-title"
            className="mt-4 text-[clamp(2.75rem,10.5vw,10rem)] font-semibold leading-[0.92] tracking-[-0.05em]"
            initial="hidden"
            whileInView="shown"
            viewport={{ once: true, amount: 0.8 }}
            transition={{ delayChildren: 0.08, staggerChildren: 0.12 }}
          >
            {lines.map((line) => (
              <span key={line} className="-my-[0.08em] block overflow-hidden py-[0.08em]">
                <motion.span
                  className="block"
                  variants={{ hidden: { y: '110%' }, shown: { y: '0%' } }}
                  transition={{ duration: 1.2, ease: easeOut }}
                >
                  {line}
                </motion.span>
              </span>
            ))}
          </motion.h2>

          {/* A trip in miniature: the line fills from pickup to delivery as you scroll */}
          <div className="mt-10 flex items-center gap-4 text-[0.8125rem] font-medium tracking-[0.01em] text-snow/70 md:mt-14" aria-hidden="true">
            <span>Pickup</span>
            <span className="relative h-px flex-1 bg-white/20">
              <motion.span className="absolute inset-0 origin-left bg-brand" style={{ scaleX: route }} />
            </span>
            <span>Delivery</span>
          </div>
        </div>

        {/* Second screen: the promise, over darkened footage */}
        <div className="shell flex min-h-svh flex-col justify-center py-28 md:py-36">
          <motion.p
            className="max-w-[52rem] text-[clamp(1.625rem,3.2vw,2.875rem)] font-semibold leading-[1.16] tracking-[-0.028em]"
            initial="hidden"
            whileInView="shown"
            viewport={{ once: true, amount: 0.6 }}
            transition={{ staggerChildren: 0.028 }}
          >
            {lede.split(' ').map((word, i) => (
              <Fragment key={i}>
                <span className="-my-[0.1em] inline-block overflow-hidden py-[0.1em] align-top">
                  <motion.span
                    className="inline-block"
                    variants={{ hidden: { y: '105%' }, shown: { y: '0%' } }}
                    transition={{ duration: 0.9, ease: easeOut }}
                  >
                    {word}
                  </motion.span>
                </span>{' '}
              </Fragment>
            ))}
          </motion.p>

          <ul className="mt-16 grid gap-10 md:mt-24 md:grid-cols-3 md:gap-8">
            {points.map(([title, body], i) => (
              <Reveal as="li" key={title} delay={0.08 * i} className="border-t border-white/25 pt-5">
                <span className="text-[0.8125rem] font-semibold tabular-nums text-brand">0{i + 1}</span>
                <p className="title mt-3">{title}</p>
                <p className="mt-2 text-snow/70">{body}</p>
              </Reveal>
            ))}
          </ul>
        </div>
      </div>
    </section>
  )
}
