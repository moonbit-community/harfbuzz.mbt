///|
test "version api" {
  let (major, minor, micro) = version_tuple()
  inspect((major, minor, micro), content="(0, 0, 0)")
  let expected = "\{major}.\{minor}.\{micro}"
  inspect(version, content=expected)
  inspect(version_string(), content=expected)
  assert_true(version_atleast(major, minor, micro))
  assert_true(!version_atleast(major + 1, minor, micro))
  assert_true(!version_atleast(major, minor + 1, micro))
  assert_true(!version_atleast(major, minor, micro + 1))
}
