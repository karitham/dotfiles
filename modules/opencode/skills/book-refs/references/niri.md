# Niri

## Source

- Repo: `niri-wm/niri` (branch: `main`)
- Book path: `docs/wiki/`
- URL pattern: `https://raw.githubusercontent.com/niri-wm/niri/main/docs/wiki/{file}.md`
- Contents API: `https://api.github.com/repos/niri-wm/niri/contents/docs/wiki`
- Rendered: `https://niri-wm.github.io/niri/`

## Notes

- File names use colons (e.g. `Configuration:-Layout.md` — escaped as `Configuration%3A-Layout.md` in URLs, but raw GitHub URLs accept the literal `:`).
- Section prefix `Configuration:-` groups config topics; `Development:-` is contributor docs, skip unless working on niri itself.

## Common chapters

| File | Covers |
|---|---|
| `Getting-Started.md` | Install, first launch, basic concepts |
| `Overview.md` | Mental model: scrollable-tiling, workspaces, outputs |
| `Configuration:-Introduction.md` | How config.kdl is loaded and merged |
| `Configuration:-Layout.md` | Scrollable layout, columns, tab-strip, borders |
| `Configuration:-Input.md` | Keyboard, mouse, touch, focus |
| `Configuration:-Key-Bindings.md` | Binds, modes, spawning |
| `Configuration:-Window-Rules.md` | Per-window matching, open-floating, opacity, border |
| `Configuration:-Outputs.md` | Monitor config, scaling, transforms |
| `Configuration:-Animations.md` | Spring config, easing, durations |
| `Configuration:-Layer-Rules.md` | Layer-shell rules (bars, wallpapers, notifications) |
| `Configuration:-Include.md` | Splicing config from other files |
| `Configuration:-Named-Workspaces.md` | Naming workspaces to switch by name |
| `Configuration:-Miscellaneous.md` | Everything else (cursor, environment, screenshots) |
| `Configuration:-Switch-Events.md` | Pre/Post hooks on switch events |
| `Configuration:-Recent-Windows.md` | Switch-to-recent behavior |
| `Workspaces.md` | Workspaces vs. outputs |
| `Tabs.md` | Tab behavior |
| `Floating-Windows.md` | Floating windows inside the layout |
| `Fullscreen-and-Maximize.md` | Fullscreen modes |
| `Window-Effects.md` | Blur, shadows, opacity |
| `Gestures.md` | Touchpad / mouse gestures |
| `Screencasting.md` | Screen-sharing via xdg-desktop-portal |
| `Xwayland.md` | Xwayland integration and quirks |
| `IPC.md` | IPC interface for status bars and tools |
| `Security-Model.md` | What niri trusts from the compositor seat |
| `FAQ.md` | Common questions |
| `Application-Issues.md` | Per-app quirks (Electron, GTK, Qt, Steam, etc.) |
| `Nvidia.md` | Nvidia-specific issues and workarounds |
| `Example-systemd-Setup.md` | Sample systemd user unit for niri |
| `Integrating-niri.md` | Status bar, screencast, notifications, polkit |
| `Important-Software.md` | Tools to know about (swaybg, swayidle, waybar, etc.) |
| `Accessibility.md` | Accessibility features |
