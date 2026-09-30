import { useRef } from 'react'
import { motion, useReducedMotion, useScroll, useTransform } from 'motion/react'
import Phone from './Phone.jsx'
import Reveal from './Reveal.jsx'
import StoreBadge from './StoreBadge.jsx'
import { stores } from '../content.js'

export default function Download() {
  const ref = useRef(null)
  const reduce = useReducedMotion()
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start end', 'end end'] })
  const rise = useTransform(scrollYProgress, [0.2, 1], reduce ? [0, 0] : [140, 0])
  const tiltLeft = useTransform(scrollYProgress, [0.2, 1], reduce ? [-6, -6] : [-14, -6])
  const tiltRight = useTransform(scrollYProgress, [0.2, 1], reduce ? [6, 6] : [14, 6])

  return (
    <section id="download" ref={ref} className="relative overflow-hidden bg-night pt-28 text-snow md:pt-40">
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-[70%] bg-[radial-gradient(60%_60%_at_50%_100%,rgb(0_200_83/0.22),transparent)]" />

      <div className="shell relative text-center">
        <Reveal>
          <div className="mx-auto grid h-24 w-24 place-items-center rounded-[26px] bg-gradient-to-b from-[#1c1c1e] to-black shadow-[0_0_0_1px_rgb(255_255_255/0.1),0_20px_50px_-10px_rgb(0_200_83/0.35)]">
            <img src="/images/logo_white.png" alt="" width="583" height="241" className="w-[72px]" />
          </div>
          <h2 className="display-lg mt-8">
            Your next move
            <br />
            starts here.
          </h2>
          <p className="lede mx-auto mt-6 max-w-xl text-fog">Book, pay and track from your phone. Free on iPhone and Android.</p>
          <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
            <StoreBadge store="apple" href={stores.client.appStore} appName={stores.client.name} size="lg" />
            <StoreBadge store="google" href={stores.client.playStore} appName={stores.client.name} size="lg" />
          </div>
        </Reveal>

        <motion.div style={{ y: rise }} className="relative mx-auto mt-20 flex h-[440px] max-w-[760px] justify-center md:h-[520px]">
          <motion.div style={{ rotate: tiltLeft }} className="absolute left-1/2 top-16 hidden origin-bottom -translate-x-[108%] opacity-60 sm:block">
            <Phone screen="book" label="The booking screen" />
          </motion.div>
          <motion.div style={{ rotate: tiltRight }} className="absolute left-1/2 top-16 hidden origin-bottom translate-x-[8%] opacity-60 sm:block">
            <Phone screen="track" label="Live tracking screen" />
          </motion.div>
          <div className="relative z-10">
            <Phone screen="home" label="The Carpital Consult home screen showing active shipments" />
          </div>
        </motion.div>
      </div>
    </section>
  )
}
