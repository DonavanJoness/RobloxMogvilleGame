#!/usr/bin/env python3
"""Execute the actual world modules with lightweight construction stubs.

This check covers generated hierarchy, ownership, effect/part budgets, cache and
cleanup. It does not emulate Roblox physics, rendering, replication or API
property validation. Studio playtesting remains required.
"""
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def binary(name):
    for directory in (ROOT / ".tools/bin", ROOT.parent / ".mogville-tools/bin"):
        candidate = directory / name
        if candidate.is_file():
            return str(candidate)
    found = shutil.which(name)
    if not found:
        raise SystemExit(f"{name} is missing. Run bash tools/install.sh first.")
    return found


def module_source(path):
    source = path.read_text()
    # Only dependency syntax is changed; the game implementation executes intact.
    patterns = (
        r'require\(ReplicatedStorage:WaitForChild\("Shared"\):WaitForChild\("([A-Za-z]+)"\)\)',
        r'require\(ReplicatedStorage.Shared:WaitForChild\("([A-Za-z]+)"\)\)',
        r"require\(ReplicatedStorage.Shared.([A-Za-z]+)\)",
        r"require\(script.Parent.([A-Za-z]+)\)",
    )
    for pattern in patterns:
        source = re.sub(pattern, lambda match: match.group(1), source)
    if re.search(r"\brequire\s*\(", source):
        raise ValueError(f"Unsupported world smoke dependency in {path}")
    return source


def main():
    paths = [ROOT / "src/shared" / f"{name}.luau" for name in (
        "CharacterCatalog", "PortraitAssets", "CharacterVisuals", "Config", "Rules",
    )]
    paths += [ROOT / "src/server/Services" / f"{name}.luau" for name in (
        "EnvironmentBuilder", "WorldService",
    )]
    parts = [(ROOT / "tests/world-runtime.luau").read_text()]
    for path in paths:
        source = module_source(path)
        parts.append(f"local {path.stem} = (function()\n{source}\nend)()")
    parts.append((ROOT / "tests/world-smoke.luau").read_text())
    with tempfile.TemporaryDirectory(prefix="mogville-world-smoke-") as directory:
        runner = Path(directory) / "world.luau"
        runner.write_text("\n".join(parts))
        subprocess.run([binary("luau"), str(runner)], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
