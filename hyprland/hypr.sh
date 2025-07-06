#!/bin/bash

# FUGIS Hyprland Configuration Generator
# Automatically generates hyprland.conf based on system detection

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

# Check if Hyprland is running
check_hyprland() {
    if ! command -v hyprctl &> /dev/null; then
        log_error "Hyprland is not installed or not in PATH"
        exit 1
    fi

    if ! hyprctl version &> /dev/null; then
        log_error "Hyprland is not running"
        exit 1
    fi

    log_info "Hyprland detected and running"
}

# Detect system variables using hyprctl
detect_system_info() {
    log_info "Detecting system information..."

    # Get monitors info
    MONITORS=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null || hyprctl monitors | grep "Monitor" | awk '{print $2}')
    PRIMARY_MONITOR=$(echo "$MONITORS" | head -n1)

    # Get resolution of primary monitor
    RESOLUTION=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].width, .[0].height' 2>/dev/null | tr '\n' 'x' | sed 's/x$//' || echo "1920x1080")

    # Get refresh rate
    REFRESH_RATE=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].refreshRate' 2>/dev/null | cut -d'.' -f1 || echo "60")

    # Detect GPU
    if lspci | grep -i nvidia &>/dev/null; then
        GPU_TYPE="nvidia"
    elif lspci | grep -i amd &>/dev/null; then
        GPU_TYPE="amd"
    else
        GPU_TYPE="intel"
    fi

    USERNAME=$(whoami)
    HOME_DIR="$HOME"

    log_info "Primary Monitor: $PRIMARY_MONITOR"
    log_info "Resolution: $RESOLUTION@${REFRESH_RATE}Hz"
    log_info "GPU Type: $GPU_TYPE"
    log_info "User: $USERNAME"
}

# Create Hyprland configuration
create_hypr_config() {
    local config_dir="$HOME_DIR/.config/hypr"
    local config_file="$config_dir/hyprland.conf"

    log_info "Creating Hyprland configuration directory..."
    mkdir -p "$config_dir"

    log_info "Generating hyprland.conf..."

    cat > "$config_file" << EOF
# FUGIS Generated Hyprland Configuration
# Generated on: $(date)
# User: $USERNAME
# Primary Monitor: $PRIMARY_MONITOR
# Resolution: $RESOLUTION@${REFRESH_RATE}Hz
# GPU: $GPU_TYPE

# Monitor configuration
monitor=$PRIMARY_MONITOR,$RESOLUTION@$REFRESH_RATE,0x0,1

# Environment variables
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
EOF

    # Add GPU-specific settings
    case $GPU_TYPE in
        "nvidia")
            cat >> "$config_file" << EOF
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = NVIDIA_MODESET,1
env = NVIDIA_DRM_MODESET,1
EOF
            ;;
        "amd")
            cat >> "$config_file" << EOF
env = LIBVA_DRIVER_NAME,radeonsi
env = WLR_DRM_DEVICES,/dev/dri/card0
env = AMD_VULKAN_ICD,RADV
EOF
            ;;
        *)
            cat >> "$config_file" << EOF
env = LIBVA_DRIVER_NAME,i965
env = INTEL_DEBUG,norbc
EOF
            ;;
    esac

    cat >> "$config_file" << EOF

# Input configuration
input {
    kb_layout = us,cz
    kb_variant = ,qwerty
    kb_model =
    kb_options = grp:alt_shift_toggle
    kb_rules =

    follow_mouse = 1
    mouse_refocus = false

    touchpad {
        natural_scroll = true
        tap-to-click = true
        drag_lock = true
        disable_while_typing = true
    }

    sensitivity = 0
    accel_profile = flat
}

# General configuration
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    layout = dwindle
    allow_tearing = false
    resize_on_border = true
    extend_border_grab_area = 15
}

# Decoration
decoration {
    rounding = 8

    blur {
        enabled = true
        size = 6
        passes = 2
        new_optimizations = true
        xray = true
        ignore_opacity = true
    }

    drop_shadow = true
    shadow_range = 20
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)

    active_opacity = 1.0
    inactive_opacity = 0.9
    fullscreen_opacity = 1.0
}

# Animations
animations {
    enabled = true

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0.0, 0.0, 1.0, 1.0
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = slow, 0, 0.85, 0.3, 1

    animation = windows, 1, 6, wind, slide
    animation = windowsIn, 1, 6, winIn, slide
    animation = windowsOut, 1, 5, winOut, slide
    animation = windowsMove, 1, 5, wind, slide
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 10, default
    animation = workspaces, 1, 5, wind
}

# Layout configuration
dwindle {
    pseudotile = true
    preserve_split = true
    smart_split = false
    smart_resizing = true
}

master {
    new_is_master = true
    always_center_master = false
}

# Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_invert = true
    workspace_swipe_min_speed_to_force = 30
    workspace_swipe_cancel_ratio = 0.5
    workspace_swipe_create_new = true
}

# Miscellaneous
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
    vrr = 1
    animate_manual_resizes = true
    animate_mouse_windowdragging = true
    enable_swallow = true
    swallow_regex = ^(kitty)$
}

# Group configuration
group {
    col.border_active = rgba(33ccffee)
    col.border_inactive = rgba(595959aa)
    col.border_locked_active = rgba(ff5555ee)
    col.border_locked_inactive = rgba(555555aa)
}

# Window rules
windowrulev2 = nomaximizerequest, class:.*
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, class:^(nm-applet)$
windowrulev2 = float, class:^(thunar)$, title:^(File Operation Progress)$

# Workspace rules
workspace = 1, monitor:$PRIMARY_MONITOR, default:true
workspace = 2, monitor:$PRIMARY_MONITOR
workspace = 3, monitor:$PRIMARY_MONITOR
workspace = 4, monitor:$PRIMARY_MONITOR
workspace = 5, monitor:$PRIMARY_MONITOR

# Keybindings
\$mainMod = SUPER

# Application shortcuts
bind = \$mainMod, Q, exec, kitty
bind = \$mainMod, C, killactive,
bind = \$mainMod, M, exit,
bind = \$mainMod, E, exec, thunar
bind = \$mainMod, V, togglefloating,
bind = \$mainMod, R, exec, wofi --show drun
bind = \$mainMod, P, pseudo,
bind = \$mainMod, J, togglesplit,
bind = \$mainMod, F, fullscreen,
bind = \$mainMod, T, togglegroup,
bind = \$mainMod SHIFT, T, lockactivegroup,

# Move focus with mainMod + arrow keys
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

# Move focus with mainMod + hjkl (vim-like)
bind = \$mainMod, h, movefocus, l
bind = \$mainMod, l, movefocus, r
bind = \$mainMod, k, movefocus, u
bind = \$mainMod, j, movefocus, d

# Move windows
bind = \$mainMod SHIFT, left, movewindow, l
bind = \$mainMod SHIFT, right, movewindow, r
bind = \$mainMod SHIFT, up, movewindow, u
bind = \$mainMod SHIFT, down, movewindow, d

bind = \$mainMod SHIFT, h, movewindow, l
bind = \$mainMod SHIFT, l, movewindow, r
bind = \$mainMod SHIFT, k, movewindow, u
bind = \$mainMod SHIFT, j, movewindow, d

# Resize windows
bind = \$mainMod CTRL, left, resizeactive, -20 0
bind = \$mainMod CTRL, right, resizeactive, 20 0
bind = \$mainMod CTRL, up, resizeactive, 0 -20
bind = \$mainMod CTRL, down, resizeactive, 0 20

bind = \$mainMod CTRL, h, resizeactive, -20 0
bind = \$mainMod CTRL, l, resizeactive, 20 0
bind = \$mainMod CTRL, k, resizeactive, 0 -20
bind = \$mainMod CTRL, j, resizeactive, 0 20

# Switch workspaces with mainMod + [0-9]
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5
bind = \$mainMod, 6, workspace, 6
bind = \$mainMod, 7, workspace, 7
bind = \$mainMod, 8, workspace, 8
bind = \$mainMod, 9, workspace, 9
bind = \$mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
bind = \$mainMod SHIFT, 6, movetoworkspace, 6
bind = \$mainMod SHIFT, 7, movetoworkspace, 7
bind = \$mainMod SHIFT, 8, movetoworkspace, 8
bind = \$mainMod SHIFT, 9, movetoworkspace, 9
bind = \$mainMod SHIFT, 0, movetoworkspace, 10

# Special workspace (scratchpad)
bind = \$mainMod, S, togglespecialworkspace, magic
bind = \$mainMod SHIFT, S, movetoworkspace, special:magic

# Scroll through existing workspaces with mainMod + scroll
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# Media keys
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioPause, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Screenshot
bind = , Print, exec, grim -g "\$(slurp)" - | wl-copy
bind = \$mainMod, Print, exec, grim - | wl-copy
bind = \$mainMod SHIFT, Print, exec, grim -g "\$(slurp)" ~/Pictures/Screenshots/\$(date +'%Y%m%d_%H%M%S').png

# Lock screen
bind = \$mainMod, L, exec, swaylock -f -c 000000

# Brightness
bind = , XF86MonBrigh
