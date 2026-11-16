#!/usr/bin/env python3
"""Build the Studio place and export a clean, self-contained source archive."""
from pathlib import Path
import subprocess
import zipfile
import shutil
from test import ROOT, binary


def preserved_place(output):
    """Update the owner's newer place without rebuilding away unknown/new Studio properties."""
    from patch_place import Place, patch
    original = ROOT / "assets/place-source/Mogville-user-upload.rbxl"
    place = Place.read(original)
    existing = place.script_sources()
    replacements, additions, represented = {}, [], set()
    for path in sorted((ROOT / "src").rglob("*.luau")):
        relative = path.relative_to(ROOT / "src")
        name = path.stem.removesuffix(".client").removesuffix(".server")
        if relative.parts[0] == "shared":
            parent = "ReplicatedStorage/Shared"
        elif relative.parts[:2] == ("client", "Controllers"):
            parent = "StarterPlayer/StarterPlayerScripts/MogvilleClient/Controllers"
        elif relative.parts[0] == "client":
            parent = "StarterPlayer/StarterPlayerScripts/MogvilleClient"
        elif relative.parts[:2] == ("server", "Services"):
            parent = "ServerScriptService/MogvilleServer/Services"
        elif relative.parts[0] == "server":
            parent = "ServerScriptService/MogvilleServer"
        else:
            raise ValueError("Unmapped source path: " + str(relative))
        target = parent + "/" + name
        represented.add(target)
        if target in existing:
            replacements[target] = path.read_text()
        else:
            cls = "LocalScript" if path.name.endswith(".client.luau") else "Script" if path.name.endswith(".server.luau") else "ModuleScript"
            additions.append({"name": name, "class": cls, "source": path.read_text(), "parentPath": parent})
    if set(existing) - represented:
        raise ValueError("Uploaded script would be omitted: " + str(set(existing) - represented))
    target = output / "Mogville.rbxl"
    patch(original, target, replacements, additions)
    result = Place.read(target)
    actual = result.script_sources()
    for name, source in replacements.items():
        if actual[name] != source:
            raise ValueError("Patched source mismatch: " + name)
    for item in additions:
        if actual[item["parentPath"] + "/" + item["name"]] != item["source"]:
            raise ValueError("Added source mismatch")
    for ref, instance in place.instances.items():
        new = result.instances[ref]
        if (new.name, new.class_name, new.parent) != (instance.name, instance.class_name, instance.parent):
            raise ValueError("Uploaded instance hierarchy changed")
    # Every original non-script property chunk is retained byte-for-byte, including
    # modern properties that this project's older Rojo reflection database cannot parse.
    expected = [c.raw for c in place.chunks if c.tag not in (b"PRNT", b"END\0")
                and not (c.tag == b"PROP" and c.payload[4:8] == bytes((6, 0, 0, 0)) and c.payload[8:14] == b"Source")]
    raw_chunks = {c.raw for c in result.chunks}
    for chunk in expected:
        if chunk not in raw_chunks:
            raise ValueError("An original non-source chunk changed")
    print(f"Preserved all {len(place.instances)} uploaded instances; patched {len(replacements)} scripts and added {len(additions)} photo modules.")


def main():
    output = ROOT / "build"
    output.mkdir(exist_ok=True)
    preserved = (ROOT / "assets/place-source/Mogville-user-upload.rbxl").exists()
    if preserved:
        preserved_place(output)
    else:
        subprocess.run([binary("rojo"), "build", "default.project.json", "--output", "build/Mogville.rbxlx"], cwd=ROOT, check=True)
        subprocess.run([binary("rojo"), "build", "default.project.json", "--output", "build/Mogville.rbxl"], cwd=ROOT, check=True)
    with zipfile.ZipFile(output / "Mogville-place.zip", "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.write(output / "Mogville.rbxl", "Mogville.rbxl")
        if preserved:
            archive.writestr("OPEN-ME.txt", "Extract Mogville.rbxl, open it in Roblox Studio, and press Play. Authentic photo pixels are embedded in this file for a Studio-only preview. No separate photo import is needed. If an image API error appears, enable Allow Mesh / Image APIs in Experience Settings > Security and restart Play. Existing saves are preserved; new Studio profiles start with a real-photo card. See REAL-FACES.md for the actual included faces and remaining references. This is not a published/photo-uploaded version.\n")
            archive.write(ROOT / "docs/REAL_FACES.md", "REAL-FACES.md")
            archive.write(ROOT / "assets/characters/studio-preview/CREDITS.md", "PHOTO-CREDITS.md")
            archive.write(ROOT / "assets/references/embedded-photo-manifest.json", "photo-manifest.json")
            for image in sorted((ROOT / "assets/characters/studio-preview").glob("*.png")):
                archive.write(image, "photo-previews/" + image.name)
            for license_file in sorted((ROOT / "assets/licenses").glob("*")):
                if license_file.is_file(): archive.write(license_file, "licenses/" + license_file.name)
        else:
            archive.writestr("OPEN-ME.txt", "Extract Mogville.rbxl, then open it in Roblox Studio on Windows or macOS. Press Play to generate the city. Studio uses temporary memory by default. See the repository README for save testing and portrait uploads.\n")
    downloads = ROOT / "downloads"
    downloads.mkdir(exist_ok=True)
    for name in ("Mogville.rbxl", "Mogville-place.zip"):
        shutil.copy2(output / name, downloads / name)
    if preserved:
        shutil.copy2(output / "Mogville.rbxl", downloads / "Mogville-real-faces.rbxl")
        shutil.copy2(output / "Mogville-place.zip", downloads / "Mogville-real-faces.zip")
    paths = [ROOT / name for name in ("README.md", ".gitignore", "default.project.json")]
    if (ROOT / ".gitattributes").exists(): paths.append(ROOT / ".gitattributes")
    for directory in ("src", "tests", "tools", "docs", "assets"):
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
