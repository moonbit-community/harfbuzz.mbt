# HarfBuzz -> MoonBit Porting Plan

## Goal
Full HarfBuzz port in MoonBit while excluding platform-specific backends.
This includes the non-platform shaping stack (OT/AAT/Graphite), table parsing,
Unicode data, variations, color/paint, and subsetting.

## Current Implementation (as of 2026-02-01)
- `common`: tags, direction, script/language helpers (expanded list; may not be exhaustive).
- `blob`: blob data holder + slicing.
- `face`: face holder + table map (TTC index aware).
- `font`: metrics (h/v advances), cmap lookup, lazy GSUB/GPOS/GDEF parsing.
- `buffer`: glyph buffer + `shape_basic` + `shape_ot` (GSUB/GPOS with feature allowlists, vertical advances), OT normalization (mark reorder + compose), script shapers (arabic/indic/khmer/myanmar/thai/hangul/hebrew/use/syllabic), fallback mark positioning/zero-width marks, space fallback advances, default-ignorable handling + variation selector flags.
- `unicode`: UCD-backed general category/combining class/script/mirroring/compose/decompose + Extended_Pictographic + Arabic joining/shaping helpers + mark/space/variation selector/default-ignorable helpers.
- `sfnt`: table directory + `head`, `hhea`, `vhea`, `maxp`, `hmtx`, `vmtx`, `cmap` (format 4/12), `loca`, `glyf`.
- `ot/tables`: coverage, layout, lookup parsing; GSUB/GPOS apply; GDEF parsing; lookup flag filtering.
  - GSUB: lookup types 1-8 and extension.
  - GPOS: lookup types 1-8 and extension (single, pair, cursive, mark-to-*, contextual, chaining).
- `ot/cff`: CFF1/CFF2 parsing + bounds helpers (fixtures present).
- `ot/var`: variation tables + var store (fvar/gvar/avar/cvar/hvar/vvar/mvar/varc) with tests.
- `ot/color` + `paint`: COLR/CPAL parsing + COLRv1 paint graph decoding (no rendering/backends yet).
- `aat`: AAT layout tables + shaping (morx/mort/kerx/ankr/trak + bsln/feat/opbd/just/ltag).
- `subset`: TrueType subsetting for glyf/loca/hmtx/vmtx/head/hhea/vhea/maxp/cmap (composite remap; long loca) + CFF1 charstrings/charset subsetting + CFF2 outline subsetting + passthrough metadata/axis tables (OS/2 with updated first/last char indices, gasp, cvt, fpgm, prep, VDMX, fvar, avar, STAT, MVAR, cvar, CPAL, meta) + VORG rebuild + kern format 0/2/3 rebuild + COLR v0 rebuild + GDEF class/attach/lig caret/mark set rebuild + GSUB lookup types 1/2/3/4/5/6/7/8 rebuild + GPOS lookup types 1/2 plus extension type 9 rebuild. Layout/color/variation tables that reference glyph IDs are preserved only for identity subsets.

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
| `unicode` | UCD + emoji data + unicode funcs | `hb-unicode.*`, `hb-ucd*` | partial (UCD + Extended_Pictographic + Arabic helpers + default-ignorable/VS/space helpers; more emoji props pending) |
| `ot/shape` | OT shaping + normalization | `hb-ot-shape.*`, `hb-ot-shaper-*.cc` | partial (normalization + script shapers in buffer; OT fallback gaps + variation selector glyph lookup pending) |
| `ot/map` | Feature/lookup mapping | `hb-ot-map.*` | partial (lookup selection + feature allowlists) |
| `shape` | Generic shaper registry + plan | `hb-shape.*`, `hb-shape-plan.*`, `hb-shaper.*` | partial (plan + registry scaffold) |
| `ot/cff` | CFF/CFF2 parsing + bounds | `hb-ot-cff*`, `hb-cff*` | done |
| `ot/var` | Variation tables + var store | `hb-ot-var*` | done |
| `ot/color` | COLR/CPAL + color utilities | `hb-ot-color.*` | partial |
| `paint` | Paint API | `hb-paint.*` | partial |
| `aat` | AAT layout + shaping | `hb-aat-*` | done |
| `graphite` | Graphite2 shaper | `hb-graphite2.*` | excluded (external dependency) |
| `subset` | Subsetting pipeline | `hb-subset*` | done (TrueType glyf/loca + vertical metrics + CFF1 charstrings/charset + CFF2 outlines + metadata/axis passthrough tables + VORG + kern format 0/2/3 + COLR v0 + GDEF class/attach/lig caret/mark sets + GSUB lookup types 1/2/3/4/5/6/7/8 + GPOS lookup types 1/2 plus extension type 9; identity-only passthrough for layout/color/variation tables that reference glyph IDs) |
| `draw` | Draw/outline helpers | `hb-draw.*`, `hb-outline.*` | planned |
| `platform/*` | Platform backends | CoreText/DirectWrite/Uniscribe/etc. | excluded |

## Remaining Non-Platform Modules (inventory)

- Unicode + UCD data: `hb-unicode.*`, `hb-ucd*`, `hb-unicode-emoji-table*` -> `unicode`.
- Shaping pipeline: `hb-shape.*`, `hb-shape-plan.*`, `hb-shaper.*`, `hb-shaper-list.hh` -> `shape`.
- OT shaper + normalization: `hb-ot-shape.*`, `hb-ot-shape-normalize.*`, `hb-ot-shape-fallback.*`,
  `hb-ot-shaper-*.cc` (arabic/indic/khmer/myanmar/use/hangul/hebrew/thai/syllabic) -> `ot/shape`
  (most script shapers + normalization done; remaining: variation selector glyph lookup + any missing fallback passes).
- OT map/feature selection: `hb-ot-map.*` -> `ot/map`.
- CFF/CFF2 support: `hb-ot-cff*`, `hb-cff*` -> `ot/cff` (done).
- Graphite2 shaper: `hb-graphite2.*` -> `graphite` (excluded; requires external Graphite2 library).
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
- UCD tables are imported from `refs/harfbuzz/src/hb-ucd-table.hh` via `scripts/gen_ucd_table.py`
  (regenerates `src/unicode/ucd_data.mbt`).
- Emoji Extended_Pictographic data is imported from `refs/harfbuzz/src/hb-unicode-emoji-table.hh`
  via `scripts/gen_emoji_table.py` (regenerates `src/unicode/emoji_data.mbt`).
- Modified combining class map is imported from `refs/harfbuzz/src/hb-unicode.{hh,cc}` via
  `scripts/gen_modified_combining_class.py` (regenerates `src/unicode/modified_combining_class.mbt`).

## Testing Plan
- Expand unit tests for table parsing and layout application.
- Add shaping snapshots with a font corpus (Latin/Arabic/Indic + mark positioning).
- Validate parity against upstream HarfBuzz outputs where feasible.

### Shaping Snapshot Coverage (current)
- Core OT shaping: GSUB/GPOS snapshots, single-pos, feature filter, kern fallback, vertical kern skip.
- Mark handling: GDEF mark class zeroing, fallback mark positioning.
- Default ignorables / variation selectors: zeroed/preserve/remove, VS fallback, VS mapping (cmap 14 non-default), VS default mapping.
- Script shapers:
  - Arabic: fallback snapshot and Syriac GSUB/DFLT snapshots.
  - Hebrew: hebr GPOS applied + no-hebr GPOS snapshot.
  - Indic: fallback snapshot, dev2 selection snapshot, dev3->USE routing snapshot.
  - Myanmar: fallback snapshot, mym2-over-DFLT snapshot.
  - USE: fallback snapshot.
  - Thai: PUA fallback (mark substitution), base replacement, GSUB-present skip snapshots.
