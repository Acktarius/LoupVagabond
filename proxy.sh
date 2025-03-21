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
    
    # Check for common browsers
    browsers=("librewolf" "firedragon" "firefox" "firefox-esr" "chromium" "brave-browser" "tor-browser")
    
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
        show_error "No supported browsers found. Please install at least one of: librewolf, firefox, tor-browser"
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

# Check if Tor service is running
if ! systemctl is-active --quiet tor.service; then
    show_error "Tor service is not running.\n\nTrying to start it automatically..."
    
    # Try to start Tor service
    if pkexec systemctl start tor.service; then
        show_message "Tor service successfully started!"
    else
        show_error "Failed to start Tor service.\n\nPlease open a Terminal window (Ctrl+Alt+T) and type:\n\n<b>sudo systemctl start tor</b>"
        exit 1
    fi
fi

# Check if Tor is properly configured and accessible
if ! command -v nc &> /dev/null; then
    # If netcat is not available, skip this check
    show_warning "Network connectivity tool (nc) not found. Skipping Tor connectivity check."
else
    if ! nc -z -w5 127.0.0.1 9050; then
        show_error "Cannot connect to Tor at 127.0.0.1:9050\nPlease check your Tor configuration."
        exit 1
    fi
fi

# Launch browser with proxy
# Launch browser in background and fully detach it
(
    $PROXY_COMMAND $BROWSER "$START_URL" >/dev/null 2>&1
) </dev/null >/dev/null 2>&1 &
disown

# Display notification
show_notification "Anonymous Browsing" "Started $BROWSER through Tor proxy"

# Ensure the script exits immediately
exit 0
