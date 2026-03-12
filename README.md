# harfbuzz.mbt

MoonBit port of [HarfBuzz](https://harfbuzz.github.io/), the open-source
text shaping engine.  The original HarfBuzz code is copyrighted by its
upstream authors and is licensed under the “Old MIT” license (see
(see `COPYING`).  All MoonBit-specific code in this repository is also
made available under the same terms.

## Licence

This repository is distributed under the Old MIT license.  See
[COPYING.md](COPYING.md) for the full text.  By contributing to this
project you agree that your contributions are covered by this licence.

## Building

(Instructions currently mirrored from `src/README.mbt.md`)

```bash
moon build --target js src/examples/js_svg
python3 -m http.server
```

Then open:

```
http://localhost:8000/src/examples/js_svg/index.html
```

## Status

Port is under active development; see `docs/PORTING_PLAN.md` for
details and current progress.
