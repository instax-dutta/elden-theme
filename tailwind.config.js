/**
 * Sentri — Tailwind configuration for Pterodactyl Panel.
 *
 * This config is used when the theme is compiled into Pterodactyl's React bundle
 * (Path B from the README). It mirrors the CSS custom properties declared in
 * `public/themes/sentri-pterodactyl-dark/theme.css` so utility-class output and
 * the runtime overlay stay in sync.
 *
 * Polarity rule: Pterodactyl is treated as a dark canvas. Tailwind's gray/neutral
 * shade ramps are remapped onto the Sentri violet family so existing `bg-neutral-*`
 * surfaces step through a coherent elevation ladder instead of collapsing onto a
 * single tone.
 */

const sentriViolet = {
  50:  '#f5f1ff',
  100: '#e7dffa',
  200: '#cebdef',
  300: '#beabeb',
  400: '#9c81df',
  500: '#79628c',  // violet-mid (DESIGN.md)
  600: '#6a5fc1',  // accent-violet (DESIGN.md)
  700: '#422082',  // violet-deep (DESIGN.md)
  800: '#362d59',  // hairline-violet (DESIGN.md)
  900: '#1f1633',  // ink-deep canvas (DESIGN.md)
  950: '#150f23',  // primary midnight (DESIGN.md)
};

module.exports = {
  content: [
    './resources/scripts/**/*.{js,jsx,ts,tsx}',
    './resources/views/**/*.blade.php',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans:    ['Rubik', 'Inter', '-apple-system', 'system-ui', 'Segoe UI', 'Helvetica', 'Arial', 'sans-serif'],
        display: ['Space Grotesk', 'Rubik', '-apple-system', 'system-ui', 'sans-serif'],
        mono:    ['JetBrains Mono', 'Monaco', 'Menlo', 'ui-monospace', 'SFMono-Regular', 'monospace'],
      },
      fontSize: {
        xs:     ['11px', { lineHeight: '1.4',  letterSpacing: '0.25px' }],
        sm:     ['13px', { lineHeight: '1.4'  }],
        base:   ['14px', { lineHeight: '1.5'  }],
        md:     ['16px', { lineHeight: '1.5'  }],
        lg:     ['20px', { lineHeight: '1.25' }],
        xl:     ['24px', { lineHeight: '1.25' }],
        '2xl':  ['30px', { lineHeight: '1.2'  }],
        '3xl':  ['60px', { lineHeight: '1.1'  }],
        hero:   ['88px', { lineHeight: '1.2',  letterSpacing: '-0.01em' }],
      },
      fontWeight: {
        normal:   '400',
        medium:   '500',
        semibold: '600',
        bold:     '700',
      },
      letterSpacing: {
        tight:  '-0.01em',
        normal: '0',
        wide:   '0.2px',
        caps:   '0.25px',
      },
      colors: {
        // Remap Tailwind's neutral families onto the Sentri violet ramp so layered
        // surfaces in Pterodactyl read with proper elevation depth.
        gray:    sentriViolet,
        neutral: sentriViolet,
        slate:   sentriViolet,
        zinc:    sentriViolet,
        stone:   sentriViolet,

        // Brand tokens — accessible as `bg-sentri-primary`, `text-sentri-lime`, etc.
        sentri: {
          primary:        'var(--sentri-primary)',
          'ink-deep':     'var(--sentri-ink-deep)',
          'ink-press':    'var(--sentri-ink-press)',
          lime:           'var(--sentri-accent-lime)',
          pink:           'var(--sentri-accent-pink)',
          violet:         'var(--sentri-accent-violet)',
          'violet-deep':  'var(--sentri-violet-deep)',
          'violet-mid':   'var(--sentri-violet-mid)',
          canvas:         'var(--sentri-surface-canvas)',
          raised:         'var(--sentri-surface-raised)',
          sunken:         'var(--sentri-surface-sunken)',
          overlay:        'var(--sentri-surface-overlay)',
        },

        // Semantic colors (server-status / alert level driven)
        success: {
          DEFAULT: 'var(--sentri-status-success)',
          bg:      'var(--sentri-status-success-bg)',
          border:  'var(--sentri-status-success-border)',
        },
        warning: {
          DEFAULT: 'var(--sentri-status-warning)',
          bg:      'var(--sentri-status-warning-bg)',
          border:  'var(--sentri-status-warning-border)',
        },
        error: {
          DEFAULT: 'var(--sentri-status-error)',
          bg:      'var(--sentri-status-error-bg)',
          border:  'var(--sentri-status-error-border)',
        },
        info: {
          DEFAULT: 'var(--sentri-status-info)',
          bg:      'var(--sentri-status-info-bg)',
          border:  'var(--sentri-status-info-border)',
        },
      },
      backgroundColor: {
        'btn-primary':   'var(--sentri-btn-primary-bg)',
        'btn-secondary': 'var(--sentri-btn-secondary-bg)',
        'btn-danger':    'var(--sentri-btn-danger-bg)',
        input:           'var(--sentri-input-bg)',
        card:            'var(--sentri-card-bg)',
        modal:           'var(--sentri-modal-bg)',
        dropdown:        'var(--sentri-dropdown-bg)',
      },
      textColor: {
        primary:   'var(--sentri-text-primary)',
        secondary: 'var(--sentri-text-secondary)',
        muted:     'var(--sentri-text-muted)',
        disabled:  'var(--sentri-text-disabled)',
        link:      'var(--sentri-text-link)',
      },
      borderColor: {
        DEFAULT: 'var(--sentri-border-default)',
        subtle:  'var(--sentri-border-subtle)',
        strong:  'var(--sentri-border-strong)',
        input:   'var(--sentri-input-border)',
      },
      spacing: {
        xxs: '2px',
        xs:  '4px',
        sm:  '8px',
        md:  '12px',
        lg:  '16px',
        xl:  '24px',
        xxl: '32px',
        section: '96px',
      },
      borderRadius: {
        xs:   '4px',
        sm:   '6px',
        md:   '8px',
        lg:   '10px',
        xl:   '12px',
        xxl:  '18px',
        full: '9999px',
      },
      boxShadow: {
        sm:        'var(--sentri-shadow-sm)',
        md:        'var(--sentri-shadow-md)',
        lg:        'var(--sentri-shadow-lg)',
        press:     'var(--sentri-shadow-press)',
        'glow-violet': 'var(--sentri-glow-violet)',
        'glow-lime':   'var(--sentri-glow-lime)',
        'glow-cta':    'var(--sentri-glow-cta)',
        'focus-ring': 'var(--sentri-focus-ring)',
      },
      transitionDuration: {
        fast: '120ms',
        base: '200ms',
        slow: '320ms',
      },
      transitionTimingFunction: {
        sentri: 'cubic-bezier(0.16, 1, 0.3, 1)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
};
