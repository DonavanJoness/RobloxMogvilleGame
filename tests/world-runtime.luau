-- Lightweight construction stubs for tools/world_smoke.py. Not a Roblox engine.
-- CFrame translation is retained; rotations/physics/rendering are intentionally not simulated.

local function vec(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,__kind='Vector3'}, {__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end,__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end,__mul=function(a,b)if type(a)=='number' then return vec(a*b.X,a*b.Y,a*b.Z)end return vec(a.X*b,a.Y*b,a.Z*b)end})end
Vector3={new=vec,zero=vec(0,0,0)}
Vector2={new=function(x,y)return {X=x,Y=y}end}
local function frame(x,y,z)
 local p=if type(x)=='table' then x else vec(x,y,z)
 return setmetatable({Position=p,__kind='CFrame'}, {__mul=function(a,b)return frame(a.Position+b.Position)end})
end
CFrame={new=frame,Angles=function(...)return frame(0,0,0)end,lookAt=function(p,_)return frame(p)end}
local realTypeof=typeof
typeof=function(v)if type(v)=='table' and v.__kind then return v.__kind end return realTypeof(v)end
Color3={fromRGB=function(...)return {...}end,fromHex=function(...)return {...}end,fromHSV=function(...)return {...}end}
local constructor={new=function(...)return {...}end}
ColorSequence=constructor; NumberSequence=constructor; NumberSequenceKeypoint=constructor;NumberRange=constructor;UDim=constructor
UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end}
local enumMt={__index=function(_,key)return key end}
Enum=setmetatable({}, {__index=function(t,key)local v=setmetatable({},enumMt);rawset(t,key,v);return v end})
local objects={}
local methods={}
function methods:SetAttribute(k,v)self._attributes[k]=v end
function methods:GetAttribute(k)return self._attributes[k]end
function methods:GetChildren()return table.clone(self._children)end
function methods:GetDescendants()local all={}for _,child in self._children do table.insert(all,child)for _,desc in child:GetDescendants()do table.insert(all,desc)end end return all end
function methods:FindFirstChild(name)for _,child in self._children do if child.Name==name then return child end end return nil end
function methods:WaitForChild(name,_)return assert(self:FindFirstChild(name),'Missing child '..name)end
function methods:Destroy()self:ClearAllChildren();self.Parent=nil;self._destroyed=true end
function methods:ClearAllChildren()for _,child in self:GetChildren()do child:Destroy()end end
function methods:IsA(class)return self.ClassName==class or(class=='BasePart' and(self.ClassName=='Part' or self.ClassName=='SpawnLocation' or self.ClassName=='WedgePart'))end
function methods:PivotTo(cf)self.CFrame=cf end
Instance={new=function(class)
 local obj={_props={ClassName=class,Name=class},_attributes={},_children={}}
 table.insert(objects,obj)
 return setmetatable(obj,{
 __index=function(t,k)
  if methods[k] then return methods[k]end
  if t._props[k]~=nil then return t._props[k]end
  if k=='Position'then return t._props.CFrame and t._props.CFrame.Position or vec(0,0,0)end
  if k=='CFrame'then return frame(t._props.Position or vec(0,0,0))end
  for _,child in t._children do if child.Name==k then return child end end
 end,
 __newindex=function(t,k,v)
  if k=='Parent'then
   local old=t._props.Parent
   if old then for i=#old._children,1,-1 do if old._children[i]==t then table.remove(old._children,i)end end end
   if v then table.insert(v._children,t)end
  end
  if k=='CFrame'then t._props.Position=v.Position end
  if k=='Position'then t._props.CFrame=frame(v)end
  t._props[k]=v
 end})
end}
local tags={}
local collection={}
function collection:AddTag(obj,name)tags[name]=tags[name]or{};table.insert(tags[name],obj)end
function collection:GetTagged(name)local result={}for _,obj in tags[name]or{}do if not obj._destroyed and obj.Parent then table.insert(result,obj)end end return result end
local replicated=Instance.new('ReplicatedStorage')
local shared=Instance.new('Folder');shared.Name='Shared';shared.Parent=replicated
local workspace=Instance.new('Workspace')
local services={CollectionService=collection,Lighting=Instance.new('Lighting'),Workspace=workspace,ReplicatedStorage=replicated}
game={GetService=function(_,name)return assert(services[name],'Missing service '..name)end}
task={spawn=function(fn,...)return fn(...)end}
