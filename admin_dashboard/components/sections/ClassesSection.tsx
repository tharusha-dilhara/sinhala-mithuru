'use client';

import { useState, useEffect, useCallback } from 'react';
import { adminApi } from '@/lib/api';
import ConfirmModal from '../ConfirmModal';

interface ClassItem {
  id: number;
  class_name: string;
  grade: number;
  teacher_id: number;
  teacher_name: string;
  teacher_email: string;
  school_id: number;
  school_name: string;
  school_district: string;
  student_count: number;
}

export default function ClassesSection() {
  const [classes, setClasses] = useState<ClassItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [schoolFilter, setSchoolFilter] = useState('');
  const [teacherFilter, setTeacherFilter] = useState('');
  const [deleteTarget, setDeleteTarget] = useState<ClassItem | null>(null);
  const [deleting, setDeleting] = useState(false);

  const loadClasses = useCallback(async () => {
    setLoading(true);
    try {
      const data = await adminApi.getClasses(
        schoolFilter ? Number(schoolFilter) : undefined,
        teacherFilter ? Number(teacherFilter) : undefined
      );
      setClasses(data);
    } catch (e: any) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [schoolFilter, teacherFilter]);

  useEffect(() => { loadClasses(); }, [loadClasses]);

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await adminApi.deleteClass(deleteTarget.id);
      setClasses(prev => prev.filter(c => c.id !== deleteTarget.id));
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
          <h2 className="text-xl sm:text-2xl font-bold text-[var(--text-strong)]">Classes</h2>
          <p className="text-sm text-[var(--text-muted)]">{classes.length} classes registered</p>
        </div>
        <span className="badge badge-green self-start sm:self-auto">{classes.length} total</span>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-2">
        <input
          className="input-field sm:w-44"
          placeholder="School ID..."
          value={schoolFilter}
          onChange={e => setSchoolFilter(e.target.value)}
          type="number"
          min="1"
        />
        <input
          className="input-field sm:w-44"
          placeholder="Teacher ID..."
          value={teacherFilter}
          onChange={e => setTeacherFilter(e.target.value)}
          type="number"
          min="1"
        />
        {(schoolFilter || teacherFilter) && (
          <button className="btn btn-secondary" onClick={() => { setSchoolFilter(''); setTeacherFilter(''); }}>
            Clear
          </button>
        )}
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <div className="spinner spinner-lg" />
        </div>
      ) : classes.length === 0 ? (
        <div className="card p-12 text-center text-[var(--text-muted)]">No classes found</div>
      ) : (
        <>
          {/* Mobile: Card View */}
          <div className="sm:hidden space-y-3">
            {classes.map(cls => (
              <div key={cls.id} className="card p-4">
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div className="min-w-0">
                    <p className="font-semibold text-[var(--text-strong)] text-sm truncate">{cls.class_name}</p>
                    <div className="flex items-center gap-1.5 mt-1">
                      <span className="badge badge-blue text-[0.65rem]">Grade {cls.grade}</span>
                      <span className="text-[0.65rem] text-[var(--text-light)]">·</span>
                      <span className="text-[0.65rem] text-[var(--text-muted)]">{cls.student_count} students</span>
                    </div>
                  </div>
                  <span className="badge badge-gray text-[0.65rem] flex-shrink-0">#{cls.id}</span>
                </div>
                <div className="text-xs text-[var(--text-muted)] mb-3 space-y-0.5">
                  <p>👩‍🏫 {cls.teacher_name || `Teacher #${cls.teacher_id}`}</p>
                  <p>🏫 {cls.school_name || `School #${cls.school_id}`}</p>
                </div>
                <button className="btn btn-danger w-full text-xs" onClick={() => setDeleteTarget(cls)}>
                  Delete Class
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
                    <th>Class / පන්තිය</th>
                    <th>Grade</th>
                    <th className="hidden md:table-cell">Teacher</th>
                    <th className="hidden lg:table-cell">School</th>
                    <th className="hidden md:table-cell">District</th>
                    <th>Students</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {classes.map(cls => (
                    <tr key={cls.id}>
                      <td><span className="badge badge-gray">#{cls.id}</span></td>
                      <td><span className="font-semibold text-[var(--text-strong)]">{cls.class_name}</span></td>
                      <td><span className="badge badge-blue">Grade {cls.grade}</span></td>
                      <td className="hidden md:table-cell">{cls.teacher_name || `#${cls.teacher_id}`}</td>
                      <td className="hidden lg:table-cell">{cls.school_name || `#${cls.school_id}`}</td>
                      <td className="hidden md:table-cell">
                        <span className="badge badge-amber">{cls.school_district || '—'}</span>
                      </td>
                      <td>{cls.student_count}</td>
                      <td>
                        <button className="btn btn-danger" onClick={() => setDeleteTarget(cls)}>Delete</button>
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
          title="Delete Class"
          message={`Are you sure you want to delete class "${deleteTarget.class_name}" (Grade ${deleteTarget.grade})? All students in this class will lose their class assignment.`}
          onConfirm={handleDelete}
          onCancel={() => setDeleteTarget(null)}
          loading={deleting}
          danger
        />
      )}
    </div>
  );
}
