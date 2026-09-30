import { useRef } from 'react'
import { motion, useReducedMotion, useScroll, useTransform } from 'motion/react'

// `*word*` is lit in brand green.
const TEXT =
  'Moving a car across Nigeria used to mean phone calls, guesswork and crossed fingers. Now it takes *a few taps.* A verified driver collects it, you *watch every kilometre,* and the keys come back with a signature.'

const words = TEXT.split(' ').reduce(
  (acc, raw) => {
    const opens = raw.startsWith('*')
    const closes = raw.endsWith('*')
    const word = raw.replaceAll('*', '')
    const accent = acc.inAccent || opens
    acc.list.push({ word, accent })
    acc.inAccent = accent && !closes
    return acc
  },
  { list: [], inAccent: false },
).list

export default function Statement() {
  const ref = useRef(null)
  const reduce = useReducedMotion()
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start 0.85', 'end 0.45'] })

  return (
    <section aria-label="Why Carpital Consult" className="bg-night py-32 text-snow md:py-48">
      <div className="shell">
        <p ref={ref} className="headline mx-auto max-w-[56rem] leading-[1.18]! md:text-[3.25rem]!">
          {words.map(({ word, accent }, i) => {
            const start = i / words.length
            const end = start + 1 / words.length
            return reduce ? (
              <span key={i} className={accent ? 'text-brand' : undefined}>
                {word}{' '}
              </span>
            ) : (
              <Word key={i} progress={scrollYProgress} range={[start, end]} accent={accent}>
                {word}
              </Word>
            )
          })}
        </p>
      </div>
    </section>
  )
}

function Word({ children, progress, range, accent }) {
  const opacity = useTransform(progress, range, [0.16, 1])
  return (
    <>
      <motion.span style={{ opacity }} className={accent ? 'text-brand' : undefined}>
        {children}
      </motion.span>{' '}
    </>
  )
}
