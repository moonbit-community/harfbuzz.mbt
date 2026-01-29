#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HH = ROOT / "refs/harfbuzz/src/hb-unicode.hh"
CC = ROOT / "refs/harfbuzz/src/hb-unicode.cc"
OUT = ROOT / "src/unicode/modified_combining_class.mbt"

hh_text = HH.read_text(encoding="utf-8")
cc_text = CC.read_text(encoding="utf-8")

MACRO_RE = re.compile(r"#define\s+(HB_MODIFIED_COMBINING_CLASS_CCC\d+)\s+(\d+)")


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


def parse_macros() -> dict[str, int]:
    macros: dict[str, int] = {}
    for m in MACRO_RE.finditer(hh_text):
        macros[m.group(1)] = int(m.group(2))
    return macros


def parse_array() -> list[int]:
    name = "_hb_modified_combining_class"
    idx = cc_text.find(name)
    if idx < 0:
        raise SystemExit("modified combining class array not found")
    snippet = cc_text[idx:]
    header = re.search(rf"{re.escape(name)}\[\d+\]\s*=\s*\{{", snippet)
    if not header:
        raise SystemExit("array header not found")
    body_start = header.end()
    end_idx = snippet.find("};", body_start)
    if end_idx < 0:
        raise SystemExit("array end not found")
    body = strip_comments(snippet[body_start:end_idx])
    tokens = split_tokens(body.replace("\n", " "))
    return tokens


def format_list(values: list[str], indent: str = "  ", per_line: int = 16) -> str:
    lines = []
    for i in range(0, len(values), per_line):
        lines.append(indent + ", ".join(values[i : i + per_line]) + ",")
    return "\n".join(lines)


def main() -> None:
    macros = parse_macros()
    tokens = parse_array()
    values: list[str] = []
    for tok in tokens:
        tok = tok.strip()
        if not tok:
            continue
        if tok in macros:
            values.append(str(macros[tok]))
        else:
            values.append(tok)
    content = []
    content.append("///|\n/// Generated from refs/harfbuzz/src/hb-unicode.cc and hb-unicode.hh.\n")
    content.append("///|\nlet modified_combining_class_map : Bytes = [\n" + format_list(values) + "\n]\n")
    OUT.write_text("\n".join(content), encoding="utf-8")


if __name__ == "__main__":
    main()
