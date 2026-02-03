#!/usr/bin/env python3
from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "src/unicode/emoji_data.mbt"
LOCAL = ROOT / "scripts/emoji-data.txt"
URL = "https://www.unicode.org/Public/17.0.0/ucd/emoji/emoji-data.txt"

PROPS = [
    "Emoji",
    "Emoji_Presentation",
    "Emoji_Modifier",
    "Emoji_Modifier_Base",
    "Emoji_Component",
    "Extended_Pictographic",
]

NAME_MAP = {
    "Emoji": "emoji_ranges",
    "Emoji_Presentation": "emoji_presentation_ranges",
    "Emoji_Modifier": "emoji_modifier_ranges",
    "Emoji_Modifier_Base": "emoji_modifier_base_ranges",
    "Emoji_Component": "emoji_component_ranges",
    "Extended_Pictographic": "extended_pictographic_ranges",
}


def load_emoji_data() -> tuple[str, str]:
    if LOCAL.exists():
        return LOCAL.read_text(encoding="utf-8"), "scripts/emoji-data.txt"
    with urllib.request.urlopen(URL) as resp:
        return resp.read().decode("utf-8"), URL


def parse_ranges(text: str) -> dict[str, list[tuple[int, int]]]:
    ranges: dict[str, list[tuple[int, int]]] = {prop: [] for prop in PROPS}
    for line in text.splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        fields = [f.strip() for f in line.split(";")]
        if len(fields) < 2:
            continue
        rang, prop = fields[0], fields[1]
        if prop not in ranges:
            continue
        if ".." in rang:
            start_s, end_s = rang.split("..", 1)
            start = int(start_s, 16)
            end = int(end_s, 16)
        else:
            start = end = int(rang, 16)
        lst = ranges[prop]
        if lst and lst[-1][1] + 1 == start:
            lst[-1] = (lst[-1][0], end)
        else:
            lst.append((start, end))
    return ranges


def format_ranges(values: list[tuple[int, int]]) -> str:
    lines: list[str] = []
    for start, end in values:
        lines.append(f"  (0x{start:X}U, 0x{end:X}U),")
    return "\n".join(lines)


def main() -> None:
    text, source = load_emoji_data()
    ranges = parse_ranges(text)
    content: list[str] = []
    content.append("///|")
    content.append(f"/// Generated from {source}.")
    content.append("")
    for prop in PROPS:
        name = NAME_MAP[prop]
        content.append("///|")
        content.append(f"let {name} : Array[(UInt, UInt)] = [")
        content.append(format_ranges(ranges[prop]))
        content.append("]")
        content.append("")
    OUT.write_text("\n".join(content).rstrip() + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
