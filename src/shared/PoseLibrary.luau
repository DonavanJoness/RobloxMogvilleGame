--!strict
-- Baked static stances (Motor6D.C0 offsets) plus procedural idle motion. No animation assets.
-- Angles are degrees {x, y, z} applied as CFrame.Angles on top of the joint's NEUTRAL C0.
-- Character convention: right side is +X, front is -Z. Joint rotations were checked in
-- tests/looks.spec.luau (hands must end above the shoulder for raised arms, etc.).
--   Shoulder z>0 swings the RIGHT arm outward/up (left arm uses -z); x>0 swings it forward.
--   Elbow z bends the forearm in the arm's own plane (keeps "raise" poses intuitive);
--   Elbow x>0 bends the forearm forward.
local PoseLibrary = {}

PoseLibrary.Poses = {
	stand = { RightShoulder = { 0, 0, 6 }, LeftShoulder = { 0, 0, -6 } },
	relaxed = { RightShoulder = { 4, 0, 11 }, LeftShoulder = { -4, 0, -11 }, Neck = { 0, -8, 0 } },
	flex = { RightShoulder = { 0, 0, 80 }, RightElbow = { 0, 0, 90 }, LeftShoulder = { 0, 0, -80 }, LeftElbow = { 0, 0, -90 }, Neck = { -6, 0, 0 } },
	victory = { RightShoulder = { 0, 0, 150 }, RightElbow = { 0, 0, 10 }, LeftShoulder = { 0, 0, -8 }, Neck = { -4, 0, 6 } },
	wave = { RightShoulder = { 0, 0, 125 }, RightElbow = { 0, 0, 35 }, LeftShoulder = { 0, 0, -6 }, Neck = { 0, 0, 5 } },
	present = {
		RightShoulder = { 55, 0, 28 }, RightElbow = { 25, 0, 0 }, LeftShoulder = { -25, 0, -14 }, LeftElbow = { 50, 0, 0 },
		Waist = { 0, -10, 0 }, Neck = { 0, 10, 0 },
	},
	salute = { RightShoulder = { 20, 0, 95 }, RightElbow = { 0, 0, 128 }, LeftShoulder = { 0, 0, -6 }, Neck = { -4, 0, 0 } },
	guard = { RightShoulder = { 22, 0, 8 }, RightElbow = { 70, 0, 0 }, LeftShoulder = { 22, 0, -8 }, LeftElbow = { 70, 0, 0 }, Neck = { -4, 0, 0 } },
	crossed = { RightShoulder = { 40, 0, -18 }, RightElbow = { 105, 0, 0 }, LeftShoulder = { 40, 0, 18 }, LeftElbow = { 105, 0, 0 } },
	hips = {
		RightShoulder = { 0, 0, 34 }, RightElbow = { 18, 0, -62 }, LeftShoulder = { 0, 0, -34 }, LeftElbow = { 18, 0, 62 },
		Neck = { 0, 0, 0 },
	},
	starpose = {
		RightShoulder = { 0, 0, 125 }, LeftShoulder = { 0, 0, -125 }, RightHip = { 0, 0, 12 }, LeftHip = { 0, 0, -12 },
		Neck = { -8, 0, 0 },
	},
	stride = {
		RightHip = { 16, 0, 4 }, LeftHip = { -14, 0, -4 }, LeftKnee = { -22, 0, 0 },
		RightShoulder = { -18, 0, 8 }, LeftShoulder = { 18, 0, -8 }, Waist = { 0, 6, 0 },
	},
	lean = {
		Waist = { 0, 0, 5 }, RightHip = { 0, 0, 4 }, LeftHip = { 0, 0, -3 }, RightShoulder = { 0, 0, 14 },
		LeftShoulder = { 12, 0, -30 }, LeftElbow = { 70, 0, 0 }, Neck = { 0, 0, -5 },
	},
}

-- Joints that idle motion drives. Everything else stays in its baked stance.
PoseLibrary.IdleJoints = { "Waist", "Neck", "RightShoulder", "LeftShoulder" }

function PoseLibrary.has(name: string): boolean
	return PoseLibrary.Poses[name] ~= nil
end

local function rad(values: { number }): CFrame
	return CFrame.Angles(math.rad(values[1]), math.rad(values[2]), math.rad(values[3]))
end

-- Pose every listed joint found in `model`. The neutral C0 is remembered the first time a
-- joint is touched so re-posing never accumulates rotation. Returns how many joints moved.
function PoseLibrary.apply(model: Instance, poseName: string): number
	local pose = PoseLibrary.Poses[poseName] or PoseLibrary.Poses.stand
	local moved = 0
	for jointName, angles in pose do
		local joint = model:FindFirstChild(jointName, true)
		if joint and joint:IsA("Motor6D") then
			local neutral = joint:GetAttribute("NeutralC0")
			if typeof(neutral) ~= "CFrame" then
				neutral = joint.C0
				joint:SetAttribute("NeutralC0", neutral)
			end
			joint.C0 = (neutral :: CFrame) * rad(angles)
			moved += 1
		end
	end
	model:SetAttribute("Pose", if PoseLibrary.Poses[poseName] then poseName else "stand")
	return moved
end

-- Small breathing/weight-shift offsets (Motor6D.Transform, client-local, never replicated).
function PoseLibrary.idle(timeSeconds: number, phase: number): { [string]: CFrame }
	local t = timeSeconds + phase
	local breathe = math.sin(t * 1.5)
	return {
		Waist = CFrame.Angles(breathe * 0.015, math.sin(t * 0.5) * 0.02, 0),
		Neck = CFrame.Angles(math.sin(t * 0.9) * 0.01, math.sin(t * 0.4) * 0.14, 0),
		RightShoulder = CFrame.Angles(0, 0, math.sin(t * 1.5 + 0.4) * 0.02),
		LeftShoulder = CFrame.Angles(0, 0, -math.sin(t * 1.5 + 0.4) * 0.02),
	}
end

return PoseLibrary
