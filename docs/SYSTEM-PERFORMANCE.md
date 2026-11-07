# System responsiveness profile

This profile changes resource scheduling and background I/O. It does not change animations, disable security mitigations, drop filesystem caches, overclock the CPU, or kill background applications.

The separate [power profiles](POWER-PROFILES.md) now provide Battery Saver, Standard (Balanced), and Performance in Settings, with authenticated CPU/GPU controls. Those hardware changes have their own baseline and restore action.

## Foreground CPU policy

`macos-responsiveness.service` uses systemd's existing cgroup-v2 CPU and I/O weights. It listens to Hyprland focus events and raises the active app scope and its immediate app/session slice to CPU weight 300 and I/O weight 200 in Standard, or CPU weight 1000 and I/O weight 500 in Performance. Battery Saver uses weight 100. Original weights are recorded before each change and restored on focus changes or clean shutdown. Stale runtime state is recovered at service start. Existing higher weights are preserved. Related Flatpak browser scopes and Kitty child scopes are grouped so their work follows the application. Core session services and the user manager are never treated as application scopes.

Weights allocate relative CPU time under contention; they do not cap CPU use, reserve whole cores, change CPU frequency, or speed up uncontended computation. Background audio and applications keep running. Repeated focus notifications caused by title changes are ignored, and genuine focus changes are coalesced within 200 ms to avoid a busy polling service. Runtime status contains only the current app class and units, not window titles or an activity history.

`macos-app-launch` starts new desktop apps in independent user scopes when a user systemd manager is available. The Dock, menu and Settings launch helpers use it, as do the Settings and Dashboard desktop entries. Existing running applications are not forcibly migrated. Applications launched elsewhere must already have a managed scope for focus weighting to apply.

```bash
systemctl --user status macos-responsiveness.service
macos-responsiveness --status
systemctl --user disable --now macos-responsiveness.service
```

## Background work and launch pressure

Background jobs run in `background.slice` with a lower relative CPU weight. Update checks and optional app-file warmup wait five minutes after login. Warmup runs only on AC, reads at most 128 MiB total/32 MiB per file, and stops or defers when memory is low, PSI indicates CPU/memory/I/O pressure, or CPU package temperature is at least 85°C. It leaves Linux's normal reclaimable page cache intact. Explicit user-requested update checks remain available immediately.

User configuration is backed up by the desktop installer and can be restored with `arch-rice-restore`. The shared installer does not alter disk schedulers, fstab, sleep mode or firmware settings.

## Verification and limits

`bash scripts/check.sh` includes priority-restoration, stale-state recovery, protected-session exclusions, pressure/thermal deferral tests. Optional live tests:

```bash
python scripts/benchmark-cpu-priority.py
python scripts/test-responsiveness-desktop.py
macos-performance-report --save
```

The optional controlled contention test uses disposable jobs to verify relative scheduling weights, rather than claiming a whole-system speedup. Live focus tests verify promotion and restoration using disposable app scopes. Read-only reports are generated locally under `~/.local/state/macos-performance/` and are excluded from publication.

References: [Linux BFQ documentation](https://docs.kernel.org/block/bfq-iosched.html), [systemd CPU resource weights](https://www.freedesktop.org/software/systemd/man/256/systemd.resource-control.html), [systemd automount behavior](https://www.freedesktop.org/software/systemd/man/256/systemd.mount.html), [Linux dirty-page writeback controls](https://docs.kernel.org/admin-guide/sysctl/vm.html), [System76 Scheduler's foreground/background approach](https://github.com/pop-os/system76-scheduler), and [Apple's task-level QoS guidance](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/PrioritizeWorkAtTheTaskLevel.html). The controller is an original implementation using existing systemd APIs; it does not port Apple's scheduler or bundle System76 daemon code.
