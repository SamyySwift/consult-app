import { useRef } from 'react'
import { motion, useReducedMotion, useScroll, useTransform } from 'motion/react'
import { springGentle } from '../lib/motion.js'

const lines = ['Your vehicle,', 'safely delivered.']

export default function Hero() {
  return (
    <section id="top" className="relative overflow-clip bg-night text-snow">
      <div className="shell pt-32 text-center md:pt-44">
        <motion.p
          className="eyebrow text-brand"
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ ...springGentle, delay: 0.1 }}
        >
          Vehicle logistics across Nigeria
        </motion.p>

        <h1 className="display-xl mt-4">
          {lines.map((line, i) => (
            <motion.span
              key={line}
              className="block"
              initial={{ opacity: 0, y: 24, filter: 'blur(10px)' }}
              animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
              transition={{ ...springGentle, duration: 1.1, delay: 0.18 + i * 0.12 }}
            >
              {line}
            </motion.span>
          ))}
        </h1>

        <motion.p
          className="lede mx-auto mt-7 max-w-[36rem] text-balance text-fog"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ ...springGentle, delay: 0.45 }}
        >
          Book a vetted driver, watch your car move on a live map, and get a signed handover at the other end. All from one app.
        </motion.p>

        <motion.div
          className="mt-9 flex flex-wrap items-center justify-center gap-x-7 gap-y-4"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ ...springGentle, delay: 0.55 }}
        >
          <a href="#download" className="pressable rounded-full bg-brand px-6 py-3 text-[1.0625rem] font-medium text-black hover:bg-brand-glow">
            Get the app
          </a>
          <a href="#how-it-works" className="group text-[1.0625rem] text-brand">
            See how it works <span className="inline-block transition-transform group-hover:translate-x-0.5">›</span>
          </a>
        </motion.div>
      </div>

      <HeroMedia />
    </section>
  )
}

function HeroMedia() {
  const ref = useRef(null)
  const reduce = useReducedMotion()
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start end', 'start 0.1'] })
  // The window widens to full-bleed as it reaches the top, while the photo inside settles.
  const scale = useTransform(scrollYProgress, [0, 1], reduce ? [1, 1] : [0.84, 1])
  const radius = useTransform(scrollYProgress, [0, 1], reduce ? [0, 0] : [40, 0])
  const innerScale = useTransform(scrollYProgress, [0, 1], reduce ? [1, 1] : [1.18, 1])

  return (
    <div ref={ref} className="relative mt-16 md:mt-24">
      <motion.div
        style={{ scale, borderRadius: radius }}
        className="relative mx-auto h-[72vh] min-h-[440px] max-h-[900px] w-full overflow-hidden will-change-transform"
      >
        <motion.picture style={{ scale: innerScale }} className="absolute inset-0 block will-change-transform">
          <source type="image/avif" srcSet="/images/carrier-2000.avif 2000w" sizes="100vw" />
          <source type="image/webp" srcSet="/images/carrier-1200.webp 1200w, /images/carrier-2000.webp 2000w" sizes="100vw" />
          <img
            src="/images/carrier-1200.webp"
            alt="A car carrier loaded with SUVs driving along a highway"
            className="h-full w-full object-cover object-[62%_55%]"
            fetchPriority="high"
          />
        </motion.picture>
        <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-black/55 via-transparent to-black/70" />

        <LiveChip />
      </motion.div>
    </div>
  )
}

function LiveChip() {
  return (
    <motion.div
      className="glass-panel absolute bottom-5 left-5 right-5 rounded-[22px] p-4 text-snow sm:right-auto sm:w-[340px] md:bottom-10 md:left-10"
      initial={{ opacity: 0, scale: 0.94, filter: 'blur(12px)' }}
      whileInView={{ opacity: 1, scale: 1, filter: 'blur(0px)' }}
      viewport={{ once: true, amount: 0.8 }}
      transition={{ ...springGentle, delay: 0.2 }}
    >
      <div className="flex items-center justify-between">
        <span className="flex items-center gap-2 text-[0.8125rem] font-semibold tracking-[0.01em] text-brand">
          <span className="relative flex h-2 w-2">
            <span className="live-ping absolute inset-0 rounded-full bg-brand" />
            <span className="relative h-2 w-2 rounded-full bg-brand" />
          </span>
          Live
        </span>
        <span className="text-[0.8125rem] text-fog">Updated 4s ago</span>
      </div>
      <p className="mt-2 text-[1.0625rem] font-semibold tracking-[-0.01em]">Lekki Phase 1 → Wuse II, Abuja</p>
      <p className="text-[0.9375rem] text-fog">In transit · arrives in about 6 hr 40 min</p>
      <div className="mt-3 h-1 overflow-hidden rounded-full bg-white/12">
        <motion.div
          className="h-full w-full origin-left rounded-full bg-brand"
          initial={{ scaleX: 0.08 }}
          whileInView={{ scaleX: 0.62 }}
          viewport={{ once: true }}
          transition={{ ...springGentle, duration: 1.8, delay: 0.5 }}
        />
      </div>
    </motion.div>
  )
}
