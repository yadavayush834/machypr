# Power profiles

Open **System Settings → Performance**, or use the shortcut in Battery. Three profiles control real hardware settings and foreground resource scheduling. **Enable Hardware Profiles** requests administrator authentication, saves the original CPU/GPU settings and installs `macos-power-profiles.service`. Standard is the initial selection. Profile changes also authenticate through Polkit; no password is stored and no unrestricted privilege rule is installed.

| Setting | Battery Saver | Standard (Balanced) | Performance |
| --- | --- | --- | --- |
| Intel P-state policy | powersave | powersave | performance |
| Energy preference | power | balance_performance | performance |
| Turbo | Disabled | Enabled | Enabled |
| HWP dynamic boost, where available | Disabled | Disabled | Enabled |
| Maximum CPU performance percentage before thermal feedback | 60% | 100% | 100% |
| CPU thermal management | 80°C software target | Normal hardware management | 96°C software target |
| Intel GPU maximum/boost ceiling | Half the supported maximum, rounded to a supported 50 MHz step | Supported maximum | Supported maximum |
| Foreground CPU weight | 100 | 300 | 1000 |
| Foreground I/O weight | 100 | 200 | 500 |
| Background slice CPU weight | 10 | 20 | 5 |
| Optional file-cache warmup | Deferred | Existing pressure/temperature checks | Deferred |

The CPU/GPU portion currently supports active `intel_pstate` and the legacy Intel i915 GT frequency controls when exposed. Unsupported hardware is reported rather than assigned a pretend profile. The foreground service changes weights on application cgroups and the containing app/session slice; it restores original weights when focus moves or the service stops. Existing higher weights are preserved. CPU and I/O weights affect resource sharing under contention, not uncontended CPU throughput. Proportional I/O sharing depends on the host disk scheduler.

The controller checks temperature every three seconds. Standard preserves the original full CPU ceiling and relies on normal hardware thermal management. In Performance, at 96°C it lowers the CPU ceiling by five percentage points, normally down to 70%; at 98°C it lowers it by fifteen points, down to 50%. Below 94°C it restores five points per check up to 100%. Battery Saver uses an 80°C target, 40% normal floor and 30% emergency floor, recovering six degrees below its target. Existing minimum CPU limits remain in force. Status is written to `/run` rather than repeatedly writing to the hard drive. Profile selection and the original baseline are stored under `/var/lib/macos-power-profiles`.

Standard preserves the existing adaptive CPU policy for everyday responsiveness. Performance permits higher heat and fan activity; neither mode promises silence or a fixed temperature. Hardware and firmware thermal protections remain active. The controller does not alter RAM timings, voltages, package power limits, fan control, security mitigations, animations, swap configuration or storage integrity settings.

## Hardware limits

Profiles operate within the limits exposed by supported drivers. Thermal throttling and slow storage can limit responsiveness; software scheduling cannot replace adequate cooling or faster storage. No fixed performance gain is promised.

## Inspect and restore

```bash
macos-power-profile --status
macos-responsiveness --status
systemctl status macos-power-profiles.service
macos-power-profile --set performance
macos-power-profile --set standard
macos-power-profile --restore
```

Restore stops/disables the controller and restores the original saved sysfs settings. The foreground priority service then returns to Standard weights. It does not delete the saved baseline, so the operation can be inspected and repeated. Switching profiles enables the controller again. The general desktop installer copies the user interface and source but does not silently install this root service.

The controller verifies requested values after writing them; a failed transition restores the pre-transition values. Tests cover all three profiles, idempotence, unsupported drivers, partial-write rollback, thermal reduction/recovery, and priority restoration. Live status reports the readback values rather than assuming a successful write.

References: [Linux Intel P-state and HWP behavior](https://www.kernel.org/doc/html/latest/admin-guide/pm/intel_pstate.html), [Intel overclocking hardware requirements](https://www.intel.com/content/www/us/en/support/articles/000097808/processors/intel-core-processors.html), [systemd CPU and I/O resource weights](https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html).
