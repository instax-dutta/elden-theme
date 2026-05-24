# Sentri — Sentry Dark Theme for Pterodactyl Panel

A full-fledged, premium dark theme for Pterodactyl Panel inspired by Sentry's developer-centric design language. Built on a rich midnight violet canvas (`#1f1633` & `#150f23`) with high-contrast electric lime accents (`#c2ef4e`), neon border glows, floating mascot illustrations, and custom Monaco-style interactive terminal controls.

## Features

- **Midnight Violet Canvas**: Standardized `#150f23` (Midnight Violet) and `#1f1633` (Ink Violet) palette spanning sidebars, headers, cards, and dropdown inputs.
- **Electric Lime Interaction**: Vibrant lime CTA gradients, high-affordance active menu bars, and focus ring outlines.
- **Cybernetic Atmosphere**: Pure CSS-driven starfield overlays and 48px code-grid textures built directly into page backgrounds.
- **Premium Monaco Console**: Styled terminal windows equipped with colored close/minimize/maximize dots, error logs, and a scanning neon beam animation.
- **Bobbing Mascot Stickers**: Illustrated cute astronauts and warning cones featuring classic white border die-cuts.
- **Dual-Path Compilation**: Choose between a quick precompiled stylesheet injection or native Tailwind compilation.

## Folder Directory

- `public/themes/sentri-pterodactyl-dark/theme.css`: Precompiled stylesheet containing all overrides.
- `resources/views/templates/wrapper.blade.php`: Base PHP template wrapper pointing to the custom assets.
- `tailwind.config.js`: Custom Tailwind mappings that redefine standard slate/gray/neutral colors to Sentry midnight violet during compilation.
- `package.json`: Theme packaging metadata.
- `install.sh`: Master automation script supporting folder copies, auto-sudo privilege elevation, host cache clearing, Docker container flushes, and full rollback uninstallation.
- `preview.html`: Fully interactive markup demonstrating layout components and CSS transitions.

## Quick Install

Run this command as a normal user or root. Sudo elevation is handled automatically:

```bash
curl -sL https://raw.githubusercontent.com/instax-dutta/elden-theme/main/install.sh -o /tmp/sentri-theme.sh && bash /tmp/sentri-theme.sh
```

If your panel is installed in a custom location:

```bash
curl -sL https://raw.githubusercontent.com/instax-dutta/elden-theme/main/install.sh -o /tmp/sentri-theme.sh && bash /tmp/sentri-theme.sh /path/to/panel
```

## Compilation Pathways

You have two pathways to experience the theme:

### Path A: Direct CSS Injection (Default)
Our installer automatically places the custom stylesheet and injects the asset links into your layout files. Caches are cleared automatically and the theme is ready to view. **No node/yarn packages required.**

### Path B: Native Tailwind Compilation (Highly Recommended)
Because the theme includes a custom `tailwind.config.js` that maps all standard Pterodactyl gray, slate, and neutral color classes directly to Sentry HSL specifications, you can compile the theme natively into your panel's core React frontend!

To compile natively, run the following commands inside your Pterodactyl directory:

```bash
cd /var/www/pterodactyl
yarn install
yarn build:production
```

This will compile Sentry colors directly into the main Javascript bundle, giving you a lightning-fast, production-native layout that never breaks during panel version updates.

## Uninstall

To remove the theme, simply pass the `--uninstall` flag to the installer. It will automatically detect your latest backups and restore your panel's templates and configurations:

```bash
bash /tmp/sentri-theme.sh --uninstall
```
Alternatively, rerun with the path:
```bash
bash /tmp/sentri-theme.sh /var/www/pterodactyl --uninstall
```

## Acknowledgments

Special thanks to `getdesign.md` for compiling the Sentry design tokens.

## License

MIT
