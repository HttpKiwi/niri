#!/bin/bash
#
# matugen-cache.sh - Cache manager for matugen outputs
#
# This script caches matugen-generated theme files per wallpaper to avoid
# regenerating them on every wallpaper change. This eliminates race conditions
# and makes wallpaper switching instant after the first generation.
#
# Usage: matugen-cache.sh <wallpaper_path> [--scheme-type TYPE] [--mode MODE] [--contrast VALUE]
#
# Options:
#   --scheme-type TYPE    Color scheme type (default: scheme-tonal-spot)
#   --mode MODE           Color mode: dark or light (default: dark)
#   --contrast VALUE      Contrast level from -1 to 1 (default: 0)
#

set -euo pipefail

# Default matugen options
SCHEME_TYPE="scheme-tonal-spot"
COLOR_MODE="dark"
CONTRAST="0"

# Configuration
WALLPAPER_DIR="${WALLPAPER_DIR:-${HOME}/Pictures/Wallpapers}"
CACHE_ROOT="$WALLPAPER_DIR/.matugen_cache"
CONFIG_HOME="${HOME}/.config"

# Files to cache (source -> cache_filename)
# Format: "source_path:cache_filename"
declare -A CACHE_FILES=(
    # Quickshell (main)
    ["${CONFIG_HOME}/quickshell/common/Colors.json"]="Colors.json"

    # GTK
    ["${CONFIG_HOME}/gtk-3.0/gtk.css"]="gtk3.css"
    ["${CONFIG_HOME}/gtk-4.0/gtk.css"]="gtk4.css"
    ["${HOME}/.cache/matugen/gradience.json"]="gradience.json"

    # Qt
    ["${CONFIG_HOME}/qt5ct/colors/matugen.conf"]="qt5ct.conf"
    ["${CONFIG_HOME}/qt6ct/colors/matugen.conf"]="qt6ct.conf"
    ["${CONFIG_HOME}/Kvantum/MaterialAdw/MaterialAdw.kvconfig"]="kvantum.kvconfig"
    ["${CONFIG_HOME}/Kvantum/MaterialAdw/MaterialAdw.svg"]="kvantum.svg"

    # Terminals
    ["${HOME}/.cache/ags/user/generated/kitty-colors.conf"]="kitty-colors.conf"

    # Apps
    ["${CONFIG_HOME}/equibop/themes/HyprLuna.css"]="equibop.css"
    ["${CONFIG_HOME}/vesktop/themes/HyprLuna.css"]="vesktop.css"
    ["${HOME}/.cache/wal/colors.json"]="pywalfox-colors.json"
    ["${CONFIG_HOME}/fuzzel/colors.ini"]="fuzzel.ini"
    ["${HOME}/.vscode/extensions/hyprluna.hyprluna-theme-1.0.2/themes/hyprluna.json"]="vscode-hyprluna.json"
)

# Logging functions
log() {
    echo "[matugen-cache] $*" >&2
}

error() {
    echo "[matugen-cache] ERROR: $*" >&2
    exit 1
}

# Get cache directory for a specific wallpaper with scheme and mode
get_cache_dir() {
    local wallpaper_path="$1"
    local filename
    filename=$(basename "$wallpaper_path")
    # Nested cache: .matugen_cache/scheme-type/mode/wallpaper.jpg/
    echo "$CACHE_ROOT/$SCHEME_TYPE/$COLOR_MODE/$filename"
}

# Outputs that must be present for a cache to be considered complete.
# Optional targets (vesktop, vscode, …) are skipped when matugen didn't produce them.
REQUIRED_CACHE_FILES=(
    "Colors.json"
    "equibop.css"
)

# Check if cache exists and is valid
cache_exists() {
    local cache_dir="$1"

    for required in "${REQUIRED_CACHE_FILES[@]}"; do
        if [ ! -f "$cache_dir/$required" ]; then
            log "Cache incomplete (missing $required), will regenerate"
            return 1
        fi
    done

    # Invalidate when matugen templates change (Discord/Equibop, etc.)
    # Templates under ~/.config/matugen/templates are often symlinks into the
    # stow repo — find -type f skips those, so we must follow links (-L).
    local templates_dir="${CONFIG_HOME}/matugen/templates"
    local fingerprint_file="$cache_dir/.templates.sha256"
    local current_fp=""
    if [ -d "$templates_dir" ]; then
        current_fp=$(find -L "$templates_dir" -type f -print0 2>/dev/null | sort -z | xargs -0 -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
    fi
    if [ -z "$current_fp" ]; then
        log "Could not fingerprint matugen templates, will regenerate"
        return 1
    fi
    local cached_fp=""
    if [ -f "$fingerprint_file" ]; then
        cached_fp=$(cat "$fingerprint_file")
    else
        log "Cache missing template fingerprint, will regenerate"
        return 1
    fi
    if [ "$current_fp" != "$cached_fp" ]; then
        log "Matugen templates changed, will regenerate"
        return 1
    fi

    return 0
}

# Resolve matugen input — videos need a still frame (matugen only accepts images)
resolve_matugen_source() {
    local wallpaper_path="$1"
    local lower
    lower=$(printf '%s' "$wallpaper_path" | tr '[:upper:]' '[:lower:]')

    case "$lower" in
        *.mp4|*.webm|*.mkv|*.mov|*.avi|*.flv|*.m4v)
            local poster_dir="$WALLPAPER_DIR/.posters"
            local base
            base=$(basename "$wallpaper_path")
            local poster="$poster_dir/${base}.jpg"
            mkdir -p "$poster_dir"
            if [ ! -f "$poster" ] || [ "$wallpaper_path" -nt "$poster" ]; then
                log "Extracting poster frame for video: $base"
                if ! command -v ffmpeg >/dev/null 2>&1; then
                    error "ffmpeg required for video wallpapers (not found in PATH)"
                fi
                ffmpeg -hide_banner -loglevel error -y -ss 0 -i "$wallpaper_path" \
                    -frames:v 1 -q:v 2 "$poster" \
                    || error "Failed to extract poster from: $wallpaper_path"
            else
                log "Using cached poster: $poster"
            fi
            printf '%s' "$poster"
            ;;
        *)
            printf '%s' "$wallpaper_path"
            ;;
    esac
}

# Generate cache by running matugen and copying outputs
generate_cache() {
    local wallpaper_path="$1"
    local cache_dir="$2"
    local matugen_source
    matugen_source=$(resolve_matugen_source "$wallpaper_path")

    log "Generating cache for: $(basename "$wallpaper_path")"
    if [ "$matugen_source" != "$wallpaper_path" ]; then
        log "  matugen source: $(basename "$matugen_source")"
    fi

    # Create cache directory
    mkdir -p "$cache_dir"

    # Run matugen to generate all theme files
    log "Running matugen with scheme=$SCHEME_TYPE, mode=$COLOR_MODE, contrast=$CONTRAST"
    # Note: We allow matugen to fail on post-hooks (like kitty reload) as long as files are generated
    matugen image "$matugen_source" -t "$SCHEME_TYPE" -m "$COLOR_MODE" --contrast "$CONTRAST" --prefer darkness 2>&1 | while read -r line; do
        log "  matugen: $line"
    done || true

    # Verify that at least the main Colors.json was generated
    if [ ! -f "${CONFIG_HOME}/quickshell/common/Colors.json" ]; then
        error "matugen failed to generate Colors.json for: $wallpaper_path"
    fi

    log "Caching generated files..."

    # Copy generated files to cache
    local cached_count=0
    for source_path in "${!CACHE_FILES[@]}"; do
        local cache_filename="${CACHE_FILES[$source_path]}"

        if [ -f "$source_path" ]; then
            cp "$source_path" "$cache_dir/$cache_filename"
            cached_count=$((cached_count + 1))
            log "  Cached: $cache_filename"
        else
            log "  Skipped (not found): $source_path"
        fi
    done

    log "Cache generated successfully ($cached_count files cached)"

    # Fingerprint templates so edits (e.g. discord.css) invalidate this cache later
    # Follow symlinks — stow installs templates as links into the repo
    local templates_dir="${CONFIG_HOME}/matugen/templates"
    if [ -d "$templates_dir" ]; then
        find -L "$templates_dir" -type f -print0 2>/dev/null | sort -z | xargs -0 -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}' > "$cache_dir/.templates.sha256"
    fi

    run_post_hooks
}

# Apply cached files to their destinations
apply_cache() {
    local cache_dir="$1"

    log "Applying cached files from: $(basename "$cache_dir")"

    local applied_count=0
    for source_path in "${!CACHE_FILES[@]}"; do
        local cache_filename="${CACHE_FILES[$source_path]}"
        local cached_file="$cache_dir/$cache_filename"

        if [ -f "$cached_file" ]; then
            # Ensure destination directory exists
            mkdir -p "$(dirname "$source_path")"

            # Remove symlink if it exists
            if [ -L "$source_path" ]; then
                rm "$source_path"
            fi

            # Use atomic write (copy to temp, then move) to reliably trigger file watchers
            local temp_file="${source_path}.tmp.$$"
            if cp "$cached_file" "$temp_file" 2>/dev/null; then
                if mv -f "$temp_file" "$source_path" 2>/dev/null; then
                    applied_count=$((applied_count + 1))
                else
                    log "  Warning: Could not move temp file to $source_path (skipping)"
                    rm -f "$temp_file"
                fi
            else
                log "  Warning: Could not write to temp file for $source_path (skipping)"
            fi
        fi
    done

    log "Applied $applied_count cached files"

    # Run post-hooks for apps that need reload signals
    run_post_hooks
}

# Run post-hooks to reload applications
run_post_hooks() {
    log "Running post-hooks..."

    # Gradience - Apply Material 3 theme to GTK4/libadwaita apps
    if command -v gradience-cli &> /dev/null; then
        local gradience_file="${HOME}/.cache/matugen/gradience.json"
        if [ -f "$gradience_file" ]; then
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
            export DBUS_SESSION_BUS_ADDRESS

            # PYTHONPATH workaround for python 3.13→3.14 upgrade
            PYTHONPATH=/usr/lib/python3.13/site-packages gradience-cli apply -p "$gradience_file" --gtk both 2>/dev/null || true
            log "  Gradience theme applied"
        fi
    fi

    # GTK theme reload - force re-read by toggling theme
    if command -v gsettings &> /dev/null; then
        DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
        export DBUS_SESSION_BUS_ADDRESS

        gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
        sleep 0.1
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-${COLOR_MODE}" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "prefer-${COLOR_MODE}" 2>/dev/null || true
        log "  GTK theme reloaded"
    fi

    # Zen Browser theme - portal handles it dynamically, don't override in user.js
    local zen_profile="${HOME}/.zen/yak8abkd.Default (release)"
    if [ -d "$zen_profile" ]; then
        local zen_user_js="${zen_profile}/user.js"
        local zen_prefs_js="${zen_profile}/prefs.js"

        if grep -q 'user_pref("ui.systemUsesDarkTheme"' "$zen_prefs_js" 2>/dev/null; then
            sed -i '/user_pref("ui.systemUsesDarkTheme"/d' "$zen_prefs_js" 2>/dev/null || true
            log "  Removed stale ui.systemUsesDarkTheme from prefs.js"
        fi

        : > "$zen_user_js"  # Empty user.js
        log "  Zen user.js cleared (portal handles theme)"
    fi

    # Kitty reload - use socket-based remote control
    if pgrep -x kitty > /dev/null 2>&1; then
        local kitty_reloaded=false
        for socket in /run/user/$(id -u)/kitty*; do
            if [ -S "$socket" ]; then
                if kitty @ --to "unix:$socket" load-config 2>/dev/null; then
                    log "  Kitty reloaded via $socket"
                    kitty_reloaded=true
                fi
            fi
        done
        if ! $kitty_reloaded; then
            pkill -SIGUSR1 kitty 2>/dev/null || true
            log "  Kitty reload signal sent (SIGUSR1)"
        fi
    fi

    # Fuzzel — reload colors after theme file update
    if pgrep -x fuzzel > /dev/null 2>&1; then
        pkill -SIGUSR1 fuzzel 2>/dev/null || true
        log "  Fuzzel reload signal sent (SIGUSR1)"
    fi

    log "Post-hooks completed"
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        error "Usage: $0 <wallpaper_path> [--scheme-type TYPE] [--mode MODE] [--contrast VALUE]"
    fi

    local wallpaper_path="$1"
    shift

    # Parse optional arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --scheme-type)
                SCHEME_TYPE="$2"
                shift 2
                ;;
            --mode)
                COLOR_MODE="$2"
                shift 2
                ;;
            --contrast)
                CONTRAST="$2"
                shift 2
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done

    # Validate wallpaper path
    if [ ! -f "$wallpaper_path" ]; then
        error "Wallpaper not found: $wallpaper_path"
    fi

    local cache_dir
    cache_dir=$(get_cache_dir "$wallpaper_path")

    # Check if cache exists
    if cache_exists "$cache_dir"; then
        log "Using cached colors for: $(basename "$wallpaper_path")"
        apply_cache "$cache_dir"
    else
        log "No cache found, generating..."
        generate_cache "$wallpaper_path" "$cache_dir"
    fi

    log "Done"
}

# Run main function
main "$@"
