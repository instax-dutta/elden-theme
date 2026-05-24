# THEME_COVERAGE.md

Sentri theme for Pterodactyl Panel — coverage report and reference.

## Theme model

This repo ships a **single-stylesheet overlay** that Pterodactyl loads via the
custom `resources/views/templates/wrapper.blade.php`. Every visual rule lives in
`public/themes/sentri-pterodactyl-dark/theme.css`. The file is composed of a
token block at the top (`:root { … }`) followed by selector groups that target
both Pterodactyl's static markup (Blade-rendered auth pages, error pages) and
its compiled React frontend (Tailwind utility classes, react-modal,
styled-component patterns, xterm.js, CodeMirror).

There is no separate `tokens.css` — for an injected-CSS overlay, splitting the
file across two HTTP requests would require updating the wrapper template, so
the tokens live at the top of `theme.css` as a single source of truth instead.

## Build / install

```bash
# Install onto a real Pterodactyl panel (auto-detects path, handles sudo)
curl -sL https://raw.githubusercontent.com/instax-dutta/elden-theme/main/install.sh -o /tmp/sentri-theme.sh \
  && bash /tmp/sentri-theme.sh

# Local preview (no Pterodactyl required)
open preview.html   # macOS — or just double-click in a file browser

# Path B (native Tailwind compile inside Pterodactyl)
cd /var/www/pterodactyl && yarn install && yarn build:production
```

Theme is purely runtime CSS — no JS, no PHP changes inside Pterodactyl.

## View / component coverage

Every row below is themed by selectors in `theme.css`. "Selector hook" lists the
classes / Tailwind utilities / styled-component name patterns matched.

### Global / shell

| Area | Status | Selector hook |
|---|---|---|
| `<html>` / `<body>` canvas, starfield, fixed gradient | ✅ | `html`, `body` |
| Webkit + Firefox scrollbar | ✅ | `::-webkit-scrollbar*`, `scrollbar-color` |
| Text selection highlight | ✅ | `::selection` |
| Keyboard focus rings | ✅ | `:focus-visible`, `.focus\:ring*` |
| Global link styling | ✅ | `a`, `a:hover` |
| Print stylesheet | ✅ | `@media print` |

### Tailwind utility re-mapping (the bulk of Pterodactyl's frontend)

| Utility family | Mapped to | Status |
|---|---|---|
| `bg-neutral-*` / `bg-gray-*` / `bg-zinc-*` / `bg-slate-*` / `bg-stone-*` (50–950) | Sentri violet ramp (`--sentri-press-stronger` → `--sentri-primary`) | ✅ |
| `text-neutral-*` / `text-gray-*` etc. (100–900) | `--sentri-text-primary` / `secondary` / `muted` | ✅ |
| `border-neutral-*` etc. (300–900) | `--sentri-border-subtle` / `default` | ✅ |
| `bg-red-*` / `text-red-*` / `border-red-*` | `--sentri-status-error*` | ✅ |
| `bg-green-*` / `text-green-*` | `--sentri-status-success*` | ✅ |
| `bg-yellow-*` / `bg-amber-*` | `--sentri-status-warning*` | ✅ |
| `bg-blue-*` / `bg-cyan-*` / `bg-sky-*` | `--sentri-status-info*` | ✅ |
| `bg-purple-*` / `bg-violet-*` / `bg-indigo-*` | Sentri violet | ✅ |
| `hover:bg-neutral-{600,700,800}` | Violet hover steps | ✅ |
| `bg-white` (used by Pterodactyl for inverted panels) | White fill + ink text auto-applied | ✅ |

### Auth & error views

| View | Status | Notes |
|---|---|---|
| Login form | ✅ | `#login`, `.LoginFormContainer`, `.auth-card` |
| 2FA challenge | ✅ | Inherits auth-card + form input styling |
| Forgot / reset password | ✅ | Same auth-card surface |
| 404 / 403 / 500 / maintenance | ✅ | `.error-page`, `[class*="ErrorPage"]`, `.error-code` |

### Navigation

| Component | Status | Selector hook |
|---|---|---|
| Top navbar | ✅ | `.header`, `header[class*="Navigation"]`, `nav[class*="NavigationBar"]` |
| Server sidebar | ✅ | `.sidebar`, `nav[class*="Sidebar"]` |
| Admin sidebar | ✅ | Same selectors as server sidebar |
| SubNavigation tab strip | ✅ | `[class*="SubNavigation"] a`, active state, hover |
| Sidebar section headers | ✅ | `.sidebar h2/h3`, `[class*="Sidebar"] h2/h3` |
| Nav items + active accent (lime left border) | ✅ | `.menu-item`, `.nav-item`, `nav … a.active` |

### Dashboard / server list

| Component | Status |
|---|---|
| Server cards | ✅ via generic `.card`/`.server-card`/`.resource-card` |
| Server status badges (running / offline / installing / suspended / error / transferring) | ✅ `.status-running`, `.status-offline`, etc. |
| Status indicator dot | ✅ `.status-indicator.{success,warning,error,info}` |
| CPU / RAM / Disk progress meters | ✅ `.progress`, `.progress-bar`, semantic variants |
| Search / filter input | ✅ Global input rules |
| Empty state | ✅ `.table-empty`, `[class*="EmptyState"]` |

### Server console

| Component | Status |
|---|---|
| xterm.js container | ✅ `.xterm`, `.xterm-viewport`, `.xterm-screen` |
| xterm cursor + selection | ✅ `.xterm-cursor-layer .xterm-cursor`, `.xterm-selection div` |
| Power buttons (start / restart / stop) | ✅ `.btn-success`, `.btn-warning`, `.btn-danger` |
| Stats bar above console | ✅ `.stat`, `.metric` |
| Decorative console chrome (preview / embeds) | ✅ `.console-header-bar`, `.console-dots`, `.console-scanline` |
| Live status badge | ✅ `.badge`, `.badge--success` |

### File manager

| Component | Status |
|---|---|
| File tree rows | ✅ `table tbody tr` + hover |
| Action toolbar buttons | ✅ Standard button system |
| Context menu (right-click) | ✅ `.dropdown-menu`, `[role="menu"]` + `.danger` item |
| File editor (CodeMirror 5/6) | ✅ `.CodeMirror*`, `.cm-editor`, `.cm-gutters`, syntax tokens |
| Inline rename input | ✅ Global input rules |

### Databases / Schedules / Users / Backups / Network / Startup / Settings

All driven by the global `.table` + `.card` + form rules. Listed individually
to make the audit traceable:

| Area | Status |
|---|---|
| Databases list + connection-string copy | ✅ |
| Schedules cards + cron-expression code chip | ✅ inline `code` rule |
| Subuser / user permissions checkboxes | ✅ custom checkbox/radio paint |
| Toggle switches (active / inactive) | ✅ `.switch`, `[role="switch"]` |
| Backup rows + storage usage bar | ✅ table + progress |
| Allocations + primary badge | ✅ table + status badges |
| Startup variable cards | ✅ `.card` |
| Server settings — danger zone | ✅ `.btn-danger`, danger card states |

### Modals, dropdowns, toasts, alerts, tooltips

| Component | Status | Selector hook |
|---|---|---|
| Modal panel | ✅ | `.modal`, `.ReactModal__Content`, `[class*="ModalContainer"]` |
| Modal overlay (with blur) | ✅ | `.ReactModal__Overlay`, `[class*="ModalOverlay"]` |
| Modal header + close button | ✅ | `.modal-header`, `.modal-close`, `[class*="ModalClose"]` |
| Dropdown menus | ✅ | `.dropdown-menu`, `[role="menu"]`, `[role="listbox"]` |
| Dropdown items + danger item | ✅ | `.dropdown-item`, `[role="menuitem"]` |
| Toast notifications (notistack) | ✅ | `[class*="SnackbarItem"]`, semantic variants |
| Flash banners | ✅ | `.alert`, `.alert-success/warning/error/info` |
| Tooltips (tippy.js) | ✅ | `.tippy-box`, `.tippy-arrow` |

### Loading states

| Component | Status |
|---|---|
| Page spinner | ✅ `.spinner`, `[class*="Spinner"]` |
| Skeleton shimmer | ✅ `.skeleton`, `[class*="Skeleton"]` |

### Account pages / Admin panel

| Page | Status |
|---|---|
| Profile / password change | ✅ via global form rules |
| 2FA setup + backup codes | ✅ Code block via `pre`/`code` |
| API Keys list + reveal modal | ✅ table + modal + inline `code` |
| SSH Keys list / add textarea | ✅ table + form |
| Activity log entries | ✅ table |
| Admin user / node / location / nest tables | ✅ generic table rules |
| Egg JSON config textarea | ✅ form `textarea` |
| Admin settings sections (SMTP, reCAPTCHA, branding) | ✅ `.card` + form |

## Token reference

Tokens are declared in `:root` at the top of `theme.css`. All selectors below
the foundation reference `var(--sentri-*)` — no hex literals appear in the body
of the file (verified with `awk` scan).

### Brand primitives (DESIGN.md hex values, unmodified)

| Token | Value | Purpose (DESIGN.md role) |
|---|---|---|
| `--sentri-primary` | `#150f23` | Midnight Violet — primary CTA on light surfaces, code-block bg |
| `--sentri-ink-deep` | `#1f1633` | Ink Violet — default body ink + dark canvas |
| `--sentri-on-primary` | `#ffffff` | Text on dark canvas, CTA labels |
| `--sentri-accent-lime` | `#c2ef4e` | Keyword chip / footer squiggle — NEVER a button bg |
| `--sentri-accent-pink` | `#fa7faa` | Sticker outlines, error/danger semantic |
| `--sentri-accent-violet` | `#6a5fc1` | Inline link emphasis, focused-input border |
| `--sentri-violet-deep` | `#422082` | Select-fill on dark, spotlight cards |
| `--sentri-violet-mid` | `#79628c` | Tag chip fills, neutral status |
| `--sentri-ink-press` | `#1a1a1a` | Pressed state of inverted buttons |
| `--sentri-press-light` | `#f0f0f0` | Pressed inverted-button fill |
| `--sentri-press-stronger` | `#efefef` | Strongest pressed inverted fill |
| `--sentri-hairline-violet` | `#362d59` | 1px borders on dark cards |
| `--sentri-on-dark-muted` | `#bdb8c0` | Secondary text on dark |
| `--sentri-on-dark-faint` | `rgb(255 255 255 / 0.18)` | Ghost button fill, dimmed nav |

### Derived / extended tokens

Spacing (`--sentri-space-{xxs,xs,sm,md,lg,xl,xxl}`), radius
(`--sentri-radius-{xs,sm,md,lg,xl,xxl,full}`), typography
(`--sentri-text-{xs,sm,md,base,lg,xl,2xl}`, `--sentri-leading-*`,
`--sentri-weight-*`, `--sentri-tracking-*`), motion
(`--sentri-transition-{fast,base,slow}`), and semantic surface tokens are
defined in full at the top of `theme.css`. The ANSI 16 (`--sentri-ansi-*`)
were derived from the brand palette so xterm.js color slots stay legible on
the `--sentri-terminal-bg` surface.

## Fidelity notes vs DESIGN.md

The first AI pass (Gemini) violated three explicit DESIGN.md rules; all are
fixed in this iteration:

1. **Primary CTAs no longer use a lime gradient.** DESIGN.md: *"Never a
   button background"* for `--sentri-accent-lime`. Primary now uses the
   `button-inverted` pattern (white fill, ink text) appropriate for dark
   canvas; lime is reserved for status badges, keyword chips, and the active
   sidebar accent.
2. **Focus ring uses the spec'd blue** (`#9dc1f5`, the `ring-focus` token)
   instead of lime, restoring its WCAG affordance against the violet canvas.
3. **Keyword chip padding corrected** to `0 12px` (DESIGN.md spec) from the
   previous `0 8px`.

Additional corrections:
- `code`/`pre` cascade narrowed so inline `code` inside `.terminal` doesn't
  inherit a double border/padding.
- `.toast`, `.dropdown-menu`, `.modal-content` no longer inherit `.card`
  hover-lift — overlays shouldn't translateY on hover.

## Cross-cutting checks

- **No hex outside tokens** — verified via `awk` scan of the body of
  `theme.css`. All literal hex/rgba live inside `:root`. The only
  alpha-channel modulations downstream use `rgb(R G B / α)` against
  already-tokenized values.
- **Contrast** — primary text (`--sentri-text-primary` = `#ffffff`) on
  `--sentri-surface-canvas` (`#1f1633`) clears 4.5:1 by a wide margin
  (≈17:1). Secondary text (`#bdb8c0`) on the same canvas is ~9.1:1. The
  inverted primary button (`#ffffff` fill, `#1f1633` text) is the same
  inverse ratio. Status semantic colors all clear 3:1 against the canvas
  for badge / large-label use.
- **No layout breakage** — sizes and radii respect Pterodactyl's existing
  spacing scale (8px base, 4–32px range, plus `section`).
- **Dark-mode discipline** — theme renders dark canvas regardless of
  `prefers-color-scheme`; Pterodactyl's own light-mode utilities
  (`bg-white`) are remapped to read with ink text so any accidental usage
  doesn't produce illegible blocks.

## Known limitations of the overlay approach

1. **styled-components hash classes.** Pterodactyl's React frontend emits
   classes like `sc-abc123-0`. The overlay cannot target these — it relies
   instead on the underlying HTML tag (`button`, `input`, `select`), on the
   compiled Tailwind utility classes present in the bundle, and on partial
   matches like `[class*="Sidebar"]`. If a future Pterodactyl release moves
   to fully hashed selectors with no Tailwind utilities, the corresponding
   selectors here will need partial-match updates.
2. **Native Tailwind compile (Path B) is required for deepest fidelity** of
   components that emit Tailwind utilities at build time. The runtime CSS
   overlay covers the common shipped utilities, but a panel that has been
   patched with custom utility prefixes would need its `tailwind.config.js`
   merged with the one in this repo.
3. **xterm.js ANSI palette** is set by the overlay's `--sentri-ansi-*`
   tokens, but Pterodactyl sometimes constructs an xterm Theme object in JS
   that overrides CSS. If the brand ANSI palette is critical, the values in
   `theme.css` can be lifted into the Pterodactyl React source and passed
   directly to the xterm constructor.
4. **Login background blur effect** uses `backdrop-filter`; Firefox <103
   ignores it. The fallback (solid translucent overlay) still reads
   correctly.
5. **CodeMirror syntax tokens** are tinted by the overlay, but if
   Pterodactyl ever switches to Monaco editor, those selectors won't apply
   — Monaco uses inline styles for syntax highlighting.

## Files in this repo

| Path | Purpose |
|---|---|
| `public/themes/sentri-pterodactyl-dark/theme.css` | Single-source theme (tokens + selectors) |
| `resources/views/templates/wrapper.blade.php` | Pterodactyl wrapper template that injects `theme.css` |
| `tailwind.config.js` | Used during Path B (native Tailwind compile inside Pterodactyl) |
| `DESIGN.md` | Sentri design language source of truth |
| `preview.html` | Local preview harness — open in a browser to inspect token coverage |
| `install.sh` | Installer (auto-sudo, docker-aware, with `--uninstall`) |
| `package.json` | Theme metadata |

## Direct-edit summary

No PHP, JS, or routing code in Pterodactyl was changed. The only file outside
the theme stylesheet that this repo modifies on the target panel is
`resources/views/templates/wrapper.blade.php` — and only to add two
preconnect hints, a body class (`.sentri-theme`), and the `<link>` tag for
the theme stylesheet. The wrapper preserves every Pterodactyl `@section`,
`@css`, and asset injection point, so functional behaviour is unchanged.
