// Run from examples/js_svg after the documented release build.
const fs = require('node:fs');
const path = require('node:path');
const html = fs.readFileSync('index.html', 'utf8');
const scripts = [...html.matchAll(/<script\b[^>]*\bsrc="([^"]+)"/g)];
if (scripts.length === 0) throw new Error('The demo has no external script');
for (const [, src] of scripts) {
  const asset = path.resolve(src);
  if (!fs.statSync(asset).isFile()) throw new Error(`Missing demo script: ${src}`);
  console.log(`Demo script exists: ${src}`);
}
