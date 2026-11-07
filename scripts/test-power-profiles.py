#!/usr/bin/env python3
"""Exercise profile writes, rollback and thermal feedback against a fake sysfs tree."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
ROOT=Path(__file__).resolve().parent.parent
spec=importlib.util.spec_from_file_location('profiles',ROOT/'home/.local/share/macos-desktop/power-profiles.py')
P=importlib.util.module_from_spec(spec);spec.loader.exec_module(P)


class ProfileTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.pstate=self.root/'devices/system/cpu/intel_pstate';self.pstate.mkdir(parents=True)
        for name,value in {'status':'active','no_turbo':'0','min_perf_pct':'11','max_perf_pct':'100','hwp_dynamic_boost':'0'}.items():(self.pstate/name).write_text(value)
        for index in range(2):
            policy=self.root/f'devices/system/cpu/cpufreq/policy{index}';policy.mkdir(parents=True)
            for name,value in {'scaling_governor':'powersave','scaling_available_governors':'powersave performance','energy_performance_preference':'balance_performance','energy_performance_available_preferences':'power performance balance_performance'}.items():(policy/name).write_text(value)
        gpu=self.root/'class/drm/card0';gpu.mkdir(parents=True)
        for name,value in {'gt_min_freq_mhz':'300','gt_max_freq_mhz':'1050','gt_boost_freq_mhz':'1050','gt_RP0_freq_mhz':'1050'}.items():(gpu/name).write_text(value)
    def tearDown(self):self.temp.cleanup()
    def test_three_distinct_profiles_and_restore(self):
        original={str(path):path.read_text() for path in P.controls(self.root)}
        P.apply('battery-saver',root=self.root)
        self.assertEqual((self.pstate/'no_turbo').read_text(),'1');self.assertEqual((self.pstate/'max_perf_pct').read_text(),'60')
        self.assertEqual((self.root/'class/drm/card0/gt_max_freq_mhz').read_text(),'500')
        P.apply('performance',root=self.root)
        self.assertEqual((self.pstate/'no_turbo').read_text(),'0');self.assertEqual((self.pstate/'hwp_dynamic_boost').read_text(),'1')
        for policy in (self.root/'devices/system/cpu/cpufreq').iterdir():
            self.assertEqual((policy/'scaling_governor').read_text(),'performance');self.assertEqual((policy/'energy_performance_preference').read_text(),'performance')
        self.assertEqual(P.apply('performance',root=self.root),[])
        P.apply('standard',root=self.root)
        self.assertEqual((self.pstate/'hwp_dynamic_boost').read_text(),'0')
        P.restore_values(original)
        self.assertEqual({str(path):path.read_text() for path in P.controls(self.root)},original)
    def test_thermal_feedback_reduces_and_recovers(self):
        self.assertEqual(P.thermal_cap('performance',100,96),95)
        self.assertEqual(P.thermal_cap('performance',100,99),85)
        self.assertEqual(P.thermal_cap('performance',70,80),75)
        self.assertEqual(P.thermal_cap('standard',40,90),100)
        self.assertEqual(P.thermal_cap('battery-saver',60,60),60)
        self.assertEqual(P.thermal_cap('performance',70,None),70)
        for profile in P.PROFILES:
            for temp in (70,90,99):
                cap=100
                for _ in range(30):cap=P.thermal_cap(profile,cap,temp)
                self.assertLessEqual(cap,P.PROFILES[profile]['ceiling']);self.assertGreaterEqual(cap,30)
    def test_partial_write_failure_rolls_back(self):
        original={str(path):path.read_text() for path in P.controls(self.root)};write=Path.write_text;failed=[False]
        def fail(path,value,*args,**kwargs):
            if path.name=='energy_performance_preference' and not failed[0]:failed[0]=True;raise OSError('fixture failure')
            return write(path,value,*args,**kwargs)
        with patch.object(Path,'write_text',fail):
            with self.assertRaises(OSError):P.apply('performance',root=self.root)
        self.assertEqual({str(path):path.read_text() for path in P.controls(self.root)},original)
    def test_unsupported_driver_does_not_write(self):
        (self.pstate/'status').write_text('passive')
        with self.assertRaises(RuntimeError):P.apply('performance',root=self.root)
        self.assertEqual((self.pstate/'max_perf_pct').read_text(),'100')
    def test_guard_limit_is_applied_to_hardware(self):
        P.apply('performance',75,root=self.root)
        self.assertEqual((self.pstate/'max_perf_pct').read_text(),'75')
        self.assertEqual((self.pstate/'min_perf_pct').read_text(),'11')


if __name__=='__main__':unittest.main()
