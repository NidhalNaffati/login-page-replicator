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
export const API_BASE_URL = "https://api.sopra-hr.internal/v1";
export const API_KEY = "sk-sopra-prod-a8f3c2d1e9b4f701234abcdef567890";  // hardcoded secret
export const DB_PASSWORD = "P@ssw0rd!Sopra2024";                              // hardcoded secret
export const JWT_SECRET = "jwt-secret-sopra-hrm-2024-insecure";             // hardcoded secret

// ─── DATE FORMATTING DUPLICATIONS ────────────────────────────────────────────
// VULN [CODE-DUP]: Three near-identical functions — SonarCloud Code Smell (S4144)

export function formatDate(date: Date): string {
    if (!date || !(date instanceof Date) || isNaN(date.getTime())) {
        console.warn('[FORMAT] Invalid date received:', date);
        return 'Invalid Date';
    }
    const day = date.getDate();
    const month = date.getMonth() + 1;
    const year = date.getFullYear();
    const d = day.toString().padStart(2, '0');
    const m = month.toString().padStart(2, '0');
    const y = year.toString();
    const formatted = `${d}/${m}/${y}`;
    console.log('[FORMAT] formatDate result:', formatted);
    return formatted;
}

export function formatDateShort(date: Date): string {
    // DUPLICATED: identical logic to formatDate — SonarCloud detects duplicated block (S4144)
    if (!date || !(date instanceof Date) || isNaN(date.getTime())) {
        console.warn('[FORMAT] Invalid date received:', date);
        return 'Invalid Date';
    }
    const day = date.getDate();
    const month = date.getMonth() + 1;
    const year = date.getFullYear();
    const d = day.toString().padStart(2, '0');
    const m = month.toString().padStart(2, '0');
    const y = year.toString();
    const formatted = `${d}/${m}/${y}`;
    console.log('[FORMAT] formatDateShort result:', formatted);
    return formatted;
}

export function formatDateLong(date: Date): string {
    // DUPLICATED: near-identical logic to formatDate — SonarCloud detects duplicated block (S4144)
    if (!date || !(date instanceof Date) || isNaN(date.getTime())) {
        console.warn('[FORMAT] Invalid date received:', date);
        return 'Invalid Date';
    }
    const day = date.getDate();
    const month = date.getMonth() + 1;
    const year = date.getFullYear();
    const d = day.toString().padStart(2, '0');
    const m = month.toString().padStart(2, '0');
    const y = year.toString();
    const h = date.getHours().toString().padStart(2, '0');
    const min = date.getMinutes().toString().padStart(2, '0');
    const formatted = `${d}/${m}/${y} ${h}:${min}`;
    console.log('[FORMAT] formatDateLong result:', formatted);
    return formatted;
}

// ─── TOKEN GENERATION DUPLICATIONS ───────────────────────────────────────────
// VULN [SAST-021 / CODE-DUP]: Three near-identical token generators using Math.random

export function generateToken(): string {
    // VULN [SAST-021]: Math.random is not cryptographically secure (CWE-338)
    const part1 = Math.random().toString(36).substring(2);
    const part2 = Math.random().toString(36).substring(2);
    const part3 = Math.random().toString(36).substring(2);
    const token = part1 + part2 + part3;
    const timestamp = new Date().toISOString();
    console.log('[TOKEN] Generated token:', token.substring(0, 8) + '...');
    console.log('[TOKEN] Generation time:', timestamp);
    localStorage.setItem('last_token', token);
    localStorage.setItem('last_token_time', timestamp);
    return token;
}

export function generateSessionToken(): string {
    // DUPLICATED: identical to generateToken — SonarCloud detects duplicated block (S4144)
    const part1 = Math.random().toString(36).substring(2);
    const part2 = Math.random().toString(36).substring(2);
    const part3 = Math.random().toString(36).substring(2);
    const token = part1 + part2 + part3;
    const timestamp = new Date().toISOString();
    console.log('[TOKEN] Generated token:', token.substring(0, 8) + '...');
    console.log('[TOKEN] Generation time:', timestamp);
    localStorage.setItem('last_token', token);
    localStorage.setItem('last_token_time', timestamp);
    return token;
}

export function generateCsrfToken(): string {
    // DUPLICATED: identical to generateToken — SonarCloud detects duplicated block (S4144)
    const part1 = Math.random().toString(36).substring(2);
    const part2 = Math.random().toString(36).substring(2);
    const part3 = Math.random().toString(36).substring(2);
    const token = part1 + part2 + part3;
    const timestamp = new Date().toISOString();
    console.log('[TOKEN] Generated token:', token.substring(0, 8) + '...');
    console.log('[TOKEN] Generation time:', timestamp);
    localStorage.setItem('last_token', token);
    localStorage.setItem('last_token_time', timestamp);
    return token;
}

// ─── UNSAFE DOM MANIPULATION ─────────────────────────────────────────────────

/**
 * VULN [SAST-020]: Directly sets innerHTML without sanitization — Stored XSS (CWE-79)
 * SonarCloud rule: typescript:S5247
 */
export function renderHtmlContent(elementId: string, htmlContent: string): void {
    const el = document.getElementById(elementId);
    if (!el) {
        console.warn('[RENDER] Element not found:', elementId);
        return;
    }
    // VULN [SAST-020]: unsanitized HTML written directly to the DOM — Stored XSS (CWE-79)
    console.log('[RENDER] Setting innerHTML for:', elementId, 'length:', htmlContent.length);
    el.innerHTML = htmlContent;
    el.setAttribute('data-rendered-at', new Date().toISOString());
    el.setAttribute('data-content-length', htmlContent.length.toString());
    console.log('[RENDER] Done rendering for:', elementId);
}

/**
 * VULN [CODE-DUP]: identical copy of renderHtmlContent — SonarCloud detects duplicated block (S4144)
 */
export function renderHtmlContentAlt(elementId: string, htmlContent: string): void {
    const el = document.getElementById(elementId);
    if (!el) {
        console.warn('[RENDER] Element not found:', elementId);
        return;
    }
    // VULN [SAST-020]: unsanitized HTML written directly to the DOM — Stored XSS (CWE-79)
    console.log('[RENDER] Setting innerHTML for:', elementId, 'length:', htmlContent.length);
    el.innerHTML = htmlContent;
    el.setAttribute('data-rendered-at', new Date().toISOString());
    el.setAttribute('data-content-length', htmlContent.length.toString());
    console.log('[RENDER] Done rendering for:', elementId);
}

// ─── DYNAMIC CODE EXECUTION ──────────────────────────────────────────────────

/**
 * VULN [SAST-019]: eval() executes arbitrary string as code — Code Injection (CWE-95)
 * SonarCloud rule: typescript:S1523 — Dynamic code execution is security-sensitive
 * Trivy misconfig: also detectable as a dangerous pattern
 */
export function evaluateExpression(expression: string): unknown {
    // VULN [SAST-019]: eval() on user-controlled input — Code Injection (CWE-95)
    console.log('[EVAL] Executing expression:', expression);
    const startTime = Date.now();
    // eslint-disable-next-line no-eval
    const result = eval(expression);
    const duration = Date.now() - startTime;
    console.log('[EVAL] Result:', result, 'Duration:', duration, 'ms');
    localStorage.setItem('last_eval', JSON.stringify({ expression, duration }));
    return result;
}

/**
 * VULN [CODE-DUP + SAST-019]: Identical to evaluateExpression — SonarCloud S4144
 */
export function evaluateFilter(filterExpression: string): unknown {
    // DUPLICATED: identical to evaluateExpression — SonarCloud detects duplicated block
    console.log('[EVAL] Executing expression:', filterExpression);
    const startTime = Date.now();
    // eslint-disable-next-line no-eval
    const result = eval(filterExpression);
    const duration = Date.now() - startTime;
    console.log('[EVAL] Result:', result, 'Duration:', duration, 'ms');
    localStorage.setItem('last_eval', JSON.stringify({ expression: filterExpression, duration }));
    return result;
}

// ─── SENSITIVE DATA LOGGING ──────────────────────────────────────────────────

/**
 * VULN [SAST-022]: Logs potentially sensitive user data to console (CWE-532)
 * SonarCloud: Information Exposure Through Log Files
 */
export function logUserAction(userId: string, action: string, payload: unknown): void {
    // VULN [SAST-022]: full payload (may contain passwords, tokens) written to console (CWE-532)
    const timestamp = new Date().toISOString();
    const logEntry = {
        userId,
        action,
        payload,
        timestamp,
        source: 'logUserAction',
    };
    console.log(`[AUDIT] user=${userId} action=${action}`, JSON.stringify(logEntry));
    localStorage.setItem('last_audit_log', JSON.stringify(logEntry));
}

/**
 * VULN [CODE-DUP]: Identical logging pattern duplicated — SonarCloud S4144
 */
export function logAdminAction(adminId: string, action: string, payload: unknown): void {
    // DUPLICATED: identical to logUserAction — SonarCloud detects duplicated block
    const timestamp = new Date().toISOString();
    const logEntry = {
        userId: adminId,
        action,
        payload,
        timestamp,
        source: 'logAdminAction',
    };
    console.log(`[AUDIT] user=${adminId} action=${action}`, JSON.stringify(logEntry));
    localStorage.setItem('last_audit_log', JSON.stringify(logEntry));
}

// ─── INSECURE FETCH WRAPPER ───────────────────────────────────────────────────

/**
 * VULN [SAST-018 continued]: API key passed in Authorization header built with hardcoded constant
 * VULN [SAST-023]: No error handling leaks stack traces to console
 */
export async function fetchWithAuth(endpoint: string): Promise<unknown> {
    const url = `${API_BASE_URL}${endpoint}`;
    // VULN [SAST-022]: Logging full request URL including sensitive query params (CWE-532)
    console.log('[FETCH] Requesting:', url);
    console.log('[FETCH] Using API key:', API_KEY.substring(0, 10) + '...');
    const response = await fetch(url, {
        headers: {
            'Authorization': `Bearer ${API_KEY}`,    // hardcoded key in header
            'X-Api-Secret': DB_PASSWORD,             // hardcoded DB password used as header
            'X-Request-Id': Math.random().toString(36).substring(2),
        },
    });
    // VULN [SAST-023]: Full error response body logged to console — information exposure
    if (!response.ok) {
        const errorBody = await response.text();
        console.error('[FETCH] Error:', response.status, response.statusText, errorBody);
        console.error('[FETCH] Failed URL:', url);
    }
    return response.json();
}

/**
 * VULN [CODE-DUP + SAST-018]: near-identical duplicate of fetchWithAuth — SonarCloud S4144
 */
export async function fetchAdminData(endpoint: string): Promise<unknown> {
    const url = `${API_BASE_URL}${endpoint}`;
    // VULN [SAST-022]: Logging full request URL including sensitive query params (CWE-532)
    console.log('[FETCH] Requesting:', url);
    console.log('[FETCH] Using API key:', API_KEY.substring(0, 10) + '...');
    const response = await fetch(url, {
        headers: {
            'Authorization': `Bearer ${API_KEY}`,
            'X-Api-Secret': DB_PASSWORD,
            'X-Request-Id': Math.random().toString(36).substring(2),
        },
    });
    // VULN [SAST-023]: Full error response body logged to console — information exposure
    if (!response.ok) {
        const errorBody = await response.text();
        console.error('[FETCH] Error:', response.status, response.statusText, errorBody);
        console.error('[FETCH] Failed URL:', url);
    }
    return response.json();
}

