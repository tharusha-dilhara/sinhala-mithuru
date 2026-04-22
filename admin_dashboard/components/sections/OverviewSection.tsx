'use client';

import { useState, useEffect } from 'react';
import { adminApi } from '@/lib/api';

interface Stats {
  total_schools: number;
  total_teachers: number;
  total_classes: number;
  total_students: number;
}

const statCards = [
  { key: 'total_schools',  label: 'Schools',  si: 'පාසල්',  icon: '🏫', color: '#4f46e5' },
  { key: 'total_teachers', label: 'Teachers', si: 'ගුරුවරු', icon: '👩‍🏫', color: '#7c3aed' },
  { key: 'total_classes',  label: 'Classes',  si: 'පන්ති',   icon: '📚', color: '#0ea5e9' },
  { key: 'total_students', label: 'Students', si: 'සිසුන්',  icon: '👦', color: '#f59e0b' },
];

export default function OverviewSection() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    adminApi.overview()
      .then(setStats)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      {/* Welcome */}
      <div>
        <h2 className="text-xl sm:text-2xl font-bold text-[var(--text-strong)]">
          ආයුබෝවන්! 👋
        </h2>
        <p className="text-sm text-[var(--text-muted)] mt-1">Here&apos;s what&apos;s happening in Sinhala Mithuru today.</p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <div className="spinner spinner-lg" />
        </div>
      ) : error ? (
        <div className="p-4 rounded-lg text-sm bg-red-50 border border-red-200 text-red-700">
          Error: {error}
        </div>
      ) : (
        <>
          {/* Stat Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
            {statCards.map((card) => (
              <div key={card.key} className="card p-4 sm:p-5">
                <div className="flex items-start gap-3">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center text-lg flex-shrink-0"
                    style={{ background: `${card.color}12` }}
                  >
                    {card.icon}
                  </div>
                  <div className="min-w-0">
                    <p className="text-[0.65rem] sm:text-xs font-semibold uppercase tracking-wider text-[var(--text-light)]">
                      {card.label}
                    </p>
                    <p className="text-xl sm:text-2xl font-extrabold leading-tight mt-0.5" style={{ color: card.color }}>
                      {(stats as any)?.[card.key] ?? 0}
                    </p>
                    <p className="text-[0.6rem] text-[var(--text-light)] mt-0.5 hidden sm:block">{card.si}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Status Banner */}
          <div className="card p-4 sm:p-6">
            <div className="flex flex-col sm:flex-row sm:items-center gap-3 mb-4">
              <div className="flex items-center gap-3">
                <span className="text-xl">📌</span>
                <div>
                  <h3 className="font-semibold text-[var(--text-strong)] text-sm">Platform Status</h3>
                  <p className="text-xs text-[var(--text-muted)]">All systems operational</p>
                </div>
              </div>
              <div className="sm:ml-auto flex items-center gap-2 px-3 py-1 bg-green-50 rounded-full border border-green-100 self-start">
                <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                <span className="text-xs font-medium text-green-700">Live</span>
              </div>
            </div>
            <div className="grid grid-cols-3 gap-3 pt-4 border-t border-[var(--border-subtle)]">
              <div className="text-center">
                <p className="text-lg sm:text-xl font-bold text-[var(--primary)]">{stats?.total_schools ?? 0}</p>
                <p className="text-[0.65rem] sm:text-xs text-[var(--text-muted)] mt-0.5">Schools</p>
              </div>
              <div className="text-center">
                <p className="text-lg sm:text-xl font-bold text-purple-600">{stats?.total_teachers ?? 0}</p>
                <p className="text-[0.65rem] sm:text-xs text-[var(--text-muted)] mt-0.5">Teachers</p>
              </div>
              <div className="text-center">
                <p className="text-lg sm:text-xl font-bold text-amber-500">{stats?.total_students ?? 0}</p>
                <p className="text-[0.65rem] sm:text-xs text-[var(--text-muted)] mt-0.5">Students</p>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
