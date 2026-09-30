import React, { useState } from 'react';
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
        return <div className="p-8 text-text-mid">Earnings View coming soon...</div>;
      case 'settings':
        return <SettingsView />;
      default:
        return <DispatchView />;
    }
  };

  const getBreadcrumbTitle = () => {
    const map = {
      dispatch: 'Command Centre',
      map: 'Live Fleet Map',
      jobs: 'Master Transport Log',
      drivers: 'Driver Management',
      partners: 'Partners & Affiliations',
      clients: 'Client Management',
      earnings: 'Financial Overview',
      settings: 'Pricing Configuration'
    };
    return map[currentView] || 'Overview';
  };
  
  const getBreadcrumbSection = () => {
    const map = {
      dispatch: 'Dispatch',
      map: 'Map',
      jobs: 'Jobs',
      drivers: 'Drivers',
      partners: 'Partners',
      clients: 'Clients',
      earnings: 'Earnings',
      settings: 'Settings'
    };
    return map[currentView] || 'Dispatch';
  };

  return (
    <>
      <Sidebar currentView={currentView} setCurrentView={setCurrentView} />
      <main className="ml-[64px] h-screen overflow-y-auto overflow-x-hidden flex flex-col scrollbar-thin">
        <Topbar title={getBreadcrumbTitle()} breadcrumb={getBreadcrumbSection()} />
        <div className="flex-1 relative">
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
