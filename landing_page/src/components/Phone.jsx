import { AnimatePresence, motion } from 'motion/react'
import { Camera, Car, Check, ChevronLeft, CreditCard, Headphones, Lock, MapPin, Mic, Navigation, Phone as PhoneIcon, Plus, Star, Zap } from 'lucide-react'
import { spring } from '../lib/motion.js'

// Screens recreate the Carpital apps' dark UI: true black, charcoal cards, vivid green.
const ui = {
  bg: '#000',
  card: '#151515',
  card2: '#1e1e1e',
  line: '#2a2a2a',
  dim: '#9e9e9e',
  green: '#00c853',
}

/** An iPhone-proportioned frame at a fixed 300×640 design size. */
export default function Phone({ screen, className = '', label }) {
  return (
    <div
      role="img"
      aria-label={label}
      className={`relative h-[640px] w-[300px] shrink-0 rounded-[52px] text-left bg-[#0b0b0c] p-[11px] shadow-[0_0_0_1.5px_#3a3a3c,0_40px_80px_-24px_rgb(0_0_0/0.55)] ${className}`}
    >
      <div className="relative h-full w-full overflow-hidden rounded-[42px]" style={{ background: ui.bg }}>
        <StatusBar />
        <AnimatePresence initial={false} mode="popLayout">
          <motion.div
            key={screen}
            className="absolute inset-0 pt-[46px]"
            initial={{ opacity: 0, y: 14, filter: 'blur(6px)' }}
            animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
            exit={{ opacity: 0, y: -14, filter: 'blur(6px)' }}
            transition={spring}
          >
            {screens[screen]}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  )
}

function StatusBar() {
  return (
    <div className="absolute inset-x-0 top-0 z-20 flex h-[46px] items-center justify-between px-7 text-[13px] font-semibold text-white">
      <span>9:41</span>
      <span className="absolute left-1/2 top-[10px] h-[26px] w-[92px] -translate-x-1/2 rounded-full bg-black" />
      <span className="flex items-center gap-1.5">
        <svg width="16" height="10" viewBox="0 0 16 10" fill="white" aria-hidden="true">
          <rect x="0" y="6" width="3" height="4" rx="1" />
          <rect x="4.3" y="4" width="3" height="6" rx="1" />
          <rect x="8.6" y="2" width="3" height="8" rx="1" />
          <rect x="12.9" y="0" width="3" height="10" rx="1" />
        </svg>
        <svg width="22" height="11" viewBox="0 0 22 11" fill="none" aria-hidden="true">
          <rect x="0.5" y="0.5" width="18" height="10" rx="3" stroke="white" opacity="0.4" />
          <rect x="2" y="2" width="13" height="7" rx="1.6" fill="white" />
          <rect x="19.6" y="3.5" width="1.6" height="4" rx="0.8" fill="white" opacity="0.4" />
        </svg>
      </span>
    </div>
  )
}

function Header({ title, step }) {
  return (
    <div className="px-5">
      <div className="flex items-center justify-between py-2 text-white">
        <span className="grid h-8 w-8 place-items-center rounded-full" style={{ background: ui.card }}>
          <ChevronLeft size={16} />
        </span>
        <span className="text-[14px] font-semibold">{title}</span>
        <span className="w-8 text-right text-[11px]" style={{ color: ui.dim }}>
          {step}/7
        </span>
      </div>
      <div className="mt-1 h-[3px] rounded-full" style={{ background: ui.card2 }}>
        <div className="h-full rounded-full" style={{ width: `${(step / 7) * 100}%`, background: ui.green }} />
      </div>
    </div>
  )
}

function Button({ children }) {
  return (
    <div
      className="absolute inset-x-5 bottom-6 flex h-12 items-center justify-center gap-2 rounded-2xl text-[14px] font-semibold text-black"
      style={{ background: ui.green }}
    >
      {children}
    </div>
  )
}

const tiers = [
  { name: 'Standard', eta: '5–7 business days', price: '₦75,000', Icon: Car },
  { name: 'Express', eta: '2–3 business days', price: '₦120,000', Icon: Zap, selected: true, badge: 'POPULAR' },
  { name: 'White Glove', eta: '1–2 business days', price: '₦200,000', Icon: Star },
]

function BookScreen() {
  return (
    <div className="h-full text-white">
      <Header title="New Booking" step={3} />
      <div className="px-5 pt-4">
        <p className="text-[21px] font-bold tracking-[-0.02em]">Service Type</p>
        <p className="mt-1 text-[12px]" style={{ color: ui.dim }}>
          Choose the shipping speed and transport method
        </p>
        <p className="mt-4 text-[12px] font-semibold">Shipping Speed</p>
        <div className="mt-2 space-y-2">
          {tiers.map(({ name, eta, price, Icon, selected, badge }) => (
            <div
              key={name}
              className="flex items-center gap-3 rounded-2xl px-3 py-2.5"
              style={{
                background: selected ? 'rgb(0 200 83 / 0.1)' : ui.card,
                boxShadow: `inset 0 0 0 1px ${selected ? ui.green : ui.line}`,
              }}
            >
              <span className="grid h-9 w-9 place-items-center rounded-xl" style={{ background: selected ? ui.green : ui.card2, color: selected ? '#000' : '#fff' }}>
                <Icon size={16} />
              </span>
              <span className="flex-1">
                <span className="flex items-center gap-1.5 text-[13px] font-semibold">
                  {name}
                  {badge && (
                    <span className="rounded px-1 py-px text-[8px] font-bold text-black" style={{ background: ui.green }}>
                      {badge}
                    </span>
                  )}
                </span>
                <span className="block text-[11px]" style={{ color: ui.dim }}>
                  {eta}
                </span>
              </span>
              <span className="text-[13px] font-semibold">{price}</span>
            </div>
          ))}
        </div>
        <p className="mt-4 text-[12px] font-semibold">Transport Method</p>
        <div className="mt-2 grid grid-cols-2 gap-2">
          {['Open Transport', 'Enclosed Transport'].map((t, i) => (
            <div
              key={t}
              className="rounded-2xl px-3 py-2.5 text-[12px] font-semibold"
              style={{ background: i === 0 ? 'rgb(0 200 83 / 0.1)' : ui.card, boxShadow: `inset 0 0 0 1px ${i === 0 ? ui.green : ui.line}` }}
            >
              {t}
              <span className="mt-0.5 block text-[10px] font-normal" style={{ color: ui.dim }}>
                {i === 0 ? 'Standard method' : 'Maximum safety'}
              </span>
            </div>
          ))}
        </div>
      </div>
      <Button>Continue</Button>
    </div>
  )
}

function Row({ label, value, strong }) {
  return (
    <div className={`flex justify-between ${strong ? 'text-[14px] font-bold text-white' : 'text-[12px]'}`} style={strong ? undefined : { color: ui.dim }}>
      <span>{label}</span>
      <span className={strong ? undefined : 'text-white'}>{value}</span>
    </div>
  )
}

function PayScreen() {
  return (
    <div className="h-full text-white">
      <Header title="Review & Pay" step={6} />
      <div className="space-y-3 px-5 pt-5">
        <div className="flex items-center gap-3 rounded-2xl p-3" style={{ background: ui.card }}>
          <span className="grid h-10 w-10 place-items-center rounded-xl" style={{ background: ui.card2 }}>
            <Car size={18} />
          </span>
          <span>
            <span className="block text-[13px] font-semibold">Toyota Camry 2021</span>
            <span className="block text-[11px]" style={{ color: ui.dim }}>
              Pearl White · Sedan
            </span>
          </span>
        </div>

        <div className="rounded-2xl p-3" style={{ background: ui.card }}>
          <div className="flex gap-3">
            <span className="flex flex-col items-center pt-1">
              <span className="h-2 w-2 rounded-full" style={{ background: ui.green }} />
              <span className="my-1 w-px flex-1" style={{ background: ui.line }} />
              <MapPin size={12} color={ui.green} />
            </span>
            <span className="space-y-3 text-[12px]">
              <span className="block">
                <span className="block text-[10px] uppercase tracking-wider" style={{ color: ui.dim }}>
                  Pickup
                </span>
                Admiralty Way, Lekki, Lagos
              </span>
              <span className="block">
                <span className="block text-[10px] uppercase tracking-wider" style={{ color: ui.dim }}>
                  Delivery
                </span>
                Aminu Kano Crescent, Wuse II, Abuja
              </span>
            </span>
          </div>
        </div>

        <div className="space-y-2.5 rounded-2xl p-4" style={{ background: ui.card }}>
          <Row label="Express service" value="₦120,000" />
          <Row label="Enclosed transport" value="₦30,000" />
          <Row label="Insurance" value="Declined" />
          <div className="h-px" style={{ background: ui.line }} />
          <Row label="Total" value="₦150,000" strong />
        </div>
      </div>
      <p className="absolute inset-x-0 bottom-[88px] text-center text-[10px]" style={{ color: ui.dim }}>
        Secured by Paystack
      </p>
      <Button>
        <Lock size={14} strokeWidth={2.5} /> Pay ₦150,000
      </Button>
    </div>
  )
}

const photoSpots = ['60% 45%', '72% 30%', '52% 68%', '66% 75%']

function PickupScreen() {
  return (
    <div className="h-full text-white">
      <div className="px-5 py-2">
        <p className="text-[11px] font-semibold" style={{ color: ui.green }}>
          Step 2 of 4 · Pickup
        </p>
        <p className="mt-1 text-[21px] font-bold tracking-[-0.02em]">Pickup Inspection</p>
        <p className="mt-1 text-[12px]" style={{ color: ui.dim }}>
          Document the condition of the vehicle at pickup.
        </p>
      </div>
      <div className="grid grid-cols-2 gap-2 px-5 pt-2">
        {photoSpots.map((pos, i) => (
          <div
            key={pos}
            className="relative aspect-[4/3] overflow-hidden rounded-xl"
            style={{ backgroundImage: 'url(/images/carrier-1200.webp)', backgroundSize: '280%', backgroundPosition: pos }}
          >
            <span className="absolute bottom-1.5 left-1.5 rounded bg-black/60 px-1.5 py-0.5 text-[9px] font-medium">
              {i < 2 ? '10:41' : '10:42'}
            </span>
          </div>
        ))}
      </div>
      <div className="mx-5 mt-3 rounded-2xl p-3 text-[12px]" style={{ background: ui.card }}>
        <p className="text-[10px] uppercase tracking-wider" style={{ color: ui.dim }}>
          Condition notes
        </p>
        <p className="mt-1">No new scratches, dents, or interior damage verified.</p>
        <div className="mt-3 flex items-center gap-2 rounded-xl p-2" style={{ background: ui.card2 }}>
          <span className="grid h-7 w-7 place-items-center rounded-full text-black" style={{ background: ui.green }}>
            <Mic size={13} />
          </span>
          <span className="flex h-5 flex-1 items-center gap-[2px]">
            {[4, 9, 14, 7, 11, 16, 8, 5, 12, 15, 9, 6, 13, 10, 5, 8, 12, 7, 4, 9, 6].map((h, i) => (
              <span key={i} className="w-[3px] rounded-full" style={{ height: h, background: i < 12 ? ui.green : '#444' }} />
            ))}
          </span>
          <span className="text-[10px]" style={{ color: ui.dim }}>
            0:14
          </span>
        </div>
      </div>
      <div className="mx-5 mt-3 flex items-center gap-2 text-[11px]" style={{ color: ui.dim }}>
        <span className="grid h-4 w-4 place-items-center rounded text-black" style={{ background: ui.green }}>
          <Check size={11} strokeWidth={3} />
        </span>
        Keys and documents received
      </div>
      <Button>
        <Camera size={15} /> Submit &amp; Confirm Pickup
      </Button>
    </div>
  )
}

const stages = ['Confirmed', 'Picked up', 'In transit', 'Out for delivery', 'Delivered']

function TrackScreen() {
  return (
    <div className="relative h-full text-white">
      <svg viewBox="0 0 300 360" className="absolute inset-x-0 top-0 h-[360px] w-full" aria-hidden="true">
        <rect width="300" height="360" fill="#0b0b0c" />
        <g stroke="#1f1f22" strokeWidth="10" fill="none" strokeLinecap="round">
          <path d="M-10 70 L320 40" />
          <path d="M-10 190 C80 180 160 220 320 170" />
          <path d="M60 -10 L90 380" />
          <path d="M210 -10 C200 120 240 240 230 380" />
          <path d="M-10 300 L320 320" />
        </g>
        <g stroke="#17171a" strokeWidth="4" fill="none">
          <path d="M-10 120 L320 110" />
          <path d="M140 -10 L150 380" />
          <path d="M-10 250 L320 240" />
        </g>
        <path d="M72 300 C80 230 90 200 150 196 S220 150 224 60" fill="none" stroke={ui.green} strokeWidth="10" opacity="0.18" strokeLinecap="round" />
        <path d="M72 300 C80 230 90 200 150 196 S220 150 224 60" fill="none" stroke={ui.green} strokeWidth="3.5" strokeLinecap="round" />
        <circle cx="72" cy="300" r="6" fill="#fff" stroke={ui.green} strokeWidth="3" />
        <g transform="translate(224 60)">
          <circle r="10" fill={ui.green} opacity="0.25" />
          <circle r="5" fill={ui.green} />
        </g>
        <g transform="translate(150 196)">
          <circle r="16" fill={ui.green} opacity="0.2" className="live-ping" style={{ transformOrigin: 'center', transformBox: 'fill-box' }} />
          <circle r="9" fill="#fff" />
          <circle r="5" fill={ui.green} />
        </g>
      </svg>

      <div className="absolute inset-x-4 top-1 flex items-center justify-between rounded-2xl bg-black/55 px-3 py-2 backdrop-blur-md">
        <span className="text-[13px] font-semibold">Track Vehicle</span>
        <span className="text-[10px]" style={{ color: ui.dim }}>
          #7F2A91
        </span>
      </div>

      <div className="absolute inset-x-0 bottom-0 rounded-t-[26px] px-5 pb-7 pt-2.5" style={{ background: ui.card }}>
        <span className="mx-auto block h-1 w-9 rounded-full" style={{ background: '#3a3a3a' }} />
        <p className="mt-3 flex items-center gap-1.5 text-[11px] font-semibold" style={{ color: ui.green }}>
          <span className="h-1.5 w-1.5 rounded-full" style={{ background: ui.green }} /> Live · updated 4s ago
        </p>
        <p className="mt-1 text-[18px] font-bold leading-tight tracking-[-0.02em]">Arrives in about 2 hr 10 min</p>
        <p className="text-[11px]" style={{ color: ui.dim }}>
          with current traffic · 142 km to delivery
        </p>

        <div className="mt-4 flex items-center">
          {stages.map((s, i) => (
            <div key={s} className="flex flex-1 items-center last:flex-none">
              <span
                className="grid h-4 w-4 shrink-0 place-items-center rounded-full"
                style={{ background: i <= 2 ? ui.green : ui.card2, boxShadow: i === 2 ? '0 0 0 4px rgb(0 200 83 / 0.25)' : undefined }}
              >
                {i < 2 && <Check size={9} strokeWidth={3.5} color="#000" />}
              </span>
              {i < stages.length - 1 && <span className="mx-1 h-[2px] flex-1 rounded-full" style={{ background: i < 2 ? ui.green : ui.line }} />}
            </div>
          ))}
        </div>
        <p className="mt-2 text-[11px]">
          <span className="font-semibold">In Transit</span> <span style={{ color: ui.dim }}>· Your vehicle is on its way</span>
        </p>

        <div className="mt-4 flex items-center gap-3 rounded-2xl p-2.5" style={{ background: ui.card2 }}>
          <span className="grid h-9 w-9 place-items-center rounded-full text-[12px] font-bold text-black" style={{ background: '#e5e5e5' }}>
            AD
          </span>
          <span className="flex-1">
            <span className="block text-[12px] font-semibold">Assigned Driver</span>
            <span className="flex items-center gap-1 text-[10px]" style={{ color: ui.green }}>
              <Check size={10} strokeWidth={3} /> Verified
            </span>
          </span>
          <span className="grid h-9 w-9 place-items-center rounded-full text-black" style={{ background: ui.green }}>
            <PhoneIcon size={15} />
          </span>
        </div>
      </div>
    </div>
  )
}

function HomeScreen() {
  return (
    <div className="h-full px-5 text-white">
      <p className="pt-3 text-[12px]" style={{ color: ui.dim }}>
        Good Morning 👋
      </p>
      <p className="text-[22px] font-bold tracking-[-0.02em]">Where to next?</p>
      <div className="mt-4 grid grid-cols-3 gap-2 text-center">
        {[
          ['1', 'Pending'],
          ['2', 'In Transit'],
          ['14', 'Delivered'],
        ].map(([n, l]) => (
          <div key={l} className="rounded-2xl py-3" style={{ background: ui.card }}>
            <p className="text-[20px] font-bold">{n}</p>
            <p className="text-[10px]" style={{ color: ui.dim }}>
              {l}
            </p>
          </div>
        ))}
      </div>
      <div className="mt-3 overflow-hidden rounded-2xl" style={{ background: ui.card }}>
        <div className="h-28 bg-cover bg-center" style={{ backgroundImage: 'url(/images/carrier-1200.webp)' }} />
        <div className="p-3">
          <p className="flex items-center justify-between text-[13px] font-semibold">
            Lexus RX 350
            <span className="rounded-full px-2 py-0.5 text-[9px] font-bold text-black" style={{ background: ui.green }}>
              IN TRANSIT
            </span>
          </p>
          <p className="mt-0.5 text-[11px]" style={{ color: ui.dim }}>
            Port Harcourt → Enugu · arrives 4:20 PM
          </p>
        </div>
      </div>
      <div className="mt-3 grid grid-cols-4 gap-2 text-center text-[10px]">
        {[
          ['New Booking', Plus],
          ['Track', Navigation],
          ['Payments', CreditCard],
          ['Support', Headphones],
        ].map(([l, Icon], i) => (
          <div key={l} className="rounded-2xl px-1 py-3" style={{ background: ui.card }}>
            <span
              className="mx-auto mb-1.5 grid h-7 w-7 place-items-center rounded-lg"
              style={{ background: i === 0 ? ui.green : ui.card2, color: i === 0 ? '#000' : '#fff' }}
            >
              <Icon size={14} strokeWidth={2.25} />
            </span>
            {l}
          </div>
        ))}
      </div>
    </div>
  )
}

const screens = {
  book: <BookScreen />,
  pay: <PayScreen />,
  pickup: <PickupScreen />,
  track: <TrackScreen />,
  home: <HomeScreen />,
}
