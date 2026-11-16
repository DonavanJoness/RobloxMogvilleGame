"""Exercise the actual shared gameplay modules under Studio and published contexts."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("mogville_test_bundle", ROOT / "tools/test.py")
bundler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bundler)


class StudioPhotoPreviewTests(unittest.TestCase):
    def run_gameplay(self, studio):
        # Keep production sources intact; only Roblox's unavailable RunService is mocked.
        source = bundler.bundle().split("local passed, failed = 0, 0", 1)[0]
        marker = '__factories["src/shared/MoggerPortraitRegistry.luau"] = function()\n'
        self.assertIn(marker, source)
        context = "true" if studio else "false"
        source = source.replace(marker, marker +
            'local game = {GetService=function(_, name) assert(name == "RunService"); '
            f'return {{IsStudio=function() return {context} end}} end}}\n', 1)
        assertions = r'''
local Registry = __require("src/shared/MoggerPortraitRegistry.luau")
local Config = __require("src/shared/Config.luau")
local Rules = __require("src/shared/Rules.luau")
local Entries = __require("src/shared/RealMoggers.luau")
local EmbeddedPhotos = __require("src/shared/EmbeddedPhotoCatalog.luau")
local Studio = STUDIO_CONTEXT
assert(Config.StudioPhotoPreview == Studio)
local profile = Rules.newProfile(function() return "new_starter" end, 100)
local realCount, legacyEnabled = 0, 0
for id, character in Config.Characters do
    if character.referenceType == "RealPerson" and character.enabled then
        realCount += 1
        assert(Studio and character.previewOnly and character.embeddedIdentityId)
        assert(not Registry.isReady(Entries[id]))
        assert(Entries[id].portraitAssetId == 0 and Entries[id].uploadStatus == "not-uploaded")
    elseif character.referenceType == "LegacyFictional" and character.enabled then legacyEnabled += 1 end
end
if Studio then
    local photoCount = 0
    for _, entry in Entries do
        if entry.variant == "Classic" and EmbeddedPhotos[entry.identityId] then photoCount += 1 end
    end
    assert(realCount == photoCount and realCount >= 15 and legacyEnabled == 0)
    assert(profile.characters[1].characterId == "real_jon_kortajarena_classic")
else
    assert(realCount == 0 and legacyEnabled >= 24)
    assert(profile.characters[1].characterId == "young_rookie")
end
local total = 0
for _, outcome in Rules.odds(profile) do
    total += outcome.probability
    local character = Config.Characters[outcome.characterId]
    assert(character.enabled)
    if Studio then assert(character.referenceType == "RealPerson") end
end
assert(math.abs(total - 1) < 0.000001)
profile.pity.rare = Config.Game.RarePity - 1
profile.pity.mythic = Config.Game.MythicPity - 1
for _, outcome in Rules.odds(profile) do
    assert(outcome.rarity == "Mythic" or outcome.rarity == "Divine" or outcome.rarity == "Ascended")
end
-- Existing legacy instances survive the Studio roll-pool change with exact IDs/stats.
profile.characters = {{uid="legacy_owned", characterId="young_rookie", mutation="Normal", level=1, acquiredAt=100}}
profile.placed = {"legacy_owned"}; profile.team = {"legacy_owned"}; profile.coins = 321
local restored = Rules.sanitize(profile, function() return "unused" end, 200)
assert(restored.characters[1].characterId == "young_rookie")
assert(restored.placed[1] == "legacy_owned" and restored.team[1] == "legacy_owned")
assert(restored.coins == 321 and Config.Characters.young_rookie.income == 2)
print("Context validated")
'''.replace("STUDIO_CONTEXT", context)
        with tempfile.TemporaryDirectory() as directory:
            script = Path(directory) / "context.luau"
            script.write_text(source + assertions)
            result = subprocess.run([bundler.binary("luau"), str(script)], cwd=ROOT,
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_private_studio_rolls_have_real_photo_sources_and_retain_legacy_saves(self):
        self.run_gameplay(True)

    def test_published_context_keeps_production_photo_gates(self):
        self.run_gameplay(False)
