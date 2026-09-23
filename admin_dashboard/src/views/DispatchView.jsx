import React from 'react';
import { useAppContext } from '../context/AppContext';
import { KPIStrip } from '../components/KPIStrip';
import { JobCard } from '../components/JobCard';

export function DispatchView() {
  const { jobs, currentFilter, setCurrentFilter } = useAppContext();

  const filters = [
    { id: 'all', label: 'All' },
    { id: 'pending', label: 'Pending' },
    { id: 'assigned', label: 'Assigned' },
    { id: 'confirmed', label: 'Confirmed' },
    { id: 'inTransit', label: 'In Transit' },
    { id: 'completed', label: 'Delivered' }
  ];

  const filteredJobs = jobs.filter(job => currentFilter === 'all' || job.status === currentFilter);

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <KPIStrip />
      
      <section className="flex-1 p-8 overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="font-syne text-[18px] font-bold text-text-primary tracking-tight">
            Live Dispatch Board
          </h2>
          <div className="flex gap-1 bg-navy-mid p-1 rounded-[10px] border border-navy-border">
            {filters.map(filter => (
              <button
                key={filter.id}
                className={`px-3.5 py-1.5 border-none rounded-[7px] text-xs font-medium cursor-pointer transition-all duration-200 font-sans ${
                  currentFilter === filter.id
                    ? 'bg-navy-light text-text-primary'
                    : 'bg-transparent text-text-mid hover:text-text-primary'
                }`}
                onClick={() => setCurrentFilter(filter.id)}
              >
                {filter.label}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-[repeat(auto-fill,minmax(320px,1fr))] gap-4">
          {filteredJobs.length > 0 ? (
            filteredJobs.map((job, index) => (
              <JobCard key={job.id} job={job} index={index} />
            ))
          ) : (
            <div className="col-span-full text-center p-10 text-text-dim">
              <p>No jobs found in this category.</p>
            </div>
          )}
        </div>
      </section>
    </div>
  );
}
