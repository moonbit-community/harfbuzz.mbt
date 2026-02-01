---
description: Subset fonts to a codepoint set (TrueType glyf/loca only).
---

# Subsetting (subset package)

This package provides a minimal, **TrueType-only** subsetting pipeline.
It currently rebuilds these tables:

- `head` (patches indexToLocFormat)
- `maxp` (numGlyphs)
- `hhea` (numberOfHMetrics)
- `hmtx` (per-glyph metrics)
- `loca` (long format)
- `glyf` (glyph data, with composite component remapping)
- `cmap` (format 12 built from input codepoints)

Optional tables `name` and `post` are copied through unchanged if present.

**Limitations**

- CFF/CFF2 fonts are not supported.
- No subsetting of GSUB/GPOS/GDEF, color, variations, or AAT tables.
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
