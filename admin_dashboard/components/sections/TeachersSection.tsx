'use client';

import { useState, useEffect, useCallback } from 'react';
import { adminApi } from '@/lib/api';
import ConfirmModal from '../ConfirmModal';

interface Teacher {
  id: number;
  full_name: string;
  email: string;
  school_id: number;
  school_name: string;
  school_district: string;
  class_count: number;
  student_count: number;
}

export default function TeachersSection() {
  const [teachers, setTeachers] = useState<Teacher[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [schoolFilter, setSchoolFilter] = useState('');
  const [deleteTarget, setDeleteTarget] = useState<Teacher | null>(null);
  const [deleting, setDeleting] = useState(false);

  const loadTeachers = useCallback(async () => {
    setLoading(true);
    try {
      const data = await adminApi.getTeachers(
        schoolFilter ? Number(schoolFilter) : undefined,
        search || undefined
      );
      setTeachers(data);
    } catch (e: any) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [search, schoolFilter]);

  useEffect(() => { loadTeachers(); }, [loadTeachers]);

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await adminApi.deleteTeacher(deleteTarget.id);
      setTeachers(prev => prev.filter(t => t.id !== deleteTarget.id));
      setDeleteTarget(null);
    } catch (e: any) {
      alert('Error: ' + e.message);
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
        <div>
          <h2 className="text-xl sm:text-2xl font-bold text-[var(--text-strong)]">Teachers</h2>
          <p className="text-sm text-[var(--text-muted)]">{teachers.length} teachers across all schools</p>
        </div>
        <span className="badge badge-blue self-start sm:self-auto">{teachers.length} total</span>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-2">
        <div className="relative flex-1">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-light)] text-sm">🔍</span>
          <input
            className="input-field pl-9"
            placeholder="Search by teacher name..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <input
          className="input-field sm:w-44"
          placeholder="School ID..."
          value={schoolFilter}
          onChange={e => setSchoolFilter(e.target.value)}
          type="number"
          min="1"
        />
        {(search || schoolFilter) && (
          <button className="btn btn-secondary" onClick={() => { setSearch(''); setSchoolFilter(''); }}>
            Clear
          </button>
        )}
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <div className="spinner spinner-lg" />
        </div>
      ) : teachers.length === 0 ? (
        <div className="card p-12 text-center text-[var(--text-muted)]">No teachers found</div>
      ) : (
        <>
          {/* Mobile: Card View */}
          <div className="sm:hidden space-y-3">
            {teachers.map(teacher => (
              <div key={teacher.id} className="card p-4">
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div className="min-w-0">
                    <p className="font-semibold text-[var(--text-strong)] text-sm truncate">{teacher.full_name}</p>
                    <p className="text-xs text-[var(--text-muted)] truncate mt-0.5">{teacher.email}</p>
                  </div>
                  <span className="badge badge-gray text-[0.65rem] flex-shrink-0">#{teacher.id}</span>
                </div>
                <div className="text-xs text-[var(--text-muted)] mb-3 space-y-0.5">
                  <p>🏫 {teacher.school_name || `School #${teacher.school_id}`}</p>
                  {teacher.school_district && <p>📍 {teacher.school_district}</p>}
                </div>
                <div className="flex gap-2 mb-3">
                  <div className="flex-1 bg-[var(--bg-app)] rounded-lg py-2 text-center">
                    <p className="text-sm font-bold text-[var(--text-strong)]">{teacher.class_count}</p>
                    <p className="text-[0.6rem] text-[var(--text-light)]">Classes</p>
                  </div>
                  <div className="flex-1 bg-[var(--bg-app)] rounded-lg py-2 text-center">
                    <p className="text-sm font-bold text-[var(--text-strong)]">{teacher.student_count}</p>
                    <p className="text-[0.6rem] text-[var(--text-light)]">Students</p>
                  </div>
                </div>
                <button className="btn btn-danger w-full text-xs" onClick={() => setDeleteTarget(teacher)}>
                  Delete Teacher
                </button>
              </div>
            ))}
          </div>

          {/* Desktop: Table View */}
          <div className="hidden sm:block data-table-wrap">
            <div className="overflow-x-auto">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Teacher / ගුරු</th>
                    <th className="hidden md:table-cell">Email</th>
                    <th className="hidden lg:table-cell">School</th>
                    <th className="hidden md:table-cell">District</th>
                    <th>Classes</th>
                    <th>Students</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {teachers.map(teacher => (
                    <tr key={teacher.id}>
                      <td><span className="badge badge-gray">#{teacher.id}</span></td>
                      <td><span className="font-semibold text-[var(--text-strong)]">{teacher.full_name}</span></td>
                      <td className="hidden md:table-cell">
                        <span className="text-[var(--text-muted)] text-sm">{teacher.email}</span>
                      </td>
                      <td className="hidden lg:table-cell">{teacher.school_name || `#${teacher.school_id}`}</td>
                      <td className="hidden md:table-cell">
                        <span className="badge badge-amber">{teacher.school_district || '—'}</span>
                      </td>
                      <td>{teacher.class_count}</td>
                      <td>{teacher.student_count}</td>
                      <td>
                        <button className="btn btn-danger" onClick={() => setDeleteTarget(teacher)}>Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {deleteTarget && (
        <ConfirmModal
          title="Delete Teacher"
          message={`Are you sure you want to delete "${deleteTarget.full_name}"? This will remove all their classes and associated data.`}
          onConfirm={handleDelete}
          onCancel={() => setDeleteTarget(null)}
          loading={deleting}
          danger
        />
      )}
    </div>
  );
}
