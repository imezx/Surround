--!optimize 2
--!native
local Surround = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local scheduler = require(ReplicatedStorage:WaitForChild("scheduler"))

local begin_profiler, end_profiler = scheduler.profiler.Begin, scheduler.profiler.End
local Player: Player = game:GetService("Players").LocalPlayer

type Object = {
	root: BasePart,
	sound: Sound,
	baseVolume: number,
	max_distance: number,
}

local default_max_distance: number = 35
local throttle: number = 1 / 24
local last_throttle: number = 0
local objects: { Object } = {}
local queued: { Object } = {}

Surround.addObject = function(_object: BasePart, sound: Sound, baseVolume: number?, max_distance: number?)
	if not _object or not sound then
		return
	end
	local object: BasePart = _object
	if _object:IsA("Model") and _object.PrimaryPart then
		object = _object.PrimaryPart
	end
	if not object:IsA("BasePart") then
		return
	end
	table.insert(objects, {
		root = object,
		sound = sound,
		baseVolume = baseVolume or sound.Volume,
		max_distance = max_distance or default_max_distance,
	})
end

RunService.PreRender:Connect(function(dt: number)
	if last_throttle <= throttle then
		last_throttle += dt
		return
	end
	last_throttle = 0
	local character = Player.Character
	local characterRoot: BasePart? = character and character.PrimaryPart
	if not characterRoot then
		return
	end
	begin_profiler("Surround.simulate")
	local characterPos: Vector3 = characterRoot.Position
	if next(queued) then
		local sounds: { [Sound]: number } = {}
		for _, object: Object in queued do
			local pos: Vector3 = object.root.Position
			local volume: number = math.max(0, object.baseVolume - (pos - characterPos).Magnitude / object.max_distance)
			local highest_volume: number = sounds[object.sound] or -1
			if volume <= highest_volume then
				continue
			end
			sounds[object.sound] = volume
		end
		table.clear(queued)
		for sound: Sound, volume: number in sounds do
			sound.Volume = volume
		end
	else
		for idx: number, object: Object in objects do
			if not object.root or not object.sound then
				objects[idx] = nil
				continue
			end
			if not object.root:IsDescendantOf(workspace) then
				continue
			end
			table.insert(queued, object)
		end
	end
	end_profiler("Surround.simulate")
end)

return Surround :: typeof(Surround)
