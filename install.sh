#!/usr/bin/env bash
# Sentri Pterodactyl Dark Theme — installer
# Designed for zero silent failures and complete cache eviction.
set -euo pipefail

# ─── constants ────────────────────────────────────────────────────────────────
THEME_NAME="sentri-pterodactyl-dark"
REPO_ZIP_URL="${REPO_ZIP_URL:-https://github.com/instax-dutta/elden-theme/archive/refs/heads/main.zip}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/www}"
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR=""   # populated by mktemp; cleaned on EXIT

# ─── logging ──────────────────────────────────────────────────────────────────
_log()  { printf '[sentri] %-7s %s\n' "$1" "$2" >&2; }
log()   { _log "info"  "$1"; }
ok()    { _log "ok"    "$1"; }
warn()  { _log "warn"  "$1"; }
die()   { _log "error" "$1"; exit 1; }

# ─── cleanup ──────────────────────────────────────────────────────────────────
_cleanup() {
    local rc=$?
    [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
    if [[ $rc -ne 0 ]]; then
        _log "error" "Install aborted (exit $rc). Files in $BACKUP_ROOT/sentri-theme-backup-* remain safe."
    fi
}
trap _cleanup EXIT
trap 'die "interrupted"' INT TERM

# ─── helpers ──────────────────────────────────────────────────────────────────
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

# Run command; silence stdout+stderr; never abort the outer script.
quietly() { "$@" >/dev/null 2>&1 || true; }

sudo_run() {
    if [[ "${EUID}" -ne 0 ]]; then sudo "$@"; else "$@"; fi
}

# ─── panel detection ──────────────────────────────────────────────────────────
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
        [[ -f "$dir/artisan" ]] && { printf '%s\n' "$dir"; return; }
    done

    # Interactive fallback
    if [[ -t 0 ]]; then
        warn "Pterodactyl directory could not be auto-detected."
        local manual_path
        read -rp '[sentri] Enter absolute path to your panel: ' manual_path
        [[ -f "$manual_path/artisan" ]] || die "artisan not found at $manual_path"
        printf '%s\n' "$manual_path"
        return
    fi

    die "cannot detect panel path — re-run with: bash install.sh /path/to/panel"
}

# ─── download with retry ──────────────────────────────────────────────────────
download_bundle() {
    local zip_path="$1"
    local attempt max_attempts=3 delay=4

    log "downloading latest Sentri theme bundle"
    need_cmd unzip

    for attempt in $(seq 1 $max_attempts); do
        if command -v curl >/dev/null 2>&1; then
            curl --fail --silent --show-error --location \
                 --max-time 90 --retry 2 --retry-delay 3 \
                 "$REPO_ZIP_URL" -o "$zip_path" && return
        elif command -v wget >/dev/null 2>&1; then
            wget --quiet --timeout=90 --tries=2 \
                 "$REPO_ZIP_URL" -O "$zip_path" && return
        else
            die "install curl or wget first"
        fi
        warn "download attempt $attempt/$max_attempts failed; retrying in ${delay}s…"
        sleep "$delay"
        delay=$(( delay * 2 ))
    done
    die "download failed after $max_attempts attempts"
}

# ─── source resolution ────────────────────────────────────────────────────────
resolve_source_dir() {
    # Running from the cloned repo: use local files directly.
    if [[ -f "$SELF_PATH/resources/views/templates/wrapper.blade.php" && \
          -f "$SELF_PATH/public/themes/$THEME_NAME/theme.css" ]]; then
        printf '%s\n' "$SELF_PATH"
        return
    fi

    # Otherwise fetch from GitHub.
    WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sentri-install.XXXXXX")"
    local zip="$WORK_DIR/bundle.zip"
    local src="$WORK_DIR/src"

    download_bundle "$zip"
    unzip -q "$zip" -d "$src"

    local extracted
    extracted="$(find "$src" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    [[ -n "$extracted" ]] || die "downloaded archive contained no directory"
    [[ -f "$extracted/resources/views/templates/wrapper.blade.php" ]] || \
        die "bundle is missing wrapper.blade.php"
    [[ -f "$extracted/public/themes/$THEME_NAME/theme.css" ]] || \
        die "bundle is missing theme.css"

    printf '%s\n' "$extracted"
}

# ─── backup ───────────────────────────────────────────────────────────────────
backup_files() {
    local panel_dir="$1"
    local backup_dir="$2"

    sudo_run mkdir -p "$backup_dir"

    local wrapper="$panel_dir/resources/views/templates/wrapper.blade.php"
    if [[ -f "$wrapper" ]]; then
        sudo_run cp -a "$wrapper" "$backup_dir/wrapper.blade.php"
    fi
    if [[ -f "$panel_dir/tailwind.config.js" ]]; then
        sudo_run cp -a "$panel_dir/tailwind.config.js" "$backup_dir/tailwind.config.js"
    fi
    if [[ -d "$panel_dir/public/themes/$THEME_NAME" ]]; then
        sudo_run cp -a "$panel_dir/public/themes/$THEME_NAME" "$backup_dir/"
    fi
}

# ─── install ──────────────────────────────────────────────────────────────────
install_theme_files() {
    local source_dir="$1"
    local panel_dir="$2"

    log "installing wrapper template"
    sudo_run mkdir -p "$panel_dir/resources/views/templates"
    sudo_run cp -a \
        "$source_dir/resources/views/templates/wrapper.blade.php" \
        "$panel_dir/resources/views/templates/wrapper.blade.php"

    log "installing theme stylesheet"
    local theme_dir="$panel_dir/public/themes/$THEME_NAME"
    sudo_run mkdir -p "$theme_dir"
    sudo_run cp -a \
        "$source_dir/public/themes/$THEME_NAME/theme.css" \
        "$theme_dir/theme.css"

    if [[ -f "$source_dir/tailwind.config.js" ]]; then
        log "installing tailwind.config.js"
        sudo_run cp -a "$source_dir/tailwind.config.js" "$panel_dir/tailwind.config.js"
    fi
}

# ─── verification ─────────────────────────────────────────────────────────────
verify_install() {
    local panel_dir="$1"
    local wrapper="$panel_dir/resources/views/templates/wrapper.blade.php"
    local css="$panel_dir/public/themes/$THEME_NAME/theme.css"

    [[ -f "$wrapper" ]] || die "wrapper.blade.php missing after install"
    [[ -s "$wrapper" ]] || die "wrapper.blade.php is empty after install"
    [[ -f "$css"     ]] || die "theme.css missing after install"
    [[ -s "$css"     ]] || die "theme.css is empty after install"

    # Sanity: confirm the CSS file actually contains our token root block
    grep -q "\-\-sentri-primary" "$css" || die "theme.css does not contain expected CSS tokens"

    ok "installed files verified"
}

# ─── cache clearing ───────────────────────────────────────────────────────────

# 1. Run a single artisan command, tolerating any failure gracefully.
_artisan() {
    local panel_dir="$1"
    local cmd="$2"
    sudo_run php "$panel_dir/artisan" "$cmd" --no-interaction --ansi 2>&1 | \
        sed "s/^/    [artisan] /" >&2 || \
        warn "artisan $cmd returned non-zero (non-fatal)"
}

# 2. All artisan cache commands relevant to a theme change.
_artisan_clear_all() {
    local panel_dir="$1"
    log "clearing Laravel caches via artisan"
    _artisan "$panel_dir" view:clear
    _artisan "$panel_dir" route:clear
    _artisan "$panel_dir" config:clear
    _artisan "$panel_dir" cache:clear
    # event:clear added in Laravel 8 — tolerated if absent (artisan exits non-zero)
    _artisan "$panel_dir" event:clear
}

# 3. PHP-FPM opcache reload — most reliable way to evict in-memory compiled scripts.
_reload_phpfpm() {
    local reloaded=0

    # Try systemctl for each common php-fpm service name
    local svc
    for svc in php8.4-fpm php8.3-fpm php8.2-fpm php8.1-fpm php8.0-fpm php7.4-fpm php-fpm; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            if sudo_run systemctl reload "$svc" 2>/dev/null; then
                ok "reloaded $svc (opcache flushed)"
                reloaded=1
                break
            fi
        fi
    done

    # Fallback: send SIGUSR2 to any php-fpm master process (graceful reload)
    if [[ $reloaded -eq 0 ]]; then
        if quietly pkill -SIGUSR2 -x php-fpm; then
            ok "sent SIGUSR2 to php-fpm master (graceful reload)"
            reloaded=1
        fi
    fi

    # Fallback: service command for non-systemd hosts
    if [[ $reloaded -eq 0 ]]; then
        if quietly sudo_run service php-fpm reload 2>/dev/null; then
            ok "reloaded php-fpm via service command"
            reloaded=1
        fi
    fi

    [[ $reloaded -eq 0 ]] && warn "could not reload php-fpm; opcache may serve stale scripts until the next FPM restart"
}

# 4. Web server config reload (not restart — preserves live connections).
_reload_webserver() {
    local reloaded=0

    # nginx
    if systemctl is-active --quiet nginx 2>/dev/null; then
        if sudo_run systemctl reload nginx 2>/dev/null; then
            ok "reloaded nginx"
            reloaded=1
        fi
    elif quietly sudo_run nginx -t 2>/dev/null; then
        quietly sudo_run nginx -s reload
        ok "reloaded nginx (direct)"
        reloaded=1
    fi

    # Apache / httpd
    for apache_svc in apache2 httpd; do
        if systemctl is-active --quiet "$apache_svc" 2>/dev/null; then
            if sudo_run systemctl reload "$apache_svc" 2>/dev/null; then
                ok "reloaded $apache_svc"
                reloaded=1
            fi
            break
        fi
    done

    [[ $reloaded -eq 0 ]] && warn "no running web server detected; skip web server reload"
}

# 5. Supervisor queue workers (Pterodactyl uses pteroq:*).
_reload_supervisor() {
    if command -v supervisorctl >/dev/null 2>&1; then
        if quietly sudo_run supervisorctl reread 2>/dev/null && \
           quietly sudo_run supervisorctl update 2>/dev/null; then
            # Restart pteroq workers to pick up any config changes
            quietly sudo_run supervisorctl restart 'pteroq:*' 2>/dev/null
            ok "supervisor queue workers restarted"
        else
            warn "supervisorctl present but reload failed (non-fatal)"
        fi
    fi
}

# 6. Docker-hosted Pterodactyl panels.
_clear_docker_caches() {
    command -v docker >/dev/null 2>&1 || return 0

    local containers
    mapfile -t containers < <(
        docker ps --format '{{.Names}}' 2>/dev/null | \
        grep -E '^(pterodactyl|ptero|panel)' || true
    )

    if [[ ${#containers[@]} -eq 0 ]]; then
        # Broader fallback: any container whose image name matches
        mapfile -t containers < <(
            docker ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | \
            grep -iE 'pterodactyl|ptero.*panel' | awk '{print $1}' || true
        )
    fi

    for container in "${containers[@]}"; do
        log "clearing caches inside Docker container: $container"
        quietly docker exec "$container" php artisan view:clear
        quietly docker exec "$container" php artisan route:clear
        quietly docker exec "$container" php artisan config:clear
        quietly docker exec "$container" php artisan cache:clear
        ok "Docker container $container caches cleared"
    done
}

# Orchestrator: call every cache-clearing strategy in sequence.
clear_panel_cache() {
    local panel_dir="$1"
    log "beginning full cache eviction"

    if command -v php >/dev/null 2>&1; then
        _artisan_clear_all "$panel_dir"
    else
        warn "php not found on host; skipping artisan caches (run them inside your container)"
    fi

    _reload_phpfpm
    _reload_webserver
    _reload_supervisor
    _clear_docker_caches
}

# ─── permissions ─────────────────────────────────────────────────────────────
fix_permissions() {
    local panel_dir="$1"

    # Detect the web server's effective user; try common names in order.
    local web_user=""
    local candidate
    for candidate in www-data nginx apache caddy http nobody; do
        if id -u "$candidate" >/dev/null 2>&1; then
            web_user="$candidate"
            break
        fi
    done

    if [[ -n "$web_user" ]]; then
        sudo_run chown -R "$web_user:$web_user" \
            "$panel_dir/resources/views/templates/wrapper.blade.php" \
            "$panel_dir/public/themes/$THEME_NAME" 2>/dev/null || \
            warn "chown to $web_user returned non-zero (non-fatal)"
        ok "ownership set to $web_user"
    else
        warn "no known web-server user found; skipping chown (set manually if needed)"
    fi

    # Ensure public assets are world-readable.
    sudo_run chmod -R a+r "$panel_dir/public/themes/$THEME_NAME" 2>/dev/null || true
}

# ─── uninstall ───────────────────────────────────────────────────────────────
uninstall_theme() {
    local panel_dir="$1"
    local wrapper="$panel_dir/resources/views/templates/wrapper.blade.php"
    local theme_dir="$panel_dir/public/themes/$THEME_NAME"

    log "uninstalling Sentri theme from $panel_dir"

    # Restore from the most recent backup (backups sort correctly by date prefix).
    local latest_backup
    latest_backup="$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "sentri-theme-backup-*" \
        2>/dev/null | sort -r | head -n 1 || true)"

    if [[ -n "$latest_backup" && -f "$latest_backup/wrapper.blade.php" ]]; then
        log "restoring wrapper.blade.php from $latest_backup"
        sudo_run cp -a "$latest_backup/wrapper.blade.php" "$wrapper"
        [[ -f "$latest_backup/tailwind.config.js" ]] && \
            sudo_run cp -a "$latest_backup/tailwind.config.js" "$panel_dir/tailwind.config.js" || true
        ok "backup restored"
    else
        warn "no backup found; stripping Sentri link from existing wrapper"
        if [[ -f "$wrapper" ]]; then
            local tmp
            tmp="$(mktemp "${TMPDIR:-/tmp}/sentri-wrapper.XXXXXX")"
            grep -v "$THEME_NAME" "$wrapper" > "$tmp" || true
            sudo_run install -m 0644 "$tmp" "$wrapper"
            rm -f "$tmp"
        fi
    fi

    if [[ -d "$theme_dir" ]]; then
        log "removing theme directory: $theme_dir"
        sudo_run rm -rf "$theme_dir"
    fi

    clear_panel_cache "$panel_dir"
    ok "uninstall complete"
}

# ─── main ────────────────────────────────────────────────────────────────────
main() {
    need_cmd awk
    need_cmd cp
    need_cmd grep
    need_cmd mktemp

    # Re-execute as root if needed (works because the one-liner saves to a file first).
    if [[ "${EUID}" -ne 0 ]]; then
        log "requesting root privileges"
        exec sudo bash "$0" "$@"
    fi

    local action="install"
    local target_dir=""
    for arg in "$@"; do
        case "$arg" in
            --uninstall|-u) action="uninstall" ;;
            *)              target_dir="$arg"  ;;
        esac
    done

    local panel_dir
    panel_dir="$(detect_panel_dir "$target_dir")"
    log "panel: $panel_dir"

    if [[ "$action" == "uninstall" ]]; then
        uninstall_theme "$panel_dir"
        return
    fi

    local source_dir
    source_dir="$(resolve_source_dir)"

    local backup_dir="$BACKUP_ROOT/sentri-theme-backup-$(date +%Y%m%d-%H%M%S)"
    log "backup: $backup_dir"
    backup_files "$panel_dir" "$backup_dir"

    install_theme_files "$source_dir" "$panel_dir"
    verify_install       "$panel_dir"
    fix_permissions      "$panel_dir"
    clear_panel_cache    "$panel_dir"

    printf '\n'
    ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ok "Sentri theme installed successfully"
    printf '[sentri] ok      Panel:  %s\n' "$panel_dir"     >&2
    printf '[sentri] ok      Backup: %s\n' "$backup_dir"    >&2
    printf '[sentri] ok      Theme:  %s\n' "$THEME_NAME"    >&2
    ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf '\n'
    printf 'Hard-refresh your browser (Ctrl+Shift+R) to load the theme.\n'
    printf 'Optional: cd %s && yarn install && yarn build:production\n' "$panel_dir"
    printf '\n'
}

main "$@"
