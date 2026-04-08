# 🔓 Intentional Vulnerabilities Added for Security Demo

All changes are clearly marked with `⚠️ SECURITY DEMO — INTENTIONALLY VULNERABLE` comments so reviewers know they are deliberate.

---

## What Trivy Will Detect

### 📁 Filesystem / Dependency Scan (`trivy-fs`)
| Vulnerability                                               | Source               | Severity |
|-------------------------------------------------------------|----------------------|----------|
| CVE-2021-23337 — Command Injection in `lodash`              | `lodash@4.17.20`     | **HIGH** |
| CVE-2020-28500 — ReDoS in `lodash`                          | `lodash@4.17.20`     | MEDIUM   |
| CVE-2025-13465 — Prototype Pollution in `lodash`            | `lodash@4.17.20`     | MEDIUM   |
| CVE-2026-2950 — Prototype Pollution array bypass            | `lodash@4.17.20`     | MEDIUM   |
| CVE-2026-4800 — Code Injection via `_.template`             | `lodash@4.17.20`     | **HIGH** |
| CVE-2022-23539 — Insecure key types in `jsonwebtoken`       | `jsonwebtoken@8.5.1` | **HIGH** |
| CVE-2022-23540 — Signature bypass via `none` algorithm      | `jsonwebtoken@8.5.1` | MEDIUM   |
| CVE-2022-23541 — RSA to HMAC forgery                        | `jsonwebtoken@8.5.1` | MEDIUM   |
| CVE-2024-29041 — Open Redirect in `express`                 | `express@4.17.1`     | MEDIUM   |
| CVE-2024-43796 — XSS via `response.redirect()`              | `express@4.17.1`     | LOW      |
| **Secrets**: API keys, passwords in `.env` and `index.html` | `.env`, `index.html` | **HIGH** |

### 🐳 Image Scan (`trivy-image-app`)
| Finding | Source |
|---|---|
| **Old nginx:1.21** base image with dozens of OS-level CVEs | `Dockerfile` |
| Hardcoded `ENV` secrets (`APP_SECRET`, `DB_PASSWORD`, `JWT_SECRET`) | `Dockerfile` |
| `.env` file with passwords/API keys copied into image | `Dockerfile` → `COPY .env` |

### 🛠️ IaC / Config Scan (`trivy-config`)
| Finding                            | Source            | Trivy ID |
|------------------------------------|-------------------|----------|
| Container running as root          | `deployment.yaml` | KSV012   |
| Privileged container               | `deployment.yaml` | KSV001   |
| Privilege escalation allowed       | `deployment.yaml` | KSV001   |
| SYS_ADMIN / NET_ADMIN capabilities | `deployment.yaml` | KSV003   |
| Host network enabled               | `deployment.yaml` | KSV023   |
| No resource limits                 | `deployment.yaml` | KSV011   |
| Read-write root filesystem         | `deployment.yaml` | KSV014   |
| SA token auto-mounted              | `deployment.yaml` | KSV036   |
| No USER directive in Dockerfile    | `Dockerfile`      | DS002    |
| No HEALTHCHECK in Dockerfile       | `Dockerfile`      | DS026    |

---

## What OWASP ZAP Will Detect

| Finding                                    | Source                            | ZAP Rule    |
|--------------------------------------------|-----------------------------------|-------------|
| Missing Content-Security-Policy            | `nginx.conf`                      | 10038       |
| Missing X-Frame-Options (clickjacking)     | `nginx.conf`                      | 10020       |
| Missing X-Content-Type-Options             | `nginx.conf`                      | 10021       |
| Missing HSTS header                        | `nginx.conf`                      | 10035       |
| Server version leaked in `Server` header   | `nginx.conf` (`server_tokens on`) | 10036       |
| Technology stack leaked via `X-Powered-By` | `nginx.conf`                      | 10037       |
| Directory browsing enabled                 | `nginx.conf` (`autoindex on`)     | 10033       |
| No cache-control on assets                 | `nginx.conf`                      | 10015       |
| Information disclosure (inline secrets)    | `index.html`                      | 10027       |
| Stored XSS via `dangerouslySetInnerHTML`   | `TodoItem.tsx`                    | 40012/40014 |

---

## Files Changed

1. **`package.json`** — Added `lodash@4.17.20`, `jsonwebtoken@8.5.1`, `express@4.17.1`
2. **`bun.lock`** — Regenerated with new dependencies
3. **`.env`** *(new)* — Fake credentials & API keys for Trivy secret scan
4. **`Dockerfile`** — Old `nginx:1.21` base, hardcoded ENV secrets, COPY .env, no USER, no HEALTHCHECK
5. **`nginx.conf`** — `server_tokens on`, `X-Powered-By`, `autoindex on`, no security headers
6. **`index.html`** — Inline `<script>` with hardcoded credentials
7. **`src/components/TodoItem.tsx`** — XSS via `dangerouslySetInnerHTML`
8. **`k8s/app/deployment.yaml`** — Privileged, root, hostNetwork, no limits, no probes, SYS_ADMIN caps
9. **`.trivyignore`** — Cleared (nothing suppressed)
10. **`.zap/rules.tsv`** — Changed IGNORE → WARN/FAIL for all rules
11. **`.github/workflows/trivy.yml`** — Removed `ignore-unfixed`, widened severity to include LOW, non-blocking
12. **`.github/workflows/deploy.yml`** — Same Trivy changes for image scans, non-blocking exit-code 0

## Pipeline Behavior

- ✅ Build still passes
- ✅ Unit tests still pass
- ✅ Trivy scans will **find & report** vulnerabilities but **won't block** the pipeline (exit-code 0)
- ✅ ZAP baseline scan will report multiple WARN/FAIL findings
- ✅ All findings generate HTML reports uploaded as GitHub Actions artifacts
