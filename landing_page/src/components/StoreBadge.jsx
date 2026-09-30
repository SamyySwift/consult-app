const APPLE_PATH =
  'M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z'

function AppleLogo({ className }) {
  return (
    <svg viewBox="0 0 814 1000" className={className} aria-hidden="true">
      <path d={APPLE_PATH} fill="currentColor" />
    </svg>
  )
}

function PlayLogo({ className }) {
  return (
    <svg viewBox="0 0 24 24" className={className} aria-hidden="true">
      <path d="M3.6 1.8 13.8 12 3.6 22.2c-.4-.2-.6-.6-.6-1.1V2.9c0-.5.2-.9.6-1.1Z" fill="#4285F4" />
      <path d="M3.6 1.8 16.9 9.4 13.8 12Z" fill="#34A853" />
      <path d="M3.6 22.2 13.8 12l3.1 2.6Z" fill="#EA4335" />
      <path d="m16.9 9.4 3.6 2c.6.4.6 1 0 1.3l-3.6 1.9-3.1-2.6Z" fill="#FBBC04" />
    </svg>
  )
}

const STORES = {
  apple: { Logo: AppleLogo, top: 'Download on the', name: 'App Store' },
  google: { Logo: PlayLogo, top: 'Get it on', name: 'Google Play' },
}

/**
 * App Store / Google Play button. With no `href` it renders a "Coming soon"
 * badge instead of a dead link.
 */
export default function StoreBadge({ store, href, appName, size = 'md', tone = 'dark' }) {
  const { Logo, top, name } = STORES[store]
  const live = Boolean(href)
  const sizing = size === 'lg' ? 'h-[60px] pl-4 pr-6 gap-3 rounded-[14px]' : 'h-[48px] pl-3 pr-5 gap-2.5 rounded-[11px]'
  const logoSize = size === 'lg' ? 'h-7 w-7' : 'h-6 w-6'
  const nameSize = size === 'lg' ? 'text-[1.4rem]' : 'text-[1.125rem]'
  const skin =
    tone === 'dark'
      ? 'bg-black text-white ring-1 ring-white/25 hover:ring-white/50'
      : 'bg-black text-white ring-1 ring-black hover:bg-slate'

  const body = (
    <>
      <Logo className={`${logoSize} shrink-0`} />
      <span className="flex flex-col items-start leading-none">
        <span className="caption font-medium tracking-[0.02em] opacity-85">{live ? top : 'Coming soon to'}</span>
        <span className={`${nameSize} font-semibold tracking-[-0.02em] mt-0.5`}>{name}</span>
      </span>
    </>
  )

  if (!live) {
    return (
      <span
        role="img"
        aria-label={`${appName} is coming soon to the ${name}`}
        className={`inline-flex items-center select-none opacity-60 ${sizing} ${skin}`}
      >
        {body}
      </span>
    )
  }

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      aria-label={`${top} ${name}: ${appName}`}
      className={`pressable inline-flex items-center ${sizing} ${skin}`}
    >
      {body}
    </a>
  )
}
