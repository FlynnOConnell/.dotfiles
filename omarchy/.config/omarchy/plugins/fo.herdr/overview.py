"""
The fo.herdr bar widget's view of herdr: every agent's status, place, and what it's doing.

    overview.py watch          print the overview as a JSON line now and after every change
    overview.py focus PANE_ID  show that agent in herdr and raise the terminal attached to herdr

What an agent is doing comes from its Claude transcript: after the last prompt, the
latest recap (Claude's away summary, skipped while it works) or else the latest reply.
"""

import datetime
import json
import os
import re
import select
import socket
import subprocess
import sys
import time
from pathlib import Path

FILEPATH_HERDR_SOCKET = str(Path.home() / ".config" / "herdr" / "herdr.sock")
DIR_CLAUDE_PROJECTS = str(Path.home() / ".claude" / "projects")
SECONDS_REFRESH = 10
SECONDS_RETRY = 3
SECONDS_DEBOUNCE = 0.25
BYTES_TRANSCRIPT_SCAN = 16 * 2**20
CHARS_SUMMARY = 600
EVENTS_GLOBAL = [
    "pane.agent_detected",
    "pane.closed",
    "pane.exited",
    "tab.created",
    "tab.closed",
    "tab.renamed",
    "tab.moved",
    "workspace.created",
    "workspace.closed",
    "workspace.renamed",
    "workspace.reordered",
]


def request_herdr(method: str, params: dict) -> dict:
    """
    One request to the herdr server.

    Returns
    -------
    dict
        The response's ``result``.
    """
    with socket.socket(socket.AF_UNIX) as sock:
        sock.connect(FILEPATH_HERDR_SOCKET)
        sock.sendall((json.dumps({"id": method, "method": method, "params": params}) + "\n").encode())
        response = json.loads(sock.makefile("r").readline())
    if "error" in response:
        raise RuntimeError(f"herdr {method}: {response['error']}")
    return response["result"]


def subscribe_herdr(pane_ids: list) -> socket.socket:
    """
    Open a connection that receives herdr events for these agent panes and for layout changes.

    Returns
    -------
    socket.socket
        Readable whenever an event arrives; closed by herdr when its server stops.
    """
    subscriptions = [{"type": "pane.agent_status_changed", "pane_id": pane_id} for pane_id in pane_ids]
    subscriptions += [{"type": event} for event in EVENTS_GLOBAL]
    sock = socket.socket(socket.AF_UNIX)
    sock.connect(FILEPATH_HERDR_SOCKET)
    request = {"id": "subscribe", "method": "events.subscribe", "params": {"subscriptions": subscriptions}}
    sock.sendall((json.dumps(request) + "\n").encode())
    return sock


def wait_for_events(sock_events: socket.socket, seconds_timeout: float) -> bool:
    """
    Block until herdr sends events (draining a short burst of them) or the timeout passes.

    Returns
    -------
    bool
        False if herdr closed the connection.
    """
    readable, _, _ = select.select([sock_events], [], [], seconds_timeout)
    while readable:
        if sock_events.recv(65536) == b"":
            return False
        readable, _, _ = select.select([sock_events], [], [], SECONDS_DEBOUNCE)
    return True


def iterate_lines_reversed(filepath: str, bytes_max: int):
    """
    Yield the lines of a file from the last one back, reading at most ``bytes_max`` bytes.
    """
    with open(filepath, "rb") as file:
        position = file.seek(0, os.SEEK_END)
        position_stop = max(0, position - bytes_max)
        remainder = b""
        while position > position_stop:
            size_chunk = min(2**20, position - position_stop)
            position -= size_chunk
            file.seek(position)
            lines = (file.read(size_chunk) + remainder).split(b"\n")
            remainder = lines[0]
            yield from reversed(lines[1:])
        ## NOTE: a scan cut short by bytes_max leaves only part of a line in remainder
        if position == 0:
            yield remainder


def clean_text(text: str) -> str:
    """
    Flatten markdown and markup from a prompt or reply into one plain line.
    """
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"[*`#]+", "", text)
    text = " ".join(text.split())
    text = text.replace(" (disable recaps in /config)", "")
    return text[:CHARS_SUMMARY]


def text_of_content(content) -> str:
    """
    The text of a message's content, which is a string or a list of blocks.
    """
    if isinstance(content, str):
        return content
    return " ".join(block["text"] for block in content if block.get("type") == "text")


def summarize_transcript(filepath: str) -> dict:
    """
    The last prompt in a Claude transcript, and the newest recap and reply after it.

    Returns
    -------
    dict
        ``prompt``, ``recap`` and ``reply`` (cleaned text, possibly empty), and
        ``ms_prompt``, the prompt's time in epoch milliseconds (None if not found).
    """
    summary = {"prompt": "", "ms_prompt": None, "recap": "", "reply": ""}
    for line in iterate_lines_reversed(filepath=filepath, bytes_max=BYTES_TRANSCRIPT_SCAN):
        ## NOTE: the substring test only spares parsing big records (tool results, api requests) that can't match
        if not (b'"away_summary"' in line or b'"type":"assistant"' in line or b'"origin":{"kind":"human"}' in line):
            continue
        ## NOTE: Claude may be writing the last line right now
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue
        if record.get("isSidechain"):
            continue
        if record.get("subtype") == "away_summary" and summary["recap"] == "":
            summary["recap"] = clean_text(record["content"])
        elif record["type"] == "assistant" and summary["reply"] == "":
            summary["reply"] = clean_text(text_of_content(record["message"]["content"]))
        elif record["type"] == "user" and record.get("origin", {}).get("kind") == "human":
            summary["prompt"] = clean_text(text_of_content(record["message"]["content"]))
            summary["ms_prompt"] = int(datetime.datetime.fromisoformat(record["timestamp"]).timestamp() * 1000)
            break
    return summary


def find_transcript(session_id: str, filepaths_bySession: dict) -> str | None:
    """
    The transcript of a Claude session, searched for once and then remembered.
    """
    if session_id not in filepaths_bySession:
        matches = sorted(Path(DIR_CLAUDE_PROJECTS).glob(f"*/{session_id}.jsonl"))
        filepaths_bySession[session_id] = str(matches[0]) if matches else None
    return filepaths_bySession[session_id]


def summarize_agent(agent: dict, filepaths_bySession: dict, summaries_byFilepath: dict) -> dict:
    """
    The transcript summary of a herdr agent, reread only when its transcript has changed.

    Returns
    -------
    dict
        As from ``summarize_transcript``, plus ``ms_active``: when the transcript was last written.
    """
    session = agent.get("agent_session") or {}
    filepath = None
    if agent["agent"] == "claude" and session.get("kind") == "id":
        filepath = find_transcript(session_id=session["value"], filepaths_bySession=filepaths_bySession)
    if filepath is None or not os.path.exists(filepath):
        return {"prompt": "", "ms_prompt": None, "recap": "", "reply": "", "ms_active": None}
    stat = os.stat(filepath)
    key = (stat.st_size, stat.st_mtime_ns)
    if summaries_byFilepath.get(filepath, (None, None))[0] != key:
        summary = summarize_transcript(filepath=filepath)
        summary["ms_active"] = stat.st_mtime_ns // 1_000_000
        summaries_byFilepath[filepath] = (key, summary)
    return summaries_byFilepath[filepath][1]


def build_overview(snapshot: dict, filepaths_bySession: dict, summaries_byFilepath: dict) -> dict:
    """
    One entry per agent, in herdr's workspace and tab order.
    """
    indices_workspace = {workspace["workspace_id"]: index for index, workspace in enumerate(snapshot["workspaces"])}
    labels_workspace = {workspace["workspace_id"]: workspace["label"] for workspace in snapshot["workspaces"]}
    tabs = {tab["tab_id"]: tab for tab in snapshot["tabs"]}
    agents = []
    for agent in snapshot["agents"]:
        summary = summarize_agent(agent=agent, filepaths_bySession=filepaths_bySession, summaries_byFilepath=summaries_byFilepath)
        if summary["recap"] != "" and agent["agent_status"] != "working":
            kind_summary, text_summary = "recap", summary["recap"]
        elif summary["reply"] != "":
            kind_summary, text_summary = "reply", summary["reply"]
        else:
            kind_summary, text_summary = "prompt", summary["prompt"]
        tab = tabs.get(agent["tab_id"], {})
        agents.append(
            {
                "pane_id": agent["pane_id"],
                "agent": agent["agent"],
                "status": agent["agent_status"],
                "title": agent.get("terminal_title_stripped") or agent["agent"],
                "workspace": labels_workspace.get(agent["workspace_id"], agent["workspace_id"]),
                "workspace_index": indices_workspace.get(agent["workspace_id"], 0),
                "tab": tab.get("label", ""),
                "tab_number": tab.get("number", 0),
                "cwd": agent.get("cwd", ""),
                "summary": text_summary,
                "summary_kind": kind_summary,
                "prompt": summary["prompt"],
                "ms_prompt": summary["ms_prompt"],
                ## NOTE: a working agent writes its transcript every few seconds; its age is ms_prompt's
                "ms_active": None if agent["agent_status"] == "working" else summary["ms_active"],
            }
        )
    agents.sort(key=lambda entry: (entry["workspace_index"], entry["tab_number"], entry["pane_id"]))
    return {"ok": True, "agents": agents}


def watch() -> None:
    """
    Print the overview as a JSON line at start and whenever it changes, until killed.
    """
    filepaths_bySession, summaries_byFilepath = {}, {}
    line_last, sock_events, pane_ids_subscribed = None, None, None
    while True:
        try:
            snapshot = request_herdr(method="session.snapshot", params={})["snapshot"]
            line = json.dumps(build_overview(snapshot=snapshot, filepaths_bySession=filepaths_bySession, summaries_byFilepath=summaries_byFilepath))
            pane_ids = sorted(agent["pane_id"] for agent in snapshot["agents"])
            if sock_events is None or pane_ids != pane_ids_subscribed:
                if sock_events is not None:
                    sock_events.close()
                sock_events, pane_ids_subscribed = subscribe_herdr(pane_ids=pane_ids), pane_ids
        except (FileNotFoundError, ConnectionRefusedError):
            line = json.dumps({"ok": False, "error": "herdr isn't running", "agents": []})
            if sock_events is not None:
                sock_events.close()
            sock_events = None
        if line != line_last:
            print(line, flush=True)
            line_last = line
        if sock_events is None:
            time.sleep(SECONDS_RETRY)
        elif not wait_for_events(sock_events=sock_events, seconds_timeout=SECONDS_REFRESH):
            sock_events.close()
            sock_events = None


def find_herdr_terminal() -> dict | None:
    """
    The Hyprland window of the terminal attached to the local herdr session, most recently focused first.
    """
    clients = json.loads(subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, check=True).stdout)
    clients_byPid = {client["pid"]: client for client in clients}
    found = []
    for dir_process in Path("/proc").glob("[0-9]*"):
        try:
            argv = (dir_process / "cmdline").read_bytes().split(b"\0")[:-1]
        except OSError:
            continue
        if not argv or os.path.basename(argv[0]) != b"herdr":
            continue
        is_attached_client = len(argv) == 1 or argv[1] == b"--session"
        if not is_attached_client:
            continue
        pid = int(dir_process.name)
        while pid > 1 and pid not in clients_byPid:
            pid = int((Path("/proc") / str(pid) / "stat").read_text().rsplit(")", 1)[1].split()[1])
        if pid in clients_byPid:
            found.append(clients_byPid[pid])
    return min(found, key=lambda client: client["focusHistoryID"]) if found else None


def focus(pane_id: str) -> None:
    """
    Show an agent in herdr and raise the terminal attached to herdr, opening one if there's none.
    """
    subprocess.run(["herdr", "agent", "focus", pane_id], capture_output=True, check=True)
    terminal = find_herdr_terminal()
    if terminal is None:
        subprocess.Popen(["omarchy-launch-terminal-herdr"], start_new_session=True)
        return
    dispatch = f'hl.dsp.focus({{ window = "address:{terminal["address"]}" }})'
    subprocess.run(["hyprctl", "dispatch", dispatch], capture_output=True, check=True)


if __name__ == "__main__":
    if sys.argv[1:2] == ["watch"]:
        watch()
    elif sys.argv[1:2] == ["focus"] and len(sys.argv) == 3:
        focus(pane_id=sys.argv[2])
    else:
        sys.exit(__doc__)
