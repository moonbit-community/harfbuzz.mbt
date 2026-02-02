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

Optional tables `name`, `post`, `OS/2` (first/last char indices updated),
`gasp`, `cvt `, `fpgm`, `prep`, `VDMX`,
`fvar`, `avar`, `STAT`, `MVAR`, `cvar`, `CPAL`, and `meta` are copied through
unchanged if present.
Layout/color/variation tables that reference glyph IDs (GSUB/GPOS/GDEF,
BASE/JSTF, AAT tables, COLR/CBDT/CBLC/SVG/sbix, gvar/HVAR/VVAR/VORG/VARC)
are copied through only when the subset preserves all glyphs (identity);
otherwise they are dropped.

For CFF1 fonts, the subset path rebuilds the `CFF ` table by slicing
CharStrings/charset to the selected glyph set (CFF subrs are copied as-is).
For CFF2 fonts, the subset path rebuilds the `CFF2` table by slicing
CharStrings to the selected glyph set and rebuilding FDSelect/FDArray to match.
The ItemVariationStore bytes are copied through unchanged if present.

**Limitations**

- CFF1 subrs are copied as-is; unused subroutines are not removed.
- CFF2 private subrs and var store bytes are copied as-is; unused subroutines are not removed.
- Layout/color/variation tables that reference glyph IDs are not subset yet;
  they are only preserved when the subset keeps all glyphs.
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
