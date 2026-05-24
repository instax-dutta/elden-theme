#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="sentri-pterodactyl-dark"
REPO_ZIP_URL="${REPO_ZIP_URL:-https://github.com/instax-dutta/elden-theme/archive/refs/heads/main.zip}"
DEFAULT_TMP_DIR="${TMPDIR:-/tmp}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/www}"
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    printf '[sentri-theme] %s\n' "$1" >&2
}

die() {
    printf '[sentri-theme] Error: %s\n' "$1" >&2
    exit 1
}

sudo_cmd() {
    if [[ "${EUID}" -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

detect_panel_dir() {
    local explicit="${1:-}"
    if [[ -n "$explicit" ]]; then
        [[ -f "$explicit/artisan" ]] || die "no artisan file found in $explicit"
        printf '%s\n' "$explicit"
        return
    fi

    local candidates=(
        /var/www/pterodactyl
        /var/www/panel
        /var/www/html/pterodactyl
        /var/www/html/panel
        /opt/pterodactyl
        /opt/panel
    )

    local dir
    for dir in "${candidates[@]}"; do
        if [[ -f "$dir/artisan" ]]; then
            printf '%s\n' "$dir"
            return
        fi
    done

    die "could not detect your Pterodactyl panel path automatically; rerun with: bash install.sh /path/to/panel"
}

download_bundle() {
    local workdir="$1"
    local zip_path="$workdir/elden-theme.zip"
    local src_dir="$workdir/src"

    log "downloading latest Sentri theme bundle"
    need_cmd unzip

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_ZIP_URL" -o "$zip_path"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$zip_path" "$REPO_ZIP_URL"
    else
        die "install curl or wget first"
    fi

    unzip -q "$zip_path" -d "$src_dir"

    local extracted
    extracted="$(find "$src_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    [[ -n "$extracted" ]] || die "downloaded archive did not contain a theme directory"
    printf '%s\n' "$extracted"
}

resolve_source_dir() {
    if [[ -f "$SELF_PATH/pterodactyl-sentry-dark.css" ]]; then
        printf '%s\n' "$SELF_PATH"
        return
    fi

    local workdir src_dir
    workdir="$(mktemp -d "$DEFAULT_TMP_DIR/sentri-theme-install.XXXXXX")"
    src_dir="$(download_bundle "$workdir")"
    [[ -f "$src_dir/pterodactyl-sentry-dark.css" ]] || die "theme bundle is missing pterodactyl-sentry-dark.css"
    printf '%s\n' "$src_dir"
}

backup_files() {
    local panel_dir="$1"
    local backup_dir="$2"

    sudo_cmd mkdir -p "$backup_dir"

    [[ -f "$panel_dir/resources/views/templates/wrapper.blade.php" ]] && sudo_cmd cp -a "$panel_dir/resources/views/templates/wrapper.blade.php" "$backup_dir/wrapper.blade.php"
    [[ -d "$panel_dir/public/themes/$THEME_NAME" ]] && sudo_cmd cp -a "$panel_dir/public/themes/$THEME_NAME" "$backup_dir/"
}

install_theme_css() {
    local source_dir="$1"
    local panel_dir="$2"
    local theme_dir="$panel_dir/public/themes/$THEME_NAME"

    sudo_cmd install -d "$theme_dir"
    sudo_cmd install -m 0644 "$source_dir/pterodactyl-sentry-dark.css" "$theme_dir/theme.css"
}

inject_stylesheet() {
    local panel_dir="$1"
    local wrapper="$panel_dir/resources/views/templates/wrapper.blade.php"
    local marker="sentri-pterodactyl-dark"
    local link="            <link rel=\"stylesheet\" href=\"/themes/$THEME_NAME/theme.css?v={{ file_exists(public_path('themes/$THEME_NAME/theme.css')) ? filemtime(public_path('themes/$THEME_NAME/theme.css')) : time() }}\" data-theme=\"$marker\">"

    [[ -f "$wrapper" ]] || die "missing wrapper template at $wrapper"

    if sudo_cmd grep -q "data-theme=\"$marker\"" "$wrapper"; then
        log "stylesheet link already present in wrapper template"
        return
    fi

    local tmp_file
    tmp_file="$(mktemp "$DEFAULT_TMP_DIR/sentri-wrapper.XXXXXX")"

    awk -v link="$link" '
        /@show/ && !done {
            print link
            done = 1
        }
        { print }
    ' "$wrapper" > "$tmp_file"

    sudo_cmd install -m 0644 "$tmp_file" "$wrapper"
    rm -f "$tmp_file"
}

clear_panel_cache() {
    local panel_dir="$1"

    log "clearing Laravel caches"
    sudo_cmd php "$panel_dir/artisan" view:clear >/dev/null || true
    sudo_cmd php "$panel_dir/artisan" cache:clear >/dev/null || true
    sudo_cmd php "$panel_dir/artisan" config:clear >/dev/null || true
    sudo_cmd php "$panel_dir/artisan" optimize:clear >/dev/null || true
}

fix_permissions() {
    local panel_dir="$1"
    if id -u www-data >/dev/null 2>&1; then
        sudo_cmd chown -R www-data:www-data "$panel_dir/resources/views/templates/wrapper.blade.php" "$panel_dir/public/themes/$THEME_NAME" >/dev/null 2>&1 || true
    fi
}

main() {
    need_cmd awk
    need_cmd cp
    need_cmd grep
    need_cmd install
    need_cmd mktemp
    need_cmd php

    if [[ "${EUID}" -ne 0 ]] && ! sudo -n true >/dev/null 2>&1; then
        die "this installer needs root privileges; rerun with sudo bash install.sh"
    fi

    local panel_dir
    panel_dir="$(detect_panel_dir "${1:-}")"

    local source_dir
    source_dir="$(resolve_source_dir)"

    local backup_dir="$BACKUP_ROOT/sentri-theme-backup-$(date +%Y%m%d-%H%M%S)"

    log "panel detected at $panel_dir"
    log "creating backup at $backup_dir"
    backup_files "$panel_dir" "$backup_dir"

    log "installing theme CSS"
    install_theme_css "$source_dir" "$panel_dir"

    log "injecting stylesheet into Pterodactyl wrapper"
    inject_stylesheet "$panel_dir"

    clear_panel_cache "$panel_dir"
    fix_permissions "$panel_dir"

    log "install complete"
    printf '\n'
    printf 'Panel:   %s\n' "$panel_dir"
    printf 'Backup:  %s\n' "$backup_dir"
    printf 'Theme:   %s\n' "$THEME_NAME"
    printf '\n'
    printf 'Next: hard refresh your browser once to load the new Sentri dark theme.\n'
}

main "$@"
