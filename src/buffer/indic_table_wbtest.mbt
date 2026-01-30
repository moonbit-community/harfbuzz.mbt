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
