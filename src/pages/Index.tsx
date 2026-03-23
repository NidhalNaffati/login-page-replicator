import { useState, useEffect } from 'react';
import Login from '@/components/Login';
import TodoDashboard from '@/components/TodoDashboard';

export default function Index() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    const authStatus = localStorage.getItem('isAuthenticated') === 'true';
    setIsAuthenticated(authStatus);
    setIsHydrated(true);
  }, []);

  const handleLogin = () => {
    localStorage.setItem('isAuthenticated', 'true');
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    localStorage.removeItem('isAuthenticated');
    setIsAuthenticated(false);
  };

  if (!isHydrated) return null;

  return (
    <div className="min-h-svh bg-rosePine-base text-rosePine-text selection:bg-rosePine-highlightHigh antialiased">
      {isAuthenticated ? (
        <TodoDashboard onLogout={handleLogout} />
      ) : (
        <Login onLogin={handleLogin} />
      )}
    </div>
  );
}
