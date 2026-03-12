<!--
Copyright 2026 International Digital Economy Academy

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# harfbuzz.mbt

This is the MoonBit port of HarfBuzz. The module name in `moon.mod.json` is a
placeholder and can be updated once the publishing owner is decided.

## License

Code in this directory is part of the harfbuzz.mbt project and is
licensed under Apache 2.0 by International Digital Economy Academy.
See the top-level `LICENSE` and `NOTICE` files for the full project
license and preserved upstream notices.

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
