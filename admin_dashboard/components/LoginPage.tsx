'use client';

import { useState } from 'react';
import { adminApi, setToken } from '@/lib/api';

interface Props {
  onLogin: () => void;
}

export default function LoginPage({ onLogin }: Props) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await adminApi.login(email, password);
      setToken(res.access_token, res.name || 'Admin');
      onLogin();
    } catch (err: any) {
      setError(err.message || 'Login failed. Check credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--bg-app)] px-4">
      <div className="w-full max-w-sm">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-[var(--primary)] text-white text-2xl mb-4 shadow-sm">
            🎓
          </div>
          <h1 className="text-2xl font-bold text-[var(--text-strong)] tracking-tight">
            Sinhala Mithuru
          </h1>
          <p className="text-sm text-[var(--text-muted)] mt-1">Platform Administration</p>
        </div>

        {/* Card */}
        <div className="card p-6 sm:p-8">
          <h2 className="text-base font-bold text-[var(--text-strong)] mb-5 text-center">
            Sign in to your account
          </h2>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-[var(--text-body)] mb-1.5">
                Email Address
              </label>
              <input
                type="email"
                className="input-field"
                placeholder="admin@example.com"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-[var(--text-body)] mb-1.5">
                Password
              </label>
              <input
                type="password"
                className="input-field"
                placeholder="••••••••"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
              />
            </div>

            {error && (
              <div className="p-3 rounded-lg text-sm bg-red-50 border border-red-200 text-red-600 flex items-start gap-2">
                <span className="flex-shrink-0">⚠️</span>
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              className="btn btn-primary w-full py-2.5 mt-1"
              disabled={loading}
            >
              {loading ? (
                <>
                  <span className="spinner" style={{ width: 16, height: 16, borderWidth: 2, borderTopColor: 'white', borderColor: 'rgba(255,255,255,0.3)' }} />
                  Authenticating...
                </>
              ) : (
                'Sign In'
              )}
            </button>
          </form>
        </div>

        <p className="text-center mt-6 text-xs text-[var(--text-light)]">
          &copy; {new Date().getFullYear()} Sinhala Mithuru. Secure administrative access only.
        </p>
      </div>
    </div>
  );
}
