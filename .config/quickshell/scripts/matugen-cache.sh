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
WALLPAPER_DIR="/home/httpkiwi/Pictures/Wallpapers"
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
    ["${CONFIG_HOME}/vesktop/themes/HyprLuna.css"]="vesktop.css"
    ["${HOME}/.cache/wal/colors.json"]="pywalfox-colors.json"
    ["${CONFIG_HOME}/fuzzel/colors.ini"]="fuzzel.ini"
    ["${HOME}/.zen/yak8abkd.Default (release)/chrome/userChrome.css"]="zen-userChrome.css"
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

# Check if cache exists and is valid
cache_exists() {
    local cache_dir="$1"

    # Check if the main Colors.json exists in cache
    [ -f "$cache_dir/Colors.json" ]
}

# Generate cache by running matugen and copying outputs
generate_cache() {
    local wallpaper_path="$1"
    local cache_dir="$2"

    log "Generating cache for: $(basename "$wallpaper_path")"

    # Create cache directory
    mkdir -p "$cache_dir"

    # Run matugen to generate all theme files
    log "Running matugen with scheme=$SCHEME_TYPE, mode=$COLOR_MODE, contrast=$CONTRAST"
    # Note: We allow matugen to fail on post-hooks (like kitty reload) as long as files are generated
    matugen image "$wallpaper_path" -t "$SCHEME_TYPE" -m "$COLOR_MODE" --contrast "$CONTRAST" 2>&1 | while read -r line; do
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

            gradience-cli apply -p "$gradience_file" --gtk both 2>/dev/null || true
            log "  Gradience theme applied"

            # Restart Nautilus to apply theme changes
            if pgrep -x nautilus > /dev/null 2>&1; then
                killall nautilus 2>/dev/null || true
                log "  Nautilus restarted for theme update"
            fi
        fi
    fi

    # GTK theme reload - force re-read by toggling theme
    if command -v gsettings &> /dev/null; then
        DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
        export DBUS_SESSION_BUS_ADDRESS

        gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
        sleep 0.1
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-${COLOR_MODE}" 2>/dev/null || true
        log "  GTK theme reloaded"
    fi

    # Kitty reload - use socket-based remote control
    if pgrep -x kitty > /dev/null 2>&1; then
        # Try to find kitty socket and reload via remote control
        for socket in /tmp/kitty-*.sock /run/user/$(id -u)/kitty-*.sock; do
            if [ -S "$socket" ]; then
                kitty @ --to "unix:$socket" load-config 2>/dev/null && log "  Kitty reloaded via $socket" && break
            fi
        done
        # Fallback: send SIGUSR1 signal
        pkill -SIGUSR1 kitty 2>/dev/null || true
        log "  Kitty reload signal sent"
    fi

    # Zen browser - touch chrome directory to trigger userChrome.css reload
    # Zen/Firefox watches the chrome directory for changes
    if pgrep -i "zen" > /dev/null 2>&1; then
        local zen_chrome="${HOME}/.zen/yak8abkd.Default (release)/chrome"
        if [ -d "$zen_chrome" ]; then
            # Touch chrome directory to trigger reload
            touch "$zen_chrome"
            # Also touch userChrome.css specifically
            [ -f "$zen_chrome/userChrome.css" ] && touch "$zen_chrome/userChrome.css"
            log "  Zen browser chrome directory touched for reload"
        fi
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
