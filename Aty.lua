-- HyperShot Dark-Cyan Utility UI v4 (Adjustable FOV Circle + Auto Shoot + Anti-Recoil)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local existingGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("HyperShotCyanHub")
if existingGui then
	existingGui:Destroy()
end

pcall(function()
	RunService:UnbindFromRenderStep("HyperShotCyanAimLock")
end)

local State = {
	AimMode = "OFF",      -- "OFF" | "HEAD" | "BODY"
	AutoShoot = false,    -- ยิงเองอัตโนมัติเมื่อเป้าอยู่ในวง
	AntiRecoil = false,   -- ลดแรงดีดปืน
	HideName = false,     -- ซ่อนชื่อตัวเอง
	ShowCircle = true,    -- แสดงวงกลมตรงเป้า
	Minimized = false,    -- พับเก็บหน้าต่าง
	FOVRadius = 140,      -- รัศมีวงกลมตรงกลางจอ (ปรับได้)
	LockStrength = 0.65,  -- ความนิ่งในการหันเข้าเป้า (0.1 - 1.0)
	RecoilPull = 0.35,    -- แรงดึงกลับเวลาปืนดีด
	LastShotTime = 0,
	ShotCooldown = 0.08
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HyperShotCyanHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- วงกลมตรงกลางจอ (FOV Circle)
local FovCircle = Instance.new("Frame")
FovCircle.Name = "FovCircle"
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FovCircle.Size = UDim2.new(0, State.FOVRadius * 2, 0, State.FOVRadius * 2)
FovCircle.BackgroundTransparency = 1
FovCircle.Visible = State.ShowCircle
FovCircle.Active = false
FovCircle.Parent = ScreenGui

local FovCorner = Instance.new("UICorner")
FovCorner.CornerRadius = UDim.new(1, 0)
FovCorner.Parent = FovCircle

local FovStroke = Instance.new("UIStroke")
FovStroke.Color = Color3.fromRGB(0, 210, 255)
FovStroke.Thickness = 1.6
FovStroke.Transparency = 0.2
FovStroke.Parent = FovCircle

local function updateFovCircle()
	local diameter = State.FOVRadius * 2
	FovCircle.Size = UDim2.new(0, diameter, 0, diameter)
	FovCircle.Visible = State.ShowCircle
end

-- หน้าต่างหลัก สีดำ-ฟ้า ขนาดพอดีมือ (256 x 315 px)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 256, 0, 315)
MainFrame.Position = UDim2.new(0.5, -128, 0.32, -157)
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 16, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 195, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.25
MainStroke.Parent = MainFrame

-- แถบด้านบนสำหรับลากย้าย
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(16, 26, 43)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local TopCover = Instance.new("Frame")
TopCover.Size = UDim2.new(1, 0, 0, 12)
TopCover.Position = UDim2.new(0, 0, 1, -12)
TopCover.BackgroundColor3 = Color3.fromRGB(16, 26, 43)
TopCover.BorderSizePixel = 0
TopCover.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -46, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "HYPERSHOT // CYAN v4"
TitleLabel.TextColor3 = Color3.fromRGB(110, 225, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 28, 0, 26)
ToggleBtn.Position = UDim2.new(1, -36, 0.5, -13)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 42, 68)
ToggleBtn.Text = "-"
ToggleBtn.TextColor3 = Color3.fromRGB(130, 235, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Parent = TopBar

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 7)
ToggleCorner.Parent = ToggleBtn

-- พื้นที่ปุ่มควบคุมภายใน
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -20, 1, -48)
ContentFrame.Position = UDim2.new(0, 10, 0, 44)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local function createToggleButton(name, text, posY, accentColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.Position = UDim2.new(0, 0, 0, posY)
	btn.BackgroundColor3 = Color3.fromRGB(18, 28, 45)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(225, 245, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12.5
	btn.Parent = ContentFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = accentColor
	stroke.Thickness = 1.2
	stroke.Transparency = 0.45
	stroke.Parent = btn

	return btn, stroke
end

local HeadBtn, HeadStroke = createToggleButton("HeadBtn", "ล็อคหัว : ปิด", 0, Color3.fromRGB(0, 195, 255))
local BodyBtn, BodyStroke = createToggleButton("BodyBtn", "ล็อคตัว : ปิด", 46, Color3.fromRGB(0, 155, 225))
local AutoShootBtn, AutoShootStroke = createToggleButton("AutoShootBtn", "ยิงในวงอัตโนมัติ : ปิด", 92, Color3.fromRGB(34, 211, 238))
local RecoilBtn, RecoilStroke = createToggleButton("RecoilBtn", "ลดแรงดีดปืน : ปิด", 138, Color3.fromRGB(14, 165, 233))
local HideNameBtn, HideNameStroke = createToggleButton("HideNameBtn", "ซ่อนชื่อตัวเอง : ปิด", 184, Color3.fromRGB(56, 189, 248))

-- แถบปรับขนาดวงกลมตรงเป้า (+ / -)
local FovRow = Instance.new("Frame")
FovRow.Name = "FovRow"
FovRow.Size = UDim2.new(1, 0, 0, 32)
FovRow.Position = UDim2.new(0, 0, 0, 230)
FovRow.BackgroundColor3 = Color3.fromRGB(15, 24, 39)
FovRow.BorderSizePixel = 0
FovRow.Parent = ContentFrame

local FovRowCorner = Instance.new("UICorner")
FovRowCorner.CornerRadius = UDim.new(0, 8)
FovRowCorner.Parent = FovRow

local FovMinusBtn = Instance.new("TextButton")
FovMinusBtn.Size = UDim2.new(0, 36, 1, 0)
FovMinusBtn.Position = UDim2.new(0, 0, 0, 0)
FovMinusBtn.BackgroundColor3 = Color3.fromRGB(22, 38, 62)
FovMinusBtn.Text = "-"
FovMinusBtn.TextColor3 = Color3.fromRGB(125, 225, 255)
FovMinusBtn.Font = Enum.Font.GothamBold
FovMinusBtn.TextSize = 15
FovMinusBtn.Parent = FovRow

local FovMinusCorner = Instance.new("UICorner")
FovMinusCorner.CornerRadius = UDim.new(0, 8)
FovMinusCorner.Parent = FovMinusBtn

local FovLabel = Instance.new("TextLabel")
FovLabel.Size = UDim2.new(1, -72, 1, 0)
FovLabel.Position = UDim2.new(0, 36, 0, 0)
FovLabel.BackgroundTransparency = 1
FovLabel.Text = "ขนาดวง : " .. tostring(State.FOVRadius)
FovLabel.TextColor3 = Color3.fromRGB(185, 235, 255)
FovLabel.Font = Enum.Font.GothamBold
FovLabel.TextSize = 12
FovLabel.Parent = FovRow

local FovPlusBtn = Instance.new("TextButton")
FovPlusBtn.Size = UDim2.new(0, 36, 1, 0)
FovPlusBtn.Position = UDim2.new(1, -36, 0, 0)
FovPlusBtn.BackgroundColor3 = Color3.fromRGB(22, 38, 62)
FovPlusBtn.Text = "+"
FovPlusBtn.TextColor3 = Color3.fromRGB(125, 225, 255)
FovPlusBtn.Font = Enum.Font.GothamBold
FovPlusBtn.TextSize = 15
FovPlusBtn.Parent = FovRow

local FovPlusCorner = Instance.new("UICorner")
FovPlusCorner.CornerRadius = UDim.new(0, 8)
FovPlusCorner.Parent = FovPlusBtn

-- ระบบลากย้ายหน้าต่างแบบลื่นๆ ทั้งทัชสกรีนและเมาส์
local dragging = false
local dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

TopBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local function setButtonActive(btn, stroke, activeText, inactiveText, isActive)
	if isActive then
		btn.Text = activeText
		btn.BackgroundColor3 = Color3.fromRGB(0, 95, 145)
		stroke.Transparency = 0
	else
		btn.Text = inactiveText
		btn.BackgroundColor3 = Color3.fromRGB(18, 28, 45)
		stroke.Transparency = 0.45
	end
end

local function refreshAimUI()
	setButtonActive(HeadBtn, HeadStroke, "ล็อคหัว : เปิดอยู่", "ล็อคหัว : ปิด", State.AimMode == "HEAD")
	setButtonActive(BodyBtn, BodyStroke, "ล็อคตัว : เปิดอยู่", "ล็อคตัว : ปิด", State.AimMode == "BODY")
end

HeadBtn.MouseButton1Click:Connect(function()
	State.AimMode = (State.AimMode == "HEAD") and "OFF" or "HEAD"
	refreshAimUI()
end)

BodyBtn.MouseButton1Click:Connect(function()
	State.AimMode = (State.AimMode == "BODY") and "OFF" or "BODY"
	refreshAimUI()
end)

AutoShootBtn.MouseButton1Click:Connect(function()
	State.AutoShoot = not State.AutoShoot
	setButtonActive(AutoShootBtn, AutoShootStroke, "ยิงในวงอัตโนมัติ : เปิดอยู่", "ยิงในวงอัตโนมัติ : ปิด", State.AutoShoot)
end)

RecoilBtn.MouseButton1Click:Connect(function()
	State.AntiRecoil = not State.AntiRecoil
	setButtonActive(RecoilBtn, RecoilStroke, "ลดแรงดีดปืน : เปิดอยู่", "ลดแรงดีดปืน : ปิด", State.AntiRecoil)
end)

local function applyHideSelfName(shouldHide)
	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if shouldHide then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.NameDisplayDistance = 0
		else
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
			humanoid.NameDisplayDistance = 100
		end
	end

	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BillboardGui") then
			obj.Enabled = not shouldHide
		end
	end
end

HideNameBtn.MouseButton1Click:Connect(function()
	State.HideName = not State.HideName
	setButtonActive(HideNameBtn, HideNameStroke, "ซ่อนชื่อตัวเอง : เปิดอยู่", "ซ่อนชื่อตัวเอง : ปิด", State.HideName)
	applyHideSelfName(State.HideName)
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	if State.HideName then
		applyHideSelfName(true)
	end
end)

-- ปุ่มปรับขนาดวงกลมตรงเป้า
FovMinusBtn.MouseButton1Click:Connect(function()
	State.FOVRadius = math.clamp(State.FOVRadius - 20, 50, 320)
	FovLabel.Text = "ขนาดวง : " .. tostring(State.FOVRadius)
	updateFovCircle()
end)

FovPlusBtn.MouseButton1Click:Connect(function()
	State.FOVRadius = math.clamp(State.FOVRadius + 20, 50, 320)
	FovLabel.Text = "ขนาดวง : " .. tostring(State.FOVRadius)
	updateFovCircle()
end)

ToggleBtn.MouseButton1Click:Connect(function()
	State.Minimized = not State.Minimized
	if State.Minimized then
		ContentFrame.Visible = false
		MainFrame.Size = UDim2.new(0, 256, 0, 38)
		ToggleBtn.Text = "+"
	else
		MainFrame.Size = UDim2.new(0, 256, 0, 315)
		ContentFrame.Visible = true
		ToggleBtn.Text = "-"
	end
end)

local function isSameTeamModel(model)
	local matchedPlayer = Players:GetPlayerFromCharacter(model)
	if matchedPlayer and LocalPlayer.Team and matchedPlayer.Team then
		return LocalPlayer.Team == matchedPlayer.Team
	end
	return false
end

local function getTargetPartFromCharacter(character, mode)
	if not character or character == LocalPlayer.Character then return nil end
	if isSameTeamModel(character) then return nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end

	if mode == "HEAD" then
		local head = character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			return head
		end
		return character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
	else
		return character:FindFirstChild("HumanoidRootPart")
			or character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("Head")
	end
end

local function collectCandidateCharacters()
	local list = {}
	local seen = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			seen[player.Character] = true
			table.insert(list, player.Character)
		end
	end

	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") then
			local model = desc.Parent
			if model ~= LocalPlayer.Character and not seen[model] then
				seen[model] = true
				table.insert(list, model)
			end
		end
	end

	return list
end

-- คืนค่า: targetPart, screenDistance จากจุดศูนย์กลางจอ
local function getClosestTargetInCircle(mode)
	Camera = Workspace.CurrentCamera
	if not Camera then return nil, math.huge end

	local viewportSize = Camera.ViewportSize
	local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
	local closestPart = nil
	local shortestDistance = State.FOVRadius

	for _, character in ipairs(collectCandidateCharacters()) do
		local targetPart = getTargetPartFromCharacter(character, mode)
		if targetPart then
			local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
			if onScreen and screenPos.Z > 0 then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
				if dist <= shortestDistance then
					shortestDistance = dist
					closestPart = targetPart
				end
			end
		end
	end

	return closestPart, shortestDistance
end

-- ยิงอัตโนมัติแบบสั้นๆ เมื่อเป้าเข้ามาอยู่ในวงกลม
local function triggerAutoFire()
	local now = os.clock()
	if now - State.LastShotTime < State.ShotCooldown then return end
	State.LastShotTime = now

	pcall(function()
		local cam = Workspace.CurrentCamera
		local center = cam and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) or Vector2.new(500, 300)
		VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
		task.delay(0.03, function()
			pcall(function()
				VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
			end)
		end)
	end)
end

-- ตัวแปรช่วยลดแรงดีดปืน (เทียบมุมกล้องเฟรมก่อนหน้ากับเฟรมปัจจุบัน)
local previousLookVector = nil

local function applyCombatStep()
	Camera = Workspace.CurrentCamera
	if not Camera then return end

	local currentCF = Camera.CFrame
	local currentLook = currentCF.LookVector

	-- 1) ลดแรงดีดปืน: ถ้ากล้องถูกดีดขึ้น/เหวี่ยงออกไปกะทันหัน ให้ช่วยดึงกลับเข้าแนวเดิมบางส่วน
	if State.AntiRecoil and previousLookVector then
		local _, pitchDiff, _ = currentCF:ToOrientation()
		local _, prevPitch, _ = previousLookVector and CFrame.lookAt(Vector3.zero, previousLookVector):ToOrientation() or 0, 0, 0
		if pitchDiff > prevPitch then
			local stabilizedLook = currentLook:Lerp(previousLookVector, State.RecoilPull).Unit
			currentCF = CFrame.lookAt(currentCF.Position, currentCF.Position + stabilizedLook)
			Camera.CFrame = currentCF
		end
	end

	-- 2) ล็อคหัว / ล็อคตัว + เช็กยิงอัตโนมัติในวงกลม
	local checkMode = (State.AimMode ~= "OFF") and State.AimMode or "HEAD"
	local targetPart, screenDist = getClosestTargetInCircle(checkMode)

	if targetPart then
		local inCircle = screenDist <= State.FOVRadius

		if State.AimMode ~= "OFF" and inCircle then
			local aimPos = targetPart.Position
			local desiredCF = CFrame.lookAt(currentCF.Position, aimPos)
			-- แยกแกนหันซ้าย-ขวา และขึ้น-ลง แบบไม่ให้มุมกล้องเอียงมั่ว
			local blendedCF = currentCF:Lerp(desiredCF, State.LockStrength)
			local cleanLook = blendedCF.LookVector.Unit
			Camera.CFrame = CFrame.lookAt(currentCF.Position, currentCF.Position + cleanLook)
			FovStroke.Color = Color3.fromRGB(0, 255, 180)
		else
			FovStroke.Color = Color3.fromRGB(0, 210, 255)
		end

		if State.AutoShoot and inCircle then
			triggerAutoFire()
		end
	else
		FovStroke.Color = Color3.fromRGB(0, 210, 255)
	end

	previousLookVector = Camera.CFrame.LookVector
end

RunService:BindToRenderStep("HyperShotCyanAimLock", Enum.RenderPriority.Camera.Value + 1, applyCombatStep)
