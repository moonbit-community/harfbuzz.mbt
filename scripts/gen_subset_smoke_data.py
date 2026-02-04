#!/usr/bin/env python3
from __future__ import annotations

import pathlib
from typing import Iterable

ROOT = pathlib.Path(__file__).resolve().parents[1]
TESTS_DIR = ROOT / "refs/harfbuzz/test/subset/data/tests"
FONTS_DIR = ROOT / "refs/harfbuzz/test/subset/data/fonts"
EXPECTED_DIR = ROOT / "refs/harfbuzz/test/subset/data/expected"
OUT = ROOT / "src/subset/subset_data_gen.mbt"

SUPPORTED_PROFILE = "default.txt"
SKIP_SUBSETS = {"*", "no-unicodes"}
MAX_MAP_BYTES = 1_000_000
SKIP_SUITES = {
    "cbdt.tests",
    "cff-japanese.tests",
    "colr.tests",
    "colr_glyphs.tests",
    "colr_with_components.tests",
    "colrv1.tests",
    "full-font.tests",
    "japanese.tests",
    "layout.duplicate_features.tests",
    "layout.gdef-attachlist.tests",
    "layout.gdef.glyphset.tests",
    "layout.gdef.tests",
    "layout.gpos8.amiri.tests",
    "layout.khmer.tests",
    "layout.notonastaliqurdu.tests",
    "layout.tinos.tests",
    "layout.unsorted_featurelist.tests",
    "layout.tests",
    "post.tests",
    "variable.tests",
}
SUITE_FONT_ALLOW = {
    "basics.tests": {"Roboto-Regular.abc.ttf"},
}


def chunk_escape(data: bytes, chunk_size: int = 120) -> Iterable[str]:
    hexed = "".join(f"\\x{b:02x}" for b in data)
    for i in range(0, len(hexed), chunk_size):
        yield hexed[i : i + chunk_size]


def bytes_literal_parts(data: bytes) -> list[str]:
    parts = list(chunk_escape(data))
    return [f'b"{part}"' for part in parts] or ['b""']


def chunk_entries(
    entries: list[tuple[str, bytes]],
    max_bytes: int,
) -> list[list[tuple[str, bytes]]]:
    chunks: list[list[tuple[str, bytes]]] = []
    current: list[tuple[str, bytes]] = []
    current_size = 0
    for key, data in entries:
        size = len(data)
        if current and current_size + size > max_bytes:
            chunks.append(current)
            current = []
            current_size = 0
        current.append((key, data))
        current_size += size
    if current:
        chunks.append(current)
    return chunks


def emit_map_parts(
    lines: list[str],
    prefix: str,
    entries: list[tuple[str, bytes]],
) -> None:
    chunks = chunk_entries(entries, MAX_MAP_BYTES)
    for index, chunk in enumerate(chunks):
        lines.append("///|")
        lines.append(f"fn {prefix}_part_{index}() -> Map[String, Bytes] {{")
        lines.append("  {")
        for key, data in chunk:
            parts = bytes_literal_parts(data)
            if len(parts) == 1:
                lines.append(f'    "{key}": {parts[0]},')
            else:
                lines.append(f'    "{key}": concat_bytes([')
                for part in parts:
                    lines.append(f"      {part},")
                lines.append("    ]),")
        lines.append("  }")
        lines.append("}")
        lines.append("")
    lines.append("///|")
    lines.append(f"let {prefix} : Map[String, Bytes] = merge_byte_maps([")
    for index in range(len(chunks)):
        lines.append(f"  {prefix}_part_{index}(),")
    lines.append("])")
    lines.append("")


def parse_suite(definition: str) -> dict[str, list[str]]:
    destinations = {
        "FONTS:": [],
        "PROFILES:": [],
        "SUBSETS:": [],
        "INSTANCES:": [],
        "OPTIONS:": [],
        "IUP_OPTIONS:": [],
    }
    current: list[str] | None = None
    for raw in definition.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line in destinations:
            current = destinations[line]
            continue
        if current is None:
            raise RuntimeError("Failed to parse test suite file.")
        current.append(line)
    return {
        "fonts": destinations["FONTS:"],
        "profiles": destinations["PROFILES:"],
        "subsets": destinations["SUBSETS:"],
        "instances": destinations["INSTANCES:"],
        "options": destinations["OPTIONS:"],
        "iup_options": destinations["IUP_OPTIONS:"],
    }


def unicodes(subset: str) -> str:
    if subset == "*":
        return "all"
    if subset == "no-unicodes":
        return "no-unicodes"
    if subset.startswith("U+"):
        return subset.replace("U+", "")
    return ",".join(f"{ord(c):X}" for c in subset)


def expected_name(font_name: str, profile_name: str, subset: str) -> str:
    font_base = pathlib.Path(font_name).stem
    font_ext = pathlib.Path(font_name).suffix
    profile_base = pathlib.Path(profile_name).stem
    unicode_str = unicodes(subset)
    return f"{font_base}.{profile_base}.{unicode_str}{font_ext}"


def filter_suite(
    suite_name: str,
    parsed: dict[str, list[str]],
) -> dict[str, list[str]] | None:
    if suite_name in SKIP_SUITES:
        return None
    if parsed["instances"] or parsed["options"] or parsed["iup_options"]:
        return None
    if SUPPORTED_PROFILE not in parsed["profiles"]:
        return None
    fonts = parsed["fonts"]
    if suite_name in SUITE_FONT_ALLOW:
        fonts = [font for font in fonts if font in SUITE_FONT_ALLOW[suite_name]]
    if not fonts:
        return None
    subsets: list[str] = []
    for subset in parsed["subsets"]:
        if subset in SKIP_SUBSETS:
            continue
        missing = False
        for font_name in fonts:
            expected_path = (
                EXPECTED_DIR
                / pathlib.Path(suite_name).stem
                / expected_name(font_name, SUPPORTED_PROFILE, subset)
            )
            if not expected_path.exists():
                missing = True
                break
        if not missing:
            subsets.append(subset)
    if not subsets:
        return None
    return {
        "fonts": fonts,
        "profiles": [SUPPORTED_PROFILE],
        "subsets": subsets,
        "instances": [],
        "options": [],
        "iup_options": [],
    }


def emit() -> None:
    suites: list[tuple[str, dict[str, list[str]]]] = []
    fonts_needed: set[str] = set()
    expected_needed: dict[str, pathlib.Path] = {}
    case_count = 0

    for path in sorted(TESTS_DIR.glob("*.tests")):
        suite_name = path.name
        definition = path.read_text(encoding="utf-8")
        parsed = parse_suite(definition)
        filtered = filter_suite(suite_name, parsed)
        if filtered is None:
            continue
        suites.append((suite_name, filtered))

        suite_base = path.stem
        for font_name in filtered["fonts"]:
            fonts_needed.add(font_name)
            for profile_name in filtered["profiles"]:
                for subset in filtered["subsets"]:
                    expected_file = expected_name(font_name, profile_name, subset)
                    expected_path = EXPECTED_DIR / suite_base / expected_file
                    if not expected_path.exists():
                        raise RuntimeError(f"expected file missing: {expected_path}")
                    key = f"{suite_base}/{expected_file}"
                    expected_needed[key] = expected_path
                    case_count += 1

    lines: list[str] = []
    lines.append("///|")
    lines.append("/// Generated by scripts/gen_subset_smoke_data.py; do not edit.")
    lines.append("pub struct SubsetDataSuite {")
    lines.append("  name : String")
    lines.append("  definition : String")
    lines.append("} derive(Show, ToJson)")
    lines.append("")
    lines.append("///|")
    lines.append("pub let subset_data_suites : Array[SubsetDataSuite] = [")
    for suite_name, parsed in suites:
        def_lines: list[str] = []
        def_lines.append("FONTS:")
        def_lines.extend(parsed["fonts"])
        def_lines.append("")
        def_lines.append("PROFILES:")
        def_lines.extend(parsed["profiles"])
        def_lines.append("")
        def_lines.append("SUBSETS:")
        for subset in parsed["subsets"]:
            if all(ord(ch) < 128 for ch in subset):
                def_lines.append(subset)
            else:
                def_lines.append(",".join(f"U+{ord(ch):X}" for ch in subset))
        def_lines.append("")
        lines.append("  SubsetDataSuite::{")
        lines.append(f'    name: "{suite_name}",')
        lines.append("    definition:")
        lines.append("      (")
        for def_line in def_lines:
            lines.append(f"        #|{def_line}")
        lines.append("      )")
        lines.append("  },")
    lines.append("]")
    lines.append("")
    lines.append("///|")
    lines.append("fn concat_bytes(parts : Array[Bytes]) -> Bytes {")
    lines.append('  if parts.is_empty() {')
    lines.append('    b""')
    lines.append("  } else {")
    lines.append("    let mut total = 0")
    lines.append("    for part in parts {")
    lines.append("      total = total + part.length()")
    lines.append("    }")
    lines.append("    let out : Array[Byte] = Array::make(total, 0)")
    lines.append("    let mut offset = 0")
    lines.append("    for part in parts {")
    lines.append("      for b in part {")
    lines.append("        out[offset] = b")
    lines.append("        offset = offset + 1")
    lines.append("      }")
    lines.append("    }")
    lines.append("    Bytes::from_array(out)")
    lines.append("  }")
    lines.append("}")
    lines.append("")
    lines.append("///|")
    lines.append("fn merge_byte_maps(parts : Array[Map[String, Bytes]]) -> Map[String, Bytes] {")
    lines.append("  let out : Map[String, Bytes] = {}")
    lines.append("  for part in parts {")
    lines.append("    for key, value in part {")
    lines.append("      out[key] = value")
    lines.append("    }")
    lines.append("  }")
    lines.append("  out")
    lines.append("}")
    lines.append("")
    lines.append("///|")
    lines.append(f"pub let subset_data_case_count : Int = {case_count}")
    lines.append("")

    font_entries: list[tuple[str, bytes]] = []
    for font_name in sorted(fonts_needed):
        data = (FONTS_DIR / font_name).read_bytes()
        font_entries.append((font_name, data))
    emit_map_parts(lines, "subset_data_fonts", font_entries)
    lines.append("///|")
    lines.append("pub fn subset_data_font_bytes(name : String) -> Bytes? {")
    lines.append("  subset_data_fonts.get(name)")
    lines.append("}")
    lines.append("")

    expected_entries: list[tuple[str, bytes]] = []
    for key in sorted(expected_needed.keys()):
        data = expected_needed[key].read_bytes()
        expected_entries.append((key, data))
    emit_map_parts(lines, "subset_data_expected", expected_entries)
    lines.append("///|")
    lines.append("pub fn subset_data_expected_bytes(name : String) -> Bytes? {")
    lines.append("  subset_data_expected.get(name)")
    lines.append("}")
    lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    emit()


if __name__ == "__main__":
    main()
