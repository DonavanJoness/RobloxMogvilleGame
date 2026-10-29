#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) ;;
  *) echo 'This helper targets Linux x86_64. On Windows/macOS install Rojo 7.5.1 and Luau 0.690 from their official releases.' >&2; exit 1 ;;
esac
mkdir -p .tools/bin
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
fetch_verified() {
  local url="$1" expected="$2" output="$3"
  curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 --output "$output" "$url"
  printf '%s  %s\n' "$expected" "$output" | sha256sum --check --status
}
fetch_verified 'https://github.com/rojo-rbx/rojo/releases/download/v7.5.1/rojo-7.5.1-linux-x86_64.zip' \
  '0d600df6c4c48a9d09c701d0c2a109c55c2db833cd9766fd7d1e6e2684843d53' "$temp_dir/rojo.zip"
fetch_verified 'https://github.com/luau-lang/luau/releases/download/0.690/luau-ubuntu.zip' \
  'a4504ae9569e5030b387a7146a023b3670d505db9a09ebc645532fe65e8479c8' "$temp_dir/luau.zip"
unzip -oq "$temp_dir/rojo.zip" -d .tools/bin
unzip -oq "$temp_dir/luau.zip" -d .tools/bin
chmod +x .tools/bin/rojo .tools/bin/luau .tools/bin/luau-compile .tools/bin/luau-analyze
.tools/bin/rojo --version
python3 -m pip install --disable-pip-version-check --requirement tools/requirements-assets.txt --requirement tools/requirements-research.txt
python3 tools/portraits.py
python3 tools/test.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/world_smoke.py
python3 tools/build.py
