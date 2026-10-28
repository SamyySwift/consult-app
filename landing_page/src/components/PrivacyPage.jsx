import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { company } from '../content.js'

const sections = [
  {
    title: '1. Information We Collect',
    body: `We collect information you provide directly, including your name, email address, phone number, vehicle details (make, model, year, VIN, vehicle documents), pickup and delivery addresses, and payment transaction references.`,
  },
  {
    title: '2. Real-Time Location Data',
    body: `To enable live shipment tracking, accurate arrival estimates, and proof-of-delivery confirmation, our platform monitors transit coordinates between origin and destination points.`,
  },
  {
    title: '3. How We Use Information',
    body: `We use your data strictly to arrange vehicle transport, process payments securely, notify you of transit milestones, deliver handover records and waybills, prevent fraudulent activities, and provide customer support.`,
  },
  {
    title: '4. Data Sharing & Security',
    body: `We do not sell your personal data. We share only necessary job parameters with assigned transport drivers. Financial transactions are tokenized and processed through PCI-DSS certified payment gateway (Paystack).`,
  },
  {
    title: '5. Data Retention',
    body: `Your profile data, digital waybills, and handover documents are retained in your secure garage to enable vehicle ownership and transit record keeping.`,
  },
  {
    title: '6. Your Rights',
    body: `You may request access to, correction of, or deletion of your personal data at any time by contacting our support team. We will respond to such requests within 30 days. You may also withdraw your consent to data processing, though this may limit your ability to use certain features of the platform.`,
  },
  {
    title: '7. Cookies & Analytics',
    body: `Our website and mobile application use minimal, strictly necessary cookies and analytics to improve service quality. We do not deploy third-party advertising trackers. Analytics data is aggregated and anonymised before analysis.`,
  },
  {
    title: '8. Third-Party Services',
    body: `We integrate with trusted third-party services for payments (Paystack), mapping (Google Maps), and push notifications. Each provider operates under their own privacy policies, and we only share the minimum data required for their service to function.`,
  },
  {
    title: '9. Children\'s Privacy',
    body: `Our services are not directed to individuals under the age of 18. We do not knowingly collect personal data from children. If we become aware that a child has provided us with personal information, we will take steps to delete such information.`,
  },
  {
    title: '10. Changes to This Policy',
    body: `We may update this Privacy Policy from time to time. When we do, we will notify you through the app or via email. Your continued use of the platform after changes are posted constitutes your acceptance of the updated policy.`,
  },
  {
    title: '11. Contact Information',
    body: `For privacy-related inquiries, contact us at ${company.email} or call ${company.phone.join(' / ')}.`,
  },
]

export default function PrivacyPage() {
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
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-gradient-to-b from-orange-500/20 to-orange-600/10">
            <span className="text-2xl">🛡️</span>
          </div>
          <div>
            <h1 className="text-[1.75rem] font-bold tracking-tight md:text-[2rem]">Privacy Policy</h1>
            <p className="mt-1 text-[0.875rem] text-fog">Last updated: October 2026</p>
          </div>
        </div>

        <p className="mt-8 text-[0.9375rem] leading-relaxed text-fog">
          {company.name} ("we", "our", or "us") is committed to protecting the privacy of our users. This Privacy Policy describes how we collect, use, and safeguard your information when you use our mobile application and related transportation services.
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
