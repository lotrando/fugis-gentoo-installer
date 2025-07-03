#!/bin/bash

# FUGIS Waybar Configuration Generator
# Automatically generates Waybar configuration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} ✓ $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} ⚠ $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} ✗ $1"
}

# Detect system info
detect_system_info() {
    log_info "Detecting system information for Waybar..."

    USERNAME=$(whoami)
    HOME_DIR="$HOME"

    # Check if battery exists
    if [ -d "/sys/class/power_supply/BAT0" ] || [ -d "/sys/class/power_supply/BAT1" ]; then
        HAS_BATTERY=true
    else
        HAS_BATTERY=false
    fi

    # Check network interfaces
    NETWORK_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

    log_info "User: $USERNAME"
    log_info "Battery detected: $HAS_BATTERY"
    log_info "Network interface: $NETWORK_INTERFACE"
}

# Create Waybar configuration
create_waybar_config() {
    local waybar_dir="$HOME_DIR/.config/waybar"
    local config_file="$waybar_dir/config"
    local style_file="$waybar_dir/style.css"

    log_info "Creating Waybar configuration directory..."
    mkdir -p "$waybar_dir"

    log_info "Generating Waybar config.json..."

    # Create modules list based on system capabilities
    local modules_right="[\"network\", \"pulseaudio\", \"disk\", \"cpu\", \"memory\", \"temperature\""

    if [ "$HAS_BATTERY" = true ]; then
        modules_right="$modules_right, \"battery\""
    fi

    modules_right="$modules_right, \"clock\", \"tray\"]"

    cat > "$config_file" << EOF
{
    "layer": "top",
    "position": "top",
    "height": 24,
    "spacing": 2,
    "margin-top": 4,
    "margin-left": 4,
    "margin-right": 4,
    "modules-left": ["hyprland/workspaces", "hyprland/mode", "hyprland/window"],
    "modules-center": [],
    "modules-right": $modules_right,

    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "persistent_workspaces": {
            "*": 5
        },
        "format-icons": {
            "1": "󰲠",
            "2": "󰲢",
            "3": "󰲤",
            "4": "󰲦",
            "5": "󰲨",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },

    "hyprland/mode": {
        "format": "<span style=\"italic\">{}</span>"
    },

    "hyprland/window": {
        "format": "{}",
        "max-length": 50,
        "separate-outputs": true
    },

    "tray": {
        "icon-size": 18,
        "spacing": 5
    },

    "clock": {
	    "timezone": "Europe/Prague",
        "tooltip-format": "<span size='10pt'>{calendar}</span>",
        "format": " {:%H:%M:%S}",
        "format-alt": " {:%d.%m.%Y}",
        "interval": 1,
        "calendar": {
            "mode": "month",
            "mode-mon-col": 3,
            "weeks-pos": "left",
            "on-scroll": 1,
            "on-click-right": "mode",
            "format": {
                "months": "<span color='#ffffff'><b>{}</b></span>",
                "days": "<span color='#abb2bf'><b>{}</b></span>",
                "weeks": "<span color='#0087bd'><b>T{}</b></span>",
                "weekdays": "<span color='#d19a66'><b>{}</b></span>",
                "today": "<span color='#e06c75'><b>{}</b></span>"
            }
        },
    },

    "disk": {
        "interval": 30,
        "format": "󰋊 HDD:{free}",
        "unit": "GB"
    },

    "cpu": {
        "format": " CPU:{usage}%",
        "tooltip": false,
        "interval": 1,
        "format-alt-click": "click",
        "format-alt": " {icon0}{icon1}{icon2}{icon3}{icon4}{icon5}",
        "format-icons": [
            "▁",
            "▂",
            "▃",
            "▄",
            "▅",
            "▆",
            "▇",
            "█"
        ],
    },

    "memory": {
        "format": "󰍛 RAM:{}% ",
        "tooltip-format": "Memory: {used:0.1f}G/{total:0.1f}G",
        "on-click": "kitty -e btop"
    },

    "temperature": {
        "thermal-zone": 2,
        "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
        "critical-threshold": 80,
        "format-critical": " CPU:{temperatureC}°C",
        "format": " CPU:{temperatureC}°C",
        "format-icons": ["", "", "", "", ""],
        "tooltip": true
    },
EOF

    # Add battery section only if battery is detected
    if [ "$HAS_BATTERY" = true ]; then
        cat >> "$config_file" << EOF

    "battery": {
        "states": {
            "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% 󰂄",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        "format-full": "100% ",
        "format-icons": ["", "", "", "", ""],
        "tooltip-format": "{timeTo}, {capacity}%"
    },
EOF
    fi

    cat >> "$config_file" << EOF

    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "󰈀 {ipaddr}/{cidr}",
        "tooltip-format": "{ifname} via {gwaddr}",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}",
        "on-click-right": "nm-connection-editor"
    },

    "pulseaudio": {
        "format": "{icon} {volume}% {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": " {volume}%",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": [
                "",
                "",
                ""
            ]
        },
        "on-click": "pavucontrol",
        "on-click-right": "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    }
}
EOF

    log_info "Generating Waybar style.css..."

    cat > "$style_file" << EOF
/* FUGIS Generated Waybar Style */
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrains Mono Nerd Font", "Font Awesome 6 Free", monospace;
    font-size: 17px;
    font-weight: bold;
    min-height: 0;
}

window#waybar {
    background-color: rgba(30, 30, 46, 0.5);
    border-radius: 5px;
    color: #cdd6f4;
    padding: 4px;
    transition-property: background-color;
    transition-duration: 0.5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

/* Workspaces */
#workspaces {
    background: rgba(49, 50, 68, 0.8);
    border-radius: 5px;
    margin: 4px;
    padding: 2px 8px;
}

#workspaces button {
    padding: 0 8px;
    background-color: transparent;
    color: #6c7086;
    border-radius: 6px;
    transition: all 0.3s ease-in-out;
}
#workspaces button:hover {
    background: rgba(116, 199, 236, 0.3);
    color: #74c7ec;
}

#workspaces button.active {
    background: #74c7ec;
    color: #1e1e2e;
}

#workspaces button.urgent {
    background: #f38ba8;
    color: #1e1e2e;
}

/* Window title */
#window {
    background: rgba(49, 50, 68, 0.8);
    border-radius: 5px;
    margin: 4px;
    padding: 0 12px;
    color: #cdd6f4;
}

/* Mode */
#mode {
    background: #f9e2af;
    color: #1e1e2e;
    border-radius: 8px;
    margin: 4px;
    padding: 0 12px;
}

/* Right modules */
#clock,
#battery,
#cpu,
#disk,
#memory,
#temperature,
#network,
#pulseaudio,
#tray {
    background: rgba(49, 50, 68, 0.8);
    border-radius: 5px;
    margin: 4px;
    padding: 0 8px;
    color: #cdd6f4;
}

/* Individual module colors */
#clock {
    background: rgba(137, 180, 250, 0.8);
    color: #1e1e2e;
}

#battery {
    background: rgba(166, 227, 161, 0.8);
    color: #1e1e2e;
}

#battery.charging {
    background: rgba(249, 226, 175, 0.8);
    color: #1e1e2e;
}

#battery.warning:not(.charging) {
    background: rgba(250, 179, 135, 0.8);
    color: #1e1e2e;
}

#battery.critical:not(.charging) {
    background: rgba(243, 139, 168, 0.8);
    color: #1e1e2e;
    animation: blink 0.5s linear infinite alternate;
}

@keyframes blink {
    to {
        background-color: rgba(243, 139, 168, 1);
    }
}

#cpu {
    background: rgba(203, 166, 247, 0.8);
    color: #1e1e2e;
}

#disk {
    background: rgba(255, 100, 200, 0.8);
    color: #1e1e2e;
}

#memory {
    background: rgba(245, 194, 231, 0.8);
    color: #1e1e2e;
}

#temperature {
    background: rgba(250, 179, 135, 0.8);
    color: #1e1e2e;
}

#temperature.critical {
    background: rgba(243, 139, 168, 0.8);
    color: #1e1e2e;
}

#network {
    background: rgba(116, 199, 236, 0.8);
    color: #1e1e2e;
}

#network.disconnected {
    background: rgba(243, 139, 168, 0.8);
    color: #1e1e2e;
}

#pulseaudio {
    background: rgba(148, 226, 213, 0.8);
    color: #1e1e2e;
}

#pulseaudio.muted {
    background: rgba(108, 112, 134, 0.8);
    color: #cdd6f4;
}

#tray {
    background: rgba(49, 50, 68, 0.8);
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: rgba(243, 139, 168, 0.8);
}

/* Tooltips */
tooltip {
    background: rgba(30, 30, 46, 0.95);
    border: 1px solid rgba(116, 199, 236, 0.5);
    border-radius: 5px;
    color: #cdd6f4;
}

tooltip label {
    color: #cdd6f4;
}
EOF

    log_info "Waybar configuration created at: $waybar_dir"
}

# Main function
main() {
    echo -e "${BLUE}FUGIS Waybar Configuration Generator${NC}"
    echo "======================================"

    detect_system_info
    create_waybar_config

    log_info "Waybar configuration generated successfully!"
    log_info "To apply changes, restart Waybar: killall waybar && waybar &"
}

# Run main function
main "$@"
