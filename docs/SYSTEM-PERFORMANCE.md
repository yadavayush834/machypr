# System responsiveness profile

This profile changes resource scheduling and background I/O. It does not change animations, disable security mitigations, drop filesystem caches, overclock the CPU, or kill background applications.

## Findings on the development laptop

The machine has an Intel i5-1035G1, approximately 16 GiB RAM, a 1 TB rotational disk, and existing 4 GiB zstd zram swap. The initial sample showed about 11 GiB RAM available and no sustained memory pressure, but substantial I/O stalls. CPU package temperatures repeatedly approached 95–100°C and hardware package-throttle counters increased during a 10-second sample. The fan was running. Browser GPU video-engine counters were zero, although the Intel VA-API runtime driver was present; decoding has not been declared fixed or forced with speculative browser flags.

The original boot measurement was 33.835 seconds: firmware 12.221, loader 0.826, kernel 4.129 and userspace 16.657. The `/boot` mount waited on a device at 14.587 seconds in userspace. These are baseline measurements, not a claim about the next boot.

## Foreground CPU policy

`macos-responsiveness.service` uses systemd's existing cgroup-v2 CPU weights. It listens to Hyprland focus events and raises the active app scope and its immediate app/session slice to weight 300. Original weights are recorded before each change and restored on focus changes or clean shutdown. Stale runtime state is recovered at service start. Existing higher weights are preserved. Related Flatpak browser scopes and Kitty child scopes are grouped so their work follows the application. Core session services and the user manager are never treated as application scopes.

Weights allocate relative CPU time under contention; they do not cap CPU use, reserve whole cores, change CPU frequency, or speed up uncontended computation. Background audio and applications keep running. Repeated focus notifications caused by title changes are ignored, and genuine focus changes are coalesced within 200 ms to avoid a busy polling service. Runtime status contains only the current app class and units, not window titles or an activity history.

`macos-app-launch` starts new desktop apps in independent user scopes when a user systemd manager is available. The Dock, menu and Settings launch helpers use it, as do the Settings and Dashboard desktop entries. Existing running applications are not forcibly migrated. Applications launched elsewhere must already have a managed scope for focus weighting to apply.

```bash
systemctl --user status macos-responsiveness.service
macos-responsiveness --status
systemctl --user disable --now macos-responsiveness.service
```

## Disk and writeback profile

`scripts/tune-system-performance.py` prints its exact plan without privileges. The explicitly applied root profile:

- Selects BFQ on BFQ-capable rotational disks and uses 512 KiB read-ahead, replacing the observed mq-deadline scheduler and 8192 KiB read-ahead.
- Starts background dirty-page writeback at 64 MiB and limits dirty-page accumulation at 256 MiB, rather than letting ratio-based thresholds grow into gigabytes on this machine.
- Makes the existing vfat `/boot` entry mount on demand through systemd automount, preserving its source, permissions and other flags. The current mounted `/boot` is not unmounted; package/kernel updates still mount it on access.

BFQ and bounded writeback favor interactive latency over maximum bulk throughput. They do not remove physical disk seek/flush latency. CPU governor/turbo policy, zram, OOM policy, network services and kernel command line remain unchanged. The root helper stores a manifest, original files and runtime values under `/var/lib/macos-performance-backups/TIMESTAMP`, validates fstab, and restores its backup if application fails. The hardware-specific profile is not silently applied by the general desktop installer.

```bash
python scripts/tune-system-performance.py
pkexec /usr/bin/python -I scripts/tune-system-performance.py --apply
pkexec /usr/bin/python -I scripts/tune-system-performance.py --undo /var/lib/macos-performance-backups/TIMESTAMP
```

Use an absolute script path when invoking pkexec from outside the repository.

## Background work and launch pressure

Background jobs run in `background.slice` with a lower relative CPU weight. Update checks and optional app-file warmup wait five minutes after login. Warmup runs only on AC, reads at most 128 MiB total/32 MiB per file, and stops or defers when memory is low, PSI indicates CPU/memory/I/O pressure, or CPU package temperature is at least 85°C. It leaves Linux's normal reclaimable page cache intact. Explicit user-requested update checks remain available immediately.

Existing user files are backed up under `~/.local/state/macos-performance/user-backup/TIMESTAMP`. To restore them and stop priority management:

```bash
python scripts/undo-performance-user.py ~/.local/state/macos-performance/user-backup/TIMESTAMP
```

Root disk/boot settings have their separate rollback above. Neither rollback reboots the computer or stops the desktop.

## Verification and limits

`bash scripts/check.sh` includes priority-restoration, stale-state recovery, protected-session exclusions, pressure/thermal deferral and idempotent fstab-transformation tests. Optional live tests:

```bash
python scripts/benchmark-cpu-priority.py
python scripts/test-responsiveness-desktop.py
macos-performance-report --save
```

The controlled contention test pins two disposable jobs to one CPU. Equal weights received 98/98 CPU ticks; changing one to weight 300 yielded 51/148 ticks, a 2.9:1 allocation. This verifies cgroup scheduling, not a 2.9× whole-system speedup. The live focus test verified promotion, background restoration and clean-stop restoration using disposable app scopes. The launcher was checked to create an independent `app.slice` scope. Warmup deferred under the actual measured I/O pressure.

Read-only reports live under `~/.local/state/macos-performance/`. One report is retained per boot so a later restart can be compared with the baseline. No cold-boot speedup is claimed before that restart; firmware and mechanical-disk limits remain. Sustained thermal throttling also remains a hardware cooling constraint. Software scheduling cannot make this HDD behave like a MacBook SSD or repair cooling hardware.

References: [Linux BFQ documentation](https://docs.kernel.org/block/bfq-iosched.html), [systemd CPU resource weights](https://www.freedesktop.org/software/systemd/man/256/systemd.resource-control.html), [systemd automount behavior](https://www.freedesktop.org/software/systemd/man/256/systemd.mount.html), [Linux dirty-page writeback controls](https://docs.kernel.org/admin-guide/sysctl/vm.html), [System76 Scheduler's foreground/background approach](https://github.com/pop-os/system76-scheduler), and [Apple's task-level QoS guidance](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/PrioritizeWorkAtTheTaskLevel.html). The controller is an original implementation using existing systemd APIs; it does not port Apple's scheduler or bundle System76 daemon code.
