"""Run the actual client photo module with explicit engine doubles, never Roblox uploads."""
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EmbeddedClientTests(unittest.TestCase):
    def test_pixel_cache_studio_scope_and_failed_image_cleanup(self):
        runtime = ROOT / ".tools/bin/luau"
        if not runtime.is_file():
            self.skipTest("Install the project Luau runtime first")
        source = (ROOT / "src/client/Controllers/EmbeddedPhotoController.luau").read_text()
        source = source.replace('require(Shared:WaitForChild("EmbeddedPhotoCatalog"))', 'TestCatalog')
        source = source.replace('require(Shared:WaitForChild("PhotoBase64"))', 'TestDecoder')
        decoder = (ROOT / "src/shared/PhotoBase64.luau").read_text()
        harness = r'''
local studio, creates, writes, destroys = true, 0, 0, 0
local engineFailure, writeFailure = false, false
local row = {width=1,height=1,rgbaBase64="AP8QIA==",sourceVerified=true,adultEraVerified=true,ownerAuthorized=true}
local TestCatalog = { person = row, malformed = table.clone(row), writeFailure = table.clone(row) }
local TestDecoder = (function()
DECODER_SOURCE
end)()
local Vector2 = {zero = {X=0,Y=0}, new = function(x,y) return {X=x,Y=y} end}
local Content = {fromObject = function(image) return {Object=image} end}
local task = {defer=function(fn) fn() end}
local warn = function(_) end
local Instance = {new=function(class)
    assert(class=="BindableEvent")
    return {Event={Wait=function() error("unexpected concurrent wait") end},Fire=function() end,Destroy=function() end}
end}
local shared = {WaitForChild=function(_,name) return name end}
local services = {
    ReplicatedStorage={WaitForChild=function() return shared end},
    RunService={IsStudio=function() return studio end},
    AssetService={CreateEditableImage=function(_,options)
        creates += 1
        if engineFailure then error("image API denied") end
        assert(options.Size.X==1 and options.Size.Y==1)
        return {
            WritePixelsBuffer=function(_,position,size,pixels)
                if writeFailure then error("write denied") end
                writes += 1
                assert(position.X==0 and position.Y==0 and size.X==1 and size.Y==1)
                assert(buffer.tostring(pixels)==string.char(0,255,16,32))
            end,
            Destroy=function() destroys += 1 end,
        }
    end},
}
local game = {GetService=function(_,name) assert(services[name],name); return services[name] end}
local Controller = (function()
CLIENT_SOURCE
end)()

assert(Controller.identity("real_person_classic",{identityId="person"})==nil,"ID must not bypass preview scope")
assert(Controller.identity("real_person_classic",{embeddedIdentityId="person"})=="person")
local a,b = {Parent=true},{Parent=true}
assert(Controller.apply(a,"person"))
assert(Controller.apply(b,"person"))
assert(creates==1 and writes==1 and a.ImageContent==b.ImageContent,"reuse one EditableImage")
studio=false
local ok,problem = Controller.apply({Parent=true},"person")
assert(not ok and string.find(problem,"Studio"),"cached pixels remain Studio scoped")
assert(not Controller.apply(a,"person"),"already-bound label cannot bypass scope")
studio=true
TestCatalog.malformed.rgbaBase64="bad"
local oldCreates=creates
ok,problem=Controller.apply({Parent=true},"malformed")
assert(not ok and string.find(problem,"damaged") and creates==oldCreates)
writeFailure=true
ok,problem=Controller.apply({Parent=true},"writeFailure")
assert(not ok and string.find(problem,"Allow Mesh") and destroys==1,"destroy partial allocation")
writeFailure=false
Controller.stop()
assert(destroys==2,"stop destroys the successful cache")
assert(Controller.apply({Parent=true},"person"),"stop clears transient failure state")
Controller.stop()
engineFailure=true
ok,problem=Controller.apply({Parent=true},"person")
assert(not ok and string.find(problem,"Allow Mesh"))
engineFailure=false
oldCreates=creates
ok=Controller.apply({Parent=true},"person")
assert(not ok and creates==oldCreates,"failed API is memoized until restart")
Controller.stop()
assert(Controller.apply({Parent=true},"person"))
Controller.stop()
print("PASS actual embedded client: cache, RGBA bytes, Studio scope, invalid data, failed image cleanup and retry")
'''.replace("DECODER_SOURCE", decoder).replace("CLIENT_SOURCE", source)
        with tempfile.TemporaryDirectory() as temporary:
            script = Path(temporary) / "client-test.luau"
            script.write_text(harness)
            result = subprocess.run([str(runtime), str(script)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PASS actual embedded client", result.stdout)
