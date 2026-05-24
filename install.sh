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
    if [[ -n "$explicit" && "$explicit" != "--uninstall" && "$explicit" != "-u" ]]; then
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

    # If in interactive terminal, prompt the user rather than failing immediately
    if [[ -t 0 ]]; then
        printf '[sentri-theme] Pterodactyl directory could not be auto-detected.\n' >&2
        local manual_path
        read -rp '[sentri-theme] Please enter the absolute path to your panel: ' manual_path
        if [[ -f "$manual_path/artisan" ]]; then
            printf '%s\n' "$manual_path"
            return
        fi
    fi

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
    if [[ -f "$SELF_PATH/resources/views/templates/wrapper.blade.php" ]]; then
        printf '%s\n' "$SELF_PATH"
        return
    fi

    local workdir src_dir
    workdir="$(mktemp -d "$DEFAULT_TMP_DIR/sentri-theme-install.XXXXXX")"
    src_dir="$(download_bundle "$workdir")"
    [[ -f "$src_dir/resources/views/templates/wrapper.blade.php" ]] || die "theme bundle is missing wrapper.blade.php"
    printf '%s\n' "$src_dir"
}

backup_files() {
    local panel_dir="$1"
    local backup_dir="$2"

    sudo_cmd mkdir -p "$backup_dir"

    # Backup wrapper.blade.php
    [[ -f "$panel_dir/resources/views/templates/wrapper.blade.php" ]] && sudo_cmd cp -a "$panel_dir/resources/views/templates/wrapper.blade.php" "$backup_dir/wrapper.blade.php"
    
    # Backup tailwind.config.js if exists
    [[ -f "$panel_dir/tailwind.config.js" ]] && sudo_cmd cp -a "$panel_dir/tailwind.config.js" "$backup_dir/tailwind.config.js" || true
    
    # Backup theme folder if exists
    [[ -d "$panel_dir/public/themes/$THEME_NAME" ]] && sudo_cmd cp -a "$panel_dir/public/themes/$THEME_NAME" "$backup_dir/" || true
}

install_theme_files() {
    local source_dir="$1"
    local panel_dir="$2"

    log "installing theme view templates"
    sudo_cmd mkdir -p "$panel_dir/resources/views/templates"
    sudo_cmd cp -a "$source_dir/resources/views/templates/wrapper.blade.php" "$panel_dir/resources/views/templates/wrapper.blade.php"

    log "installing theme public assets"
    local theme_dir="$panel_dir/public/themes/$THEME_NAME"
    sudo_cmd mkdir -p "$theme_dir"
    sudo_cmd cp -a "$source_dir/public/themes/$THEME_NAME/theme.css" "$theme_dir/theme.css"

    # Copy tailwind.config.js to root directory for build compilation
    if [[ -f "$source_dir/tailwind.config.js" ]]; then
        log "copying tailwind.config.js for compilation support"
        sudo_cmd cp -a "$source_dir/tailwind.config.js" "$panel_dir/tailwind.config.js"
    fi
}

clear_panel_cache() {
    local panel_dir="$1"

    log "clearing Laravel caches"
    
    # 1. Clean on host if PHP is installed on the host
    if command -v php >/dev/null 2>&1; then
        sudo_cmd php "$panel_dir/artisan" view:clear >/dev/null || true
        sudo_cmd php "$panel_dir/artisan" cache:clear >/dev/null || true
        sudo_cmd php "$panel_dir/artisan" config:clear >/dev/null || true
        sudo_cmd php "$panel_dir/artisan" optimize:clear >/dev/null || true
    else
        log "PHP command not found on host; skipping host artisan caches."
    fi

    # 2. Automatically detect if running inside Docker container and clear cache inside
    if command -v docker >/dev/null 2>&1; then
        local container
        container=$(docker ps --format '{{.Names}}' | grep -E 'pterodactyl|panel' | head -n 1 || true)
        if [[ -n "$container" ]]; then
            log "detected running Pterodactyl container: $container"
            log "clearing caches inside the Docker container..."
            docker exec "$container" php artisan view:clear >/dev/null 2>&1 || true
            docker exec "$container" php artisan cache:clear >/dev/null 2>&1 || true
            docker exec "$container" php artisan config:clear >/dev/null 2>&1 || true
        fi
    fi
}

fix_permissions() {
    local panel_dir="$1"
    if id -u www-data >/dev/null 2>&1; then
        sudo_cmd chown -R www-data:www-data "$panel_dir/resources/views/templates/wrapper.blade.php" "$panel_dir/public/themes/$THEME_NAME" >/dev/null 2>&1 || true
    fi
}

uninstall_theme() {
    local panel_dir="$1"
    local wrapper="$panel_dir/resources/views/templates/wrapper.blade.php"
    local theme_dir="$panel_dir/public/themes/$THEME_NAME"

    log "uninstalling theme from $panel_dir"
    
    # Attempt to restore from latest backup folder
    local latest_backup
    latest_backup=$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "sentri-theme-backup-*" | sort -r | head -n 1 || true)

    if [[ -n "$latest_backup" && -f "$latest_backup/wrapper.blade.php" ]]; then
        log "restoring original wrapper.blade.php from backup: $latest_backup"
        sudo_cmd cp -a "$latest_backup/wrapper.blade.php" "$wrapper"
        
        if [[ -f "$latest_backup/tailwind.config.js" && -f "$panel_dir/tailwind.config.js" ]]; then
            log "restoring original tailwind.config.js"
            sudo_cmd cp -a "$latest_backup/tailwind.config.js" "$panel_dir/tailwind.config.js"
        fi
    else
        log "no backup wrapper.blade.php found; removing custom link from existing file"
        if [[ -f "$wrapper" ]]; then
            local tmp_file
            tmp_file="$(mktemp "$DEFAULT_TMP_DIR/sentri-wrapper-uninstall.XXXXXX")"
            grep -v "sentri-pterodactyl-dark" "$wrapper" > "$tmp_file" || true
            sudo_cmd install -m 0644 "$tmp_file" "$wrapper"
            rm -f "$tmp_file"
        fi
    fi

    if [[ -d "$theme_dir" ]]; then
        log "deleting theme directory: $theme_dir"
        sudo_cmd rm -rf "$theme_dir"
    fi

    clear_panel_cache "$panel_dir"
    log "uninstall complete! Theme has been removed."
}

main() {
    need_cmd awk
    need_cmd cp
    need_cmd grep
    need_cmd install
    need_cmd mktemp

    # Interactively ask for sudo credentials if run as normal user
    if [[ "${EUID}" -ne 0 ]]; then
        log "Requesting root privileges... Running script with sudo."
        exec sudo bash "$0" "$@"
    fi

    local action="install"
    local target_dir=""

    # Parse command line options
    for arg in "$@"; do
        if [[ "$arg" == "--uninstall" || "$arg" == "-u" ]]; then
            action="uninstall"
        else
            target_dir="$arg"
        fi
    done

    local panel_dir
    panel_dir="$(detect_panel_dir "$target_dir")"

    if [[ "$action" == "uninstall" ]]; then
        uninstall_theme "$panel_dir"
        return
    fi

    local source_dir
    source_dir="$(resolve_source_dir)"
    local backup_dir="$BACKUP_ROOT/sentri-theme-backup-$(date +%Y%m%d-%H%M%S)"

    log "panel detected at $panel_dir"
    log "creating backup at $backup_dir"
    backup_files "$panel_dir" "$backup_dir"

    log "copying theme files to panel directory..."
    install_theme_files "$source_dir" "$panel_dir"

    clear_panel_cache "$panel_dir"
    fix_permissions "$panel_dir"

    log "install complete!"
    printf '\n'
    printf 'Panel:   %s\n' "$panel_dir"
    printf 'Backup:  %s\n' "$backup_dir"
    printf 'Theme:   %s\n' "$THEME_NAME"
    printf '\n'
    printf 'Next: hard refresh your browser once to load the new Sentri dark theme.\n'
    printf 'Optionally: run `yarn install && yarn build:production` in your panel root to compile Tailwind colors!\n'
}

main "$@"
