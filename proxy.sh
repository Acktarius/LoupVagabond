#!/bin/bash

# Variables for customization
DEFAULT_BROWSER="librewolf"
START_URL="https://www.qwant.com/"
PROXY_COMMAND="proxychains4"

# Check for required dependencies
if ! command -v zenity &>/dev/null; then
    echo "Error: zenity is required but not installed. Please install it first." >&2
    echo "On Debian/Ubuntu: sudo apt install zenity" >&2
    echo "On Fedora: sudo dnf install zenity" >&2
    echo "On Arch: sudo pacman -S zenity" >&2
    exit 1
fi

# Function for displaying messages
show_message() {
    zenity --info --timeout=15 --width=400 --text="$1" 2>/dev/null
}

show_error() {
    zenity --error --timeout=15 --width=400 --text="$1" 2>/dev/null
}

show_warning() {
    zenity --warning --timeout=15 --width=400 --text="$1" 2>/dev/null
}

# Function to display notifications
show_notification() {
    local title="$1"
    local message="$2"
    
    # First try using notify-send but check if it actually works
    if command -v notify-send &>/dev/null; then
        # Test if notify-send works without symbol errors
        if notify-send --version &>/dev/null; then
            notify-send "$title" "$message" 2>/dev/null && return
        fi
    fi
    
    # If we get here, notify-send failed or doesn't work properly
    # Use zenity notification (we already checked it exists at script start)
    zenity --notification --text="$title: $message" 2>/dev/null
}

# Function to check for installed browsers
get_browser_choice() {
    # Initialize variables
    local browser_list=""
    local available_browsers=()
    
    # Check for common browsers - EXCLUDING Firefox and Tor Browser
    browsers=("librewolf" "firedragon" "chromium" "brave-browser")
    
    for browser in "${browsers[@]}"; do
        if command -v "$browser" &> /dev/null; then
            available_browsers+=("$browser")
            # Make librewolf (or DEFAULT_BROWSER) the default selection if available
            if [ "$browser" = "$DEFAULT_BROWSER" ]; then
                browser_list+="TRUE $browser "
            else
                browser_list+="FALSE $browser "
            fi
        fi
    done
    
    # If no browsers found
    if [ ${#available_browsers[@]} -eq 0 ]; then
        show_error "No supported browsers found. Please install at least one of: librewolf, chromium, brave-browser"
        exit 1
    fi
    
    # If only one browser is available, use it without asking
    if [ ${#available_browsers[@]} -eq 1 ]; then
        echo "${available_browsers[0]}"
        return
    fi
    
    # Ask user to select a browser
    selection=$(zenity --list --radiolist --title="Select Browser" \
                       --text="Choose which browser to use with Tor proxy:" \
                       --column="Select" --column="Browser" $browser_list \
                       --width=400 --height=300)
    
    if [ -z "$selection" ]; then
        # User cancelled - default to first available browser
        echo "${available_browsers[0]}"
    else
        echo "$selection"
    fi
}

# Choose browser
BROWSER=$(get_browser_choice)

# Check if browser is already running
if pgrep -x "$BROWSER" > /dev/null; then
    show_warning "$BROWSER is already running,\nyou have to exit first\nbefore running this anonymous instance."
    exit 1
fi

# Function to check if Tor is actually running and providing a SOCKS proxy
check_tor_status() {
    # First check if the systemd service is active
    if ! systemctl is-active --quiet tor.service; then
        return 1
    fi
    
    # Verify the SOCKS port is actually listening
    if command -v nc &> /dev/null; then
        if ! nc -z -w2 127.0.0.1 9050; then
            return 1
        fi
    elif command -v ss &> /dev/null; then
        if ! ss -nlt | grep -q "127.0.0.1:9050"; then
            return 1
        fi

    fi
    
    # All checks passed
    return 0
}

# Function to verify that proxychains is working correctly with Tor
verify_proxychains() {
    # Check if curl is installed
    if ! command -v curl &>/dev/null; then
        show_warning "curl not installed. Skipping proxychains verification."
        return 0
    fi
    
    # Try to get IP through proxychains
    local regular_ip=$(curl -s --max-time 10 https://ip.me)
    if [ -z "$regular_ip" ]; then
        show_warning "Could not determine your regular IP. Skipping verification."
        return 0
    fi
    
    # Get IP through proxychains
    echo "Testing Tor connection..." >&2
    local proxy_ip=$(proxychains4 curl -s --max-time 15 https://ip.me 2>/dev/null)
    
    # Check if we got a response
    if [ -z "$proxy_ip" ]; then
        show_error "proxychains doesn't seem to be working correctly.\nCould not get an IP address through Tor."
        return 1
    fi
    
    # Check if the IPs are different (indicating proxychains is working)
    if [ "$regular_ip" == "$proxy_ip" ]; then
        show_error "proxychains is not working correctly!\nYour real IP ($regular_ip) is leaking through Tor."
        return 1
    fi
    
    # Success - show notification with the Tor IP
    show_notification "Tor Connection" "Connected via Tor IP: $proxy_ip"
    return 0
}

# Set browser-specific proxy settings
configure_browser_for_privacy() {
    case "$BROWSER" in
        librewolf|firedragon)
            # Use a clean profile with minimal customization
            PROFILE_NAME="torproxy_$(date +%s)"
            $BROWSER --CreateProfile "$PROFILE_NAME" >/dev/null 2>&1
            sleep 1
            
            # Update the browser command to use this profile
            BROWSER="$BROWSER -P $PROFILE_NAME -no-remote"
            BROWSER_TYPE="mozilla"
            ;;
            
        brave-browser)
            # For Brave Browser, direct SOCKS proxy approach instead of proxychains
            DATA_DIR=$(mktemp -d /tmp/brave_proxy_XXXXXX)
            chmod 700 "$DATA_DIR"
            
            # Add direct SOCKS proxy settings
            BROWSER="brave-browser --incognito --proxy-server=socks5://127.0.0.1:9050 --user-data-dir=$DATA_DIR"
            BROWSER_TYPE="brave"
            ;;
            
        chromium)
            # For Chromium, use direct proxy settings
            DATA_DIR=$(mktemp -d /tmp/chrome_proxy_XXXXXX)
            chmod 700 "$DATA_DIR"
            
            BROWSER="$BROWSER --incognito --proxy-server=socks5://127.0.0.1:9050 --user-data-dir=$DATA_DIR"
            BROWSER_TYPE="chromium"
            ;;
            
        *)
            # For other browsers, we'll rely on proxychains alone
            show_warning "Unknown browser: $BROWSER\nWill rely solely on proxychains for anonymization."
            BROWSER_TYPE="unknown"
            ;;
    esac
}

# Check if Tor service is running and providing SOCKS proxy
if ! check_tor_status; then
    show_error "Tor service is not running.\n\nPlease open a Terminal window (Ctrl+Alt+T) and type:\n\nsudo systemctl start tor"
    exit 1
fi

# Verify proxychains is working correctly
if ! verify_proxychains; then
    show_error "ProxyChains is not working correctly. Please check your configuration."
    exit 1
fi

# Configure the browser with proxy settings
configure_browser_for_privacy

# Launch browser with proxy
show_notification "Anonymous Browsing" "Starting $BROWSER through Tor proxy"

# Launch browser in background and fully detach it based on browser type
if [ "$BROWSER_TYPE" = "brave" ]; then
    # For Brave, launch directly with its own proxy settings, no proxychains
    (
        echo "Launching Brave directly with proxy settings: $BROWSER"
        $BROWSER "$START_URL" >/dev/null 2>&1
    ) </dev/null >/dev/null 2>&1 &
    disown
else
    # Default launch for other browsers using proxychains
    (
        $PROXY_COMMAND $BROWSER "$START_URL" >/dev/null 2>&1
    ) </dev/null >/dev/null 2>&1 &
    disown
fi

# Ensure the script exits immediately
exit 0
