'use client';

import { useState, useEffect, useCallback } from 'react';
import { adminApi } from '@/lib/api';
import ConfirmModal from '../ConfirmModal';
import StudentGameStateModal from '../StudentGameStateModal';

interface Student {
  id: number;
  name: string;
  parent_phone: string;
  class_id: number;
  class_name: string;
  grade: number;
  school_name: string;
  school_district: string;
  teacher_name: string;
}

export default function StudentsSection() {
  const [students, setStudents] = useState<Student[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [classFilter, setClassFilter] = useState('');
  const [schoolFilter, setSchoolFilter] = useState('');
  const [deleteTarget, setDeleteTarget] = useState<Student | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [gameStateTarget, setGameStateTarget] = useState<Student | null>(null);

  const loadStudents = useCallback(async () => {
    setLoading(true);
    try {
      const data = await adminApi.getStudents(
        classFilter ? Number(classFilter) : undefined,
        schoolFilter ? Number(schoolFilter) : undefined,
        search || undefined
      );
      setStudents(data);
    } catch (e: any) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [search, classFilter, schoolFilter]);

  useEffect(() => { loadStudents(); }, [loadStudents]);

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await adminApi.deleteStudent(deleteTarget.id);
      setStudents(prev => prev.filter(s => s.id !== deleteTarget.id));
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
          <h2 className="text-xl sm:text-2xl font-bold text-[var(--text-strong)]">Students</h2>
          <p className="text-sm text-[var(--text-muted)]">{students.length} students loaded</p>
        </div>
        <span className="badge badge-amber self-start sm:self-auto">{students.length} shown</span>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-2 flex-wrap">
        <div className="relative flex-1 min-w-0">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-light)] text-sm">🔍</span>
          <input
            className="input-field pl-9"
            placeholder="Search by student name..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <input
          className="input-field sm:w-36"
          placeholder="Class ID..."
          value={classFilter}
          onChange={e => setClassFilter(e.target.value)}
          type="number"
          min="1"
        />
        <input
          className="input-field sm:w-36"
          placeholder="School ID..."
          value={schoolFilter}
          onChange={e => setSchoolFilter(e.target.value)}
          type="number"
          min="1"
        />
        {(classFilter || schoolFilter || search) && (
          <button className="btn btn-secondary" onClick={() => { setClassFilter(''); setSchoolFilter(''); setSearch(''); }}>
            Clear
          </button>
        )}
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <div className="spinner spinner-lg" />
        </div>
      ) : students.length === 0 ? (
        <div className="card p-12 text-center text-[var(--text-muted)]">No students found</div>
      ) : (
        <>
          {/* Mobile: Card View */}
          <div className="sm:hidden space-y-3">
            {students.map(student => (
              <div key={student.id} className="card p-4">
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div className="min-w-0">
                    <p className="font-semibold text-[var(--text-strong)] text-sm truncate">{student.name}</p>
                    <div className="flex items-center gap-1.5 mt-1 flex-wrap">
                      <span className="badge badge-blue text-[0.65rem]">Grade {student.grade}</span>
                      <span className="text-[0.65rem] text-[var(--text-muted)]">{student.class_name || `Class #${student.class_id}`}</span>
                    </div>
                  </div>
                  <span className="badge badge-gray text-[0.65rem] flex-shrink-0">#{student.id}</span>
                </div>
                <div className="text-xs text-[var(--text-muted)] mb-3 space-y-0.5">
                  <p>🏫 {student.school_name || '—'}</p>
                  {student.parent_phone && <p>📞 {student.parent_phone}</p>}
                </div>
                <div className="flex gap-2">
                  <button
                    className="btn btn-secondary flex-1 text-xs"
                    onClick={() => setGameStateTarget(student)}
                  >
                    🎮 Progress
                  </button>
                  <button
                    className="btn btn-danger flex-1 text-xs"
                    onClick={() => setDeleteTarget(student)}
                  >
                    Delete
                  </button>
                </div>
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
                    <th>Student / සිසු</th>
                    <th className="hidden md:table-cell">Phone</th>
                    <th>Class</th>
                    <th className="hidden md:table-cell">School</th>
                    <th className="hidden lg:table-cell">District</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {students.map(student => (
                    <tr key={student.id}>
                      <td><span className="badge badge-gray">#{student.id}</span></td>
                      <td><span className="font-semibold text-[var(--text-strong)]">{student.name}</span></td>
                      <td className="hidden md:table-cell">
                        <span className="text-[var(--text-muted)] text-sm">{student.parent_phone || '—'}</span>
                      </td>
                      <td>
                        <div>
                          <span className="text-sm">{student.class_name || `#${student.class_id}`}</span>
                          <span className="badge badge-blue text-[0.6rem] ml-1.5">G{student.grade}</span>
                        </div>
                      </td>
                      <td className="hidden md:table-cell text-sm">{student.school_name || '—'}</td>
                      <td className="hidden lg:table-cell">
                        <span className="badge badge-gray">{student.school_district || '—'}</span>
                      </td>
                      <td>
                        <div className="flex gap-1.5">
                          <button
                            onClick={() => setGameStateTarget(student)}
                            className="btn btn-secondary text-xs !py-1.5 !px-2.5"
                          >
                            🎮 Progress
                          </button>
                          <button
                            className="btn btn-danger text-xs"
                            onClick={() => setDeleteTarget(student)}
                          >
                            Delete
                          </button>
                        </div>
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
          title="Delete Student"
          message={`Are you sure you want to delete student "${deleteTarget.name}"? All their game progress and activity data will be permanently lost.`}
          onConfirm={handleDelete}
          onCancel={() => setDeleteTarget(null)}
          loading={deleting}
          danger
        />
      )}

      {gameStateTarget && (
        <StudentGameStateModal
          studentId={gameStateTarget.id}
          studentName={gameStateTarget.name}
          onClose={() => setGameStateTarget(null)}
        />
      )}
    </div>
  );
}
