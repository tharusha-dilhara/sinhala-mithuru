'use client';

import { Section } from './Dashboard';

const navItems: { id: Section; label: string; icon: string }[] = [
  { id: 'overview', label: 'Overview', icon: '📊' },
  { id: 'schools', label: 'Schools', icon: '🏫' },
  { id: 'teachers', label: 'Teachers', icon: '👩‍🏫' },
  { id: 'classes', label: 'Classes', icon: '📚' },
  { id: 'students', label: 'Students', icon: '👦' },
];

interface Props {
  active: Section;
  onNavigate: (s: Section) => void;
  onLogout: () => void;
  adminName: string;
}

export default function Sidebar({ active, onNavigate, onLogout, adminName }: Props) {
  return (
    <aside className="w-[240px] bg-white border-r border-[var(--border-subtle)] flex flex-col h-full flex-shrink-0">
      {/* Brand */}
      <div className="px-5 py-5 border-b border-[var(--border-subtle)]">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-[var(--primary)] flex items-center justify-center text-white text-lg flex-shrink-0">
            🎓
          </div>
          <div className="min-w-0">
            <p className="font-bold text-[0.8rem] text-[var(--text-strong)] truncate leading-tight">Sinhala Mithuru</p>
            <p className="text-[0.65rem] font-medium text-[var(--text-light)] uppercase tracking-widest mt-0.5">Admin</p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
        <p className="px-3 py-2 text-[0.6rem] font-semibold text-[var(--text-light)] uppercase tracking-widest">
          Menu
        </p>
        {navItems.map(item => {
          const isActive = active === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left transition-colors text-sm ${
                isActive
                  ? 'bg-[var(--primary-light)] text-[var(--primary)] font-semibold'
                  : 'text-[var(--text-body)] hover:bg-[var(--bg-surface-hover)]'
              }`}
            >
              <span className="text-base">{item.icon}</span>
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="px-3 py-3 border-t border-[var(--border-subtle)]">
        <button
          onClick={onLogout}
          className="w-full flex items-center justify-center gap-2 px-4 py-2 rounded-lg text-sm font-medium text-[var(--text-muted)] hover:bg-red-50 hover:text-red-600 transition-colors"
        >
          <span>🚪</span> Sign Out
        </button>
      </div>
    </aside>
  );
}
