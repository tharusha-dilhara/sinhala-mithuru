const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('admin_token');
}

export function setToken(token: string, name: string) {
  localStorage.setItem('admin_token', token);
  localStorage.setItem('admin_name', name);
}

export function clearToken() {
  localStorage.removeItem('admin_token');
  localStorage.removeItem('admin_name');
}

export function getAdminName(): string {
  if (typeof window === 'undefined') return '';
  return localStorage.getItem('admin_name') || 'Admin';
}

async function apiFetch(path: string, options: RequestInit = {}) {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(err.detail || `HTTP ${res.status}`);
  }
  return res.json();
}

// --- Auth ---
export const adminApi = {
  login: (email: string, password: string) =>
    apiFetch('/admin/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  overview: () => apiFetch('/admin/overview'),

  // Schools
  getSchools: (search?: string, district?: string) => {
    const params = new URLSearchParams();
    if (search) params.append('search', search);
    if (district) params.append('district', district);
    return apiFetch(`/admin/schools?${params}`);
  },
  deleteSchool: (id: number) =>
    apiFetch(`/admin/schools/${id}`, { method: 'DELETE' }),

  // Teachers
  getTeachers: (schoolId?: number, search?: string) => {
    const params = new URLSearchParams();
    if (schoolId) params.append('school_id', String(schoolId));
    if (search) params.append('search', search);
    return apiFetch(`/admin/teachers?${params}`);
  },
  deleteTeacher: (id: number) =>
    apiFetch(`/admin/teachers/${id}`, { method: 'DELETE' }),

  // Classes
  getClasses: (schoolId?: number, teacherId?: number) => {
    const params = new URLSearchParams();
    if (schoolId) params.append('school_id', String(schoolId));
    if (teacherId) params.append('teacher_id', String(teacherId));
    return apiFetch(`/admin/classes?${params}`);
  },
  deleteClass: (id: number) =>
    apiFetch(`/admin/classes/${id}`, { method: 'DELETE' }),

  // Students
  getStudents: (classId?: number, schoolId?: number, search?: string) => {
    const params = new URLSearchParams();
    if (classId) params.append('class_id', String(classId));
    if (schoolId) params.append('school_id', String(schoolId));
    if (search) params.append('search', search);
    return apiFetch(`/admin/students?${params}`);
  },
  deleteStudent: (id: number) =>
    apiFetch(`/admin/students/${id}`, { method: 'DELETE' }),

  // Game State
  getStudentGameState: (studentId: number) =>
    apiFetch(`/admin/students/${studentId}/game-state`),

  updateStudentGameLevel: (studentId: number, newLevelId: number) =>
    apiFetch(`/admin/students/${studentId}/game-level`, {
      method: 'PUT',
      body: JSON.stringify({ new_level_id: newLevelId }),
    }),

  getGameLevels: () => apiFetch('/admin/game-levels'),
};
