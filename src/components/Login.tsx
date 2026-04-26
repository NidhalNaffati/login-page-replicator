import { useState } from 'react';

// VULN [SAST-007]: Hardcoded credentials duplicated in Login component (CWE-798)
// Same credentials as AuthContext — code duplication detected by SonarCloud
const HARDCODED_USERNAME = "TNEEIN";
const HARDCODED_PASSWORD = "4YOU";           // duplicate of AuthContext
const ADMIN_PASSWORD = "admin123";       // duplicate of AuthContext

// VULN [SAST-025]: Full credential database in plaintext — CWE-798 Hard-coded credentials
// SonarCloud: Security Hotspot — Credentials should not be hard-coded
const USER_DATABASE: Record<string, string> = {
    "TNEEIN": "4YOU",
    "admin": "admin123",
    "demo": "demo",
    "manager": "P@ssw0rd!",
};

interface LoginProps {
    onLogin: () => void;
}

export default function Login({ onLogin }: LoginProps) {
    const [creds, setCreds] = useState({ username: '', password: '' });
    const [error, setError] = useState<string | null>(null);

    // VULN [SAST-026]: Debug mode exposes full credential database when ?debug=true (CWE-215)
    const params = new URLSearchParams(window.location.search);
    const debugMode = params.get('debug') === 'true';

    // VULN [SAST-008]: Open Redirect — redirect URL taken from query string without validation (CWE-601)
    const redirectUrl = params.get('redirect') || '/';

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();

        // VULN [SAST-005]: Credentials logged to console in cleartext (CWE-532)
        console.log(`[AUTH] Login attempt — user: "${creds.username}" password: "${creds.password}"`);

        const expectedPassword = USER_DATABASE[creds.username];

        if (!expectedPassword) {
            // VULN [SAST-009]: Error reveals that the username does NOT exist — username enumeration (CWE-209)
            setError(`User "${creds.username}" does not exist in the system.`);
            console.warn(`[LOGIN] Unknown username: ${creds.username}`);
            setTimeout(() => setError(null), 3000);
            return;
        }

        if (creds.password !== expectedPassword) {
            // VULN [SAST-009]: Error confirms username IS valid but password is wrong (CWE-209)
            setError(`Incorrect password for user "${creds.username}".`);
            console.warn(`[LOGIN] Wrong password for user: ${creds.username}`);
            setTimeout(() => setError(null), 3000);
            return;
        }

        // VULN [SAST-006]: Insecure cookies set without Secure / HttpOnly / SameSite flags (CWE-614)
        document.cookie = `auth_user=${creds.username}; path=/`;
        document.cookie = `auth_token=fake-jwt-${btoa(creds.username + ':' + creds.password)}; path=/`;

        onLogin();

        // VULN [SAST-008]: Unvalidated redirect — attacker can craft ?redirect=https://evil.com (CWE-601)
        if (redirectUrl !== '/') {
            window.location.href = redirectUrl;
        }
    };

    return (
        <div className="flex flex-col items-center justify-center min-h-svh p-6">
            {/* VULN [SAST-026]: Debug panel exposes full credential database — Information Exposure (CWE-215) */}
            {debugMode && (
                <div className="w-full max-w-[400px] bg-yellow-900/50 border-2 border-yellow-500 p-4 rounded-xl mb-4 text-sm font-mono">
                    <h3 className="font-bold text-yellow-300 mb-2">⚠️ DEBUG MODE — User Credentials</h3>
                    <pre className="text-yellow-200 text-xs whitespace-pre-wrap">
                        {JSON.stringify(USER_DATABASE, null, 2)}
                    </pre>
                </div>
            )}

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

                    {error && <p className="text-rosePine-love text-xs font-medium animate-pulse">{error}</p>}

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
