"""Quota semantics and offline behavior, without any network calls."""

import json
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

import importlib.util

spec = importlib.util.spec_from_file_location("usage", Path(__file__).resolve().parent.parent / "home/.local/share/codex-usage/usage.py")
usage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(usage)


class QuotaTests(unittest.TestCase):
    def test_windows_are_identified_by_duration(self):
        data = {
            "limits": {
                "primary": {"windowDurationMins": 10080, "usedPercent": 13},
                "secondary": {"windowDurationMins": 300, "usedPercent": 45},
            }
        }
        self.assertIn("5h 55% · W 87%", usage.waybar(data)["text"])

    def test_missing_window_is_unavailable_not_full(self):
        data = {
            "limits": {
                "primary": {"windowDurationMins": 10080, "usedPercent": 13},
                "secondary": None,
            }
        }
        self.assertIn("5h — · W 87%", usage.waybar(data)["text"])

    def test_expired_reset_does_not_invent_new_allowance(self):
        window = {
            "windowDurationMins": 300,
            "usedPercent": 100,
            "resetsAt": time.time() - 1,
        }
        result = usage.waybar({"limits": {"primary": window}})
        self.assertEqual(result["class"], "stale")
        self.assertIn("5h 0%", result["text"])

    def test_null_reset_and_invalid_percentage(self):
        window = {"windowDurationMins": 300, "usedPercent": "NaN", "resetsAt": None}
        self.assertIsNone(usage.remaining(window))
        self.assertEqual(
            usage.waybar({"limits": {"primary": window}})["class"], "unavailable"
        )

    def test_zero_remaining_is_critical(self):
        self.assertEqual(
            usage.waybar(
                {"limits": {"primary": {"windowDurationMins": 300, "usedPercent": 100}}}
            )["class"],
            "critical",
        )

    def test_failed_refresh_preserves_and_marks_cached_data(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            saved = {
                "fetched_at": time.time() - 120,
                "limits": {"primary": {"windowDurationMins": 300, "usedPercent": 45}},
            }
            path = cache / "limits.json"
            path.write_text(json.dumps(saved))
            with (
                patch.object(usage, "CACHE", cache),
                patch.object(usage, "SNAPSHOT", path),
                patch.object(usage, "read_limits", side_effect=RuntimeError("Offline")),
            ):
                result = usage.snapshot(force=True)
            self.assertEqual(result["error"], "Offline")
            self.assertEqual(result["limits"], saved["limits"])
            self.assertEqual(usage.waybar(result)["class"], "stale")
            self.assertEqual(json.loads(path.read_text()), saved)


if __name__ == "__main__":
    unittest.main()
