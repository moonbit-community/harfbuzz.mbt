#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "refs/harfbuzz/src/hb-ucd-table.hh"
OUT = ROOT / "src/unicode/ucd_data.mbt"

TEXT = SRC.read_text(encoding="utf-8")


def strip_comments(text: str) -> str:
    text = re.sub(r"/\\*.*?\\*/", "", text, flags=re.S)
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


def parse_array(name: str) -> tuple[int, list[str]]:
    idx = TEXT.find(name)
    if idx < 0:
        raise SystemExit(f"array {name} not found")
    snippet = TEXT[idx:]
    header = re.search(rf"{re.escape(name)}\[(\d+)\]\s*=\s*\{{", snippet)
    if not header:
        raise SystemExit(f"array {name} header not found")
    size = int(header.group(1))
    body_start = header.end()
    end_idx = snippet.find("};", body_start)
    if end_idx < 0:
        raise SystemExit(f"array {name} end not found")
    body = strip_comments(snippet[body_start:end_idx])
    tokens = split_tokens(body.replace("\n", " "))
    return size, tokens


def to_int(token: str) -> int:
    token = token.strip()
    if token.startswith("0x") or token.startswith("0X"):
        return int(token, 16)
    return int(token)


def encode3(a: int, b: int, c: int) -> int:
    return ((a & 0x1FFFFF) << 42) | ((b & 0x1FFFFF) << 21) | (c & 0x1FFFFF)


def encode3_11_7_14(a: int, b: int, c: int) -> int:
    return ((a & 0x07FF) << 21) | ((b & 0x007F) << 14) | (c & 0x3FFF)


def parse_dm2_tokens(tokens: list[str]) -> list[int]:
    out: list[int] = []
    for tok in tokens:
        tok = tok.strip()
        if tok.startswith("HB_CODEPOINT_ENCODE3_11_7_14"):
            inner = tok[tok.find("(") + 1 : tok.rfind(")")]
            parts = [p.strip() for p in inner.split(",")]
            a, b, c = (to_int(p) for p in parts)
            out.append(encode3_11_7_14(a, b, c))
        elif tok.startswith("HB_CODEPOINT_ENCODE3"):
            inner = tok[tok.find("(") + 1 : tok.rfind(")")]
            parts = [p.strip() for p in inner.split(",")]
            a, b, c = (to_int(p) for p in parts)
            out.append(encode3(a, b, c))
        else:
            out.append(to_int(tok))
    return out


def format_list(values: list[str], indent: str = "  ", per_line: int = 12) -> str:
    lines = []
    for i in range(0, len(values), per_line):
        lines.append(indent + ", ".join(values[i : i + per_line]) + ",")
    return "\n".join(lines)


def format_ints(values: list[int], per_line: int = 12) -> str:
    tokens = [f"{v}" for v in values]
    return format_list(tokens, per_line=per_line)


def format_hex(values: list[int], width: int, per_line: int = 12) -> str:
    fmt = "0x{:0" + str(width) + "X}"
    tokens = [fmt.format(v) for v in values]
    return format_list(tokens, per_line=per_line)


def script_name_to_common(token: str) -> str:
    token = token.strip()
    if not token.startswith("HB_SCRIPT_"):
        raise ValueError(f"unexpected script token: {token}")
    name = token[len("HB_SCRIPT_") :].lower()
    return f"@common.script_{name}"


def main() -> None:
    _, sc_tokens = parse_array("_hb_ucd_sc_map")
    sc_values = [script_name_to_common(t) for t in sc_tokens]

    _, dm1_p0_tokens = parse_array("_hb_ucd_dm1_p0_map")
    dm1_p0 = [to_int(t) for t in dm1_p0_tokens]

    _, dm1_p2_tokens = parse_array("_hb_ucd_dm1_p2_map")
    dm1_p2 = [to_int(t) for t in dm1_p2_tokens]

    _, dm2_u32_tokens = parse_array("_hb_ucd_dm2_u32_map")
    dm2_u32 = parse_dm2_tokens(dm2_u32_tokens)

    _, dm2_u64_tokens = parse_array("_hb_ucd_dm2_u64_map")
    dm2_u64 = parse_dm2_tokens(dm2_u64_tokens)

    _, u8_tokens = parse_array("_hb_ucd_u8")
    u8_vals = [to_int(t) for t in u8_tokens]

    _, u16_tokens = parse_array("_hb_ucd_u16")
    u16_vals = [to_int(t) for t in u16_tokens]

    _, i16_tokens = parse_array("_hb_ucd_i16")
    i16_vals = [int(t.strip()) for t in i16_tokens]

    content = []
    content.append("///|\n/// Generated from refs/harfbuzz/src/hb-ucd-table.hh.\n")

    content.append("///|\nlet ucd_sc_map : Array[@common.Script] = [\n" + format_list(sc_values) + "\n]\n")
    content.append("///|\nlet ucd_dm1_p0 : Array[UInt16] = [\n" + format_hex(dm1_p0, 4) + "\n]\n")
    content.append("///|\nlet ucd_dm1_p2 : Array[UInt16] = [\n" + format_hex(dm1_p2, 4) + "\n]\n")
    content.append("///|\nlet ucd_dm2_u32 : Array[UInt] = [\n" + format_hex(dm2_u32, 8) + "\n]\n")
    content.append("///|\nlet ucd_dm2_u64 : Array[UInt64] = [\n" + format_hex(dm2_u64, 16) + "\n]\n")
    content.append("///|\nlet ucd_u8 : Bytes = [\n" + format_ints(u8_vals) + "\n]\n")
    content.append("///|\nlet ucd_u16 : Array[UInt16] = [\n" + format_hex(u16_vals, 4) + "\n]\n")
    content.append("///|\nlet ucd_i16 : Array[Int16] = [\n" + format_ints(i16_vals) + "\n]\n")

    OUT.write_text("\n".join(content), encoding="utf-8")


if __name__ == "__main__":
    main()
