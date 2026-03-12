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

MoonBit port of [HarfBuzz](https://harfbuzz.github.io/), the open-source
text shaping engine.  The original HarfBuzz code is copyrighted by its
upstream authors.  This repository is distributed under Apache 2.0 by
International Digital Economy Academy, and the upstream HarfBuzz
notice texts are preserved verbatim in `NOTICE`.

## License

MoonBit-specific code in this repository is licensed under Apache 2.0.
See [LICENSE](LICENSE) for the project license and [NOTICE](NOTICE) for
the concatenated upstream HarfBuzz notice texts.

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
