import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { nav } from '../content.js'
import { spring } from '../lib/motion.js'

export default function Nav() {
  const [open, setOpen] = useState(false)
  const [tone, setTone] = useState('dark')
  const header = useRef(null)
  const light = tone === 'light' && !open

  // Match whatever section is under the pill, like Apple's adaptive toolbars.
  useEffect(() => {
    let frame = 0
    const sample = () => {
      frame = 0
      const under = document
        .elementsFromPoint(window.innerWidth / 2, 40)
        .find((el) => !header.current.contains(el))
        ?.closest('[data-nav]')
      setTone(under?.dataset.nav === 'light' ? 'light' : 'dark')
    }
    const onScroll = () => {
      if (!frame) frame = requestAnimationFrame(sample)
    }
    sample()
    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll)
    return () => {
      cancelAnimationFrame(frame)
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
    }
  }, [])

  useEffect(() => {
    if (!open) return
    const onKey = (e) => e.key === 'Escape' && setOpen(false)
    const { overflow } = document.body.style
    document.body.style.overflow = 'hidden'
    window.addEventListener('keydown', onKey)
    return () => {
      document.body.style.overflow = overflow
      window.removeEventListener('keydown', onKey)
    }
  }, [open])

  return (
    <header ref={header} className="pointer-events-none fixed inset-x-0 top-3 z-50 px-3">
      {/* Dim to focus while the menu is open */}
      <AnimatePresence>
        {open && (
          <motion.div
            aria-hidden="true"
            className="pointer-events-auto fixed inset-0 bg-black/45 md:hidden"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={spring}
            onClick={() => setOpen(false)}
          />
        )}
      </AnimatePresence>

      <div className="pointer-events-auto relative mx-auto max-w-[980px] md:w-fit">
        <div aria-hidden="true" className={`glass-chrome-dark absolute inset-0 rounded-full transition-opacity duration-500 ${light ? 'opacity-0' : 'opacity-100'}`} />
        <div aria-hidden="true" className={`glass-chrome-light absolute inset-0 rounded-full transition-opacity duration-500 ${light ? 'opacity-100' : 'opacity-0'}`} />

        <nav
          aria-label="Primary"
          className={`relative flex h-14 items-center justify-between pl-5 pr-2 transition-colors duration-500 md:gap-10 ${light ? 'text-ink' : 'text-snow'}`}
        >
          <a href="#top" aria-label="Carpital Consult, back to top" className="pressable -ml-1 flex items-center p-1">
            <img
              src="/images/logo_white.png"
              alt=""
              width="583"
              height="241"
              className={`h-[22px] w-auto transition-[filter] duration-500 ${light ? 'invert' : ''}`}
            />
          </a>

          <ul className="hidden items-center gap-7 md:flex">
            {nav.map((item) => (
              <li key={item.href}>
                <a href={item.href} className="text-[0.8125rem] font-medium tracking-[0.01em] opacity-75 transition-opacity hover:opacity-100">
                  {item.label}
                </a>
              </li>
            ))}
          </ul>

          <div className="flex items-center gap-1">
            <a
              href="#download"
              className="pressable flex h-10 items-center rounded-full bg-brand px-4 text-[0.8125rem] font-semibold tracking-[0.01em] text-black hover:bg-brand-glow"
            >
              Get the app
            </a>
            <button
              type="button"
              onClick={() => setOpen((v) => !v)}
              aria-expanded={open}
              aria-controls="mobile-menu"
              aria-label={open ? 'Close menu' : 'Open menu'}
              className="pressable relative grid h-10 w-10 place-items-center rounded-full md:hidden"
            >
              <motion.span
                className="absolute h-[1.5px] w-[18px] rounded-full bg-current"
                animate={open ? { y: 0, rotate: 45 } : { y: -4, rotate: 0 }}
                transition={spring}
              />
              <motion.span
                className="absolute h-[1.5px] w-[18px] rounded-full bg-current"
                animate={open ? { y: 0, rotate: -45 } : { y: 4, rotate: 0 }}
                transition={spring}
              />
            </button>
          </div>
        </nav>

        {/* Grows out of the menu button and returns to it */}
        <AnimatePresence>
          {open && (
            <motion.div
              id="mobile-menu"
              className="glass-chrome-dark absolute inset-x-0 top-full mt-2 origin-top-right rounded-[28px] p-2 md:hidden"
              initial={{ opacity: 0, scale: 0.94, filter: 'blur(8px)' }}
              animate={{ opacity: 1, scale: 1, filter: 'blur(0px)' }}
              exit={{ opacity: 0, scale: 0.94, filter: 'blur(8px)' }}
              transition={spring}
            >
              <ul className="flex flex-col">
                {nav.map((item, i) => (
                  <motion.li
                    key={item.href}
                    initial={{ opacity: 0, y: -6 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ ...spring, delay: 0.03 * i }}
                  >
                    <a
                      href={item.href}
                      onClick={() => setOpen(false)}
                      className="pressable block rounded-[20px] px-4 py-3.5 text-[1.375rem] font-semibold tracking-[-0.02em] text-snow hover:bg-white/8"
                    >
                      {item.label}
                    </a>
                  </motion.li>
                ))}
              </ul>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </header>
  )
}
