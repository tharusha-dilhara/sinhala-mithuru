'use client';

import { useState, useEffect } from 'react';
import { adminApi, setToken, getToken } from '@/lib/api';
import Dashboard from '@/components/Dashboard';
import LoginPage from '@/components/LoginPage';

export default function Home() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const token = getToken();
    setIsLoggedIn(!!token);
  }, []);

  if (!mounted) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--bg-app)]">
        <div className="spinner spinner-lg" />
      </div>
    );
  }

  if (!isLoggedIn) {
    return <LoginPage onLogin={() => setIsLoggedIn(true)} />;
  }

  return <Dashboard onLogout={() => setIsLoggedIn(false)} />;
}
