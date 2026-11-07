#!/usr/bin/env python3
"""Accounting boundaries, persistence, pause and reminders, without session changes."""
import datetime as dt
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'home/.local/lib'))
import macos_screen_time as S


class AccountingTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.path=Path(self.temp.name)/'usage.sqlite3'
    def tearDown(self):self.temp.cleanup()
    def test_midnight_is_split_and_multiple_apps_persist(self):
        end=dt.datetime.combine(dt.date.today(),dt.time()).timestamp()
        with S.connect(self.path) as db:
            S.record(db,'discord',end-3,end+2)
            S.record(db,'codex',end+2,end+7)
        today=S.summary(path=self.path);yesterday=S.summary(offset=1,path=self.path)
        self.assertEqual(dict(today['apps']),{'discord':2,'codex':5})
        self.assertEqual(dict(yesterday['apps']),{'discord':3})
        self.assertEqual(S.summary(7,path=self.path)['total'],10)
    def test_sleep_gaps_and_missing_app_are_not_counted(self):
        now=dt.datetime.now().timestamp()
        with S.connect(self.path) as db:
            S.record(db,'codex',now-3600,now);S.record(db,None,now-5,now)
        self.assertEqual(S.summary(path=self.path)['total'],0)
    def test_pause_limits_and_clear_are_persistent(self):
        S.configure('paused',True,self.path);S.set_limit('codex',30,self.path)
        data=S.summary(path=self.path)
        self.assertTrue(data['paused']);self.assertEqual(data['limits'],{'codex':30})
        S.clear(self.path);data=S.summary(path=self.path)
        self.assertTrue(data['paused']);self.assertEqual(data['limits'],{'codex':30});self.assertEqual(data['total'],0)
        S.set_limit('codex',0,self.path);self.assertEqual(S.summary(path=self.path)['limits'],{})
        with self.assertRaises(ValueError):S.set_limit('codex',-1,self.path)
        self.assertEqual(self.path.stat().st_mode&0o777,0o600)


if __name__=='__main__':unittest.main()
