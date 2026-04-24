#!/bin/bash
set -e

echo "================================================"
echo "VLSub Bazarr+ Installer"
echo "================================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Download source: raw file on the fork's default branch.
# Works before any GitHub release is published.
RAW_SOURCE_URL="${VLSUB_BAZARR_PLUS_URL:-https://raw.githubusercontent.com/LavX/vlsub-bazarr-plus/main/vlsubcom.lua}"

# Paths to install into, populated by detect_platform / detect_linux_targets.
# Format: "label|absolute_path"
TARGETS=()

# Check if curl is available
if ! command -v curl &> /dev/null; then
    printf "${RED}Error: curl is required but not installed.${NC}\n"
    echo "Please install curl and try again."
    echo ""
    echo "Install curl:"
    echo "  macOS: brew install curl (or use built-in)"
    echo "  Ubuntu/Debian: sudo apt install curl"
    echo "  Fedora: sudo dnf install curl"
    echo "  Arch: sudo pacman -S curl"
    exit 1
fi

# Detect each VLC flavor installed on Linux and queue the matching extensions dir.
# Covers native packages, Flatpak (org.videolan.VLC), and Snap (vlc).
detect_linux_targets() {
    local found_any=0

    if command -v vlc &> /dev/null; then
        TARGETS+=("Native (vlc on PATH)|$HOME/.local/share/vlc/lua/extensions")
        found_any=1
    fi

    if command -v flatpak &> /dev/null \
       && flatpak list --app --columns=application 2>/dev/null \
          | grep -qix "org.videolan.VLC"; then
        TARGETS+=("Flatpak (org.videolan.VLC)|$HOME/.var/app/org.videolan.VLC/data/vlc/lua/extensions")
        found_any=1
    fi

    if command -v snap &> /dev/null \
       && snap list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "vlc"; then
        TARGETS+=("Snap (vlc)|$HOME/snap/vlc/current/.local/share/vlc/lua/extensions")
        found_any=1
    fi

    if [ "$found_any" -eq 0 ]; then
        printf "${YELLOW}⚠ No VLC install detected (vlc/flatpak/snap all absent).${NC}\n"
        echo "Falling back to the standard per-user dir; VLC will pick it up if you"
        echo "install it later via your distro's package manager."
        TARGETS+=("Native (fallback)|$HOME/.local/share/vlc/lua/extensions")
    fi
}

# Detect platform and set installation target(s).
detect_platform() {
    case "$OSTYPE" in
        darwin*)
            PLATFORM="macOS"
            TARGETS+=("macOS|$HOME/Library/Application Support/org.videolan.vlc/lua/extensions")
            ;;
        linux-gnu*|linux-musl*)
            PLATFORM="Linux"
            detect_linux_targets
            ;;
        msys|cygwin|win*)
            PLATFORM="Windows"
            if [ -n "$APPDATA" ]; then
                TARGETS+=("Windows|$APPDATA/vlc/lua/extensions")
            else
                printf "${RED}Error: Cannot detect VLC extensions directory on Windows.${NC}\n"
                echo "Please install manually by copying vlsubcom.lua to:"
                echo "%APPDATA%\\vlc\\lua\\extensions\\"
                exit 1
            fi
            ;;
        *)
            printf "${RED}Error: Unsupported platform: $OSTYPE${NC}\n"
            echo "Supported platforms: macOS, Linux, Windows (Git Bash/WSL)"
            echo ""
            echo "For manual installation, copy vlsubcom.lua to your VLC extensions directory:"
            echo "  Windows:       %APPDATA%\\vlc\\lua\\extensions\\"
            echo "  macOS:         ~/Library/Application Support/org.videolan.vlc/lua/extensions/"
            echo "  Linux native:  ~/.local/share/vlc/lua/extensions/"
            echo "  Linux flatpak: ~/.var/app/org.videolan.VLC/data/vlc/lua/extensions/"
            echo "  Linux snap:    ~/snap/vlc/current/.local/share/vlc/lua/extensions/"
            exit 1
            ;;
    esac
}

# Summarize detected targets before doing anything destructive.
print_targets() {
    printf "${BLUE}VLC install target(s):${NC}\n"
    local t
    for t in "${TARGETS[@]}"; do
        local label="${t%%|*}"
        local path="${t#*|}"
        printf "  • %s\n    %s\n" "$label" "$path"
    done
}

# Check if VLC is reachable for the given platform (informational).
check_vlc() {
    echo "Checking for VLC installation..."
    case "$PLATFORM" in
        "macOS")
            if [ -d "/Applications/VLC.app" ] || command -v vlc &> /dev/null; then
                printf "${GREEN}✓ VLC found${NC}\n"
            else
                printf "${YELLOW}⚠ VLC not found.${NC}\n"
                echo "Download VLC: https://www.videolan.org/vlc/download-macosx.html"
                read -p "Continue installation anyway? (y/N): " -n 1 -r < /dev/tty || REPLY=""
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            fi
            ;;
        "Linux")
            # detect_linux_targets already printed a warning if nothing was found.
            printf "${GREEN}✓ Proceeding with %d target(s)${NC}\n" "${#TARGETS[@]}"
            ;;
        "Windows")
            echo "Please ensure VLC is installed from https://www.videolan.org/"
            ;;
    esac
}

# Download the extension once into a temp file, then fan it out to all targets.
download_to_temp() {
    TEMP_FILE="$(mktemp)"
    echo "Downloading VLSub Bazarr+..."
    printf "${BLUE}From: $RAW_SOURCE_URL${NC}\n"

    if curl -L -f -o "$TEMP_FILE" "$RAW_SOURCE_URL" --progress-bar; then
        printf "${GREEN}✓ Download successful${NC}\n"
    else
        printf "${RED}✗ Download failed${NC}\n"
        echo "Please check your internet connection and try again."
        echo "Or download manually from: https://github.com/LavX/vlsub-bazarr-plus"
        rm -f "$TEMP_FILE"
        exit 1
    fi
}

# Install the downloaded temp file into every target dir, with per-target backup.
install_to_targets() {
    local t
    for t in "${TARGETS[@]}"; do
        local label="${t%%|*}"
        local dir="${t#*|}"
        local dest="$dir/vlsubcom.lua"

        echo
        printf "${BLUE}→ %s${NC}\n" "$label"
        printf "  dir: %s\n" "$dir"

        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            printf "  ${GREEN}✓ Directory created${NC}\n"
        fi

        if [ -f "$dest" ]; then
            local backup="$dest.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$dest" "$backup"
            printf "  ${GREEN}✓ Backup: %s${NC}\n" "$(basename "$backup")"
        fi

        cp "$TEMP_FILE" "$dest"
        if [ "$PLATFORM" != "Windows" ]; then
            chmod 644 "$dest"
        fi
        printf "  ${GREEN}✓ Installed${NC}\n"
    done

    rm -f "$TEMP_FILE"
}

# Show completion message
show_completion() {
    echo
    echo "================================================"
    printf "${GREEN}🎉 Installation Complete!${NC}\n"
    echo "================================================"
    echo
    printf "${BLUE}📁 Installed to:${NC}\n"
    local t
    for t in "${TARGETS[@]}"; do
        local label="${t%%|*}"
        local dir="${t#*|}"
        printf "  ${YELLOW}%s${NC}\n    %s/vlsubcom.lua\n" "$label" "$dir"
    done
    echo
    printf "${YELLOW}Next steps:${NC}\n"
    printf "1. ${BLUE}Restart VLC Media Player${NC}\n"
    printf "   • Native:  run ${YELLOW}vlc${NC}\n"
    printf "   • Flatpak: run ${YELLOW}flatpak run org.videolan.VLC${NC}\n"
    printf "   • Snap:    run ${YELLOW}snap run vlc${NC}\n"
    printf "2. ${BLUE}Go to View → VLSub Bazarr+${NC}\n"
    printf "3. ${BLUE}Open Config and set Bazarr+ Base URL + API Key${NC}\n"
    printf "   ${GREEN}(Base URL example: http://your-bazarr-host:6767)${NC}\n"
    echo
    printf "${YELLOW}Support & Documentation:${NC}\n"
    printf "• ${BLUE}Issues:${NC} https://github.com/LavX/vlsub-bazarr-plus/issues\n"
    printf "• ${BLUE}Repo:${NC}   https://github.com/LavX/vlsub-bazarr-plus\n"
    echo
    printf "${BLUE}💡 To uninstall:${NC} delete vlsubcom.lua from any path above\n"
    echo
}

# Main installation process
main() {
    printf "${BLUE}Platform detection...${NC}\n"
    detect_platform
    printf "${GREEN}Platform: $PLATFORM${NC}\n"
    echo

    print_targets
    echo

    check_vlc
    echo

    download_to_temp
    install_to_targets

    show_completion
}

main "$@"
