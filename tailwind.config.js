const sentryDarkColors = {
  50:  '#fdfcff',
  100: '#f0ebfa',
  200: '#dbcef5',
  300: '#beabeb',
  400: '#9c81df',
  500: '#79628c', // mid-violet
  600: '#6a5fc1', // violet accent
  700: '#422082', // deep violet
  800: '#362d59', // hairline-violet
  900: '#1f1633', // ink-deep canvas background
  950: '#150f23', // primary midnight violet
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
        sans: ['Rubik', 'Inter', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['Monaco', 'Menlo', 'ui-monospace', 'SFMono-Regular', 'monospace'],
      },
      colors: {
        // Redefine standard Tailwind grays so Pterodactyl compiles into Sentry Midnight Violet natively!
        gray:    sentryDarkColors,
        neutral: sentryDarkColors,
        slate:   sentryDarkColors,
        zinc:    sentryDarkColors,
        stone:   sentryDarkColors,
        
        // Brand & Accent colors
        sentry: {
          primary: '#150f23',
          ink: '#1f1633',
          lime: '#c2ef4e',
          pink: '#fa7faa',
          violet: '#6a5fc1',
          'violet-deep': '#422082',
          'violet-mid': '#79628c',
        }
      },
      borderRadius: {
        xs: '4px',
        sm: '6px',
        md: '8px',
        lg: '10px',
        xl: '12px',
        xxl: '18px',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
};
