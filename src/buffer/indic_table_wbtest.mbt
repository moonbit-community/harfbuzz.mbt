// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

test "indic table dotted circle category" {
  let value = indic_get_categories(0x25CCU)
  inspect(indic_category(value), content="11")
  inspect((value >> 8) & 0xffU, content="4")
}

test "indic table special no-break space" {
  let value = indic_get_categories(0x00A0U)
  inspect(indic_category(value), content="10")
  inspect((value >> 8) & 0xffU, content="4")
}

test "indic table devanagari ra" {
  let value = indic_get_categories(0x0930U)
  inspect(indic_category(value), content="15")
  inspect((value >> 8) & 0xffU, content="4")
}

test "indic table devanagari virama" {
  let value = indic_get_categories(0x094DU)
  inspect(indic_category(value), content="4")
  inspect((value >> 8) & 0xffU, content="8")
}
