#!/usr/bin/env python3
"""What a Claude Code session cost in tokens, and how long it ran, read from the session logs on your machine.

    python3 cost_from_logs.py                      # the 10 latest sessions started in THIS folder
    python3 cost_from_logs.py --folder <path>      # the 10 latest sessions started in another folder
    python3 cost_from_logs.py --latest 3           # how many to show
    python3 cost_from_logs.py <session.jsonl> ...  # specific log files

Claude Code keeps one log per session in ~/.claude/projects/<the folder path with every symbol turned into ->/.
Agents a session started are logged in <session id>/subagents/ beside it and are added to the session's total.

Prices are list prices in dollars per million tokens, taken from the Anthropic pricing page
(https://platform.claude.com/docs/en/about-claude/pricing) on 8 Oct 2026: input, output, 5-minute cache write,
1-hour cache write, cache hit. Prices change: check the page and edit PRICE below if they have moved. A model not in PRICE is reported
but not costed.

Two honest limits:
- OUTPUT TOKENS ARE ESTIMATED. The log records the output count when a reply starts, which undercounts. The
  script also counts the characters actually written (text plus tool inputs, about 3.6 characters a token) and
  uses whichever is larger. Treat output cost as close, not exact.
- This is the token cost only. Anything paid to another service during the run (music on fal.ai, for example)
  is not in the log.
"""
import argparse, glob, json, os, re, sys
from datetime import datetime

PRICE = {  # input, output, cache write 5m, cache write 1h, cache hit  ($ per million tokens, 8 Oct 2026)
    "claude-opus-5-5": (4.0, 20.0, 5.0, 8.0, 0.20),
    "claude-sonnet-5-5": (2.0, 10.0, 2.5, 4.0, 0.10),
}


def projects_dir():
    base = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
    return os.path.join(base, "projects")


def folder_logs(folder):
    name = re.sub(r"[^A-Za-z0-9]", "-", os.path.abspath(folder))
    d = os.path.join(projects_dir(), name)
    if not os.path.isdir(d):
        sys.exit(f"No Claude Code logs for {folder}\n(looked in {d})\nStart a session in that folder first, or pass log files directly.")
    return sorted(glob.glob(os.path.join(d, "*.jsonl")), key=os.path.getmtime, reverse=True)


def read(path, msgs, chars, times):
    for line in open(path, encoding="utf-8", errors="ignore"):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if d.get("timestamp"):
            times.append(d["timestamp"])
        m = d.get("message")
        if not isinstance(m, dict) or not m.get("usage") or not m.get("id"):
            continue
        content = m.get("content") if isinstance(m.get("content"), list) else []
        chars[m["id"]] = chars.get(m["id"], 0) + sum(
            len(b.get("text", "")) + len(json.dumps(b.get("input", "")))
            for b in content if isinstance(b, dict) and b.get("type") in ("text", "tool_use"))
        old = msgs.get(m["id"])  # one API reply is logged once per content block: keep the fullest copy
        if old is None or m["usage"].get("output_tokens", 0) >= old["usage"].get("output_tokens", 0):
            msgs[m["id"]] = m


def session(path):
    msgs, chars, times = {}, {}, []
    read(path, msgs, chars, times)
    subs = glob.glob(os.path.join(path[:-6], "subagents", "*.jsonl"))
    for s in subs:
        read(s, msgs, chars, times)
    by_model, cost, uncosted = {}, 0.0, set()
    for mid, m in msgs.items():
        model = m.get("model") or "?"
        u = m["usage"]
        cc = u.get("cache_creation") or {}
        w5 = cc.get("ephemeral_5m_input_tokens", 0) if cc else u.get("cache_creation_input_tokens", 0)
        w1 = cc.get("ephemeral_1h_input_tokens", 0) if cc else 0
        t = by_model.setdefault(model, dict(replies=0, inp=0, out=0, w5=0, w1=0, rd=0))
        t["replies"] += 1
        t["inp"] += u.get("input_tokens", 0)
        t["out"] += max(u.get("output_tokens", 0), round(chars.get(mid, 0) / 3.6))
        t["w5"] += w5
        t["w1"] += w1
        t["rd"] += u.get("cache_read_input_tokens", 0)
    for model, t in by_model.items():
        p = PRICE.get(model)
        if p is None:
            uncosted.add(model)
            continue
        cost += (t["inp"] * p[0] + t["out"] * p[1] + t["w5"] * p[2] + t["w1"] * p[3] + t["rd"] * p[4]) / 1e6
    secs = 0
    if times:
        ts = sorted(datetime.fromisoformat(x.replace("Z", "+00:00")) for x in times)
        secs = (ts[-1] - ts[0]).total_seconds()
    return by_model, cost, uncosted, secs, len(subs)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("logs", nargs="*")
    ap.add_argument("--folder", default=".")
    ap.add_argument("--latest", type=int, default=10)
    a = ap.parse_args()
    paths = a.logs or folder_logs(a.folder)[: a.latest]
    for p in paths:
        by_model, cost, uncosted, secs, nsub = session(p)
        if not by_model:
            continue
        sid = os.path.basename(p)[:-6]
        when = datetime.fromtimestamp(os.path.getmtime(p)).strftime("%d %b %H:%M")
        print(f"{sid}  (last active {when}{f', {nsub} agent log(s) included' if nsub else ''})")
        for model, t in by_model.items():
            print(f"  {model}: {t['replies']} replies  in {t['inp']:,}  out (estimated) {t['out']:,}  "
                  f"cache write {t['w5'] + t['w1']:,}  cache read {t['rd']:,}")
        line = f"  wall time {int(secs // 60)}m{int(secs % 60):02d}s   token cost ${cost:.2f}"
        if uncosted:
            line += f"   (not costed, no price set: {', '.join(sorted(uncosted))})"
        print(line + "\n")


if __name__ == "__main__":
    main()
