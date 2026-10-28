-- Executed against the actual world builders and shared definitions by tools/world_smoke.py.
-- This checks construction, budgets and basic layout math, not Studio rendering or collision.

local world=WorldService.new()
world:build()
assert(#world.plots==12,'12 plots')
local baselineParts=0
for _,instance in world.root:GetDescendants()do if instance:IsA('BasePart')then baselineParts+=1 end end
assert(world.cityInfo.metrics.parts>=500 and world.cityInfo.metrics.parts<=Config.World.MaxStaticParts,'city generation part bounds')
print('BASELINE PARTS '..baselineParts..'; city '..world.cityInfo.metrics.parts)
local standCount=0
for _,plot in world.plots do
 standCount+=#plot.stands
 local spawn=plot.spawnCFrame.Position
 assert(math.abs(spawn.X-plot.origin.X)<44 and math.abs(spawn.Z-plot.origin.Z)<27,'spawn inside residence floor')
 for _,stand in plot.stands do
  assert(math.abs(stand.position.Z-plot.origin.Z)-stand.part.Size.Z/2>=6,'central walking aisle clear of stands')
 end
end
for i,first in world.plots do
 for j,second in world.plots do
  if i<j then assert(math.abs(first.origin.X-second.origin.X)>=88 or math.abs(first.origin.Z-second.origin.Z)>=54,'plot floors do not overlap')end
 end
end
assert(standCount==120,'120 stands')
local nextUid=0
local function uid()nextUid+=1;return 'uid-'..nextUid end
local function event()return {Connect=function(_,fn)local c={connected=true};function c:Disconnect()self.connected=false end;return c end}end
local player={UserId=1234,DisplayName='Mock Collector',CharacterAdded=event(),CharacterRemoving=event()}
local character=Instance.new('Model');character.Name='Player';character.Parent=workspace
local hrp=Instance.new('Part');hrp.Name='HumanoidRootPart';hrp.Parent=character
player.Character=character
assert(world:assign(player),'assign starter player')
local profile=Rules.newProfile(uid,100)
profile.placed={profile.characters[1].uid}
world:render(player,profile)
local plot=world:getPlot(player)
assert(#plot.display:GetChildren()==1,'one starter displayed')
local starterModel=plot.display:GetChildren()[1]
assert(starterModel:GetAttribute('CharacterUID')==profile.characters[1].uid,'display retains acquired instance UID')
assert(starterModel:GetAttribute('OwnerUserId')==player.UserId,'display identifies its owner')
local portrait=starterModel:FindFirstChild('PortraitCard'):FindFirstChild('CharacterPortrait'):FindFirstChild('Frame')
assert(portrait:FindFirstChild('OriginalFallback'),'procedural portrait fallback always present')
local starterVisual=CharacterVisuals.get(profile.characters[1].characterId)
local expectedPortrait=if starterVisual.enabled and starterVisual.portraitAssetId>0 then 'rbxassetid://'..tostring(starterVisual.portraitAssetId) else ''
assert(portrait:FindFirstChild('ApprovedPortrait').Image==expectedPortrait,'portrait follows central approved Roblox ID mapping')
local inspect=starterModel:FindFirstChild('Jacket'):FindFirstChild('OpenInspect')
assert(inspect:GetAttribute('Action')=='Inspect' and inspect:GetAttribute('CharacterUID')==profile.characters[1].uid,'inspection prompt carries exact instance')
assert(plot.stands[1].caption.Visible==false,'occupied stand caption hidden')
assert(Rules.income(profile)>0,'starter earns')
profile.upgrades.slots=7; profile.ascension=5
profile.characters={};profile.placed={}
for i=1,10 do
 local item={uid=uid(),characterId='apex_mogger',mutation='Apex',level=10,acquiredAt=100}
 table.insert(profile.characters,item);table.insert(profile.placed,item.uid)
end
profile.upgrades.petSlots=2
profile.pets={};profile.equippedPets={}
for i=1,3 do local pet={uid=uid(),petId='lucky_cat'};table.insert(profile.pets,pet);table.insert(profile.equippedPets,pet.uid)end
world:render(player,profile)
assert(#plot.display:GetChildren()==10,'ten high-rarity models')
assert(#plot.upgrades:GetChildren()>0,'prestige upgrade geometry')
assert(#plot.pets:GetChildren()==3,'equipped pet companions')
assert(#collection:GetTagged('MogvilleLight')<=24,'global light count budget')
assert(#collection:GetTagged('MogvilleParticles')<=24,'global emitter count budget')
local placedCount=#plot.display:GetChildren()
local cachedModel=plot.display:GetChildren()[1]
world:render(player,profile)
assert(#plot.display:GetChildren()==placedCount and plot.display:GetChildren()[1]==cachedModel,'signature cache keeps same model instances')
local plot2Players={}
for i=2,12 do
 local p={UserId=1234+i,DisplayName='Collector '..i,CharacterAdded=event(),CharacterRemoving=event()}
 assert(world:assign(p),'allocate unique plot '..i)
 assert(world:getPlot(p)~=plot,'unique owner plots')
 local otherCharacter=Instance.new('Model');otherCharacter.Name='Player'..i;otherCharacter.Parent=workspace
 local otherRoot=Instance.new('Part');otherRoot.Name='HumanoidRootPart';otherRoot.Parent=otherCharacter
 p.Character=otherCharacter
 local other=Rules.newProfile(uid,100)
 other.upgrades.slots=7;other.upgrades.petSlots=2;other.ascension=5
 other.characters={};other.placed={};other.pets={};other.equippedPets={}
 for n=1,10 do local item={uid=uid(),characterId='apex_mogger',mutation='Apex',level=10,acquiredAt=100};table.insert(other.characters,item);table.insert(other.placed,item.uid)end
 for n=1,3 do local item={uid=uid(),petId='lucky_cat'};table.insert(other.pets,item);table.insert(other.equippedPets,item.uid)end
 world:render(p,other)
 table.insert(plot2Players,p)
end
local extra={UserId=9999,DisplayName='Extra',CharacterAdded=event(),CharacterRemoving=event()}
assert(world:assign(extra)==false,'full plot server refuses extra')
local peakParts=0
for _,instance in world.root:GetDescendants()do if instance:IsA('BasePart')then peakParts+=1 end end
assert(peakParts<=3300,'full twelve-player part budget')
assert(#collection:GetTagged('MogvilleLight')<=Config.World.MaxLights,'full city light cap')
assert(#collection:GetTagged('MogvilleParticles')<=Config.World.MaxParticleEmitters,'full city emitter cap')
print('FULL CAPACITY PARTS '..peakParts..'; tagged lights '..#collection:GetTagged('MogvilleLight')..'; tagged emitters '..#collection:GetTagged('MogvilleParticles'))
local ownedConnections=world.connections[player]
world:release(player)
for _,connection in ownedConnections do assert(not connection.connected,'released character connections disconnected')end
assert(world:getPlot(player)==nil,'ownership released')
assert(#plot.display:GetChildren()==0 and #plot.pets:GetChildren()==0 and #plot.upgrades:GetChildren()==0,'generated displays cleaned')
assert(plot.stands[1].prompt.Enabled==false,'released prompts disabled')
assert(world:assign(extra),'released plot reusable')
print('WORLD GENERATION MOCK PASS: 12 unique plots,120 stands,starter/fallback portraits,120 Ascended displays,36 pets,prestige,effect caps,cache,capacity,release/reuse')
print('STATIC PARTS '..world.cityInfo.metrics.parts..'; active tagged lights '..#collection:GetTagged('MogvilleLight')..'; active tagged emitters '..#collection:GetTagged('MogvilleParticles'))
