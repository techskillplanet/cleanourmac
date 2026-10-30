#!/usr/bin/env bash
# Build a relocatable scrcpy tree under third_party/scrcpy for out-of-box mirroring.
# Requires a working Homebrew scrcpy on the build machine (arm64/x86_64).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/third_party/scrcpy"
LIB="$OUT/lib"
SCRCPY_SRC="$(command -v scrcpy || true)"
if [[ -z "$SCRCPY_SRC" ]]; then
  for c in /opt/homebrew/bin/scrcpy /usr/local/bin/scrcpy; do
    if [[ -x "$c" ]]; then SCRCPY_SRC=$c; break; fi
  done
fi
if [[ -z "$SCRCPY_SRC" ]]; then
  echo "error: scrcpy not found. Run: brew install scrcpy" >&2
  exit 1
fi
SCRCPY_SRC="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$SCRCPY_SRC")"
PREFIX="$(brew --prefix scrcpy 2>/dev/null || true)"
SERVER_SRC=""
if [[ -n "$PREFIX" && -f "$PREFIX/share/scrcpy/scrcpy-server" ]]; then
  SERVER_SRC="$PREFIX/share/scrcpy/scrcpy-server"
fi
if [[ -z "$SERVER_SRC" ]]; then
  echo "error: scrcpy-server not found under brew --prefix scrcpy" >&2
  exit 1
fi

echo "Bundling scrcpy from: $SCRCPY_SRC"
rm -rf "$LIB"
mkdir -p "$LIB"
cp -f "$SCRCPY_SRC" "$OUT/scrcpy"
cp -f "$SERVER_SRC" "$OUT/scrcpy-server"
chmod +x "$OUT/scrcpy"

python3 - "$OUT" "$SCRCPY_SRC" <<'PY'
import os, shutil, subprocess, sys
from pathlib import Path

out = Path(sys.argv[1])
lib_dir = out / 'lib'
binary = out / 'scrcpy'
SYSTEM = ('/usr/lib/', '/System/', '/Library/Apple/')

def is_system(path: str) -> bool:
    return any(path.startswith(p) for p in SYSTEM)

def deps(path: Path) -> list[str]:
    text = subprocess.check_output(['otool', '-L', str(path)], text=True)
    result = []
    for line in text.splitlines()[1:]:
        p = line.strip().split(' (', 1)[0].strip()
        if p and not p.startswith('@') and not is_system(p):
            result.append(p)
    return result

seen: set[Path] = set()
queue = [Path(sys.argv[2]).resolve()]
collected: list[Path] = []
while queue:
    cur = queue.pop()
    if cur in seen:
        continue
    seen.add(cur)
    if cur.suffix == '.dylib' or '.dylib' in cur.name:
        collected.append(cur)
    for dep in deps(cur):
        p = Path(dep)
        if not p.exists():
            continue
        rp = p.resolve()
        if rp not in seen and not is_system(str(rp)):
            queue.append(rp)

name_map: dict[str, str] = {}
for src in collected:
    dest = lib_dir / src.name
    shutil.copy2(src, dest)
    name_map[str(src)] = dest.name
    # also map versioned cellar realpaths via basename later

def rewrite(target: Path, *, is_binary: bool):
    # Set id for dylibs
    if not is_binary:
        subprocess.check_call([
            'install_name_tool', '-id', f'@loader_path/{target.name}', str(target)
        ])
    for dep in deps(target):
        src = Path(dep)
        key = str(src.resolve()) if src.exists() else dep
        base = name_map.get(key) or name_map.get(dep) or src.name
        if base not in {p.name for p in lib_dir.iterdir()}:
            continue
        new = f'@loader_path/lib/{base}' if is_binary else f'@loader_path/{base}'
        subprocess.check_call(['install_name_tool', '-change', dep, new, str(target)])

# First pass may still see absolute paths in copied libs; rewrite libs then binary.
for dylib in sorted(lib_dir.glob('*.dylib')):
    rewrite(dylib, is_binary=False)
rewrite(binary, is_binary=True)

# codesign ad-hoc so macOS will load relocated libs in local debug builds
for path in [binary, *sorted(lib_dir.glob('*.dylib'))]:
    subprocess.check_call(['codesign', '--force', '--sign', '-', str(path)])

print(f'Bundled {len(list(lib_dir.glob("*.dylib")))} dylibs -> {out}')
PY

# Smoke: dyld resolve without Homebrew in PATH
if ! SCRCPY_SERVER_PATH="$OUT/scrcpy-server" "$OUT/scrcpy" --version >/dev/null; then
  echo "error: bundled scrcpy failed to start (--version)" >&2
  exit 1
fi
"$OUT/scrcpy" --version | head -3
echo "OK: $OUT/scrcpy"
