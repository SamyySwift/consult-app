import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { company } from '../content.js'

const sections = [
  {
    title: '1. Agreement to Terms',
    body: `By using the ${company.name} mobile application and related transportation services, you agree to comply with and be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.`,
  },
  {
    title: '2. Vehicle Transport Services',
    body: `${company.name} provides automotive logistics, vehicle towing, open haulage, and enclosed carrier transport services across Nigeria. We verify vehicles before transport and inspect condition upon pickup and delivery.`,
  },
  {
    title: '3. Booking & Payment',
    body: `All bookings must be confirmed through the platform. Rates are calculated based on vehicle class, route distance, selected service speed (Standard, Express, White Glove), and optional enclosed transport. Payment is securely processed via Paystack. Bookings are only dispatched upon successful payment confirmation.`,
  },
  {
    title: '4. Client Responsibilities',
    body: `The client warrants that the vehicle being transported is legally owned or authorized for transit, free of hazardous or prohibited cargo, and that accurate vehicle details, ownership documents, and contact details are provided.`,
  },
  {
    title: '5. Insurance & Liability',
    body: `${company.name} offers comprehensive goods-in-transit insurance for covered vehicle journeys. If selected, claims are processed in accordance with the underwriter's evaluation of verified damage incurred strictly during transit.`,
  },
  {
    title: '6. Cancellation & Refunds',
    body: `Bookings may be cancelled prior to driver dispatch. Once a driver has been dispatched or pickup has commenced, cancellation fees may apply in accordance with operational expenses incurred.`,
  },
  {
    title: '7. Driver Conduct & Verification',
    body: `All drivers on the ${company.name} platform undergo identity verification including NIN, driver's licence, address, and next-of-kin checks. Drivers are expected to maintain professional conduct, follow designated routes, and handle all vehicles with care throughout transit.`,
  },
  {
    title: '8. Prohibited Uses',
    body: `You may not use the platform to transport stolen vehicles, contraband, or any illegal goods. You may not interfere with the platform's operation, attempt to gain unauthorized access to our systems, or use the service for any purpose that violates applicable Nigerian law.`,
  },
  {
    title: '9. Limitation of Liability',
    body: `To the maximum extent permitted by law, ${company.name} shall not be liable for indirect, incidental, or consequential damages arising from the use of our services. Our total liability for any claim shall not exceed the amount paid for the specific transport service giving rise to the claim.`,
  },
  {
    title: '10. Dispute Resolution',
    body: `Any disputes arising from the use of our services shall first be addressed through our customer support team. If a resolution cannot be reached, disputes shall be referred to mediation or arbitration in accordance with Nigerian law, with Lagos State as the agreed jurisdiction.`,
  },
  {
    title: '11. Modifications to Terms',
    body: `We reserve the right to modify these Terms of Service at any time. Changes will be communicated through the app or via email. Continued use of the service after modifications constitutes acceptance of the revised terms.`,
  },
  {
    title: '12. Contact Information',
    body: `For inquiries regarding these Terms, contact us at ${company.email} or call ${company.phone.join(' / ')}.`,
  },
]

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-night text-snow">
      <div className="mx-auto max-w-3xl px-5 pb-20 pt-12">
        {/* Header */}
        <Link
          to="/"
          className="pressable inline-flex items-center gap-2 rounded-full bg-white/8 px-4 py-2 text-[0.875rem] font-medium text-fog transition-colors hover:bg-white/12 hover:text-snow"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to home
        </Link>

        <div className="mt-10 flex items-center gap-4">
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-gradient-to-b from-blue-500/20 to-blue-600/10">
            <span className="text-2xl">📄</span>
          </div>
          <div>
            <h1 className="text-[1.75rem] font-bold tracking-tight md:text-[2rem]">Terms of Service</h1>
            <p className="mt-1 text-[0.875rem] text-fog">Last updated: October 2026</p>
          </div>
        </div>

        <p className="mt-8 text-[0.9375rem] leading-relaxed text-fog">
          Please read these Terms of Service carefully before using the {company.name} platform. These terms govern your access to and use of our vehicle logistics services across Nigeria.
        </p>

        {/* Sections */}
        <div className="mt-10 space-y-10">
          {sections.map((section) => (
            <div key={section.title}>
              <h2 className="text-[1.125rem] font-semibold text-brand">{section.title}</h2>
              <p className="mt-3 text-[0.9375rem] leading-relaxed text-fog">{section.body}</p>
            </div>
          ))}
        </div>

        {/* Footer divider */}
        <div className="mt-16 border-t border-white/10 pt-8">
          <p className="text-[0.8125rem] text-fog/60">
            © {new Date().getFullYear()} {company.name}. All rights reserved.
          </p>
        </div>
      </div>
    </div>
  )
}
