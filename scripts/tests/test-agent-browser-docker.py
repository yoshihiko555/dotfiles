#!/usr/bin/env python3
"""ローカル Chrome へのフォールバックと他セッションへの干渉を防ぐ。"""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import unittest
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("agent_browser_docker", ROOT / "scripts/agent-browser-docker.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class BrowserTests(unittest.TestCase):
    def setUp(self):
        self.browser = MODULE.Browser("test", ROOT)
        self.info = {
            "Config": {"Labels": {MODULE.LABEL: self.browser.name}},
            "State": {"Running": True},
            "NetworkSettings": {"Ports": {"9223/tcp": [{"HostIp": "127.0.0.1", "HostPort": "43210"}]}},
        }

    def test_sessions_and_workspaces_are_isolated(self):
        self.assertNotEqual(self.browser.name, MODULE.Browser("other", ROOT).name)
        self.assertNotEqual(self.browser.name, MODULE.Browser("test", ROOT / "other").name)
        with self.assertRaises(MODULE.Error):
            MODULE.Browser("../other", ROOT)

    def test_connection_overrides_are_rejected_before_execution(self):
        commands = [
            ["open", "about:blank", "--cdp=9222"],
            ["snapshot", "--auto-connect"],
            ["batch", "open about:blank", "close", "open about:blank"],
            ["batch", "open about:blank --executable-path /Applications/Chrome"],
            ["batch", "--json"], ["connect", "9222"], ["close", "--all"],
        ]
        with patch.object(MODULE, "docker") as docker:
            for command in commands:
                with self.subTest(command=command), self.assertRaises(MODULE.Error):
                    self.browser.execute(command)
            docker.assert_not_called()

    def test_cdp_failure_never_calls_agent_browser(self):
        with patch.object(MODULE.shutil, "which", return_value="/fake/cli"), \
                patch.object(MODULE, "docker"), \
                patch.object(self.browser, "inspect", return_value=self.info), \
                patch.object(self.browser, "endpoint", side_effect=MODULE.Error("接続失敗")), \
                patch.object(self.browser, "agent") as agent:
            with self.assertRaises(MODULE.Error):
                self.browser.execute(["snapshot"])
            agent.assert_not_called()

    def test_agent_always_gets_explicit_cdp_and_isolated_config(self):
        calls = []

        def run(command, **kwargs):
            calls.append(command)
            config = Path(command[command.index("--config") + 1])
            self.assertEqual(json.loads(config.read_text()), {})
            self.assertFalse(any(key.startswith("AGENT_BROWSER_") for key in kwargs["env"]))
            return SimpleNamespace(returncode=7)

        endpoint = "ws://127.0.0.1:43210/devtools/browser/test"
        with patch.dict(os.environ, {"AGENT_BROWSER_AUTO_CONNECT": "1"}), \
                patch.object(MODULE.subprocess, "run", side_effect=run):
            self.assertEqual(self.browser.agent(endpoint, ["snapshot"]), 7)
        self.assertEqual(calls[0][calls[0].index("--cdp") + 1], endpoint)
        self.assertEqual(calls[0][calls[0].index("--session") + 1], "test")
        self.assertEqual(calls[0][calls[0].index("--namespace") + 1], self.browser.namespace)

    def test_unowned_container_cannot_be_closed(self):
        self.info["Config"]["Labels"] = {}
        result = SimpleNamespace(returncode=0, stdout=json.dumps([self.info]), stderr="")
        with patch.object(MODULE, "docker", return_value=result) as docker:
            with self.assertRaises(MODULE.Error):
                self.browser.close()
        self.assertEqual(docker.call_count, 1)
        self.assertEqual(docker.call_args.args[:2], ("container", "inspect"))

    def test_startup_failure_removes_only_created_container(self):
        result = SimpleNamespace(returncode=0, stdout="", stderr="")
        with patch.object(self.browser, "inspect", side_effect=[None, self.info]), \
                patch.object(self.browser, "endpoint", side_effect=MODULE.Error("接続失敗")), \
                patch.object(MODULE, "docker", return_value=result) as docker:
            with self.assertRaises(MODULE.Error):
                self.browser.start()
        self.assertEqual(docker.call_args.args, ("rm", "--force", self.browser.name))
        run = next(call.args for call in docker.call_args_list if call.args[0] == "run")
        self.assertIn("127.0.0.1::9223", run)
        self.assertNotIn("--mount", run)
        self.assertNotIn("--volume", run)

    def test_close_removes_container_even_if_agent_times_out(self):
        with patch.object(self.browser, "inspect", return_value=self.info), \
                patch.object(self.browser, "endpoint", return_value="ws://127.0.0.1:43210/devtools/browser/test"), \
                patch.object(self.browser, "agent", side_effect=subprocess.TimeoutExpired("agent-browser", 15)), \
                patch.object(MODULE, "docker") as docker:
            with self.assertRaises(subprocess.TimeoutExpired):
                self.browser.close()
        docker.assert_called_once_with("rm", "--force", self.browser.name)

    def test_non_loopback_endpoint_is_rejected(self):
        self.info["NetworkSettings"]["Ports"]["9223/tcp"][0]["HostIp"] = "0.0.0.0"
        with self.assertRaises(MODULE.Error):
            self.browser.endpoint(self.info)


if __name__ == "__main__":
    unittest.main()
