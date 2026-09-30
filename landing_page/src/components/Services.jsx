import { useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { Bus, Car, CarFront, Check, CloudLightning, Motorbike, ShieldCheck, Siren, Truck } from 'lucide-react'
import Reveal from './Reveal.jsx'
import { enclosedAddon, insuranceCovers, services, vehicleTypes } from '../content.js'
import { naira, spring } from '../lib/motion.js'

const vehicleIcons = { Sedans: Car, SUVs: CarFront, Trucks: Truck, Vans: Bus, Motorcycles: Motorbike }
const coverIcons = [Siren, ShieldCheck, CloudLightning]

export default function Services() {
  return (
    <section id="services" data-nav="light" className="bg-mist py-28 text-ink md:py-40">
      <div className="shell">
        <Reveal className="max-w-3xl">
          <p className="eyebrow text-brand">Services</p>
          <h2 className="display-lg mt-3">
            Three speeds.
            <br />
            One standard of care.
          </h2>
          <p className="lede mt-6 max-w-2xl text-ink-2">
            Choose how soon it needs to be there. Every trip comes with a verified driver, live GPS tracking and a signed handover.
          </p>
        </Reveal>

        <div className="mt-14 grid gap-5 md:mt-20 md:grid-cols-3">
          {services.map((s, i) => (
            <Reveal key={s.id} delay={i * 0.08}>
              <TierCard service={s} featured={s.id === 'express'} />
            </Reveal>
          ))}
        </div>

        <div className="mt-5 grid gap-5 lg:grid-cols-5">
          <Reveal className="lg:col-span-3">
            <TransportTile />
          </Reveal>
          <Reveal className="lg:col-span-2" delay={0.08}>
            <InsuranceTile />
          </Reveal>
        </div>

        <Reveal className="mt-16 md:mt-24">
          <p className="title text-center">What we move</p>
          <ul className="mx-auto mt-8 grid max-w-3xl grid-cols-3 gap-y-8 sm:grid-cols-5">
            {vehicleTypes.map((v) => {
              const Icon = vehicleIcons[v]
              return (
                <li key={v} className="flex flex-col items-center gap-3 text-ink-2">
                  <span className="grid h-16 w-16 place-items-center rounded-full bg-paper text-ink shadow-[0_1px_0_rgb(0_0_0/0.04)]">
                    <Icon className="h-7 w-7" strokeWidth={1.5} aria-hidden="true" />
                  </span>
                  <span className="text-[0.9375rem] font-medium">{v}</span>
                </li>
              )
            })}
          </ul>
        </Reveal>
      </div>
    </section>
  )
}

function TierCard({ service, featured }) {
  const dark = featured
  return (
    <article
      className={`flex h-full flex-col rounded-[28px] p-8 md:p-9 ${dark ? 'bg-night text-snow' : 'bg-paper text-ink'}`}
    >
      <div className="flex items-center justify-between gap-3">
        <h3 className="title">{service.name}</h3>
        {service.badge && (
          <span
            className={`rounded-full px-2.5 py-1 text-[0.75rem] font-semibold tracking-[0.02em] ${
              dark ? 'bg-brand text-black' : 'bg-ink text-snow'
            }`}
          >
            {service.badge}
          </span>
        )}
      </div>
      <p className={`mt-2 min-h-[3em] ${dark ? 'text-fog' : 'text-ink-2'}`}>{service.summary}</p>

      <p className="mt-10 flex items-baseline gap-2">
        <span className="text-[4rem] font-semibold leading-none tracking-[-0.05em]">{service.eta}</span>
        <span className={`text-[1.0625rem] font-medium ${dark ? 'text-fog' : 'text-ink-2'}`}>business days</span>
      </p>

      <ul className={`mt-8 space-y-3 border-t pt-6 ${dark ? 'border-white/12' : 'border-hairline'}`}>
        {service.points.map((p) => (
          <li key={p} className="flex items-start gap-3 text-[0.9375rem]">
            <Check className="mt-0.5 h-4 w-4 shrink-0 text-brand" strokeWidth={2.5} aria-hidden="true" />
            {p}
          </li>
        ))}
      </ul>

      <p className="mt-auto pt-10 text-[0.9375rem]">
        <span className={dark ? 'text-fog' : 'text-ink-2'}>From </span>
        <span className="text-[1.3125rem] font-semibold tracking-[-0.02em]">{naira(service.price)}</span>
      </p>
    </article>
  )
}

const transportModes = [
  {
    id: 'open',
    label: 'Open carrier',
    title: 'Open multi-car carrier.',
    body: 'The everyday choice. Your vehicle travels on a professional multi-car carrier — efficient, proven and included in every price.',
    price: 'Included',
  },
  {
    id: 'enclosed',
    label: 'Enclosed',
    title: 'Enclosed carrier.',
    body: 'A protected container shields the vehicle from dust, rain and road debris. Ideal for luxury, classic and brand-new cars.',
    price: `+ ${naira(enclosedAddon)}`,
  },
]

function TransportTile() {
  const [mode, setMode] = useState('open')
  const active = transportModes.find((m) => m.id === mode)

  return (
    <article className="flex h-full flex-col overflow-hidden rounded-[28px] bg-paper p-8 md:p-10">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="eyebrow text-brand">Transport method</p>
          <h3 className="headline mt-2">Open or enclosed.</h3>
        </div>

        <div role="radiogroup" aria-label="Transport method" className="relative flex rounded-full bg-mist p-1">
          {transportModes.map((m) => (
            <button
              key={m.id}
              type="button"
              role="radio"
              aria-checked={mode === m.id}
              onClick={() => setMode(m.id)}
              className="pressable relative rounded-full px-4 py-2 text-[0.875rem] font-medium"
            >
              {mode === m.id && (
                <motion.span
                  layoutId="transport-thumb"
                  transition={spring}
                  className="absolute inset-0 rounded-full bg-paper shadow-[0_1px_3px_rgb(0_0_0/0.12),0_0_0_0.5px_rgb(0_0_0/0.04)]"
                />
              )}
              <span className={`relative ${mode === m.id ? 'text-ink' : 'text-ink-2'}`}>{m.label}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="relative mt-8 aspect-[16/6] w-full">
        <CarrierArt enclosed={mode === 'enclosed'} />
      </div>

      <div className="mt-6 min-h-[7.5rem]">
        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={active.id}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={spring}
          >
            <p className="flex flex-wrap items-baseline justify-between gap-2">
              <span className="title">{active.title}</span>
              <span className="text-[0.9375rem] font-semibold text-brand">{active.price}</span>
            </p>
            <p className="mt-2 max-w-xl text-ink-2">{active.body}</p>
          </motion.div>
        </AnimatePresence>
      </div>
    </article>
  )
}

/** Side-on line drawing of a carrier; the trailer walls close in for "enclosed". */
function CarrierArt({ enclosed }) {
  const stroke = 'currentColor'
  return (
    <svg viewBox="0 0 640 240" className="h-full w-full text-ink" role="img" aria-label={enclosed ? 'Enclosed car carrier' : 'Open multi-car carrier'}>
      {/* road */}
      <line x1="0" y1="214" x2="640" y2="214" stroke="#d2d2d7" strokeWidth="2" />

      {/* cab */}
      <path d="M520 196V110c0-8 6-14 14-14h40l38 44v56z" fill="none" stroke={stroke} strokeWidth="3" strokeLinejoin="round" />
      <path d="M548 106h24l26 30h-50z" fill="none" stroke={stroke} strokeWidth="2.5" strokeLinejoin="round" />

      {/* chassis */}
      <path d="M40 196h572" stroke={stroke} strokeWidth="3" strokeLinecap="round" />

      {/* decks */}
      <path d="M52 186h450M52 118h450" stroke={stroke} strokeWidth="3" strokeLinecap="round" />
      <path d="M60 118v68M500 118v68M280 118v68" stroke={stroke} strokeWidth="2" opacity="0.5" />

      {/* cars: lower and upper deck */}
      {[
        [80, 186],
        [300, 186],
        [80, 118],
        [300, 118],
      ].map(([x, y]) => (
        <g key={`${x}-${y}`} transform={`translate(${x} ${y - 46})`}>
          <path
            d="M6 38c0-8 4-12 12-14l24-4 26-16c6-3 12-4 18-4h52c8 0 14 4 18 10l12 16 12 2c8 2 12 6 12 12v6H6z"
            fill="#f5f5f7"
            stroke={stroke}
            strokeWidth="2.5"
            strokeLinejoin="round"
          />
          <circle cx="44" cy="37" r="9" fill="#fff" stroke={stroke} strokeWidth="2.5" />
          <circle cx="146" cy="37" r="9" fill="#fff" stroke={stroke} strokeWidth="2.5" />
        </g>
      ))}

      {/* enclosure */}
      <motion.rect
        x="44"
        y="54"
        width="466"
        height="140"
        rx="10"
        fill="#1d1d1f"
        stroke={stroke}
        strokeWidth="3"
        initial={false}
        animate={{ opacity: enclosed ? 1 : 0, scaleY: enclosed ? 1 : 0.92 }}
        style={{ originY: 1 }}
        transition={spring}
      />
      <motion.text
        x="277"
        y="134"
        textAnchor="middle"
        fill="#f5f5f7"
        fontSize="30"
        fontWeight="600"
        letterSpacing="-0.5"
        initial={false}
        animate={{ opacity: enclosed ? 1 : 0 }}
        transition={spring}
      >
        carpital
      </motion.text>

      {/* wheels */}
      {[92, 150, 420, 560].map((cx) => (
        <circle key={cx} cx={cx} cy="206" r="15" fill="#fff" stroke={stroke} strokeWidth="3" />
      ))}
    </svg>
  )
}

function InsuranceTile() {
  return (
    <article className="flex h-full flex-col rounded-[28px] bg-night p-8 text-snow md:p-10">
      <p className="eyebrow text-brand">Insurance</p>
      <h3 className="headline mt-2">Cover priced to your car.</h3>
      <p className="mt-4 text-fog">
        Add insurance when you book, calculated as a set percentage of the value you declare. Your vehicle is protected for the whole journey.
      </p>
      <ul className="mt-auto space-y-4 pt-10">
        {insuranceCovers.map((c, i) => {
          const Icon = coverIcons[i]
          return (
            <li key={c} className="flex items-center gap-4">
              <span className="grid h-10 w-10 place-items-center rounded-full bg-white/8 text-brand">
                <Icon className="h-5 w-5" strokeWidth={1.75} aria-hidden="true" />
              </span>
              <span className="font-medium">{c}</span>
            </li>
          )
        })}
      </ul>
    </article>
  )
}
