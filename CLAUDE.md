# PermiX — CLAUDE.md

> Automatically loaded by Claude Code. Provides project context, architecture, coding conventions,
> and the full PermiX design system so every generated file stays on-brand and consistent.

---

## Project Overview

**PermiX** is an enterprise-grade SharePoint Online permissions auditing tool. It runs a
**PowerShell HTTP server** (`HttpListener`) that serves a **browser-based single-page app**
to the user's default browser. Data is collected via PnP PowerShell and Microsoft Graph,
exposed through a REST API backend, and visualised in a modern HTML/CSS/JS frontend.

It can run **locally** (PowerShell 7 + browser) or **containerised** (Docker/Podman).

- **Backend**: PowerShell 7+ with `HttpListener` web server
- **Frontend**: Vanilla HTML, CSS, JavaScript (no framework) served from `Web/`
- **Charts**: Chart.js
- **Auth**: Azure AD App Registration (MSAL public client flow)
- **SharePoint SDK**: PnP.PowerShell 3.x + Microsoft Graph API
- **Container**: Docker / Podman via `compose.yaml`
- **Target**: Windows (local) or any container host

---

## Architecture

```
PermiX/
├── Start-SPOTool-Web.ps1           # Entry point — starts web server & opens browser
├── Dockerfile                      # Container image definition
├── compose.yaml                    # Podman/Docker Compose config
├── docker-entrypoint.ps1           # Container startup script
├── Install-Prerequisites.ps1       # Module installer for local mode
│
├── Functions/
│   ├── Core/                       # Infrastructure & utilities
│   │   ├── AuditLog.ps1            #   Audit trail logging
│   │   ├── Checkpoint.ps1          #   Analysis checkpoint/resume support
│   │   ├── Logging.ps1             #   General logging helpers
│   │   ├── OutputAdapter.ps1       #   Output formatting adapter
│   │   ├── Settings.ps1            #   Configuration management
│   │   ├── SharePointDataManager.ps1 # Central data store & caching
│   │   └── ThrottleProtection.ps1  #   API throttle/rate-limit handling
│   │
│   ├── Analysis/                   # Data analysis & enrichment
│   │   ├── GraphEnrichment.ps1     #   Microsoft Graph user enrichment
│   │   ├── JsonExport.ps1          #   JSON export formatting
│   │   └── RiskScoring.ps1         #   Security risk scoring engine
│   │
│   ├── SharePoint/                 # SharePoint data collection
│   │   ├── PermissionsCollector.ps1 #  Collects all permission assignments
│   │   ├── PermissionsMatrix.ps1   #   Builds permission matrix view
│   │   ├── SiteCollector.ps1       #   Site enumeration & metadata
│   │   └── SPOConnection.ps1       #   Authentication & connection handling
│   │
│   ├── Server/                     # Web server & REST API backend
│   │   ├── ApiHandlers.ps1         #   REST API route handlers
│   │   ├── BackgroundJobManager.ps1 #  Background analysis job runner
│   │   └── WebServer.ps1           #   HTTP server (PowerShell HttpListener)
│   │
│   └── Demo/                       # Demo mode
│       └── DemoDataGenerator.ps1   #   Generates realistic sample data
│
├── Web/                            # Browser-based frontend (SPA)
│   ├── index.html                  #   Single-page app shell
│   ├── css/
│   │   ├── app.css                 #   Core styles, CSS variables & layout
│   │   └── enhancements.css        #   Extended components & animations
│   └── js/
│       ├── app.js                  #   App bootstrap & tab routing
│       ├── app-state.js            #   Shared application state
│       ├── api.js                  #   Backend API client (fetch wrappers)
│       ├── analytics.js            #   Analytics tab logic
│       ├── charts.js               #   Chart rendering (Chart.js)
│       ├── connection.js           #   Connection tab & auth flow
│       ├── deep-dives.js           #   Deep dive modal views
│       ├── export.js               #   CSV/JSON export logic
│       ├── operations.js           #   Operations tab logic
│       ├── permissions-matrix.js   #   Permissions matrix view
│       ├── search.js               #   Global omnibox search (Ctrl+K)
│       └── ui-helpers.js           #   Shared UI utilities
│
├── Images/                         # Screenshots for documentation
└── Logs/                           # Runtime logs (auto-created)
```

---

## Commands

```powershell
# Install dependencies (local mode, run once)
.\Install-Prerequisites.ps1

# Start the app locally (opens browser automatically)
.\Start-SPOTool-Web.ps1

# Run in Docker/Podman
docker compose up        # or: podman compose up

# Suppress PnP update nag
$env:PNPPOWERSHELL_UPDATECHECK = "Off"
```

---

## Code Style

### PowerShell
- Use **approved verbs** (`Get-`, `Set-`, `Invoke-`, `New-`, `Remove-`) for all functions
- **4-space indentation** — no tabs
- `PascalCase` for function names and parameters: `Get-SitePermissions`, `$SiteUrl`
- `camelCase` for local variables inside functions: `$siteData`, `$userList`
- Always include `[CmdletBinding()]` and typed parameters on public functions
- All SharePoint/Graph calls must be wrapped in `try/catch`; log errors via `Write-ActivityLog`
- Prefer `$null -eq $var` over `$var -eq $null`
- No inline credentials — all secrets via UI input or Azure auth flows
- API responses must always include a `Content-Type: application/json` header
- Route handlers live in `ApiHandlers.ps1` — do not add routing logic to `WebServer.ps1`
- Background jobs use `BackgroundJobManager.ps1` — never `Start-Job` directly in handlers

### HTML
- One single-page app shell: `index.html` — do not create additional `.html` files
- Tab panels use `data-tab` attributes for routing via `app.js`
- All dynamic content is injected via JavaScript — no server-side templating
- Use semantic elements: `<section>`, `<nav>`, `<header>`, `<main>`, `<aside>`
- Always reference CSS variables — never hardcode hex values in HTML `style` attributes

### CSS
- **All colors, spacing, radius and typography via CSS custom properties** defined in `app.css`
- Follow the PermiX design token naming convention (see Design System below)
- `app.css` — core variables, resets, layout, and base component styles
- `enhancements.css` — animations, extended component variants, responsive overrides
- Use `rem` for font sizes, `px` for borders, CSS variables for everything else
- BEM-inspired class naming: `.card`, `.card__title`, `.card--highlighted`
- Never use `!important` except for utility override classes prefixed with `.u-`

### JavaScript
- Vanilla JS only — no framework, no build step, no npm
- Each file owns one concern (see architecture above) — do not mix tab logic between files
- All API calls go through `api.js` — no raw `fetch()` calls in tab files
- State mutations go through `app-state.js` — no module-level globals elsewhere
- Use `async/await` — no `.then()` chains
- Error handling: always `try/catch` around API calls, surface errors via `ui-helpers.js`
- Chart.js instances must be destroyed before re-rendering to avoid canvas memory leaks

### Git
- Branch naming: `feature/description`, `fix/description`, `chore/description`
- Commit messages: imperative present tense — `Add risk score column to matrix`, not `Added`

---

## Design System — PermiX Brand

All UI must use the CSS custom properties defined in `Web/css/app.css`.
**Never hardcode hex values in CSS rules or HTML style attributes.**

### Color Palette

Derived from the PermiX logo: indigo → cyan gradient on deep navy.

| CSS Variable                  | Hex       | Usage                                          |
|-------------------------------|-----------|------------------------------------------------|
| `--color-primary`             | `#6366F1` | Primary actions, active states, links          |
| `--color-primary-light`       | `#818CF8` | Hover states, secondary highlights             |
| `--color-primary-dark`        | `#4F46E5` | Pressed states, focus rings                    |
| `--color-accent`              | `#22D3EE` | Gradient end, badges, progress, chart accents  |
| `--color-accent-muted`        | `#06B6D4` | Subtle accent use, secondary chart lines       |
| `--color-bg`                  | `#0F0F1A` | Page/app background                            |
| `--color-surface`             | `#1A1A2E` | Cards, panels, tab content areas               |
| `--color-surface-elevated`    | `#22223A` | Modals, dropdowns, tooltips                    |
| `--color-border`              | `#2E2E4A` | Dividers, input borders, card outlines         |
| `--color-border-subtle`       | `#1E1E35` | Subtle separators, table row dividers          |
| `--color-text-primary`        | `#F1F5F9` | Body text, headings, labels                    |
| `--color-text-secondary`      | `#94A3B8` | Placeholder text, metadata, captions           |
| `--color-text-muted`          | `#475569` | Disabled text, footnotes                       |
| `--color-success`             | `#10B981` | Success states, allowed permissions            |
| `--color-success-bg`          | `#0D3321` | Success badge/chip background                  |
| `--color-warning`             | `#F59E0B` | Warnings, elevated permissions                 |
| `--color-warning-bg`          | `#3A2C0D` | Warning badge/chip background                  |
| `--color-danger`              | `#EF4444` | Errors, denied access, destructive actions     |
| `--color-danger-bg`           | `#7F1D1D` | Error badge/chip background                    |
| `--color-gradient-start`      | `#6366F1` | Brand gradient start (indigo)                  |
| `--color-gradient-end`        | `#22D3EE` | Brand gradient end (cyan)                      |

The brand gradient applied as a CSS rule:
```css
background: linear-gradient(135deg, var(--color-gradient-start), var(--color-gradient-end));
```

### Typography

```
Font stack:  'Segoe UI', system-ui, -apple-system, sans-serif
Mono stack:  'Consolas', 'Cascadia Code', monospace

Scale (rem):
  --font-size-xs:   0.6875rem   (11px) — timestamps, footnotes
  --font-size-sm:   0.8125rem   (13px) — metadata, captions, taglines
  --font-size-base: 0.875rem    (14px) — body text, table cells
  --font-size-md:   1rem        (16px) — card titles, tab labels
  --font-size-lg:   1.125rem    (18px) — section headings
  --font-size-xl:   1.5rem      (24px) — page/panel titles
  --font-size-2xl:  2rem        (32px) — hero/stat numbers

Font weights:
  --font-weight-normal:    400
  --font-weight-medium:    500
  --font-weight-semibold:  600
  --font-weight-bold:      700
```

### Spacing

```
Base unit: 4px

  --space-1:   0.25rem   (4px)
  --space-2:   0.5rem    (8px)
  --space-3:   0.75rem   (12px)
  --space-4:   1rem      (16px)
  --space-6:   1.5rem    (24px)
  --space-8:   2rem      (32px)
  --space-12:  3rem      (48px)
```

### Border Radius

```
  --radius-sm:   4px    — tags, chips, small badges
  --radius-md:   8px    — buttons, inputs, small cards
  --radius-lg:   12px   — panels, modals, large cards
  --radius-full: 9999px — pills, avatars, circular badges
```

### Shadows

```css
--shadow-sm:  0 1px 3px rgba(0,0,0,0.4);
--shadow-md:  0 4px 12px rgba(0,0,0,0.5);
--shadow-lg:  0 8px 32px rgba(0,0,0,0.6);
--shadow-glow: 0 0 20px rgba(99,102,241,0.3);   /* primary glow */
--shadow-glow-accent: 0 0 20px rgba(34,211,238,0.3); /* accent glow */
```

---

## CSS Custom Property Block

Add this to the `:root` block in `Web/css/app.css`:

```css
:root {
  /* Brand */
  --color-primary:          #6366F1;
  --color-primary-light:    #818CF8;
  --color-primary-dark:     #4F46E5;
  --color-accent:           #22D3EE;
  --color-accent-muted:     #06B6D4;
  --color-gradient-start:   #6366F1;
  --color-gradient-end:     #22D3EE;

  /* Backgrounds */
  --color-bg:               #0F0F1A;
  --color-surface:          #1A1A2E;
  --color-surface-elevated: #22223A;

  /* Borders */
  --color-border:           #2E2E4A;
  --color-border-subtle:    #1E1E35;

  /* Text */
  --color-text-primary:     #F1F5F9;
  --color-text-secondary:   #94A3B8;
  --color-text-muted:       #475569;

  /* Semantic */
  --color-success:          #10B981;
  --color-success-bg:       #0D3321;
  --color-warning:          #F59E0B;
  --color-warning-bg:       #3A2C0D;
  --color-danger:           #EF4444;
  --color-danger-bg:        #7F1D1D;

  /* Typography */
  --font-sans:              'Segoe UI', system-ui, -apple-system, sans-serif;
  --font-mono:              'Consolas', 'Cascadia Code', monospace;
  --font-size-xs:           0.6875rem;
  --font-size-sm:           0.8125rem;
  --font-size-base:         0.875rem;
  --font-size-md:           1rem;
  --font-size-lg:           1.125rem;
  --font-size-xl:           1.5rem;
  --font-size-2xl:          2rem;
  --font-weight-normal:     400;
  --font-weight-medium:     500;
  --font-weight-semibold:   600;
  --font-weight-bold:       700;

  /* Spacing */
  --space-1:   0.25rem;
  --space-2:   0.5rem;
  --space-3:   0.75rem;
  --space-4:   1rem;
  --space-6:   1.5rem;
  --space-8:   2rem;
  --space-12:  3rem;

  /* Radius */
  --radius-sm:   4px;
  --radius-md:   8px;
  --radius-lg:   12px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm:         0 1px 3px rgba(0,0,0,0.4);
  --shadow-md:         0 4px 12px rgba(0,0,0,0.5);
  --shadow-lg:         0 8px 32px rgba(0,0,0,0.6);
  --shadow-glow:       0 0 20px rgba(99,102,241,0.3);
  --shadow-glow-accent:0 0 20px rgba(34,211,238,0.3);
}
```

---

## Chart.js Color Palette

When generating charts in `charts.js`, use these consistent dataset colors:

```js
const PERMIX_CHART_COLORS = {
  primary:      'rgba(99,  102, 241, 0.85)',
  accent:       'rgba(34,  211, 238, 0.85)',
  success:      'rgba(16,  185, 129, 0.85)',
  warning:      'rgba(245, 158, 11,  0.85)',
  danger:       'rgba(239, 68,  68,  0.85)',
  muted:        'rgba(148, 163, 184, 0.5)',
  // Borders (full opacity)
  primaryBorder: '#6366F1',
  accentBorder:  '#22D3EE',
};

// Global Chart.js defaults to set once in charts.js
Chart.defaults.color           = '#94A3B8';
Chart.defaults.borderColor     = '#2E2E4A';
Chart.defaults.backgroundColor = '#1A1A2E';
```

---

## API Conventions (Server ↔ Frontend)

- All endpoints return `Content-Type: application/json`
- Success responses: `{ "success": true, "data": { ... } }`
- Error responses:  `{ "success": false, "error": "Human readable message" }`
- Long-running operations return a `jobId` and are polled via `/api/job/:id/status`
- Demo mode responses mirror real response shapes exactly

---

## Rules for Claude Code

- **Never hardcode hex values** in CSS or HTML — always `var(--color-xxx)`
- **Never add npm, node_modules, or a build step** — this is intentionally zero-dependency frontend
- **Never create new `.html` files** — all views are panels inside `index.html`
- New tab logic goes in its own `Web/js/<tabname>.js` file, registered in `app.js`
- New API routes are added to `ApiHandlers.ps1` only — not inline in `WebServer.ps1`
- Always destroy existing Chart.js instances before re-rendering
- Demo mode data must exactly mirror the shape of real API responses

---

## Planned Features (do not implement without confirmation)

- Users deep dive view
- Groups deep dive view
- External users deep dive view
- Batch multi-site analysis queue
- Scheduled export via container cron
