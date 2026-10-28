-- Construction-only asset doubles. No mesh rendering, physics, Animator or
-- Roblox property validation is simulated by these objects.
local Base = require("./runtime")
local Runtime = { parenting = {} }
Runtime.workspace, Runtime.task, Runtime.warn = Base.workspace, Base.task, Base.warn
Runtime.Enum = {
	HumanoidRigType = { R15 = "R15", R6 = "R6" },
	HumanoidDisplayDistanceType = { None = "None" },
}

local Methods = {}
local Meta = {}
local parts = { Part = true, MeshPart = true, WedgePart = true }
local function removeChild(parent, item)
	if not parent then return end
	for index, child in parent._children do
		if child == item then table.remove(parent._children, index); return end
	end
end

function Meta.__index(self, key)
	return Methods[key] or self._properties[key]
end
function Meta.__newindex(self, key, value)
	if string.sub(key, 1, 1) == "_" then rawset(self, key, value); return end
	if key == "Parent" then
		removeChild(self._properties.Parent, self)
		self._properties.Parent = value
		if value then
			table.insert(value._children, self)
			if self.ClassName == "Model" then
				table.insert(Runtime.parenting, { object = self, parent = value, classes = self:classCounts() })
			end
		end
	else self._properties[key] = value end
end

function Runtime.object(className, name)
	return setmetatable({ _children = {}, _attributes = {}, _properties = {
		ClassName = className, Name = name or className, CanCollide = true,
		Anchored = false, CanTouch = true,
	}, _bounds = { X = 4, Y = 8, Z = 2 }, _scale = 1 }, Meta)
end

function Methods:IsA(className)
	return className == self.ClassName or (className == "BasePart" and parts[self.ClassName] == true)
		or (className == "BaseScript" and (self.ClassName == "Script" or self.ClassName == "LocalScript"))
end
function Methods:GetChildren() return table.clone(self._children) end
function Methods:GetDescendants()
	local result = {}
	local function visit(item)
		for _, child in item._children do table.insert(result, child); visit(child) end
	end
	visit(self)
	return result
end
function Methods:FindFirstChild(name)
	for _, child in self._children do if child.Name == name then return child end end
	return nil
end
function Methods:FindFirstChildOfClass(className)
	for _, child in self._children do if child.ClassName == className then return child end end
	return nil
end
function Methods:FindFirstAncestorOfClass(className)
	local parent = self.Parent
	while parent do if parent.ClassName == className then return parent end; parent = parent.Parent end
	return nil
end
function Methods:SetAttribute(key, value) self._attributes[key] = value end
function Methods:GetAttribute(key) return self._attributes[key] end
function Methods:GetBoundingBox() return nil, self._bounds end
function Methods:GetScale() return self._scale end
function Methods:ScaleTo(value) self._scale = value end
function Methods:PivotTo(value) self._pivot = value end
function Methods:SetNetworkOwner(value) self._owner = value end
function Methods:Destroy()
	for _, child in self:GetChildren() do child:Destroy() end
	self.Parent = nil
	self.Destroyed = true
end
function Methods:Clone()
	if self.Archivable == false then return nil end
	local mapping = {}
	local function cloneTree(source)
		if source.Archivable == false then return nil end
		local target = Runtime.object(source.ClassName, source.Name)
		mapping[source] = target
		for key, value in source._properties do
			if key ~= "Parent" then target._properties[key] = value end
		end
		target._attributes = table.clone(source._attributes)
		target._bounds, target._scale = table.clone(source._bounds), source._scale
		for _, child in source._children do
			local cloned = cloneTree(child)
			if cloned then cloned.Parent = target end
		end
		return target
	end
	local result = cloneTree(self)
	-- Roblox Clone remaps references between descendants to the matching clone.
	for _, target in mapping do
		for key, value in target._properties do
			if mapping[value] then target._properties[key] = mapping[value] end
		end
	end
	return result
end
function Methods:classCounts()
	local result = {}
	for _, item in self:GetDescendants() do result[item.ClassName] = (result[item.ClassName] or 0) + 1 end
	return result
end

function Runtime.add(parent, className, name)
	local child = Runtime.object(className, name)
	child.Parent = parent
	return child
end

function Runtime.reset()
	Runtime.parenting = {}
	Runtime.storage = Runtime.object("Folder", "ApprovedAssets")
	Runtime.world = Runtime.object("Folder", "TestWorld")
end

function Runtime.rig(name)
	local model = Runtime.object("Model", name or "R15Template")
	local humanoid = Runtime.add(model, "Humanoid", "Humanoid")
	humanoid.RigType = Runtime.Enum.HumanoidRigType.R15
	local bodyNames = {
		"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
		"RightUpperLeg", "RightLowerLeg", "RightFoot",
	}
	local bodies = {}
	for _, bodyName in bodyNames do bodies[bodyName] = Runtime.add(model, "MeshPart", bodyName) end
	local edges = {
		{ "HumanoidRootPart", "LowerTorso" }, { "LowerTorso", "UpperTorso" }, { "UpperTorso", "Head" },
		{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
	}
	for index, edge in edges do
		local motor = Runtime.add(model, "Motor6D", "Joint" .. index)
		motor.Part0, motor.Part1 = bodies[edge[1]], bodies[edge[2]]
	end
	return model
end

Runtime.game = { JobId = "asset-test-job" }
function Runtime.game:GetService(name)
	if name == "ServerStorage" then
		return { FindFirstChild = function(_, key) return if key == "ApprovedAssets" then Runtime.storage else nil end }
	end
	return Base.game:GetService(name)
end

Runtime.reset()
return Runtime
