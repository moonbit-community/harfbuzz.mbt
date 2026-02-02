---
description: Subset fonts to a codepoint set (TrueType glyf/loca; CFF1 charstrings/charset; CFF2 outlines).
---

# Subsetting (subset package)

This package provides a minimal subsetting pipeline.
It fully subsets TrueType (glyf/loca) fonts and currently rebuilds these tables:

- `head` (patches indexToLocFormat)
- `maxp` (numGlyphs)
- `hhea` (numberOfHMetrics)
- `hmtx` (per-glyph metrics)
- `vhea` (numberOfVMetrics, if present)
- `vmtx` (per-glyph vertical metrics, if present)
- `loca` (long format)
- `glyf` (glyph data, with composite component remapping)
- `cmap` (format 12 built from input codepoints; format 4 for BMP-only subsets)

Optional tables `name`, `OS/2` (first/last char indices updated),
`gasp`, `cvt `, `fpgm`, `prep`, `VDMX`,
`fvar`, `avar`, `STAT`, `MVAR`, `cvar`, `CPAL`, and `meta` are copied through
unchanged if present.
The `post` table is copied through unchanged for identity subsets; for remapped
subsets format 2.0 is rebuilt and format 3.0 is preserved.
Layout/color/variation tables that reference glyph IDs (GSUB/GPOS,
BASE/JSTF, AAT tables, CBDT/CBLC/SVG/sbix, gvar/HVAR/VVAR/VARC)
are copied through only when the subset preserves all glyphs (identity);
otherwise they are dropped.
`VORG` is rebuilt from the glyph subset when present.
`kern` format 0/2/3 subtables are rebuilt for remapped subsets (formats 2/3 are
expanded to format 0); other formats are dropped.
COLR v0 tables are rebuilt for remapped subsets.
GDEF is rebuilt with glyph/mark class definitions, attach lists, ligature caret
lists, and mark glyph sets.
GSUB lookup types 1/2/3/4 (single/multiple/alternate/ligature substitution)
are rebuilt for remapped subsets; other GSUB/GPOS lookups are dropped.

For CFF1 fonts, the subset path rebuilds the `CFF ` table by slicing
CharStrings/charset to the selected glyph set (CFF subrs are copied as-is).
For CFF2 fonts, the subset path rebuilds the `CFF2` table by slicing
CharStrings to the selected glyph set and rebuilding FDSelect/FDArray to match.
The ItemVariationStore bytes are copied through unchanged if present.

**Limitations**

- CFF1 subrs are copied as-is; unused subroutines are not removed.
- CFF2 private subrs and var store bytes are copied as-is; unused subroutines are not removed.
- Layout/color/variation tables that reference glyph IDs are not subset yet
  (except `VORG`, COLR v0, GDEF class defs/attach/lig caret/mark sets, GSUB
  lookup types 1/2/3/4, and `kern` format 0/2/3); they are only preserved when the
  subset keeps all glyphs.
- `loca` is always written in long format.
- `cmap` is rebuilt only from the supplied codepoints.

## Usage

```mbt nocheck
let input = @subset.SubsetInput::from_codepoints([0x41U, 0x42U])
let bytes = match @subset.subset(font, input) {
  Err(err) => fail("subset failed: \{err}")
  Ok(value) => value
}
let subset_font = @font.Font::from_bytes(bytes)
```
