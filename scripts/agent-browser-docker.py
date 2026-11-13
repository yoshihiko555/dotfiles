#!/usr/bin/env python3
"""作業専用の Docker Chromium に agent-browser を接続する。"""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request


IMAGE = "mcr.microsoft.com/playwright:v1.52.0-noble"
LABEL = "dev.dotfiles.agent-browser"
SERVER = Path(__file__).with_name("agent-browser-docker-server.cjs")
COMMANDS = set("""open goto navigate snapshot click dblclick fill type press keyboard
hover focus check uncheck select scroll scrollintoview drag upload download wait
get is find eval screenshot pdf set tab frame dialog mouse keyboard network
cookies storage state console errors highlight diff batch back forward reload""".split())
BLOCKED_OPTIONS = set("""--cdp --cdp-headers --session --namespace --config --provider -p
--engine --executable-path --args --profile --extension --auto-connect --no-auto-connect
--relaunch --restore --session-name --headed --state""".split())


class Error(Exception):
    pass


def validate_command(command):
    if not command or command[0] not in COMMANDS | {"start", "status", "close"}:
        raise Error("ブラウザ操作、start、status、close のいずれかを指定してください")
    if command[0] in {"start", "status", "close"} and len(command) != 1:
        raise Error("start / status / close に追加の引数は指定できません")
    for arg in command:
        if arg.split("=", 1)[0] in BLOCKED_OPTIONS:
            raise Error(f"接続先・起動方法を変更するオプションは使えません: {arg.split('=', 1)[0]}")
    if command[0] == "batch":
        if len(command) == 1 or any(arg.startswith("-") for arg in command[1:]):
            raise Error("batch はコマンド文字列を引数で指定してください")
        for line in command[1:]:
            nested = shlex.split(line)
            if not nested or nested[0] in {"batch", "start", "status", "close"}:
                raise Error("batch 内でセッションの起動・終了はできません")
            validate_command(nested)


def docker(*args, check=True):
    result = subprocess.run(
        ["docker", *args], capture_output=True, text=True, timeout=45,
    )
    if check and result.returncode:
        raise Error(result.stderr.strip() or "Docker の操作に失敗しました")
    return result


class Browser:
    def __init__(self, session, cwd, image=IMAGE):
        if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,47}", session):
            raise Error("session は英小文字・数字・ハイフン・アンダースコアで 1〜48 文字にしてください")
        scope = hashlib.sha256(str(Path(cwd).resolve()).encode()).hexdigest()[:12]
        self.session = session
        self.image = image
        self.namespace = f"docker-{scope}"
        self.name = f"codex-browser-{os.getuid()}-{scope}-{session}"

    def inspect(self):
        result = docker("container", "inspect", self.name, check=False)
        if result.returncode:
            if "No such" in result.stderr:
                return None
            raise Error(result.stderr.strip() or "コンテナの状態を取得できません")
        info = json.loads(result.stdout)[0]
        if info["Config"].get("Labels", {}).get(LABEL) != self.name:
            raise Error("同名の管理対象外コンテナがあります。操作を中止しました")
        return info

    def start(self):
        info = self.inspect()
        if info:
            if not info["State"]["Running"]:
                raise Error("ブラウザが停止しています。close で片付けてから open してください")
            if info["Config"]["Image"] != self.image:
                raise Error("別のイメージで起動済みです。close してから切り替えてください")
            return info
        if docker("image", "inspect", self.image, check=False).returncode:
            raise Error(f"ブラウザイメージがありません。先に実行してください: docker pull {self.image}")
        docker(
            "run", "--detach", "--rm", "--init", "--name", self.name,
            "--label", f"{LABEL}={self.name}",
            "--publish", "127.0.0.1::9223", "--shm-size", "512m",
            "--cap-drop", "ALL", "--security-opt", "no-new-privileges",
            "--add-host", "host.docker.internal:host-gateway",
            "--entrypoint", "node", self.image, "-e", SERVER.read_text(),
        )
        try:
            info = self.inspect()
            if not info:
                raise Error("ブラウザが起動直後に終了しました")
            self.endpoint(info, timeout=20)
            return info
        except BaseException:
            docker("rm", "--force", self.name, check=False)
            raise

    @staticmethod
    def endpoint(info, timeout=3):
        bindings = info["NetworkSettings"]["Ports"].get("9223/tcp") or []
        if len(bindings) != 1 or bindings[0]["HostIp"] != "127.0.0.1":
            raise Error("CDP がローカルホストだけに公開されていません")
        address = f"127.0.0.1:{int(bindings[0]['HostPort'])}"
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        deadline = time.monotonic() + timeout
        while True:
            try:
                with opener.open(f"http://{address}/json/version", timeout=1) as response:
                    data = json.load(response)
                path = urllib.parse.urlsplit(data["webSocketDebuggerUrl"]).path
                if not path.startswith("/devtools/browser/"):
                    raise Error("ブラウザの CDP 接続先が不正です")
                return f"ws://{address}{path}"
            except (OSError, ValueError, KeyError, urllib.error.URLError):
                if time.monotonic() >= deadline:
                    raise Error("CDP に接続できません。ローカル Chrome は起動しません") from None
                time.sleep(0.2)

    def agent(self, endpoint, command):
        # 接続先を変える既存設定を継承せず、操作ごとに CDP を明示する。
        env = {key: value for key, value in os.environ.items() if not key.startswith("AGENT_BROWSER_")}
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json") as config:
            config.write("{}\n")
            config.flush()
            return subprocess.run([
                "agent-browser", "--config", config.name,
                "--namespace", self.namespace, "--session", self.session,
                "--cdp", endpoint, *command,
            ], env=env, timeout=15 if command == ["close"] else 120).returncode

    def close(self):
        info = self.inspect()
        if not info:
            print("終了済みです")
            return 0
        try:
            if info["State"]["Running"]:
                try:
                    endpoint = self.endpoint(info)
                except Error:
                    endpoint = None
                if endpoint and shutil.which("agent-browser"):
                    self.agent(endpoint, ["close"])
        finally:
            # デーモンの切断に失敗しても、このセッションのコンテナを片付ける。
            docker("rm", "--force", self.name)
        print("ブラウザコンテナを終了しました")
        return 0

    def execute(self, command):
        validate_command(command)
        if not shutil.which("docker"):
            raise Error("Docker がありません")
        docker("info", "--format", "{{.ServerVersion}}")
        if command[0] == "close":
            return self.close()
        if command[0] == "status":
            info = self.inspect()
            print(json.dumps({"container": self.name, "running": bool(info and info["State"]["Running"])}, ensure_ascii=False))
            return 0
        if not shutil.which("agent-browser"):
            raise Error("agent-browser がありません")
        first = shlex.split(command[1])[0] if command[0] == "batch" else command[0]
        info = self.start() if first in {"start", "open", "goto", "navigate"} else self.inspect()
        if not info or not info["State"]["Running"]:
            raise Error("ブラウザが起動していません。先に open <URL> を実行してください")
        endpoint = self.endpoint(info)
        if command[0] == "start":
            print(json.dumps({"container": self.name, "cdp": endpoint}, ensure_ascii=False))
            return 0
        return self.agent(endpoint, command)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", required=True, help="作業専用の名前。同じ作業では同じ名前を使う")
    parser.add_argument("--image", default=IMAGE, help="使用する Playwright イメージ（バージョン固定）")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="open / snapshot / click / screenshot / close など")
    args = parser.parse_args()
    try:
        browser = Browser(args.session, Path.cwd(), args.image)
        validate_command(args.command)
        lock = Path(tempfile.gettempdir()) / f"{browser.name}.lock"
        with lock.open("a") as stream:
            try:
                fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise Error("同じセッションの操作が実行中です。完了を待ってください") from None
            return browser.execute(args.command)
    except (Error, OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("中断しました。セッションを終了する場合は close を実行してください", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.exit(main())
