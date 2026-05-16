-- Migrated from hyprland.conf to Lua syntax for Hyprland 0.55+
-- Date: 2026-05-15

------------------
---- MONITORS ----
------------------

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "station"
local fileManager = "index"
local menu = "vicinae toggle"
local lockScreen = "hyprlock"
local webBrowser = "flatpak run com.brave.Browser"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("brightnessctl -s set 48000 & hyprscreend & hyprextscreend & hyprsunset")
    hl.exec_cmd("autostart-kde-polkit & xdg-user-dirs-update & autostart-pipewire & autostart-xdg-portals")
    hl.exec_cmd("waybar & hyprpaper & hypridle & swaync & crystal-dock & nwg-look -a & swaync-client -R & swaync-client -rs & wl-paste --watch clipvault store")
    hl.exec_cmd("nx-apphubd & gamemoded -d & openrazer-daemon -F & nx-sys-usecase & nx-dynamic-ppd & nx-battery-notify & nudge-osd --emoji & vicinae server")
    hl.exec_cmd("dmemcg-booster --mode agent --focus-provider=hyprland --socket-path /run/dmemcg-booster/focus.sock")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("GTK_USE_PORTAL", "1")

hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "nitrux_snow_cursors")

hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

hl.env("SDL_VIDEODRIVER", "wayland")

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "nitrux_snow_cursors")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 1,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        allow_tearing = true,
        layout = "dwindle",
    },

    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 0.8,
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("leanBack", { type = "bezier", points = { { 0, 0 }, { 0, 1 } } })

hl.animation({ leaf = "monitorAdded", enabled = true, speed = 3, bezier = "leanBack" })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "myBezier", style = "slide bottom" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        vrr = 3,
        enable_anr_dialog = false,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local laptopLid = "Lid Switch"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(webBrowser))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("nudge-osd --volume-down 5"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("nudge-osd --volume-up 5"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("nudge-osd --volume-mute"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("nudge-osd --brightness-up 10"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("nudge-osd --brightness-down 10"))

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(lockScreen))
hl.bind("switch:" .. laptopLid, hl.dsp.exec_cmd(lockScreen), { locked = true })

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("pkill wlogout || wlogout"))

hl.bind("Print", hl.dsp.exec_cmd("grimshot -f"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("pkill -x slurp || grimshot -s"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("pkill -x slurp || grimshot -w"))

hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("vicinae vicinae://launch/clipboard/history"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("killall crystal-dock && crystal-dock"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("autostart-kde-polkit"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("killall waybar || true && waybar"))

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -R -rs"))


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.layer_rule({
    match = { namespace = "logout_dialog" },
    blur = true,
})
hl.layer_rule({
    match = { namespace = "logout_dialog" },
    ignore_alpha = 0.4,
})

hl.layer_rule({
    match = { namespace = "^window$" },
    blur = true,
})
hl.layer_rule({
    match = { namespace = "^window$" },
    ignore_alpha = 0.4,
})

hl.layer_rule({
    match = { namespace = "^wofi$" },
    blur = true,
})
hl.layer_rule({
    match = { namespace = "^wofi$" },
    ignore_alpha = 0.4,
})

hl.window_rule({
    name = "nudge-osd",
    match = { class = "^(nudge-osd)$" },
    float = true,
    size = "300 70",
    move = "(monitor_w/2-150) (monitor_h-180)",
    decorate = false,
    no_shadow = true,
    no_blur = true,
    no_focus = true,
    no_initial_focus = true,
    pin = true,
    opacity = "1.0 override 1.0 override",
})

hl.layer_rule({
    name = "vicinae-blur",
    match = { namespace = "vicinae" },
    blur = true,
    ignore_alpha = 0,
})


----------------
---- NO NEWS ---
----------------

hl.config({
    ecosystem = {
        no_update_news = true,
    },
})
