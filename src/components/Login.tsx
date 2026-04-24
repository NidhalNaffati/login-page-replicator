import { useState } from 'react';

// VULN [SAST-007]: Hardcoded credentials duplicated in Login component (CWE-798)
// Same credentials as AuthContext — code duplication detected by SonarCloud
const HARDCODED_USERNAME = "TNEEIN";
const HARDCODED_PASSWORD = "4YOU";           // duplicate of AuthContext
const ADMIN_PASSWORD     = "admin123";       // duplicate of AuthContext

interface LoginProps {
  onLogin: () => void;
}

export default function Login({ onLogin }: LoginProps) {
  const [creds, setCreds] = useState({ username: '', password: '' });
  const [error, setError] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // VULN [SAST-008]: Open Redirect — redirect URL taken directly from query string without validation (CWE-601)
    // DAST (ZAP rule 10016) will detect this as a redirect vulnerability
    const params = new URLSearchParams(window.location.search);
    const redirectUrl = params.get('redirect') || '/dashboard';

    // VULN [SAST-007 continued]: Credentials compared in plaintext, duplicated logic
    if (
      creds.username === HARDCODED_USERNAME && creds.password === HARDCODED_PASSWORD ||
      creds.username === 'admin'             && creds.password === ADMIN_PASSWORD
    ) {
      onLogin();
      // VULN [SAST-008]: Unvalidated redirect — attacker can set ?redirect=https://evil.com
      window.location.href = redirectUrl;
    } else {
      setError(true);
      // VULN [SAST-009]: Error message reveals valid username hint — information leakage (CWE-209)
      console.warn(`[LOGIN] Failed attempt for user: ${creds.username}`);
      setTimeout(() => setError(false), 2000);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-svh p-6">
      <div className="w-full max-w-[400px] bg-rosePine-surface p-8 rounded-2xl shadow-surface">
        <header className="mb-8">
          <h1 className="text-2xl font-semibold text-rosePine-iris tracking-tight">Welcome back</h1>
          <p className="text-rosePine-muted text-sm mt-1">Please enter your details to continue.</p>
        </header>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-xs font-medium uppercase tracking-wider text-rosePine-subtle ml-1">Username</label>
            <input
              type="text"
              required
              className="w-full bg-rosePine-overlay px-4 py-2.5 rounded-lg outline-none focus:ring-2 ring-rosePine-iris/30 transition-all duration-200 placeholder:text-rosePine-muted text-rosePine-text"
              placeholder="TNEEIN"
              value={creds.username}
              onChange={e => setCreds({ ...creds, username: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <label className="text-xs font-medium uppercase tracking-wider text-rosePine-subtle ml-1">Password</label>
            <input
              type="password"
              required
              className="w-full bg-rosePine-overlay px-4 py-2.5 rounded-lg outline-none focus:ring-2 ring-rosePine-iris/30 transition-all duration-200 placeholder:text-rosePine-muted text-rosePine-text"
              placeholder="••••••••"
              value={creds.password}
              onChange={e => setCreds({ ...creds, password: e.target.value })}
            />
          </div>

          {error && <p className="text-rosePine-love text-xs font-medium animate-pulse">Invalid credentials. Try again.</p>}

          <button
            type="submit"
            className="w-full bg-rosePine-iris hover:bg-rosePine-iris/90 text-rosePine-base font-bold py-3 rounded-lg transition-all active:scale-[0.98] mt-4"
          >
            Sign In
          </button>
        </form>
      </div>
    </div>
  );
}
