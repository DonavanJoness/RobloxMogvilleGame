--!strict
-- Photo data is reconstructed on each client: EditableImage Content does not replicate.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog: any = require(Shared:WaitForChild("EmbeddedPhotoCatalog"))
local PhotoBase64: any = require(Shared:WaitForChild("PhotoBase64"))
local Controller = {}
local suppliedImages = 0
for _, entry in Catalog do
	if type(entry) == "table" and entry.sourceVerified == true and entry.adultEraVerified == true and entry.ownerAuthorized == true then suppliedImages += 1 end
end
local MAX_IMAGES = math.clamp(suppliedImages, 1, 32)
local cache: { [string]: any } = {}
local failures: { [string]: string } = {}
local pending: { [string]: BindableEvent } = {}
local bound: { [Instance]: RBXScriptConnection } = setmetatable({}, { __mode = "k" }) :: any
local applied: { [Instance]: string } = setmetatable({}, { __mode = "k" }) :: any
local count = 0
local descendantConnection: RBXScriptConnection? = nil

function Controller.record(identity: any): any
	local entry = if type(identity) == "string" then Catalog[identity] else nil
	if type(entry) ~= "table" or entry.sourceVerified ~= true or entry.adultEraVerified ~= true
		or entry.ownerAuthorized ~= true then return nil end
	return entry
end

function Controller.identity(_characterId: any, visual: any?): string?
	if type(visual) == "table" then
		local key = visual.embeddedIdentityId
		if Controller.record(key) then return key end
	end
	return nil
end

local function getImage(identity: string): (any, string?)
	if not RunService:IsStudio() then return nil, "Embedded source photos are available in Studio preview only" end
	if cache[identity] then return cache[identity].content, nil end
	if failures[identity] then return nil, failures[identity] end
	if pending[identity] then
		pending[identity].Event:Wait()
		return if cache[identity] then cache[identity].content else nil, failures[identity]
	end
	local entry = Controller.record(identity)
	if not entry then return nil, "No sourced photograph for this identity" end
	if count >= MAX_IMAGES then return nil, "Photo memory budget reached; restart Play" end
	if type(entry.width) ~= "number" or type(entry.height) ~= "number" or entry.width % 1 ~= 0
		or entry.height % 1 ~= 0 or entry.width < 1 or entry.height < 1 or entry.width > 512 or entry.height > 512 then
		return nil, "Invalid embedded photo dimensions"
	end
	local signal = Instance.new("BindableEvent")
	pending[identity] = signal
	count += 1 -- Reserve before any engine call so concurrent identities obey the budget.
	local image: any = nil
	local stage = "decode"
	local ok, result = pcall(function()
		local pixels, problem = PhotoBase64.decode(entry.rgbaBase64, entry.width * entry.height * 4)
		if not pixels then error(problem or "Invalid photo pixels") end
		stage = "create"
		image = AssetService:CreateEditableImage({ Size = Vector2.new(entry.width, entry.height) })
		if not image then stage = "budget"; error("EditableImage memory allocation failed") end
		stage = "write"
		image:WritePixelsBuffer(Vector2.zero, Vector2.new(entry.width, entry.height), pixels)
		return Content.fromObject(image)
	end)
	if ok then
		cache[identity] = { image = image, content = result }
	else
		if image then image:Destroy() end
		count -= 1
		failures[identity] = if stage == "decode" then "Embedded photo data is damaged; reopen the original place download."
			elseif stage == "budget" then "Photo memory budget reached; restart Play."
			else "Photo display unavailable. Enable Allow Mesh / Image APIs in Experience Settings > Security, then restart Play."
		warn("MOGVILLE photo " .. identity .. ": " .. tostring(result))
	end
	pending[identity] = nil
	signal:Fire()
	task.defer(function() signal:Destroy() end)
	return if cache[identity] then cache[identity].content else nil, failures[identity]
end

function Controller.apply(imageLabel: ImageLabel, identity: string): (boolean, string?)
	if not RunService:IsStudio() then return false, "Embedded source photos are available in Studio preview only" end
	if applied[imageLabel] == identity then return true, nil end
	local content, problem = getImage(identity)
	if not content then return false, problem end
	if not imageLabel.Parent then return false, "Photo panel was closed" end
	local ok, failure = pcall(function()
		imageLabel.ImageContent = content
		imageLabel.Visible = true
	end)
	if not ok then return false, tostring(failure) end
	applied[imageLabel] = identity
	return true, nil
end

local function bindWorld(instance: Instance)
	if not instance:IsA("ImageLabel") or bound[instance] then return end
	local function update()
		local identity = instance:GetAttribute("MogvillePortraitIdentity")
		if type(identity) ~= "string" or not Controller.record(identity) then return end
		local ok, problem = Controller.apply(instance, identity)
		local existing = instance:FindFirstChild("PhotoDisplayError")
		if ok then
			if existing then existing:Destroy() end
			return
		end
		if not instance.Parent then return end
		local message = existing or Instance.new("TextLabel")
		message.Name = "PhotoDisplayError"
		local label = message :: TextLabel
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(0.94, 0.94)
		label.Position = UDim2.fromScale(0.03, 0.03)
		label.Text = problem or "Photo display unavailable"
		label.TextWrapped = true
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 224, 190)
		label.Font = Enum.Font.GothamMedium
		label.ZIndex = 4
		label.Parent = instance
		instance.Visible = true
	end
	bound[instance] = instance:GetAttributeChangedSignal("MogvillePortraitIdentity"):Connect(function() task.spawn(update) end)
	instance.Destroying:Connect(function()
		local connection = bound[instance]
		if connection then connection:Disconnect(); bound[instance] = nil end
		applied[instance] = nil
	end)
	task.spawn(update)
end

function Controller.start()
	if descendantConnection then return end
	descendantConnection = workspace.DescendantAdded:Connect(bindWorld)
	for _, instance in workspace:GetDescendants() do bindWorld(instance) end
end

function Controller.stop()
	if descendantConnection then descendantConnection:Disconnect(); descendantConnection = nil end
	for instance, connection in bound do connection:Disconnect(); bound[instance] = nil end
	for identity, value in cache do value.image:Destroy(); cache[identity] = nil end
	table.clear(applied)
	table.clear(failures)
	count = 0
end

return Controller
