import Nav from './components/Nav.jsx'
import Hero from './components/Hero.jsx'
import Statement from './components/Statement.jsx'
import Services from './components/Services.jsx'
import HowItWorks from './components/HowItWorks.jsx'
import Coverage from './components/Coverage.jsx'
import Highlights from './components/Highlights.jsx'
import Fleet from './components/Fleet.jsx'
import Drivers from './components/Drivers.jsx'
import Download from './components/Download.jsx'
import Faq from './components/Faq.jsx'
import Footer from './components/Footer.jsx'

export default function App() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:z-[60] focus:rounded-full focus:bg-brand focus:px-4 focus:py-2 focus:text-black"
      >
        Skip to content
      </a>
      <Nav />
      <main id="main">
        <Hero />
        <Statement />
        <Services />
        <HowItWorks />
        <Coverage />
        <Highlights />
        <Fleet />
        <Drivers />
        <Download />
        <Faq />
      </main>
      <Footer />
    </>
  )
}
