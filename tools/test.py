#!/usr/bin/env python3
"""Compile every Luau file, then run the actual modules in a dependency bundle.

Roblox-only integration uses explicit in-memory API mocks; this is not Studio.
The bundler only rewrites static requires and does not translate gameplay logic.
"""
from pathlib import Path
import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def binary(name):
    for path in [ROOT / ".tools/bin" / name, ROOT.parent / ".mogville-tools/bin" / name]:
        if path.is_file():
            return str(path)
    found = shutil.which(name)
    if not found:
        raise SystemExit(f"{name} is missing. Run bash tools/install.sh first.")
    return found


def bundle():
    modules = {}

    def add(path):
        path = path.resolve()
        if not path.is_relative_to(ROOT):
            raise ValueError(f"Module outside project: {path}")
        key = path.relative_to(ROOT).as_posix()
        if key in modules:
            return key
        modules[key] = ""
        source = path.read_text()

        def replace(match):
            expr = match.group(1).strip()
            if expr.startswith(('"', "'")):
                relative = expr[1:-1]
                dependency = (path.parent / relative).with_suffix(".luau")
                # .spec and runtime are intentional basename suffixes.
                if not dependency.exists():
                    dependency = Path(str(path.parent / relative) + ".luau")
            elif expr.startswith("script.Parent."):
                dependency = path.parent.joinpath(*expr.removeprefix("script.Parent.").split(".")).with_suffix(".luau")
            elif expr.startswith("ReplicatedStorage.Shared."):
                dependency = ROOT / "src/shared" / (expr.split(".")[-1] + ".luau")
            else:
                raise ValueError(f"Unsupported test require in {key}: {expr}")
            return "__require(" + json.dumps(add(dependency)) + ")"

        source = re.sub(r"require\(([^()]+)\)", replace, source)
        if key.startswith("src/server/Services/"):
            source = ('local Runtime = __require("tests/runtime.luau")\n'
                      'local game, workspace, task, warn = Runtime.game, Runtime.workspace, Runtime.task, Runtime.warn\n'
                      + source)
        modules[key] = source
        return key

    # Load explicit mocks first, but inject them only in server modules.
    if (ROOT / "tests/runtime.luau").exists():
        add(ROOT / "tests/runtime.luau")
    suites = [add(path) for path in sorted((ROOT / "tests").glob("*.spec.luau"))]
    preamble = '''local __factories, __cache, __loading = {}, {}, {}
local function __require(id)
    if __cache[id] ~= nil then return __cache[id] end
    assert(__factories[id], "Module not bundled: " .. id)
    assert(not __loading[id], "Cyclic dependency: " .. id)
    __loading[id] = true
    local value = __factories[id]()
    __cache[id] = value
    __loading[id] = nil
    return value
end
'''
    parts = [preamble]
    for key, source in modules.items():
        parts.append(f"__factories[{json.dumps(key)}] = function()\n{source}\nend\n")
    parts.append('''local passed, failed = 0, 0
local function test(name, fn)
    local ok, problem = pcall(fn)
    if ok then passed += 1; print("PASS " .. name)
    else failed += 1; print("FAIL " .. name .. ": " .. tostring(problem)) end
end
''')
    for suite in suites:
        parts.append(f'print("\\nSUITE {suite}"); __require({json.dumps(suite)})(test)\n')
    parts.append('print(string.format("\\n%d passed; %d failed", passed, failed))\nassert(passed > 0 and failed == 0, "Tests failed")\n')
    return "\n".join(parts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skip-compile", action="store_true")
    args = parser.parse_args()
    if not args.skip_compile:
        compiler = binary("luau-compile")
        paths = sorted((ROOT / "src").rglob("*.luau")) + sorted((ROOT / "tests").rglob("*.luau"))
        for path in paths:
            subprocess.run([compiler, str(path)], check=True, stdout=subprocess.DEVNULL)
        print(f"Compiled {len(paths)} Luau source/test files.", flush=True)
    with tempfile.TemporaryDirectory(prefix="mogville-tests-") as directory:
        runner = Path(directory) / "run.luau"
        runner.write_text(bundle())
        subprocess.run([binary("luau"), str(runner)], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
