# HarfBuzz -> MoonBit Porting Plan

## Goal
Full HarfBuzz port in MoonBit while excluding platform-specific backends.
This includes the non-platform shaping stack (OT/AAT/Graphite), table parsing,
Unicode data, variations, color/paint, and subsetting.

## Current Implementation (as of 2026-01-29)
- `common`: tags, direction, script/language helpers (expanded list; may not be exhaustive).
- `blob`: blob data holder + slicing.
- `face`: face holder + table map.
- `font`: metrics, cmap lookup, lazy GSUB/GPOS/GDEF parsing.
- `buffer`: glyph buffer + `shape_basic` + `shape_ot` (GSUB/GPOS with feature allowlists).
- `sfnt`: table directory + `head`, `hhea`, `maxp`, `hmtx`, `cmap` (format 4/12), `loca`, `glyf`.
- `ot/tables`: coverage, layout, lookup parsing; GSUB/GPOS apply; GDEF parsing; lookup flag filtering.
  - GSUB: lookup types 1-8 and extension.
  - GPOS: lookup types 1-8 and extension (single, pair, cursive, mark-to-*, contextual, chaining).

## Package Map (current + planned)

| MoonBit package | Purpose | Upstream reference | Status |
| --- | --- | --- | --- |
| `common` | Tags, script/language, direction | `hb-common.*`, `hb-script-list.h` | done |
| `blob` | Blob + slicing | `hb-blob.*` | done |
| `face` | Face + table map | `hb-face.*`, `hb-ot-face.*` | done |
| `font` | Font metrics + table access | `hb-font.*`, `hb-ot-font.*` | done |
| `buffer` | Buffer + shaping entrypoint | `hb-buffer.*` | partial (serialize/verify missing) |
| `sfnt` | SFNT tables (head/hhea/etc.) | `hb-ot-*-table.hh` | partial |
| `ot/tables` | GSUB/GPOS/GDEF + lookup parsing | `hb-ot-layout-*-table.hh` | partial |
| `unicode` | UCD + emoji data + unicode funcs | `hb-unicode.*`, `hb-ucd*` | planned |
| `ot/shape` | OT shaping + normalization | `hb-ot-shape.*`, `hb-ot-shaper-*.cc` | planned |
| `ot/map` | Feature/lookup mapping | `hb-ot-map.*` | planned |
| `shape` | Generic shaper registry + plan | `hb-shape.*`, `hb-shape-plan.*`, `hb-shaper.*` | planned |
| `ot/var` | Variation tables + var store | `hb-ot-var*` | planned |
| `ot/color` | COLR/CPAL + color utilities | `hb-ot-color.*` | planned |
| `paint` | Paint API | `hb-paint.*` | planned |
| `aat` | AAT layout + shaping | `hb-aat-*` | planned |
| `graphite` | Graphite2 shaper | `hb-graphite2.*` | planned |
| `subset` | Subsetting pipeline | `hb-subset*` | planned |
| `draw` | Draw/outline helpers | `hb-draw.*`, `hb-outline.*` | planned |
| `platform/*` | Platform backends | CoreText/DirectWrite/Uniscribe/etc. | excluded |

## Remaining Non-Platform Modules (inventory)

- Unicode + UCD data: `hb-unicode.*`, `hb-ucd*`, `hb-unicode-emoji-table*` -> `unicode`.
- Shaping pipeline: `hb-shape.*`, `hb-shape-plan.*`, `hb-shaper.*`, `hb-shaper-list.hh` -> `shape`.
- OT shaper + normalization: `hb-ot-shape.*`, `hb-ot-shape-normalize.*`, `hb-ot-shape-fallback.*`,
  `hb-ot-shaper-*.cc` (arabic/indic/khmer/myanmar/use/hangul/hebrew/thai/syllabic) -> `ot/shape`.
- OT map/feature selection: `hb-ot-map.*` -> `ot/map`.
- OT tables not yet parsed: `BASE`, `JSTF`, `MATH`, `OS/2`, `name`, `post`, `meta`, `stat`, `gasp`,
  `hdmx`, `vorg`, `kern`, `color` tables -> `sfnt`/`ot/tables`/`ot/color`.
- Variations: `fvar`, `gvar`, `avar`, `cvar`, `hvar`, `mvar`, `varc`, tuple var store -> `ot/var`.
- CFF/CFF2 support: `hb-ot-cff*`, `hb-cff*` -> planned `sfnt/cff` or `ot/cff` package.
- Color + paint APIs: `hb-ot-color.*`, `hb-paint.*` -> `ot/color`, `paint`.
- AAT shaping: `hb-aat-*` -> `aat`.
- Graphite2 shaper: `hb-graphite2.*` -> `graphite`.
- Subsetting: `hb-subset*` -> `subset`.
- Buffer serialization/verify: `hb-buffer-serialize.*`, `hb-buffer-verify.cc` -> `buffer`.
- Utility data structures and helpers: `hb-set.*`, `hb-map.*`, `hb-serialize.*`, `hb-repacker.*`,
  `hb-number-parser.*` -> new support package (or fold into existing).

## Platform-Specific Exclusions
- OS shapers/backends: `hb-coretext.*`, `hb-directwrite.*`, `hb-uniscribe.*`, `hb-gdi.*`.
- External integrations/bindings: `hb-ft.*`, `hb-icu.*`, `hb-glib.*`, `hb-gobject.*`, `hb-cairo.*`.
- WASM API glue: `hb-wasm-*` (treat as optional binding layer).

## Data & Codegen Strategy
- Reuse HarfBuzz generators where possible (`gen-ucd-table.py`, `gen-emoji-table.py`,
  `gen-tag-table.py`, `gen-*-table.py`).
- For early phases, embed minimal static tables and replace with generated data later.

## Testing Plan
- Expand unit tests for table parsing and layout application.
- Add shaping snapshots with a font corpus (Latin/Arabic/Indic + mark positioning).
- Validate parity against upstream HarfBuzz outputs where feasible.
