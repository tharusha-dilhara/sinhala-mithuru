'use client';

import { Section } from './Dashboard';

const navItems: { id: Section; icon: string; label: string }[] = [
  { id: 'overview',  icon: '📊', label: 'Overview'  },
  { id: 'schools',   icon: '🏫', label: 'Schools'   },
  { id: 'teachers',  icon: '👩‍🏫', label: 'Teachers'  },
  { id: 'classes',   icon: '📚', label: 'Classes'   },
  { id: 'students',  icon: '👦', label: 'Students'  },
];

interface Props {
  active: Section;
  onNavigate: (s: Section) => void;
}

export default function MobileNav({ active, onNavigate }: Props) {
  return (
    <nav className="md:hidden flex-shrink-0 bg-white border-t border-[var(--border-subtle)] flex items-center justify-around px-1 py-1.5 w-full">
      {navItems.map(item => (
        <button
          key={item.id}
          onClick={() => onNavigate(item.id)}
          className={`flex flex-col items-center justify-center gap-0.5 py-1.5 px-1 rounded-lg transition-colors min-w-0 flex-1 ${
            active === item.id
              ? 'text-[var(--primary)]'
              : 'text-[var(--text-light)]'
          }`}
        >
          <span className="text-lg leading-none">{item.icon}</span>
          <span className={`text-[0.6rem] leading-none ${active === item.id ? 'font-bold' : 'font-medium'}`}>
            {item.label}
          </span>
        </button>
      ))}
    </nav>
  );
}
