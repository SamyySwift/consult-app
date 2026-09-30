import { BadgeCheck, Layers, Navigation, Wallet, MapPin } from 'lucide-react'
import Reveal from './Reveal.jsx'
import StoreBadge from './StoreBadge.jsx'
import { company, driverPerks, stores } from '../content.js'

const perkIcons = [MapPin, Navigation, Layers, Wallet]

export default function Drivers() {
  return (
    <section id="drivers" data-nav="light" className="bg-paper py-28 text-ink md:py-40">
      <div className="shell">
        <div className="grid items-end gap-10 lg:grid-cols-2">
          <Reveal>
            <p className="eyebrow text-brand">For drivers &amp; fleets</p>
            <h2 className="display-lg mt-3">Drive with Carpital.</h2>
          </Reveal>
          <Reveal delay={0.06}>
            <p className="lede text-ink-2">
              Join a logistics network that sends real transport jobs straight to your phone. Apply in minutes and hear back within 24 hours.
            </p>
          </Reveal>
        </div>

        <Reveal className="relative mt-14 overflow-hidden rounded-[32px] md:mt-20">
          <picture>
            <source media="(min-width: 768px)" srcSet="/images/driver-1600.webp" />
            <img
              src="/images/driver-800.webp"
              alt="A driver’s hand resting on the steering wheel"
              className="h-[420px] w-full object-cover object-[50%_60%] md:h-[560px]"
              loading="lazy"
            />
          </picture>
          <div className="absolute inset-0 bg-gradient-to-r from-black/75 via-black/30 to-transparent" />
          <div className="absolute inset-y-0 left-0 flex max-w-lg flex-col justify-end p-7 text-snow md:p-12">
            <p className="flex items-center gap-2 text-[0.9375rem] font-semibold text-brand">
              <BadgeCheck className="h-5 w-5" aria-hidden="true" /> Approved within 24 hours
            </p>
            <p className="headline mt-3">Your next job is already nearby.</p>
            <div className="mt-7 flex flex-wrap gap-3">
              <StoreBadge store="apple" href={stores.driver.appStore} appName={stores.driver.name} />
              <StoreBadge store="google" href={stores.driver.playStore} appName={stores.driver.name} />
            </div>
          </div>
        </Reveal>

        <ul className="mt-5 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {driverPerks.map((perk, i) => {
            const Icon = perkIcons[i]
            return (
              <Reveal as="li" key={perk.title} delay={i * 0.06} className="rounded-[28px] bg-mist p-7">
                <Icon className="h-7 w-7 text-brand" strokeWidth={1.75} aria-hidden="true" />
                <p className="title mt-6 text-balance">{perk.title}</p>
                <p className="mt-2 text-[0.9375rem] text-ink-2">{perk.body}</p>
              </Reveal>
            )
          })}
        </ul>

        <Reveal className="mt-10 text-center text-ink-2">
          Run a logistics company?{' '}
          <a href={`mailto:${company.email}?subject=Partner%20fleet%20enquiry`} className="font-medium text-brand hover:underline">
            Become a partner fleet ›
          </a>
        </Reveal>
      </div>
    </section>
  )
}
