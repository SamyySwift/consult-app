import { useRef, useState } from 'react'
import { motion, useMotionValueEvent, useScroll } from 'motion/react'
import Phone from './Phone.jsx'
import Reveal from './Reveal.jsx'
import { steps } from '../content.js'
import { springGentle } from '../lib/motion.js'

const screenLabels = {
  book: 'The booking screen, choosing Express service',
  pay: 'The review and pay screen, secured by Paystack',
  pickup: 'The driver’s pickup inspection with photos and condition notes',
  track: 'Live tracking with arrival time and shipment timeline',
}

export default function HowItWorks() {
  const ref = useRef(null)
  const [active, setActive] = useState(0)
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start 0.5', 'end 0.5'] })

  useMotionValueEvent(scrollYProgress, 'change', (v) => {
    setActive(Math.min(steps.length - 1, Math.max(0, Math.floor(v * steps.length))))
  })

  return (
    <section id="how-it-works" data-nav="light" className="bg-paper py-28 text-ink md:py-40">
      <div className="shell">
        <Reveal className="mx-auto max-w-3xl text-center">
          <p className="eyebrow text-brand">How it works</p>
          <h2 className="display-lg mt-3">From booking to handover.</h2>
          <p className="lede mx-auto mt-6 max-w-2xl text-ink-2">
            Four steps, one app, and a clear view of your vehicle the whole way.
          </p>
        </Reveal>

        {/* Large screens: steps scroll past a phone that stays put */}
        <div ref={ref} className="mt-20 hidden lg:grid lg:grid-cols-2 lg:gap-16">
          <ol>
            {steps.map((step, i) => (
              <li key={step.id} className="flex min-h-[78vh] items-center">
                <motion.div
                  animate={{ opacity: active === i ? 1 : 0.22 }}
                  transition={springGentle}
                  className="max-w-md"
                >
                  <StepText step={step} index={i} />
                </motion.div>
              </li>
            ))}
          </ol>
          <div className="relative">
            <div className="sticky top-0 flex h-screen items-center justify-center">
              <div className="absolute h-[520px] w-[520px] rounded-full bg-[radial-gradient(closest-side,rgb(0_200_83/0.16),transparent)]" />
              <Phone screen={steps[active].id} label={screenLabels[steps[active].id]} />
            </div>
          </div>
        </div>

        {/* Small screens: each step brings its own phone */}
        <ol className="mt-16 space-y-24 lg:hidden">
          {steps.map((step, i) => (
            <Reveal as="li" key={step.id} className="flex flex-col items-center text-center">
              <StepText step={step} index={i} />
              <div className="mt-10 h-[560px] w-[262px]">
                <div className="origin-top-left scale-[0.874]">
                  <Phone screen={step.id} label={screenLabels[step.id]} />
                </div>
              </div>
            </Reveal>
          ))}
        </ol>
      </div>
    </section>
  )
}

function StepText({ step, index }) {
  return (
    <>
      <p className="eyebrow flex items-center gap-3 text-ink-3 max-lg:justify-center">
        <span className="grid h-8 w-8 place-items-center rounded-full bg-ink text-[0.875rem] text-snow">{index + 1}</span>
        {step.kicker}
      </p>
      <h3 className="headline mt-5">{step.title}</h3>
      <p className="lede mt-4 text-ink-2">{step.body}</p>
    </>
  )
}
