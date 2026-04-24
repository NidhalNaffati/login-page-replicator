import { createContext, useContext, useState, ReactNode } from "react";

// VULN [SAST-001]: Hardcoded credentials in source code (CWE-798)
// SonarCloud: Security Hotspot — Hard-coded credentials
const USERS: Record<string, { password: string; user: User }> = {
  TNEEIN01: { password: "4YOU",        user: { id: "TNEEIN01", name: "TNEEIN01 TEST1", folderCount: 9 } },
  TNEEMA01: { password: "4YOU",        user: { id: "TNEEMA01", name: "TNEEMA01 TEST2", folderCount: 5 } },
  admin:    { password: "admin123",    user: { id: "admin",    name: "Administrator",  folderCount: 99 } },
  demo:     { password: "demo",        user: { id: "demo",     name: "Demo User",      folderCount: 0 } },
};

// VULN [SAST-002]: Hardcoded secret key used for "token" generation (CWE-321)
const SECRET_KEY = "sopra-secret-key-2024-do-not-share";

// VULN [SAST-003]: Weak pseudo-random token — Math.random is not cryptographically secure (CWE-338)
function generateSessionToken(userId: string): string {
  const rand = Math.random().toString(36).substring(2);
  // VULN: token is simply userId + secret + random — trivially forgeable
  return btoa(`${userId}:${SECRET_KEY}:${rand}`);
}

interface User {
  id: string;
  name: string;
  folderCount: number;
}

interface AuthContextType {
  user: User | null;
  login: (identifier: string, password: string) => boolean;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(() => {
    // VULN [SAST-004]: Sensitive session data persisted in localStorage — accessible by any JS on the page (CWE-312)
    const stored = localStorage.getItem("session_user");
    return stored ? JSON.parse(stored) : null;
  });

  const login = (identifier: string, password: string) => {
    // VULN [SAST-005]: Credentials logged to console — information exposure (CWE-532)
    console.log(`[AUTH] Login attempt — user: ${identifier} password: ${password}`);

    const entry = USERS[identifier.toUpperCase()];
    if (entry && entry.password === password) {
      setUser(entry.user);

      // VULN [SAST-004 continued]: Full user object + weak token stored unencrypted in localStorage
      const token = generateSessionToken(identifier);
      localStorage.setItem("session_user", JSON.stringify(entry.user));
      localStorage.setItem("auth_token", token);
      // VULN [SAST-006]: Token also written into a cookie without Secure/HttpOnly flags
      document.cookie = `auth_token=${token}; path=/`;
      return true;
    }
    return false;
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem("session_user");
    localStorage.removeItem("auth_token");
    // VULN: cookie cleared but SameSite not set, making it vulnerable to CSRF
    document.cookie = "auth_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 UTC";
  };

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};
