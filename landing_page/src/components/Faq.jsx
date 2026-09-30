import { useId, useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { Plus } from 'lucide-react'
import Reveal from './Reveal.jsx'
import { company, faqs } from '../content.js'
import { spring } from '../lib/motion.js'

export default function Faq() {
  const [open, setOpen] = useState(0)

  return (
    <section id="faq" data-nav="light" className="bg-paper py-28 text-ink md:py-40">
      <div className="shell grid gap-12 lg:grid-cols-[minmax(0,5fr)_minmax(0,7fr)] lg:gap-20">
        <Reveal className="lg:sticky lg:top-28 lg:self-start">
          <p className="eyebrow text-brand">FAQ</p>
          <h2 className="display-lg mt-3">
            Questions?
            <br />
            Answers.
          </h2>
          <p className="lede mt-6 text-ink-2">
            Can’t find what you need?{' '}
            <a href={`mailto:${company.email}`} className="text-brand hover:underline">
              Email our team ›
            </a>
          </p>
        </Reveal>

        <Reveal as="ul" className="border-t border-hairline">
          {faqs.map((item, i) => (
            <FaqItem key={item.q} item={item} open={open === i} onToggle={() => setOpen(open === i ? -1 : i)} />
          ))}
        </Reveal>
      </div>
    </section>
  )
}

function FaqItem({ item, open, onToggle }) {
  const id = useId()
  return (
    <li className="border-b border-hairline">
      <h3>
        <button
          type="button"
          aria-expanded={open}
          aria-controls={id}
          onClick={onToggle}
          className="group flex w-full items-center justify-between gap-6 py-6 text-left"
        >
          <span className="title text-[1.1875rem]! md:text-[1.3125rem]!">{item.q}</span>
          <motion.span
            animate={{ rotate: open ? 45 : 0 }}
            transition={spring}
            className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-mist text-ink transition-colors group-hover:bg-hairline"
          >
            <Plus className="h-4 w-4" strokeWidth={2.25} aria-hidden="true" />
          </motion.span>
        </button>
      </h3>
      <AnimatePresence initial={false}>
        {open && (
          <motion.div
            id={id}
            role="region"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={spring}
            className="overflow-hidden"
          >
            <p className="max-w-2xl pb-7 pr-12 text-ink-2">{item.a}</p>
          </motion.div>
        )}
      </AnimatePresence>
    </li>
  )
}
