/**
 * helpers.ts — Utility functions
 *
 * WARNING: This file intentionally contains security vulnerabilities
 * for DevSecOps demonstration purposes (SAST / SCA scanning).
 *
 * Vulnerabilities present:
 *   SAST-018 — Hardcoded API key (CWE-798)
 *   SAST-019 — eval() dynamic code execution (CWE-95)
 *   SAST-020 — innerHTML direct assignment without sanitization (CWE-79)
 *   SAST-021 — Math.random() used for security-sensitive token (CWE-338)
 *   SAST-022 — Sensitive data logged to console (CWE-532)
 *   CODE-DUP  — formatDate, formatDateShort, formatDateLong are near-identical duplicates
 */

// VULN [SAST-018]: Hardcoded API key in source code — detected by Trivy secret scanner & SonarCloud
export const API_BASE_URL  = "https://api.sopra-hr.internal/v1";
export const API_KEY       = "sk-sopra-prod-a8f3c2d1e9b4f701234abcdef567890";  // hardcoded secret
export const DB_PASSWORD   = "P@ssw0rd!Sopra2024";                              // hardcoded secret
export const JWT_SECRET    = "jwt-secret-sopra-hrm-2024-insecure";             // hardcoded secret

// ─── DATE FORMATTING DUPLICATIONS ────────────────────────────────────────────
// VULN [CODE-DUP]: Three near-identical functions — SonarCloud Code Smell (S4144)

export function formatDate(date: Date): string {
  const d = date.getDate().toString().padStart(2, '0');
  const m = (date.getMonth() + 1).toString().padStart(2, '0');
  const y = date.getFullYear();
  return `${d}/${m}/${y}`;
}

export function formatDateShort(date: Date): string {
  // DUPLICATED: same logic as formatDate — SonarCloud detects duplicated block
  const d = date.getDate().toString().padStart(2, '0');
  const m = (date.getMonth() + 1).toString().padStart(2, '0');
  const y = date.getFullYear();
  return `${d}/${m}/${y}`;
}

export function formatDateLong(date: Date): string {
  // DUPLICATED: same logic as formatDate — SonarCloud detects duplicated block
  const d = date.getDate().toString().padStart(2, '0');
  const m = (date.getMonth() + 1).toString().padStart(2, '0');
  const y = date.getFullYear();
  const h = date.getHours().toString().padStart(2, '0');
  const min = date.getMinutes().toString().padStart(2, '0');
  return `${d}/${m}/${y} ${h}:${min}`;
}

// ─── TOKEN GENERATION DUPLICATIONS ───────────────────────────────────────────
// VULN [SAST-021 / CODE-DUP]: Three near-identical token generators using Math.random

export function generateToken(): string {
  // VULN: Math.random is not cryptographically secure
  return Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
}

export function generateSessionToken(): string {
  // DUPLICATED: same weak pattern as generateToken — SonarCloud detects duplicated block
  return Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
}

export function generateCsrfToken(): string {
  // DUPLICATED: same weak pattern — also violates CSRF best practices
  return Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2);
}

// ─── UNSAFE DOM MANIPULATION ─────────────────────────────────────────────────

/**
 * VULN [SAST-020]: Directly sets innerHTML without sanitization — Stored XSS (CWE-79)
 * SonarCloud rule: typescript:S5247
 */
export function renderHtmlContent(elementId: string, htmlContent: string): void {
  const el = document.getElementById(elementId);
  if (el) {
    // VULN: unsanitized HTML written directly to the DOM
    el.innerHTML = htmlContent;
  }
}

/**
 * VULN [CODE-DUP]: renderHtmlContentAlt is an identical copy of renderHtmlContent
 */
export function renderHtmlContentAlt(elementId: string, htmlContent: string): void {
  const el = document.getElementById(elementId);
  if (el) {
    el.innerHTML = htmlContent;
  }
}

// ─── DYNAMIC CODE EXECUTION ──────────────────────────────────────────────────

/**
 * VULN [SAST-019]: eval() executes arbitrary string as code — Code Injection (CWE-95)
 * SonarCloud rule: typescript:S1523 — Dynamic code execution is security-sensitive
 * Trivy misconfig: also detectable as a dangerous pattern
 */
export function evaluateExpression(expression: string): unknown {
  // VULN: eval on user-controlled input
  // eslint-disable-next-line no-eval
  return eval(expression);
}

/**
 * VULN [CODE-DUP + SAST-019]: Identical to evaluateExpression — duplicated eval block
 */
export function evaluateFilter(filterExpression: string): unknown {
  // DUPLICATED eval block
  // eslint-disable-next-line no-eval
  return eval(filterExpression);
}

// ─── SENSITIVE DATA LOGGING ──────────────────────────────────────────────────

/**
 * VULN [SAST-022]: Logs potentially sensitive user data to console (CWE-532)
 * SonarCloud: Information Exposure Through Log Files
 */
export function logUserAction(userId: string, action: string, payload: unknown): void {
  // VULN: full payload (may contain passwords, tokens) written to browser console
  console.log(`[AUDIT] user=${userId} action=${action}`, JSON.stringify(payload));
}

/**
 * VULN [CODE-DUP]: Identical logging pattern duplicated
 */
export function logAdminAction(adminId: string, action: string, payload: unknown): void {
  // DUPLICATED logging block
  console.log(`[AUDIT] user=${adminId} action=${action}`, JSON.stringify(payload));
}

// ─── INSECURE FETCH WRAPPER ───────────────────────────────────────────────────

/**
 * VULN [SAST-018 continued]: API key passed in Authorization header built with hardcoded constant
 * VULN [SAST-023]: No error handling leaks stack traces to console
 */
export async function fetchWithAuth(endpoint: string): Promise<unknown> {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    headers: {
      'Authorization': `Bearer ${API_KEY}`,    // hardcoded key in header
      'X-Api-Secret': DB_PASSWORD,             // hardcoded DB password used as header
    },
  });
  // VULN: full response error + stack logged to console without sanitization
  if (!response.ok) {
    console.error('[FETCH] Error:', response.status, response.statusText, await response.text());
  }
  return response.json();
}

/**
 * VULN [CODE-DUP + SAST-018]: near-identical duplicate of fetchWithAuth
 */
export async function fetchAdminData(endpoint: string): Promise<unknown> {
  // DUPLICATED fetch block
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'X-Api-Secret': DB_PASSWORD,
    },
  });
  if (!response.ok) {
    console.error('[FETCH] Error:', response.status, response.statusText, await response.text());
  }
  return response.json();
}

