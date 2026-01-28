# HarfBuzz → MoonBit Porting Plan

## Goal
Build a MoonBit-native HarfBuzz-compatible shaping stack. Start with a minimal
OpenType shaping pipeline, then expand coverage (scripts, tables, shapers,
subset/variations, platform backends).

## Current Status
- `common`: tags/direction/script/language helpers (subset of scripts).
- `blob`: blob data holder + slicing.
- `face`: basic face holder + table map.

## Package Map (proposed)

| MoonBit package | Purpose | Upstream reference |
| --- | --- | --- |
| `common` | Tags, direction, script/language types, version helpers | `hb-common.h`, `hb-common.cc`, `hb-script-list.h` |
| `blob` | Binary data holder, sub-blob slicing | `hb-blob.h`, `hb-blob.cc` |
| `face` | Face object, table access, metadata | `hb-face.h`, `hb-face.cc`, `hb-ot-face.*` |
| `font` | Font metrics/scale, glyph funcs | `hb-font.h`, `hb-font.cc`, `hb-ot-font.*` |
| `buffer` | Text buffer, serialization, verify | `hb-buffer.h`, `hb-buffer.cc`, `hb-buffer-serialize.*`, `hb-buffer-verify.cc` |
| `unicode` | Unicode funcs + UCD data | `hb-unicode.h`, `hb-unicode.cc`, `hb-ucd*`, `hb-unicode-emoji-table*` |
| `ot/tables` | OpenType table structs/parsers | `hb-ot-*-table.hh`, `hb-ot-*.cc` |
| `ot/layout` | GSUB/GPOS, GDEF, script/feature selection | `hb-ot-layout.*`, `hb-ot-map.*`, `hb-ot-layout-gsubgpos.hh` |
| `ot/shape` | Normalization + shaping entry points | `hb-ot-shape.*`, `hb-ot-shape-normalize.*`, `hb-ot-shaper-*.cc` |
| `aat` | AAT layout tables + shaping | `hb-aat-*` |
| `subset` | Subsetting pipeline | `hb-subset.*` |
| `paint` | COLR/paint APIs | `hb-paint.*` |
| `graphite` | Graphite2 shaper (optional) | `hb-graphite2.*` |
| `platform/*` | Platform shapers (optional) | `hb-coretext.*`, `hb-directwrite.*`, `hb-uniscribe.*`, `hb-icu.*`, `hb-glib.*`, `hb-ft.*` |

## MVP Scope (phase 1)
Focus on TrueType/OpenType shaping for basic Latin:
1) **Core data model**: `blob`, `face`, `font`, `buffer`.
2) **Table parsing**: `head`, `hhea`, `maxp`, `hmtx`, `cmap` (format 4 + 12), `loca`, `glyf`.
3) **Layout**: GSUB/GPOS (single + ligature + pair positioning minimal set), script/language defaults.
4) **Shaper**: default OT shaper for left-to-right scripts.
5) **Output**: glyph IDs + advances/offsets.

Non-goals for phase 1:
- CFF/CFF2, color, math, AAT, variations, subsetting.
- Platform backends (CoreText/DirectWrite/Uniscribe).

## MVP Milestones
1) **Buffer + Font types**
   - Implement `buffer` and `font` packages (glyph buffer, clusters, metrics).
2) **Table parsing foundation**
   - `sfnt`/table directory + `head/hhea/maxp/hmtx/cmap` parsers.
3) **Glyph mapping**
   - `cmap` → glyph IDs; integrate with buffer.
4) **GSUB/GPOS minimal**
   - Single substitution + basic pair positioning.
5) **Default shaper**
   - Script/language feature mapping (start with `kern`, `liga`).
6) **Golden tests**
   - Compare shaping results for a few known fonts/text cases.

## Data & Codegen Strategy
- Reuse HarfBuzz-generated tables where possible by porting the generator logic
  (e.g., `gen-ucd-table.py`, `gen-emoji-table.py`, `gen-tag-table.py`).
- For early MVP, embed minimal static tables (scripts + Unicode categories needed
  for default shaper).

## Risks / Unknowns
- Full script list + direction mapping is large and needs codegen.
- Unicode data tables are sizeable; need a plan for generation or embedding.
- Performance parity will require careful data structure choices.
- GSUB/GPOS correctness is hard to validate without broad test coverage.

## Testing Plan
- Add MoonBit unit tests for table parsing and shaping primitives.
- Establish a small corpus of font fixtures (e.g., Noto Sans Regular) and
  compare shaping outputs against upstream HarfBuzz for a handful of strings.

## Suggested Next Tasks
- Expand script list + horizontal direction mapping (full `hb-script-list.h`).
- Implement `buffer` and `font` packages (core shaping data model).
- Add `sfnt` table directory parsing + base tables.
