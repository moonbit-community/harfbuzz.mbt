# harfbuzz.mbt

This is the MoonBit port of HarfBuzz. The module name in `moon.mod.json` is a
placeholder and can be updated once the publishing owner is decided.

## Licence

Code in this directory is part of the harfbuzz.mbt project and is
licenced under the Old MIT licence; see the top‑level `COPYING` file.

## Examples

- JS SVG demo: `src/examples/js_svg`

```bash
moon build --target js src/examples/js_svg
python3 -m http.server
```

Then open:

```
http://localhost:8000/src/examples/js_svg/index.html
```

```mbt check
///|
test "module version placeholder" {
  inspect(version, content="0.0.0")
}
```
