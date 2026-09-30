import React, { useState } from 'react';
import { Wallet } from 'lucide-react';
import { AppProvider } from './context/AppContext';
import { Sidebar } from './components/Sidebar';
import { Topbar } from './components/Topbar';
import { DispatchView } from './views/DispatchView';
import { FleetMapView } from './views/FleetMapView';
import { JobsView } from './views/JobsView';
import { DriversView } from './views/DriversView';
import { ClientsView } from './views/ClientsView';
import { PartnersView } from './views/PartnersView';
import { SettingsView } from './views/SettingsView';
import { DetailDrawer } from './components/DetailDrawer';
import { EmptyState } from './components/ui';

const PAGES = {
  dispatch: { section: 'Dispatch', title: 'Command Centre' },
  map: { section: 'Map', title: 'Live Fleet Map' },
  jobs: { section: 'Jobs', title: 'Master Transport Log' },
  drivers: { section: 'Drivers', title: 'Driver Management' },
  partners: { section: 'Partners', title: 'Partners & Affiliations' },
  clients: { section: 'Clients', title: 'Client Management' },
  earnings: { section: 'Earnings', title: 'Financial Overview' },
  settings: { section: 'Settings', title: 'Pricing Configuration' },
};

function AppContent() {
  const [currentView, setCurrentView] = useState('dispatch');

  const renderView = () => {
    switch (currentView) {
      case 'dispatch':
        return <DispatchView />;
      case 'map':
        return <FleetMapView />;
      case 'jobs':
        return <JobsView />;
      case 'drivers':
        return <DriversView />;
      case 'partners':
        return <PartnersView />;
      case 'clients':
        return <ClientsView />;
      case 'earnings':
        return (
          <div className="px-8 pt-4">
            <EmptyState
              icon={Wallet}
              title="Earnings coming soon"
              subtitle="This page isn't built yet."
              className="max-w-md"
            />
          </div>
        );
      case 'settings':
        return <SettingsView />;
      default:
        return <DispatchView />;
    }
  };

  const page = PAGES[currentView] ?? PAGES.dispatch;

  return (
    <>
      <div aria-hidden className="aurora fixed inset-0 -z-10 pointer-events-none" />
      <Sidebar currentView={currentView} setCurrentView={setCurrentView} />
      <main className="h-screen pl-[calc(var(--spacing-rail)+12px)] overflow-y-auto overflow-x-hidden flex flex-col scrollbar-thin">
        <Topbar title={page.title} section={page.section} />
        <div key={currentView} className="flex-1 relative flex flex-col min-h-0 animate-enter">
          {renderView()}
        </div>
      </main>
      <DetailDrawer />
    </>
  );
}

function App() {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  );
}

export default App;
