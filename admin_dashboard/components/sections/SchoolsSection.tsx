'use client';

import { useState, useEffect, useCallback } from 'react';
import { adminApi } from '@/lib/api';
import ConfirmModal from '../ConfirmModal';

interface School {
  id: number;
  name: string;
  district: string;
  teacher_count: number;
  class_count: number;
  student_count: number;
}

export default function SchoolsSection() {
  const [schools, setSchools] = useState<School[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [district, setDistrict] = useState('');
  const [deleteTarget, setDeleteTarget] = useState<School | null>(null);
  const [deleting, setDeleting] = useState(false);

  const loadSchools = useCallback(async () => {
    setLoading(true);
    try {
      const data = await adminApi.getSchools(search || undefined, district || undefined);
      setSchools(data);
    } catch (e: any) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [search, district]);

  useEffect(() => { loadSchools(); }, [loadSchools]);

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await adminApi.deleteSchool(deleteTarget.id);
      setSchools(prev => prev.filter(s => s.id !== deleteTarget.id));
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
          <h2 className="text-xl sm:text-2xl font-bold text-[var(--text-strong)]">Schools</h2>
          <p className="text-sm text-[var(--text-muted)]">{schools.length} schools registered</p>
        </div>
        <span className="badge badge-blue self-start sm:self-auto">{schools.length} total</span>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-2">
        <div className="relative flex-1">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-light)] text-sm">🔍</span>
          <input
            className="input-field pl-9"
            placeholder="Search by school name..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <input
          className="input-field sm:w-44"
          placeholder="Filter by district..."
          value={district}
          onChange={e => setDistrict(e.target.value)}
        />
        {(search || district) && (
          <button className="btn btn-secondary" onClick={() => { setSearch(''); setDistrict(''); }}>
            Clear
          </button>
        )}
      </div>

      {/* Mobile Cards + Desktop Table */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <div className="spinner spinner-lg" />
        </div>
      ) : schools.length === 0 ? (
        <div className="card p-12 text-center text-[var(--text-muted)]">No schools found</div>
      ) : (
        <>
          {/* Mobile: Card View */}
          <div className="sm:hidden space-y-3">
            {schools.map(school => (
              <div key={school.id} className="card p-4">
                <div className="flex items-start justify-between gap-2 mb-3">
                  <div className="min-w-0">
                    <p className="font-semibold text-[var(--text-strong)] text-sm truncate">{school.name}</p>
                    <p className="text-xs text-[var(--text-muted)] mt-0.5">{school.district || '—'}</p>
                  </div>
                  <span className="badge badge-gray text-[0.65rem] flex-shrink-0">#{school.id}</span>
                </div>
                <div className="grid grid-cols-3 gap-2 text-center mb-3">
                  <div className="bg-[var(--bg-app)] rounded-lg py-2">
                    <p className="text-sm font-bold text-[var(--text-strong)]">{school.teacher_count}</p>
                    <p className="text-[0.6rem] text-[var(--text-light)]">Teachers</p>
                  </div>
                  <div className="bg-[var(--bg-app)] rounded-lg py-2">
                    <p className="text-sm font-bold text-[var(--text-strong)]">{school.class_count}</p>
                    <p className="text-[0.6rem] text-[var(--text-light)]">Classes</p>
                  </div>
                  <div className="bg-[var(--bg-app)] rounded-lg py-2">
                    <p className="text-sm font-bold text-[var(--text-strong)]">{school.student_count}</p>
                    <p className="text-[0.6rem] text-[var(--text-light)]">Students</p>
                  </div>
                </div>
                <button className="btn btn-danger w-full text-xs" onClick={() => setDeleteTarget(school)}>
                  Delete School
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
                    <th>School / පාසල</th>
                    <th>District</th>
                    <th className="hidden md:table-cell">Teachers</th>
                    <th className="hidden md:table-cell">Classes</th>
                    <th>Students</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {schools.map(school => (
                    <tr key={school.id}>
                      <td><span className="badge badge-gray">#{school.id}</span></td>
                      <td><span className="font-semibold text-[var(--text-strong)]">{school.name}</span></td>
                      <td><span className="badge badge-amber">{school.district || '—'}</span></td>
                      <td className="hidden md:table-cell">{school.teacher_count}</td>
                      <td className="hidden md:table-cell">{school.class_count}</td>
                      <td>{school.student_count}</td>
                      <td>
                        <button className="btn btn-danger" onClick={() => setDeleteTarget(school)}>Delete</button>
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
          title="Delete School"
          message={`Are you sure you want to delete "${deleteTarget.name}"? This will also remove all associated teachers, classes, and students.`}
          onConfirm={handleDelete}
          onCancel={() => setDeleteTarget(null)}
          loading={deleting}
          danger
        />
      )}
    </div>
  );
}
