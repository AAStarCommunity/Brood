#!/usr/bin/env python3
"""port skill — 列出本机在监听的 web 服务并支持按 ID kill。

用法:
  port.py list [--all]        扫描监听端口, 探测 HTTP, 抓取 title, 输出 markdown 表格
  port.py kill <ID...> [-9]   按上次 list 的 ID 杀掉对应进程 (kill 前重新核对 pid/端口)
                              支持多个 ID 和区间, 如: kill 1 3 5-8

状态文件: ~/.cache/claude-port/state.json (list 时写入, kill 时读取)
"""

import json
import os
import re
import signal
import ssl
import subprocess
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

STATE_DIR = os.path.expanduser("~/.cache/claude-port")
STATE_FILE = os.path.join(STATE_DIR, "state.json")
HTTP_TIMEOUT = 2.5
TITLE_READ_LIMIT = 65536


def scan_listeners():
    """返回 [{port, pid, name}], 按端口去重排序。只扫当前用户可见的进程。"""
    out = subprocess.run(
        ["lsof", "-nP", "-iTCP", "-sTCP:LISTEN"],
        capture_output=True, text=True,
    ).stdout
    seen = {}
    for line in out.splitlines()[1:]:
        parts = line.split()
        if len(parts) < 9:
            continue
        name, pid, addr = parts[0], parts[1], parts[8]
        m = re.search(r":(\d+)$", addr)
        if not m:
            continue
        port = int(m.group(1))
        # 同一端口 IPv4/IPv6 重复行只保留一条
        if port not in seen:
            seen[port] = {"port": port, "pid": int(pid), "name": name}
    return sorted(seen.values(), key=lambda x: x["port"])


def probe(entry):
    """探测端口是否为 web 服务; 是则填入 url 和 title, 否则 url=None。"""
    port = entry["port"]
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    for scheme in ("http", "https"):
        url = f"{scheme}://localhost:{port}/"
        req = urllib.request.Request(url, headers={"User-Agent": "port-skill/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT, context=ctx) as resp:
                body = resp.read(TITLE_READ_LIMIT)
                entry["url"] = url
                entry["status"] = resp.status
                entry["title"] = extract_title(body) or "(无 title)"
                return entry
        except urllib.error.HTTPError as e:
            # 4xx/5xx 也是 HTTP 服务在响应
            entry["url"] = url
            entry["status"] = e.code
            try:
                entry["title"] = extract_title(e.read(TITLE_READ_LIMIT)) or f"(HTTP {e.code})"
            except Exception:
                entry["title"] = f"(HTTP {e.code})"
            return entry
        except Exception:
            continue
    entry["url"] = None
    entry["title"] = None
    return entry


def extract_title(body):
    for enc in ("utf-8", "gbk", "latin-1"):
        try:
            text = body.decode(enc, errors="ignore")
            break
        except Exception:
            continue
    m = re.search(r"<title[^>]*>(.*?)</title>", text, re.IGNORECASE | re.DOTALL)
    if not m:
        return None
    title = re.sub(r"\s+", " ", m.group(1)).strip()
    return title[:80] if title else None


def cmd_list(show_all=False):
    listeners = scan_listeners()
    if not listeners:
        print("没有发现任何处于 LISTEN 状态的 TCP 端口。")
        return
    with ThreadPoolExecutor(max_workers=16) as ex:
        results = list(ex.map(probe, listeners))

    web = [r for r in results if r["url"]]
    other = [r for r in results if not r["url"]]

    state = []
    print("| ID | Title | URL | Port | 进程 | PID |")
    print("|---:|---|---|---:|---|---:|")
    for i, r in enumerate(web, 1):
        title = (r["title"] or "").replace("|", "\\|")
        print(f"| {i} | {title} | {r['url']} | {r['port']} | {r['name']} | {r['pid']} |")
        state.append({"id": i, "port": r["port"], "pid": r["pid"],
                      "name": r["name"], "title": r["title"], "url": r["url"]})

    os.makedirs(STATE_DIR, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump({"ts": time.time(), "entries": state}, f, ensure_ascii=False, indent=2)

    if other:
        if show_all:
            print("\n非 HTTP 的监听端口 (不参与 kill 编号):")
            print("| Port | 进程 | PID |")
            print("|---:|---|---:|")
            for r in other:
                print(f"| {r['port']} | {r['name']} | {r['pid']} |")
        else:
            ports = ", ".join(str(r["port"]) for r in other[:20])
            print(f"\n另有 {len(other)} 个非 HTTP 监听端口未列出 ({ports})，加 --all 查看。")


def kill_one(state, target_id, force=False):
    entry = next((e for e in state["entries"] if e["id"] == target_id), None)
    if entry is None:
        print(f"跳过 [{target_id}]: 不在上次 list 的列表里 (共 {len(state['entries'])} 项)，请重新 list。")
        return

    # kill 前重新核对: 该 pid 是否仍在监听该端口, 防止 pid 被复用误杀
    current = {e["port"]: e for e in scan_listeners()}
    live = current.get(entry["port"])
    if live is None or live["pid"] != entry["pid"]:
        print(
            f"跳过 [{target_id}] 端口 {entry['port']}: 进程已变化 (记录 pid={entry['pid']}, "
            f"当前 {'无监听' if live is None else 'pid=' + str(live['pid'])})。"
            "为避免误杀未执行，请重新 list。"
        )
        return

    sig = signal.SIGKILL if force else signal.SIGTERM
    try:
        os.kill(entry["pid"], sig)
    except OSError as e:
        print(f"跳过 [{target_id}] pid {entry['pid']}: kill 失败 ({e})")
        return
    desc = f"[{entry['id']}] {entry['title']} — {entry['url']} (pid {entry['pid']}, {entry['name']})"
    if force:
        print(f"已发送 SIGKILL: {desc}")
        return
    # SIGTERM 后等待确认
    for _ in range(10):
        time.sleep(0.3)
        try:
            os.kill(entry["pid"], 0)
        except OSError:
            print(f"已终止: {desc}")
            return
    print(f"已发送 SIGTERM 但进程仍在运行: {desc}\n可用 `kill {entry['id']} -9` 强制终止。")


def parse_ids(tokens):
    """把 ["1", "3", "5-8"] 解析成 [1, 3, 5, 6, 7, 8]。"""
    ids = []
    for t in tokens:
        m = re.fullmatch(r"(\d+)-(\d+)", t)
        if m:
            ids.extend(range(int(m.group(1)), int(m.group(2)) + 1))
        elif t.isdigit():
            ids.append(int(t))
    return sorted(set(ids))


def cmd_kill(ids, force=False):
    if not os.path.exists(STATE_FILE):
        sys.exit("没有找到上次 list 的记录，请先运行 list。")
    with open(STATE_FILE) as f:
        state = json.load(f)
    for target_id in ids:
        kill_one(state, target_id, force=force)


def main():
    args = sys.argv[1:]
    if not args or args[0] == "list":
        cmd_list(show_all="--all" in args)
    elif args[0] == "kill":
        ids = parse_ids(args[1:])
        if not ids:
            sys.exit("用法: port.py kill <ID...> [-9]  (支持区间, 如 kill 1 3 5-8)")
        cmd_kill(ids, force="-9" in args or "--force" in args)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
