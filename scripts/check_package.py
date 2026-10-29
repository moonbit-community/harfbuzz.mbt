"""Exercise a fresh consumer against the exact Mooncakes package contents."""
import os
from pathlib import Path
import subprocess
import tempfile
import zipfile

root = Path(__file__).resolve().parents[1]
env = dict(os.environ, MOON_WORK='off')
subprocess.run(['moon', 'package'], cwd=root, env=env, check=True)
archive = root / '_build/publish/moonbit-community-harfbuzz-0.2.0.zip'
with tempfile.TemporaryDirectory(prefix='harfbuzz-package-') as tmp:
    work = Path(tmp)
    package = work / 'package'
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert not any('/_build/' in n or '/.git/' in n for n in z.namelist())
        z.extractall(package)
    assert (package / 'src/paint/types.mbt').is_file()
    consumer = work / 'consumer'
    consumer.mkdir()
    (work / 'moon.work').write_text('members = ["package", "consumer"]\n')
    (consumer / 'moon.mod').write_text('name = "check/harfbuzz"\nimport { "moonbit-community/harfbuzz@0.2.0" }\n')
    (consumer / 'moon.pkg').write_text('''import {
  "moonbit-community/harfbuzz/paint",
  "moonbit-community/harfbuzz/buffer",
  "moonbit-community/harfbuzz/common",
  "moonbit-community/harfbuzz/shape",
}
''')
    (consumer / 'consumer_test.mbt').write_text('''///|
test "published gradient serialization and shaping plan" {
  let gradient : @paint.ColorLine = { extend_mode: 2, stops: [] }
  assert_eq(Json(gradient), { "extend": 2, "stops": [] })
  let buffer = @buffer.Buffer::new()
  buffer.set_script(@common.script_latin)
  buffer.set_language(@common.Language::from_string("en"))
  buffer.set_direction(@common.direction_ltr)
  let plan = @shape.ShapePlan::from_buffer(buffer, shapers=["ot"])
  assert_eq(plan.shaper, "ot")
}
''')
    consumer_env = dict(os.environ)
    consumer_env.pop('MOON_WORK', None)
    for target in ('wasm', 'wasm-gc', 'js', 'native'):
        subprocess.run(['moon', 'test', '--target', target], cwd=consumer,
                       env=consumer_env, check=True)
    print('Extracted archive consumer passed on all four targets.')
