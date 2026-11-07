#!/usr/bin/env python3
"""Background app detection and scoped quit without terminating real applications."""
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'home/.local/lib'))
import macos_background_apps as B

class BackgroundTests(unittest.TestCase):
    def test_flatpak_instances_are_grouped_without_windows(self):
        with tempfile.TemporaryDirectory() as folder:
            apps=B.discover(Path(folder),'com.discordapp.Discord\ncom.discordapp.Discord\norg.telegram.desktop\n')
        self.assertEqual(set(apps),{'discord','telegram'})
        self.assertEqual(apps['discord']['flatpak'],'com.discordapp.Discord')
    def test_native_background_process_without_windows(self):
        with tempfile.TemporaryDirectory() as folder:
            proc=Path(folder);(proc/'12').mkdir()
            with patch.object(B,'process_record',return_value=(12,'100','ChatGPT')):
                apps=B.discover(proc,'')
        self.assertEqual(apps['chatgpt']['processes'],[(12,'100','ChatGPT')])
    def test_reused_pid_is_not_signalled(self):
        with patch.object(B,'process_record',return_value=(12,'200','ChatGPT')),patch.object(B.os,'kill') as kill:
            B.quit_app('chatgpt',{'processes':[(12,'100','ChatGPT')]})
            kill.assert_not_called()
    def test_native_quit_revalidates_identity(self):
        record=(12,'100','ChatGPT')
        with patch.object(B,'process_record',return_value=record),patch.object(B.os,'kill') as kill:
            B.quit_app('chatgpt',{'processes':[record]})
            kill.assert_called_once_with(12,B.signal.SIGTERM)
    def test_docker_quit_stops_backend_service(self):
        with patch.object(B.subprocess,'run') as run:
            B.quit_app('docker',{})
            self.assertEqual(run.call_args.args[0],['systemctl','--user','stop','docker-desktop.service'])
    def test_flatpak_quit_targets_only_selected_app(self):
        with patch.object(B.subprocess,'run') as run:
            B.quit_app('discord',{'flatpak':'com.discordapp.Discord'})
            self.assertEqual(run.call_args.args[0],['flatpak','kill','com.discordapp.Discord'])

if __name__=='__main__':unittest.main()
