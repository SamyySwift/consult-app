// Everything a non-developer is likely to edit lives here: links, prices, copy.

export const company = {
  name: 'Carpital Consult',
  tagline: 'Your vehicle, safely delivered.',
  email: 'support@carpitalconsult.com',
  termsUrl: 'https://carpitalconsult.com/terms',
  privacyUrl: 'https://carpitalconsult.com/privacy',
}

// Store links. A `null` link renders the badge as "Coming soon" instead of a
// dead link, so fill these in as each app goes live.
export const stores = {
  client: {
    name: 'Carpital Consult',
    appStore: null, // TODO: e.g. https://apps.apple.com/app/id0000000000
    playStore: 'https://play.google.com/store/apps/details?id=com.carpitalconsult.consultlogistics',
  },
  driver: {
    name: 'Carpital Driver',
    appStore: null, // TODO: add once the driver app is on the App Store
    playStore: 'https://play.google.com/store/apps/details?id=com.automove.automove_driver',
  },
}

export const nav = [
  { label: 'Services', href: '#services' },
  { label: 'How it works', href: '#how-it-works' },
  { label: 'Coverage', href: '#coverage' },
  { label: 'Safety', href: '#safety' },
  { label: 'Drivers', href: '#drivers' },
  { label: 'FAQ', href: '#faq' },
]

// Mirrors the defaults in consult_client (pricing_config in Supabase is the
// source of truth — keep these in step with the admin dashboard).
export const services = [
  {
    id: 'standard',
    name: 'Standard',
    summary: 'Reliable delivery at the best price.',
    eta: '5–7',
    price: 75000,
    points: ['Verified driver', 'Live GPS tracking', 'Signed proof of handover'],
  },
  {
    id: 'express',
    name: 'Express',
    summary: 'Faster delivery with priority handling.',
    eta: '2–3',
    price: 120000,
    badge: 'Most popular',
    points: ['Everything in Standard', 'Priority handling', 'A shorter delivery window'],
  },
  {
    id: 'white-glove',
    name: 'White Glove',
    summary: 'Premium door-to-door with a full inspection.',
    eta: '1–2',
    price: 200000,
    badge: 'Premium',
    points: ['Everything in Express', 'Full vehicle inspection', 'Premium door-to-door service'],
  },
]

export const enclosedAddon = 30000

export const vehicleTypes = ['Sedans', 'SUVs', 'Trucks', 'Vans', 'Motorcycles']

export const insuranceCovers = ['Accidents & collisions', 'Theft & vandalism', 'Weather & natural disasters']

export const steps = [
  {
    id: 'book',
    kicker: 'Book',
    title: 'Book in minutes.',
    body: 'Tell us about the vehicle, drop pins for pickup and delivery, and pick a service. You see the full price before you commit.',
  },
  {
    id: 'pay',
    kicker: 'Pay',
    title: 'Pay securely.',
    body: 'Pay by card or bank transfer through Paystack. Your receipt and order request are saved to your account the moment it clears.',
  },
  {
    id: 'pickup',
    kicker: 'Collect',
    title: 'We collect it, carefully.',
    body: 'Your driver calls 30 minutes ahead, then photographs the vehicle and records its condition before it moves an inch.',
  },
  {
    id: 'track',
    kicker: 'Deliver',
    title: 'Track it. Sign for it.',
    body: 'Follow the car live with traffic-aware arrival times. At delivery, the recipient signs on the driver’s phone and you get proof of handover.',
  },
]

// [lat, lon]
export const cities = {
  lagos: { name: 'Lagos', at: [6.5244, 3.3792] },
  ibadan: { name: 'Ibadan', at: [7.3775, 3.947] },
  abuja: { name: 'Abuja', at: [9.0765, 7.3986] },
  kano: { name: 'Kano', at: [12.0022, 8.592] },
  kaduna: { name: 'Kaduna', at: [10.5105, 7.4165] },
  portHarcourt: { name: 'Port Harcourt', at: [4.8156, 7.0498] },
  enugu: { name: 'Enugu', at: [6.4584, 7.5464] },
  benin: { name: 'Benin City', at: [6.335, 5.6037] },
  jos: { name: 'Jos', at: [9.8965, 8.8583] },
  maiduguri: { name: 'Maiduguri', at: [11.8311, 13.151] },
  sokoto: { name: 'Sokoto', at: [13.0059, 5.2476] },
  calabar: { name: 'Calabar', at: [4.9757, 8.3417] },
  ilorin: { name: 'Ilorin', at: [8.4966, 4.5421] },
  owerri: { name: 'Owerri', at: [5.4836, 7.0333] },
  warri: { name: 'Warri', at: [5.516, 5.75] },
  yola: { name: 'Yola', at: [9.2035, 12.4954] },
}

export const routes = [
  ['lagos', 'abuja'],
  ['lagos', 'portHarcourt'],
  ['lagos', 'ibadan'],
  ['lagos', 'benin'],
  ['abuja', 'kano'],
  ['abuja', 'kaduna'],
  ['kaduna', 'kano'],
  ['abuja', 'enugu'],
  ['portHarcourt', 'enugu'],
  ['portHarcourt', 'calabar'],
  ['abuja', 'jos'],
  ['kano', 'maiduguri'],
  ['kano', 'sokoto'],
  ['ibadan', 'ilorin'],
  ['benin', 'warri'],
  ['enugu', 'owerri'],
  ['jos', 'yola'],
]

// Example trips cycled through on the coverage map.
export const sampleTrips = [
  { from: 'lagos', to: 'abuja', vehicle: 'Toyota Highlander · Pearl White', service: 'Express', etaMin: 400 },
  { from: 'portHarcourt', to: 'enugu', vehicle: 'Lexus RX 350 · Obsidian', service: 'White Glove', etaMin: 135 },
  { from: 'abuja', to: 'kano', vehicle: 'Honda Accord · Silver', service: 'Standard', etaMin: 290 },
  { from: 'lagos', to: 'benin', vehicle: 'Mercedes-Benz GLE · Black', service: 'Express', etaMin: 185 },
]

export const timeline = ['Booking confirmed', 'Vehicle picked up', 'In transit', 'Out for delivery', 'Delivered']

// Photo, black and white cards alternate so no two neighbours share a look.
export const highlights = [
  {
    id: 'drivers',
    eyebrow: 'Vetted drivers',
    title: 'Every driver is verified before their first job.',
    body: 'NIN, driver’s licence, address and next of kin — checked and on file.',
    image: '/images/driver-800.webp',
    imageWide: '/images/driver-1600.webp',
  },
  {
    id: 'inspection',
    eyebrow: 'Pickup inspection',
    title: 'The condition, on record.',
    body: 'Photos from every angle, written notes and voice memos, captured before the car moves.',
    tone: 'dark',
  },
  {
    id: 'live',
    eyebrow: 'Live GPS',
    title: 'Watch every kilometre.',
    body: 'A live map with arrival times that account for current traffic.',
    image: '/images/lagos-1000.webp',
    imageWide: '/images/lagos-2000.webp',
    imagePosition: '72% 50%',
  },
  {
    id: 'call',
    eyebrow: 'Call-ahead',
    title: 'A heads-up, never a surprise.',
    body: 'Your driver calls 30 minutes before pickup, and you can call them any time in transit.',
    tone: 'dark',
  },
  {
    id: 'insurance',
    eyebrow: 'Insured transit',
    title: 'Cover priced to your car.',
    body: 'Optional insurance at a set percentage of your vehicle’s declared value.',
    image: '/images/carrier-1200.webp',
    imageWide: '/images/carrier-2000.webp',
    imagePosition: '65% 50%',
  },
  {
    id: 'payments',
    eyebrow: 'Secure payments',
    title: 'Pay your way, safely.',
    body: 'Card or bank transfer through Paystack, with every receipt kept in your payment history.',
  },
  {
    id: 'handover',
    eyebrow: 'Signed handover',
    title: 'Keys, papers, signature.',
    body: 'The recipient signs on delivery and a proof-of-handover document lands in your garage.',
    image: '/images/keys-1000.webp',
  },
  {
    id: 'alerts',
    eyebrow: 'Notifications',
    title: 'Always in the loop.',
    body: 'An update at every stage — confirmed, picked up, in transit, out for delivery, delivered.',
    tone: 'dark',
  },
]

export const driverPerks = [
  { title: 'Jobs near you', body: 'Browse transport jobs in your area and accept the ones that fit your day.' },
  { title: 'Built-in navigation', body: 'Turn-by-turn directions to pickup and drop-off without leaving the app.' },
  { title: 'Several jobs at once', body: 'Run multiple active jobs side by side, with the client tracking each one.' },
  { title: 'Daily earnings', body: 'See completed deliveries and what you’ve earned, every day.' },
]

export const faqs = [
  {
    q: 'How much does it cost to move my vehicle?',
    a: `Standard starts from ₦75,000, Express from ₦120,000 and White Glove from ₦200,000. Enclosed transport and insurance are optional extras. The app shows your full price before you pay — no surprises afterwards.`,
  },
  {
    q: 'How long will delivery take?',
    a: 'Standard delivers in 5–7 business days, Express in 2–3, and White Glove in 1–2. You pick a pickup date and time when you book, and the app keeps your arrival estimate current once the car is moving.',
  },
  {
    q: 'Is my vehicle insured during transport?',
    a: 'You can add insurance when you book. It covers accidents and collisions, theft and vandalism, and weather or natural disasters, priced at a set percentage of the value you declare for the vehicle. If you decline it, the app asks you to confirm that the vehicle won’t be covered.',
  },
  {
    q: 'What documents do I need?',
    a: 'Photos of the vehicle (front, rear and sides), proof of ownership or title, and a valid ID for the owner. You can upload them in the app while booking, or skip and add them before pickup.',
  },
  {
    q: 'Which vehicles can you move?',
    a: 'Sedans, SUVs, pickup trucks, vans and motorcycles. Choose open multi-car transport for everyday moves, or an enclosed carrier for extra protection.',
  },
  {
    q: 'How do I track my vehicle?',
    a: 'Open the Track tab. You’ll see the driver’s live position on the map, an arrival estimate based on current traffic, a timeline of each stage, and a button to call your driver.',
  },
  {
    q: 'What happens at delivery?',
    a: 'The driver completes a final check with the recipient and hands over the keys and documents. The recipient signs on the driver’s phone, and a proof-of-handover document is saved to your account.',
  },
  {
    q: 'How do I become a Carpital driver?',
    a: 'Download the Carpital Driver app, create an account and complete your profile: personal details, NIN, driver’s licence, next of kin and the partner company you drive for. Applications are reviewed within 24 hours.',
  },
]
