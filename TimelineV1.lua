--TIMELINE RUNTIME V1 BY CRAZYBLOX

--------TERMS AND CONDITIONS:
--This script is open source and falls under the Creative Commons (CC BY-SA 4.0) license.
--In essence, this is free to use/edit/share etc, but you MUST credit, disclose changes, share and maintain the same license/T&C's.
--A good place to credit Crazyblox (The author of this script) is within your work's publicly accessible credits, such as your games description.

local Timelines = script.Parent:WaitForChild("Timelines")
if not Timelines then error("Map requires 'Timelines' to function") end
local Lib = workspace.Multiplayer.GetMapVals:Invoke()
local TweenService = game:GetService("TweenService")
local TimelinePlayer = {}

--Changes state of water and changes color
function TimelinePlayer.SetWaterState(water, state, noChangeColor, specifiedColor)
	if water:IsA("BasePart") then
		local oldColor = water.Color
		local newColor = specifiedColor or
			(string.lower(state) == "water" or state == nil) and BrickColor.new("Deep blue").Color
			or string.lower(state) == "acid" and BrickColor.new("Lime green").Color
			or string.lower(state) == "lava" and BrickColor.new("Really red").Color
		if noChangeColor ~= true then
			local tInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
			local PropTable = {Color = newColor} 
			local ColorTween = TweenService:Create(water, tInfo, PropTable)
			ColorTween:Play()
		end
		delay(1, function()
			local updState = water:FindFirstChild("WaterState")
			if updState then updState.Value = string.lower(state) end

			if noChangeColor ~= true then water.Color = newColor end
		end)
	end
end

--Function that moves parts and models; used primarily for floods
local InternalTweenConfigs = { }
function TimelinePlayer.MovePart(Object, Translation, Duration, IsLocalSpace, EasingStyle, EasingDirection)
	if typeof(Object) ~= "Instance" then error("Object: Only an Instance (Model, BasePart) can be provided") end
	if not ( Object:IsA("Model") or Object:IsA("BasePart") ) then error("Object: MovePart can only accept a Model with a PrimaryPart or a BasePart") end
	if typeof(Translation) ~= "Vector3" then error("Translation: Provided invalid data type (".. typeof(Translation) .."); please provide a Vector3 Value") end
	local EasingStyle, EasingDirection = EasingStyle or "Sine", EasingDirection or "InOut"
	local IsModel = Object:IsA("Model")
	if IsModel then
		if Object.PrimaryPart == nil then
			local ModelDescendants = Object:GetDescendants()
			for _,Descendant in next, ModelDescendants do
				if Descendant:IsA("BasePart") then
					Object.PrimaryPart = Descendant
					warn("PrimaryPart not present; function has automatically assigned a PrimaryPart")
					break
				end
			end
		end
	end
	local InternalCFrameValue = Instance.new("CFrameValue")
	InternalTweenConfigs[Object] = InternalTweenConfigs[Object] or Instance.new("Configuration")
	local AttConfig = InternalTweenConfigs[Object]
	local TweenAttribute = ( "Tween_" .. (IsLocalSpace and "Local" or "Global") .. "_" .. game:GetService("HttpService"):GenerateGUID(false):sub(1, 8) )
	AttConfig:SetAttribute( TweenAttribute, Vector3.new() )
	if AttConfig:GetAttribute("OriginalCFrame") == nil then
		local refCFrame = IsModel and Object:GetPrimaryPartCFrame() or Object.CFrame
		AttConfig:SetAttribute("OriginalCFrame", refCFrame)
		AttConfig.AttributeChanged:Connect(function(ChangedAttribute)
			local AppliedCFrame = AttConfig:GetAttribute("OriginalCFrame")
			local Vectors = { ["Local"] = Vector3.new(), ["Global"] = Vector3.new() }
			for AttributeName, AttributeValue in pairs(AttConfig:GetAttributes()) do
				if AttributeName:find("Tween_") then
					for VectorName, VectorValue in pairs(Vectors) do
						if AttributeName:find(VectorName) then
							Vectors[VectorName] = Vectors[VectorName] + AttributeValue
						end
					end
				end
			end
			AppliedCFrame = AppliedCFrame * CFrame.new(Vectors.Local.X, Vectors.Local.Y, Vectors.Local.Z)
			AppliedCFrame = AppliedCFrame + Vectors.Global
			if IsModel then Object:PivotTo(AppliedCFrame) else Object.CFrame = AppliedCFrame end
		end)
	end
	InternalCFrameValue.Changed:Connect(function(NewCFrame) AttConfig:SetAttribute( TweenAttribute, Vector3.new( NewCFrame.X, NewCFrame.Y, NewCFrame.Z ) ) end)
	local TranslationTween = TweenService:Create(InternalCFrameValue, TweenInfo.new(Duration, Enum.EasingStyle[EasingStyle], Enum.EasingDirection[EasingDirection]), {Value = CFrame.new(Translation.X, Translation.Y, Translation.Z)})
	TranslationTween.Completed:Connect(function()
		InternalCFrameValue:Destroy()
		AttConfig:SetAttribute( TweenAttribute, nil )
		local CompleteCFrame = AttConfig:GetAttribute("OriginalCFrame")
		if IsLocalSpace then
			CompleteCFrame = CompleteCFrame * CFrame.new(Translation.X, Translation.Y, Translation.Z)
		else
			CompleteCFrame = CompleteCFrame + Translation
		end
		if IsModel then Object:PivotTo(CompleteCFrame) else Object.CFrame = CompleteCFrame end
		AttConfig:SetAttribute("OriginalCFrame", CompleteCFrame)
		local oldCFrame = IsModel and Object:GetPrimaryPartCFrame() or Object.CFrame
	end)
	TranslationTween:Play()
end

--Performs tweens on an objects properties and attributes
function TimelinePlayer.Tween(Object, PropTable, AttributeInfo, TInfo, ApplyToDescendants, ApplyRelative)
	local InternalValues = { ["CFrame"] = "CFrameValue", ["number"] = "NumberValue", ["Color3"] = "Color3Value", vector3 = "Vector3Value" }
	for AttName, AttValue in next, AttributeInfo do
		if not InternalValues[typeof(AttValue)] then
			print(AttName, typeof(AttValue), "not a valid internal value type")
		else
			local NewInternalValue = Instance.new(InternalValues[typeof(AttValue)])
			local AttributeTween = game:GetService("TweenService"):Create(NewInternalValue, TInfo, {Value = AttValue})
			NewInternalValue.Value = Object:GetAttribute(AttName)
			NewInternalValue:GetPropertyChangedSignal("Value"):Connect(function()
				Object:SetAttribute(AttName, NewInternalValue.Value)
			end)
			AttributeTween.Completed:Connect(function() NewInternalValue:Destroy() end)
			AttributeTween:Play()
		end 
	end
	local ObjectsToApplyTo = {Object}
	if ApplyToDescendants == true then
		for _,c in next, Object:GetDescendants() do
			table.insert(ObjectsToApplyTo, c)
		end
	end
	for _,Obj in next, ObjectsToApplyTo do
		pcall(function()
			local PropTween = game:GetService("TweenService"):Create(Obj, TInfo, PropTable)
			PropTween:Play()
		end)
	end
end

--Instantly sets the properties or attributes of an object
function TimelinePlayer.SetProperties(Object, PropTable, AttributeTable, ApplyToDescendants, ApplyRelative)
	if Object.Name == "Settings" or Object.Name == "Rescue" then
		error(Object.Name .. " can not be accessed by SetProperties")
	end
	if Object.Name ~= "Settings" and Object.Name ~= "Rescue" then
		for AttName, AttValue in next, AttributeTable do
			Object:SetAttribute(AttName, AttValue)
		end
	end
	local ObjectsToApplyTo = {Object}
	if ApplyToDescendants == true then
		for _,c in next, Object:GetDescendants() do
			table.insert(ObjectsToApplyTo, c)
		end
	end
	for _,Obj in next, ObjectsToApplyTo do
		for Name, Value in pairs(PropTable) do
			pcall(function() Obj[Name] = Value end)
		end
	end
end

--Plays a sound in the map
function TimelinePlayer.Sound(Object, ID, Volume, Pitch)
	local NewSound = Instance.new("Sound")
	NewSound.SoundId = "rbxassetid://" .. ID
	NewSound.Volume = Volume
	NewSound.Pitch = Pitch
	NewSound.Parent = Object or script.Parent
	NewSound:Play()
end

function TimelinePlayer.Alert(Message, Color, Duration)
	print("Alert function needs to be hooked up to the client!")
end

function TimelinePlayer.ShakeCamera(Intensity, Length) 
	print("ShakeCamera function needs to be hooked up to the client!")
end

--Teleports players
function TimelinePlayer.Teleport(Destination, Player)
	local PlayersToTele = Player and {Player} or {--[[Plug your own method for getting all ingame players here]]} 
	for PlayerName, PlayerObject in pairs(PlayersToTele) do
		if PlayerObject.Character and PlayerObject.Character:FindFirstChild("HumanoidRootPart") then
			PlayerObject.Character.HumanoidRootPart.CFrame = Destination.CFrame
		end
	end
end

--Sets information for camera manipulation
function TimelinePlayer.SetCamera(Subject, Enabled, CamInfo, RelativeToSubject)
	print("SetCamera needs to be hooked up to the client!")
end

--Function Wrapper For Timeline Execution
function TimelinePlayer.PerformXFrame(MapModel, XFrame, Player)
	local Function, Position, Length = XFrame:GetAttribute("XFrame_Function"), XFrame:GetAttribute("XFrame_Timestamp"), XFrame:GetAttribute("XFrame_Length")
	if not Function or typeof(Function) ~= "string" then error("XFrame " .. XFrame.Name .. " contains invalid function") end
	if not Position or typeof(Position) ~= "number" then error("XFrame " .. XFrame.Name .. " contains invalid Timestamp") end
	if not Length or typeof(Length) ~= "number" then Length = 0 end
	if Function == "Tween" then
		if XFrame.Value then
			local AllAttributes = XFrame:GetAttributes()
			local PropTable = {}
			local AttributeTable = {}
			for Name, Value in pairs(AllAttributes) do
				if string.find(Name, "Property_") then
					local PropertyName = string.sub(Name, 10)
					PropTable[PropertyName] = Value
				elseif string.find(Name, "Attribute_") then
					AttributeTable[ string.sub(Name, 11) ] = Value
				end
			end
			local TweenRepeat = typeof(XFrame:GetAttribute("Tween_RepeatCount")) == "number" and XFrame:GetAttribute("Tween_RepeatCount") or 0
			local TInfo = TweenInfo.new(Length, Enum.EasingStyle[XFrame:GetAttribute("Tween_EasingStyle") or "Sine"], Enum.EasingDirection[XFrame:GetAttribute("Tween_EasingDirection") or "InOut"], TweenRepeat, XFrame:GetAttribute("Tween_Reverses") or false, XFrame:GetAttribute("Tween_DelayTime") or 0)
			TimelinePlayer.Tween(XFrame.Value, PropTable, AttributeTable, TInfo, XFrame:GetAttribute("XFrame_ApplyToDescendants") or XFrame:GetAttribute("ApplyToDescendants"), XFrame:GetAttribute("ApplyRelative"))
		end
		return
	end
	if Function == "SetProperties" then
		if XFrame.Value then
			local AllAttributes = XFrame:GetAttributes()
			local PropTable = {}
			local AttributeTable = {}
			local IsTweenFunction = false
			for Name, Value in pairs(AllAttributes) do
				if string.find(Name, "Property_") then
					PropTable[ string.sub(Name, 10) ] = Value
				elseif string.find(Name, "Attribute_") then
					AttributeTable[ string.sub(Name, 11) ] = Value
				elseif string.find(Name, "Tween_") then IsTweenFunction = true end
			end

			if IsTweenFunction then
				local TInfo = TweenInfo.new(Length, Enum.EasingStyle[XFrame:GetAttribute("Tween_EasingStyle") or "Sine"], Enum.EasingDirection[XFrame:GetAttribute("Tween_EasingDirection") or "InOut"], XFrame:GetAttribute("Tween_RepeatCount") or 0, XFrame:GetAttribute("Tween_Reverses") or false, XFrame:GetAttribute("Tween_DelayTime") or 0)
				TimelinePlayer.Tween(XFrame.Value, PropTable, AttributeTable, TInfo, XFrame:GetAttribute("XFrame_ApplyToDescendants") or XFrame:GetAttribute("ApplyToDescendants"), XFrame:GetAttribute("ApplyRelative"))
			else
				TimelinePlayer.SetProperties(XFrame.Value, PropTable, AttributeTable, XFrame:GetAttribute("XFrame_ApplyToDescendants") or XFrame:GetAttribute("ApplyToDescendants"), XFrame:GetAttribute("ApplyRelative"))
			end
		end
		return
	end
	if Function == "SetWaterState" then
		if XFrame.Value then
			TimelinePlayer.SetWaterState(XFrame.Value, XFrame:GetAttribute("State"), XFrame:GetAttribute("DontChangeColor"), XFrame:GetAttribute("SpecifiedColor"))
		end
		return
	end
	if Function == "MovePart" then
		if XFrame.Value then
			TimelinePlayer.MovePart(XFrame.Value, XFrame:GetAttribute("Translation"), Length, XFrame:GetAttribute("UseLocalSpace") or false, XFrame:GetAttribute("EasingStyle"), XFrame:GetAttribute("EasingDirection"))
		end
		return
	end
	if Function == "Alert" then
		TimelinePlayer.Alert(XFrame:GetAttribute("Message"), XFrame:GetAttribute("Color"), Length)
		return
	end
	if Function == "Sound" then
		TimelinePlayer.Sound(XFrame.Value, XFrame:GetAttribute("SoundId"), XFrame:GetAttribute("Volume") or 1, XFrame:GetAttribute("Pitch") or 1)
		return
	end
	if Function == "ShakeCamera" then
		TimelinePlayer.ShakeCamera(XFrame:GetAttribute("Intensity"), Length)
		return
	end
	if Function == "Teleport" then
		TimelinePlayer.Teleport(XFrame.Value, Player)
		return
	end
	if Function == "SetCamera" then
		TimelinePlayer.SetCamera(XFrame.Value, XFrame:GetAttribute("Enabled"), XFrame:GetAttribute("CamInfo"), XFrame:GetAttribute("RelativeToSubject"))
		return
	end
end

------------TIMELINE WRAPPER
--Validates a Timeline
local function ValidateIsTimeline(Timeline)
	if Timeline:IsA("Configuration") then
		if Timeline:GetAttribute("Trigger_Delay") or Timeline:GetAttribute("Trigger_Button") or Timeline:GetAttribute("Trigger_Timeline") or Timeline:GetAttribute("Trigger_Touch") then
			return true
		end
	end
end

--Validates an XFrame
local function ValidateIsXFrame(XFrame)
	if XFrame:IsA("ObjectValue") then
		if typeof( XFrame:GetAttribute("XFrame_Function") ) == "string" and typeof( XFrame:GetAttribute("XFrame_Timestamp") ) == "number" then
			return true
		end
	end
end

--Gets duration of Timeline
local function GetTimelineDuration(Timeline)
	local FurthestPointInTime = 0
	for _,Keyframe in pairs(Timeline:GetChildren()) do
		local KeyframeEndPoint = 0
		local Time_Position, Time_Duration = Keyframe:GetAttribute("XFrame_Timestamp"), Keyframe:GetAttribute("XFrame_Length") or 0
		if typeof(Time_Position) == "number" then
			if typeof(Time_Duration) == "number" then
				local TweenRepeatCount = Keyframe:GetAttribute("Tween_RepeatCount") or 0
				if TweenRepeatCount == -1 then TweenRepeatCount = math.huge end
				local TweenRepeatMultiplier = 1 + ( TweenRepeatCount )
				KeyframeEndPoint = Time_Position + ( ( Time_Duration * TweenRepeatMultiplier ) * ( Keyframe:GetAttribute("Tween_Reverses") and 2 or 1 ) )
			else
				KeyframeEndPoint = Time_Position
			end
		end
		if KeyframeEndPoint > FurthestPointInTime then
			FurthestPointInTime = KeyframeEndPoint
		end
	end
	return FurthestPointInTime
end

--Executes all XFrames within Timeline
local function PlayTimeline(Timeline, Player)
	local Loop = Timeline:GetAttribute("RepeatOnCompletion")
	local MultipleTouches = Timeline:GetAttribute("Touch_AllowMultiple")
	local TimelineDuration = GetTimelineDuration(Timeline)
	local TimelineDelay = Timeline:GetAttribute("Trigger_Delay")
	if typeof( TimelineDelay ) == "number" and TimelineDelay > 0 then 
		task.wait( TimelineDelay )
	end
	repeat 
		for _,Keyframe in pairs(Timeline:GetDescendants()) do
			if ValidateIsXFrame(Keyframe) then
				local Time_Position = Keyframe:GetAttribute("XFrame_Timestamp")
				local Time_Duration = Keyframe:GetAttribute("XFrame_Length") or 0
				if typeof(Time_Position) == "number" and typeof(Keyframe:GetAttribute("XFrame_Function")) == "string" then
					task.delay(Time_Position, 
						function()
							TimelinePlayer.PerformXFrame(script.Parent, Keyframe, Player)
						end
					)
				end
			end
		end
		task.wait(TimelineDuration)
	until Loop ~= true or MultipleTouches == true
	for _,c in pairs(Timelines:GetDescendants()) do
		if ValidateIsTimeline(c) then
			if c:GetAttribute("Trigger_Timeline") == Timeline.Name then
				task.spawn(PlayTimeline, c)
			end
		end
	end
end

--Timeline Listeners
--Button Listener
Lib.Button:connect(function(p, bNo)
	for _,Timeline in pairs(Timelines:GetDescendants()) do
		if ValidateIsTimeline(Timeline) then
			local TimelineTrigger, ButtonTrigger = Timeline:GetAttribute("Trigger_Timeline"), Timeline:GetAttribute("Trigger_Button")
			if not (typeof(TimelineTrigger) == "string" and TimelineTrigger ~= "") then
				if ButtonTrigger == bNo then
					task.spawn(PlayTimeline, Timeline)
				end
			end
		end
	end
end)

--Extra Timeline Listeners
local AllObjects = script.Parent:GetDescendants()
for _,Timeline in pairs(Timelines:GetDescendants()) do
	if ValidateIsTimeline(Timeline) then
		local TimelineTrigger, ButtonTrigger, TouchTrigger, DelayTrigger = Timeline:GetAttribute("Trigger_Timeline"), Timeline:GetAttribute("Trigger_Button"), Timeline:GetAttribute("Trigger_Touch"), Timeline:GetAttribute("Trigger_Delay")
		if typeof(TouchTrigger) == "string" and TouchTrigger ~= "" then
			local AllowedToRun = true
			if typeof(TimelineTrigger) == "string" and TimelineTrigger ~= "" then AllowedToRun = false end
			if typeof(ButtonTrigger) == "number" and ButtonTrigger > 0 then AllowedToRun = false end
			if AllowedToRun == true then
				local TouchListenerCount = 0
				local MaxTouchListeners = 10
				local PlayerDebounce = {}
				local TouchedOnce = false
				local TouchAllowMultiple = Timeline:GetAttribute("Touch_AllowMultiple")
				for _, Object in pairs(AllObjects) do
					if Object:IsA("BasePart") and Object.Name == TouchTrigger then
						if TouchListenerCount < MaxTouchListeners then
							TouchListenerCount += 1
							Object.Touched:Connect(function(hit)
								if not (TouchedOnce == true and TouchAllowMultiple ~= true) then
									local Player = game.Players:GetPlayerFromCharacter(hit.Parent)
									if Player and ( not PlayerDebounce[tostring(Player.UserId)] ) then
										PlayerDebounce[tostring(Player.UserId)] = true
										TouchedOnce = true
										task.spawn(PlayTimeline, Timeline, TouchAllowMultiple and Player)
										if TouchAllowMultiple then
											task.wait(1)
											PlayerDebounce[tostring(Player.UserId)] = false
										end
									end
								end
							end)
						end
					end
				end
			end 
		else
			if typeof(DelayTrigger) == "number" then
				local AllowedToRun = true
				if typeof(TimelineTrigger) == "string" and TimelineTrigger ~= "" then AllowedToRun = false end
				if typeof(ButtonTrigger) == "number" and ButtonTrigger > 0 then AllowedToRun = false end
				if typeof(TouchTrigger) == "string" and TouchTrigger ~= "" then AllowedToRun = false end
				if AllowedToRun == true then task.spawn(PlayTimeline, Timeline) end
			end
		end
	end
end
