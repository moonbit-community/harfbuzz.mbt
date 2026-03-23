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

# Graphite2 Integration Strategy

## Decision
Graphite2 shaping remains **excluded** from the core MoonBit port by default.
It introduces an external C dependency, adds platform-specific build/packaging
work, and is not needed for the core OT/AAT shaping parity goals.

## Detection
Graphite-capable fonts can be detected by the presence of Graphite tables
(e.g. `Silf`, `Glat`, `Gloc`, `Feat`, `Sill`). When Graphite2 support is not
available, these tables are ignored and shaping falls back to OT/AAT.

## Optional Integration Path (if required)
If Graphite2 support becomes a requirement, implement it as an **optional**
package with a separate build step, keeping core code dependency-free.

Suggested approach:
1. Add a `graphite` package that defines a minimal shaper interface and
   translates MoonBit `Face`/`Font`/`Buffer` data to Graphite2 inputs.
2. Provide FFI bindings to the Graphite2 C API (face/font creation, segment
   shaping, glyph position extraction).
3. Gate the shaper behind a build flag (or separate module) so the core build
   remains clean when Graphite2 is unavailable.
4. If bindings are enabled, route shaping to Graphite2 only when Graphite
   tables are present; otherwise default to OT/AAT.

## Non-Goals
- No bundled Graphite2 source or vendored build in the core repository.
- No platform-specific tooling in the core build graph.

## Follow-up
If the optional integration path is chosen, open a separate epic for:
- FFI bindings + build tooling per target.
- Shaper bridge implementation and tests with Graphite fonts.
