import { Mail } from 'lucide-react'
import { company } from '../content.js'

const columns = [
  {
    title: 'Services',
    links: [
      ['Standard', '#services'],
      ['Express', '#services'],
      ['White Glove', '#services'],
      ['Enclosed transport', '#services'],
    ],
  },
  {
    title: 'Company',
    links: [
      ['How it works', '#how-it-works'],
      ['Coverage', '#coverage'],
      ['Safety', '#safety'],
      ['Drive with us', '#drivers'],
    ],
  },
  {
    title: 'Support',
    links: [
      ['FAQ', '#faq'],
      ['Contact support', `mailto:${company.email}`],
      ['Terms of service', company.termsUrl],
      ['Privacy policy', company.privacyUrl],
    ],
  },
]

export default function Footer() {
  const year = new Date().getFullYear()
  return (
    <footer data-nav="light" className="bg-mist text-ink-2">
      <div className="shell py-16">
        <div className="flex flex-col gap-8 rounded-[28px] bg-paper p-8 md:flex-row md:items-center md:justify-between md:p-10">
          <div>
            <p className="title text-ink">Moving more than one vehicle?</p>
            <p className="mt-2 max-w-lg">Fleets, dealerships and relocations — tell us what you’re moving and we’ll plan it with you.</p>
          </div>
          <a
            href={`mailto:${company.email}?subject=Multi-vehicle%20enquiry`}
            className="pressable inline-flex items-center gap-2 self-start rounded-full bg-ink px-5 py-3 font-medium text-snow hover:bg-black md:self-auto"
          >
            <Mail className="h-4 w-4" aria-hidden="true" /> Talk to us
          </a>
        </div>

        <div className="mt-14 grid gap-10 border-b border-hairline pb-10 sm:grid-cols-2 lg:grid-cols-[2fr_1fr_1fr_1fr]">
          <div>
            <img src="/images/logo_white.png" alt={company.name} width="583" height="241" className="h-7 w-auto invert" />
            <p className="mt-4 max-w-xs text-[0.875rem]">{company.tagline} Door-to-door vehicle logistics across Nigeria.</p>
          </div>
          {columns.map((col) => (
            <nav key={col.title} aria-label={col.title}>
              <p className="text-[0.8125rem] font-semibold text-ink">{col.title}</p>
              <ul className="mt-3 space-y-2.5">
                {col.links.map(([label, href]) => (
                  <li key={label}>
                    <a href={href} className="text-[0.8125rem] hover:text-ink hover:underline">
                      {label}
                    </a>
                  </li>
                ))}
              </ul>
            </nav>
          ))}
        </div>

        <div className="caption mt-6 flex flex-col gap-2 text-ink-3 md:flex-row md:justify-between">
          <p>
            Copyright © {year} {company.name}. All rights reserved.
          </p>
          <p>
            Map data:{' '}
            <a href="https://www.geoboundaries.org" className="hover:underline" target="_blank" rel="noopener noreferrer">
              geoBoundaries
            </a>{' '}
            (CC BY 4.0). Photography: Unsplash.
          </p>
        </div>
      </div>
    </footer>
  )
}
