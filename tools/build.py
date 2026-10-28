#!/usr/bin/env python3
"""Build the Studio place and export a clean, self-contained source archive."""
from pathlib import Path
import subprocess
import zipfile
from test import ROOT, binary


def main():
    output = ROOT / "build"
    output.mkdir(exist_ok=True)
    subprocess.run([binary("rojo"), "build", "default.project.json", "--output", "build/Mogville.rbxlx"], cwd=ROOT, check=True)
    paths = [ROOT / name for name in ("README.md", ".gitignore", "default.project.json")]
    for directory in ("src", "tests", "tools", "docs"):
        paths.extend(p for p in (ROOT / directory).rglob("*") if p.is_file() and "__pycache__" not in p.parts)
    archive_path = output / "Mogville-source.zip"
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(paths):
            archive.write(path, path.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(archive_path) as archive:
        assert archive.testzip() is None, "Source archive integrity failure"
        assert "default.project.json" in archive.namelist()
    print(f"Source archive: {archive_path} ({len(paths)} files)")


if __name__ == "__main__":
    main()
