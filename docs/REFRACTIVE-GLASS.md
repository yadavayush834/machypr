# Refractive glass and window bounds

The glass switch uses a native HyprGlass renderer built against the installed Hyprland headers. It samples pixels behind the surface in the compositor and processes them through a refraction shader. This is a working Linux renderer, not Apple's private implementation and not a browser screenshot or translucent CSS presented as refraction.

## Installation and controls

The full installer attempts `scripts/install-refractive-glass.sh`. It pins HyprGlass revision `dc00c628623e5e504b363e26dd489ee766d2fa12` for Hyprland **0.57.1**, builds with two compiler jobs and installs the library, license and build metadata under `~/.local/lib/macos-desktop`. A different Hyprland version requires a matching source revision and rebuild; the helper stops rather than bypassing the renderer's compatibility checks. If installation fails, the desktop still has its standard/frosted appearance.

Enable or disable the effect in **System Settings → Appearance**, the Apple menu or Control Center. The equivalent commands are:

```bash
macos-glass on
macos-glass off
macos-glass status
```

Status distinguishes `hyprglass`, `frosted-fallback` and `off`, and includes native diagnostics when available. A file's existence alone is not treated as proof of active rendering. The live system was checked with `versionCheck: match`, `shaders: ready`, and active window/layer features.

## Scope and readability

The renderer targets normal application windows and these owned shell layers: Dock, menu bar, menus, Spotlight, Launchpad, OSD and Dashboard. The desktop icon surface is deliberately not a full-screen glass target. Settings exposes translucent shell backgrounds; other apps retain their own widget implementations.

A 0.92 opacity multiplier lets the sampled material show through apps that draw fully opaque client backgrounds. This affects the whole composited app window, including its text; it is a conservative compromise rather than a replacement of each application's toolbar. Shell foreground text is still drawn by GTK/Cairo. Fullscreen windows receive an opaque rule and a dynamic renderer-exclusion tag, which is removed when they leave fullscreen. Missing/incompatible renderers receive no global opacity rule.

The renderer is loaded declaratively on every enabled config evaluation and guarded by `MACOS_DISABLE_PLUGINS`. Turning glass off removes its configuration, opacity and layer rules. The standard title-bar configuration is restored on reload. The guarded session's existing trusted plugin baseline was extended locally only after build/load checks and a live A/B render test. No machine-specific baseline or binary is stored in the repository.

## Window containment

`misc.float_force_onscreen=2` keeps normal floating-window moves fully within an available monitor. New windows start at 85% of monitor width and 80% of its height, with maximum dimensions of 95% and 85%, respectively, leaving room for the menu bar/title bar. The settings use current Lua expressions (`monitor_w` and `monitor_h`), not legacy percentage strings. Existing windows retain their current sizes unless a size limit applies; normal window interaction stays freely floating within the screen.

Native explicit resize dispatchers intentionally bypass size hints, so an administrator can still force unusual geometry from a script. The live regression targets oversized client requests, valid maximum-size properties and ordinary movement, rather than claiming a security boundary against compositor commands.

## Verification

`bash scripts/check.sh` checks configuration generation, guarded fallback, fullscreen rule generation and complete disable, alongside the existing desktop suite.

In a running Hyprland desktop:

```bash
python scripts/test-refractive-desktop.py
python scripts/test-window-bounds-desktop.py
```

The first creates disposable native windows, captures the same translucent pane with glass enabled and excluded, compares output pixels, checks GPU draw counters, and verifies fullscreen exclusion/restoration. The second checks an oversized initial client request and deliberately moves a disposable window beyond the upper-left and lower-right boundaries. Both close their test windows. Captures stay under `/tmp/machypr-glass-captures` by default.

Sources: [HyprGlass documentation and source](https://github.com/hyprnux/hyprglass/tree/dc00c628623e5e504b363e26dd489ee766d2fa12), [Hyprland window rules](https://wiki.hypr.land/configuring/core/rules/window-rules/), and [configuration options](https://wiki.hypr.land/configuring/core/config-options/).
