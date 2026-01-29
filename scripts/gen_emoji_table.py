#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "refs/harfbuzz/src/hb-unicode-emoji-table.hh"
OUT = ROOT / "src/unicode/emoji_data.mbt"

TEXT = SRC.read_text(encoding="utf-8")


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//.*", "", text)
    return text


def split_tokens(body: str) -> list[str]:
    tokens: list[str] = []
    current: list[str] = []
    depth = 0
    for ch in body:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth = max(0, depth - 1)
        elif ch == "," and depth == 0:
            token = "".join(current).strip()
            if token:
                tokens.append(token)
            current = []
            continue
        current.append(ch)
    tail = "".join(current).strip()
    if tail:
        tokens.append(tail)
    return tokens


def parse_array(name: str) -> list[int]:
    idx = TEXT.find(name)
    if idx < 0:
        raise SystemExit(f"array {name} not found")
    snippet = TEXT[idx:]
    header = re.search(rf"{re.escape(name)}\[(\d+)\]\s*=\s*\{{", snippet)
    if not header:
        raise SystemExit(f"array {name} header not found")
    body_start = header.end()
    end_idx = snippet.find("};", body_start)
    if end_idx < 0:
        raise SystemExit(f"array {name} end not found")
    body = strip_comments(snippet[body_start:end_idx])
    tokens = split_tokens(body.replace("\n", " "))
    return [int(t.strip(), 16) if t.strip().startswith("0x") else int(t.strip()) for t in tokens]


def format_list(values: list[str], indent: str = "  ", per_line: int = 12) -> str:
    lines = []
    for i in range(0, len(values), per_line):
        lines.append(indent + ", ".join(values[i : i + per_line]) + ",")
    return "\n".join(lines)


def format_ints(values: list[int], per_line: int = 16) -> str:
    tokens = [f"{v}" for v in values]
    return format_list(tokens, per_line=per_line)


def main() -> None:
    u8_vals = parse_array("_hb_emoji_u8")
    content = []
    content.append("///|\n/// Generated from refs/harfbuzz/src/hb-unicode-emoji-table.hh.\n")
    content.append("///|\nlet emoji_u8 : Bytes = [\n" + format_ints(u8_vals) + "\n]\n")
    OUT.write_text("\n".join(content), encoding="utf-8")


if __name__ == "__main__":
    main()
