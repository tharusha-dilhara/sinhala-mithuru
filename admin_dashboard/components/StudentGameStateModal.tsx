'use client';

import { useState, useEffect } from 'react';
import { adminApi } from '@/lib/api';
import ConfirmModal from './ConfirmModal';

interface Props {
  studentId: number;
  studentName: string;
  onClose: () => void;
}

interface GameLevel {
  id: number;
  level_number: number;
  grade: number;
}

interface ActivityLog {
  id: number;
  component_type: string;
  score: number;
  is_correct: boolean;
  time_taken: number;
  created_at: string;
}

interface GameState {
  student_id: number;
  current_level_id: number;
  current_hw_count: number;
  current_pron_count: number;
  current_gram_count: number;
  current_narr_count: number;
  total_score: number;
  game_levels?: {
    id: number;
    level_number: number;
    grade: number;
    default_target_hw: number;
    default_target_pron: number;
    default_target_gram: number;
    default_target_narr: number;
  };
}

const COMPONENT_LABELS: Record<string, { label: string; color: string; icon: string }> = {
  hw:   { label: 'Handwriting',   color: '#4f46e5', icon: '✍️' },
  pron: { label: 'Pronunciation', color: '#7c3aed', icon: '🎤' },
  gram: { label: 'Grammar',       color: '#0ea5e9', icon: '📝' },
  narr: { label: 'Narrative',     color: '#f59e0b', icon: '📖' },
};

export default function StudentGameStateModal({ studentId, studentName, onClose }: Props) {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedLevelId, setSelectedLevelId] = useState<number | ''>('');
  const [updating, setUpdating] = useState(false);
  const [updateSuccess, setUpdateSuccess] = useState('');
  const [confirmOpen, setConfirmOpen] = useState(false);

  useEffect(() => {
    adminApi.getStudentGameState(studentId)
      .then(d => {
        setData(d);
        if (d?.game_state?.current_level_id) {
          setSelectedLevelId(d.game_state.current_level_id);
        }
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, [studentId]);

  const handleLevelUpdate = async () => {
    if (!selectedLevelId) return;
    setUpdating(true);
    setUpdateSuccess('');
    try {
      const res = await adminApi.updateStudentGameLevel(studentId, Number(selectedLevelId));
      setUpdateSuccess(res.message || 'Level updated!');
      // Refresh data
      const fresh = await adminApi.getStudentGameState(studentId);
      setData(fresh);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setUpdating(false);
      setConfirmOpen(false);
    }
  };

  const gameState: GameState | null = data?.game_state || null;
  const allLevels: GameLevel[] = data?.all_levels || [];
  const activityLogs: ActivityLog[] = data?.activity_logs || [];
  const student = data?.student || {};
  const currentLevel = gameState?.game_levels;

  const components = [
    { key: 'hw',   count: gameState?.current_hw_count ?? 0,   target: currentLevel?.default_target_hw ?? '?' },
    { key: 'pron', count: gameState?.current_pron_count ?? 0, target: currentLevel?.default_target_pron ?? '?' },
    { key: 'gram', count: gameState?.current_gram_count ?? 0, target: currentLevel?.default_target_gram ?? '?' },
    { key: 'narr', count: gameState?.current_narr_count ?? 0, target: currentLevel?.default_target_narr ?? '?' },
  ];

  return (
    <div className="modal-backdrop" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal-panel max-w-3xl p-5 sm:p-8 m-2 sm:m-4 animate-in">
        {/* Header */}
        <div className="flex items-start justify-between mb-6 pb-4 border-b border-[var(--border-subtle)]">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl flex items-center justify-center text-xl bg-amber-50 border border-amber-100 flex-shrink-0">
              🎮
            </div>
            <div className="min-w-0">
              <h2 className="text-base sm:text-lg font-bold text-[var(--text-strong)] truncate">
                {studentName}
              </h2>
              <p className="text-xs text-[var(--text-muted)] mt-0.5 truncate">
                {student.school_name} · {student.class_name} · Grade {student.grade}
              </p>
            </div>
          </div>
          <button onClick={onClose} className="btn btn-ghost text-lg flex-shrink-0 ml-2">✕</button>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="spinner spinner-lg" />
          </div>
        ) : error ? (
          <div className="p-4 rounded-lg text-sm bg-red-50 text-red-600 border border-red-200">
            Error: {error}
          </div>
        ) : (
          <>
            {/* Level & Score */}
            <div className="grid grid-cols-2 gap-3 mb-6">
              <div className="card p-4 bg-[var(--bg-app)]">
                <p className="text-[0.65rem] font-semibold uppercase tracking-wider text-[var(--text-light)] mb-1">Current Level</p>
                <p className="text-2xl sm:text-3xl font-extrabold text-[var(--text-strong)]">
                  {currentLevel ? `Lv ${currentLevel.level_number}` : '—'}
                </p>
                <p className="text-xs text-[var(--text-muted)] mt-1">Grade {currentLevel?.grade ?? '?'}</p>
              </div>
              <div className="card p-4 bg-[var(--bg-app)]">
                <p className="text-[0.65rem] font-semibold uppercase tracking-wider text-[var(--text-light)] mb-1">Total Score</p>
                <p className="text-2xl sm:text-3xl font-extrabold text-[var(--primary)]">
                  {typeof gameState?.total_score === 'number' ? gameState.total_score.toFixed(1) : '—'}
                </p>
                <p className="text-xs text-[var(--text-muted)] mt-1">Points</p>
              </div>
            </div>

            {/* Component Progress */}
            <div className="mb-6">
              <p className="text-xs font-bold text-[var(--text-strong)] mb-3 uppercase tracking-wider">Level Progress</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {components.map(c => {
                  const info = COMPONENT_LABELS[c.key];
                  const pct = typeof c.target === 'number' && c.target > 0
                    ? Math.min(100, Math.round((c.count / c.target) * 100))
                    : 0;
                  return (
                    <div key={c.key} className="card p-3 flex flex-col gap-2">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <span className="text-base">{info.icon}</span>
                          <span className="text-xs font-semibold text-[var(--text-strong)]">{info.label}</span>
                        </div>
                        <span className="text-xs font-bold" style={{ color: info.color }}>
                          {c.count}/{c.target}
                        </span>
                      </div>
                      <div className="w-full rounded-full bg-[var(--bg-app)] h-1.5 overflow-hidden">
                        <div
                          className="h-full rounded-full transition-all"
                          style={{ width: `${pct}%`, background: info.color }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Level Override */}
            <div className="card p-4 mb-6 border-indigo-100 bg-indigo-50/40">
              <p className="text-xs font-bold text-indigo-700 mb-1 flex items-center gap-1.5">
                <span>⚡</span> Set Override Level
              </p>
              <p className="text-[0.7rem] text-indigo-600/80 mb-3">
                Updating the level will reset current progress counters. Total score is preserved.
              </p>

              {updateSuccess && (
                <div className="mb-3 p-2.5 rounded-lg text-xs bg-green-50 text-green-700 border border-green-200 font-medium">
                  ✓ {updateSuccess}
                </div>
              )}

              <div className="flex flex-col sm:flex-row gap-2">
                <select
                  value={selectedLevelId}
                  onChange={e => setSelectedLevelId(Number(e.target.value))}
                  className="input-field bg-white flex-1"
                  style={{ cursor: 'pointer' }}
                >
                  <option value="">Select a level...</option>
                  {allLevels.map(lv => (
                    <option key={lv.id} value={lv.id}>
                      Level {lv.level_number} — Grade {lv.grade}
                      {lv.id === gameState?.current_level_id ? ' (current)' : ''}
                    </option>
                  ))}
                </select>
                <button
                  className="btn btn-primary"
                  disabled={!selectedLevelId || selectedLevelId === gameState?.current_level_id || updating}
                  onClick={() => setConfirmOpen(true)}
                >
                  {updating ? (
                    <><span className="spinner" style={{ width: 14, height: 14, borderWidth: 2, borderTopColor: 'white', borderColor: 'rgba(255,255,255,0.3)' }} /> Updating...</>
                  ) : (
                    'Set Level'
                  )}
                </button>
              </div>
            </div>

            {/* Activity Logs */}
            <div>
              <p className="text-xs font-bold text-[var(--text-strong)] mb-3 uppercase tracking-wider">
                Recent Activity (Last 20)
              </p>
              {activityLogs.length === 0 ? (
                <div className="card p-8 text-center text-[var(--text-muted)] text-sm">
                  No activity recorded yet
                </div>
              ) : (
                <>
                  {/* Mobile: Card view */}
                  <div className="sm:hidden space-y-2">
                    {activityLogs.map(log => {
                      const info = COMPONENT_LABELS[log.component_type] || { label: log.component_type, color: '#94a3b8', icon: '❓' };
                      return (
                        <div key={log.id} className="card p-3">
                          <div className="flex items-center justify-between mb-1">
                            <span className="flex items-center gap-1.5 text-xs font-semibold">
                              <span>{info.icon}</span>
                              <span style={{ color: info.color }}>{info.label}</span>
                            </span>
                            <span className={`badge text-[0.6rem] ${log.is_correct ? 'badge-green' : 'badge-red'}`}>
                              {log.is_correct ? '✓ Pass' : '✗ Retry'}
                            </span>
                          </div>
                          <div className="flex items-center justify-between text-[0.65rem] text-[var(--text-muted)]">
                            <span>Score: <strong className="text-[var(--text-strong)]">{(log.score * 100).toFixed(0)}%</strong></span>
                            <span>{log.time_taken ? `${log.time_taken.toFixed(1)}s` : '—'}</span>
                            <span>{new Date(log.created_at).toLocaleDateString('si-LK', { day: '2-digit', month: 'short' })}</span>
                          </div>
                        </div>
                      );
                    })}
                  </div>

                  {/* Desktop: Table view */}
                  <div className="hidden sm:block data-table-wrap">
                    <div className="overflow-x-auto">
                      <table className="data-table">
                        <thead>
                          <tr>
                            <th>Module</th>
                            <th>Score</th>
                            <th>Result</th>
                            <th>Time (s)</th>
                            <th>Date</th>
                          </tr>
                        </thead>
                        <tbody>
                          {activityLogs.map(log => {
                            const info = COMPONENT_LABELS[log.component_type] || { label: log.component_type, color: '#94a3b8', icon: '❓' };
                            return (
                              <tr key={log.id}>
                                <td>
                                  <span className="flex items-center gap-2 font-medium">
                                    <span>{info.icon}</span>
                                    <span style={{ color: info.color }}>{info.label}</span>
                                  </span>
                                </td>
                                <td>
                                  <span className="font-bold text-[var(--text-strong)]">
                                    {(log.score * 100).toFixed(0)}%
                                  </span>
                                </td>
                                <td>
                                  <span className={`badge ${log.is_correct ? 'badge-green' : 'badge-red'}`}>
                                    {log.is_correct ? '✓ Passed' : '✗ Retry'}
                                  </span>
                                </td>
                                <td className="text-[var(--text-muted)]">
                                  {log.time_taken ? log.time_taken.toFixed(1) : '—'}
                                </td>
                                <td className="text-[var(--text-muted)] text-[13px]">
                                  {new Date(log.created_at).toLocaleDateString('si-LK', {
                                    day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit'
                                  })}
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </>
              )}
            </div>
          </>
        )}
      </div>

      {confirmOpen && (
        <ConfirmModal
          title="Confirm Level Change"
          message={`Are you sure you want to set ${studentName}'s level to Level ${allLevels.find(l => l.id === selectedLevelId)?.level_number ?? '?'}? Their current progress counters (hw, pron, gram, narr) will reset.`}
          onConfirm={handleLevelUpdate}
          onCancel={() => setConfirmOpen(false)}
          loading={updating}
        />
      )}
    </div>
  );
}
