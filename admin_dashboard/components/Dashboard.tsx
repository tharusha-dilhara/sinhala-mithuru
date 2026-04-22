'use client';

import { useState } from 'react';
import { clearToken, getAdminName } from '@/lib/api';
import Sidebar from './Sidebar';
import MobileNav from './MobileNav';
import OverviewSection from './sections/OverviewSection';
import SchoolsSection from './sections/SchoolsSection';
import TeachersSection from './sections/TeachersSection';
import ClassesSection from './sections/ClassesSection';
import StudentsSection from './sections/StudentsSection';

export type Section = 'overview' | 'schools' | 'teachers' | 'classes' | 'students';

interface Props {
  onLogout: () => void;
}

const sectionTitles: Record<Section, { en: string; si: string }> = {
  overview: { en: 'Dashboard Overview', si: 'දළ සටහන' },
  schools: { en: 'Schools Management', si: 'පාසල් කළමනාකරණය' },
  teachers: { en: 'Teachers Management', si: 'ගුරුවරු කළමනාකරණය' },
  classes: { en: 'Classes Management', si: 'පන්ති කළමනාකරණය' },
  students: { en: 'Students Management', si: 'සිසුන් කළමනාකරණය' },
};

export default function Dashboard({ onLogout }: Props) {
  const [activeSection, setActiveSection] = useState<Section>('overview');
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const adminName = getAdminName();

  const handleLogout = () => {
    clearToken();
    onLogout();
  };

  const renderSection = () => {
    switch (activeSection) {
      case 'overview': return <OverviewSection />;
      case 'schools': return <SchoolsSection />;
      case 'teachers': return <TeachersSection />;
      case 'classes': return <ClassesSection />;
      case 'students': return <StudentsSection />;
      default: return <OverviewSection />;
    }
  };

  const handleNavigate = (section: Section) => {
    setActiveSection(section);
    setMobileSidebarOpen(false);
  };

  const title = sectionTitles[activeSection];

  return (
    <div className="flex h-screen overflow-hidden bg-[var(--bg-app)]">
      {/* Desktop Sidebar */}
      <div className="hidden md:block">
        <Sidebar
          active={activeSection}
          onNavigate={handleNavigate}
          onLogout={handleLogout}
          adminName={adminName}
        />
      </div>

      {/* Mobile Sidebar Overlay */}
      {mobileSidebarOpen && (
        <div
          className="fixed inset-0 z-50 md:hidden"
          onClick={() => setMobileSidebarOpen(false)}
        >
          <div className="absolute inset-0 bg-black/30 backdrop-blur-sm" />
          <div
            className="absolute left-0 top-0 bottom-0 w-[260px] animate-in"
            onClick={e => e.stopPropagation()}
          >
            <Sidebar
              active={activeSection}
              onNavigate={handleNavigate}
              onLogout={handleLogout}
              adminName={adminName}
            />
          </div>
        </div>
      )}

      {/* Main Area */}
      <main className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top Bar */}
        <header className="flex-shrink-0 border-b border-[var(--border-subtle)] bg-white px-4 sm:px-6 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button
              className="md:hidden p-2 -ml-2 text-[var(--text-muted)] hover:bg-[var(--bg-surface-hover)] rounded-lg transition-colors"
              onClick={() => setMobileSidebarOpen(true)}
            >
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M3 5h14M3 10h14M3 15h14" strokeLinecap="round" />
              </svg>
            </button>
            <div>
              <h1 className="text-base sm:text-lg font-bold text-[var(--text-strong)] leading-tight">
                {title.en}
              </h1>
              <p className="text-[0.7rem] text-[var(--text-light)] mt-0.5 hidden sm:block">{title.si}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="text-right hidden sm:block">
              <p className="text-sm font-semibold text-[var(--text-strong)] leading-tight">{adminName}</p>
              <p className="text-[0.65rem] text-[var(--text-light)]">Administrator</p>
            </div>
            <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold bg-[var(--primary)] text-white flex-shrink-0">
              {adminName.charAt(0).toUpperCase()}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="flex-1 overflow-auto p-4 sm:p-6">
          <div className="max-w-7xl mx-auto animate-in">
            {renderSection()}
          </div>
        </div>

        {/* Mobile Bottom Nav */}
        <MobileNav active={activeSection} onNavigate={handleNavigate} />
      </main>
    </div>
  );
}
