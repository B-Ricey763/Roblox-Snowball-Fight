local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage.Packages
local Knit = require(packages.Knit)
local TableUtil = require(packages.TableUtil)
local PlayerData = DataStoreService:GetDataStore("PlayerData")
local KillsData = DataStoreService:GetOrderedDataStore("Kills")

local sessionData = {}
local DataService = Knit.CreateService { Name = "DataService" }

local function LeaderboardSetup(kills)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"	

	local money = Instance.new("IntValue")
	money.Name = "Kills"
	money.Value = kills
	money.Parent = leaderstats
	
	return leaderstats
end

local function LoadData(player)
	local success, result = pcall(function()
		return KillsData:GetAsync(player.UserId)
	end)
	if not success then
		warn(result)
	end
	return success, result
end

local function SaveData(player, data)
	local success, result = pcall(function()
		KillsData:SetAsync(player.UserId, data)
	end)
	if not success then 
		warn(result)
	end
	return success
end

function DataService:KnitStart()
	local function onPlayerAdded(player)
		local success, data = LoadData(player)
		-- Currently only support saving kills
		sessionData[player.UserId] = { Kills = if success and data ~= nil then data else 0 }
		print(sessionData[player.UserId])
		local leaderstats = LeaderboardSetup(sessionData[player.UserId].Kills)
		leaderstats.Parent = player
	end

	local function onPlayerRemoving(player)
		-- Only supports saving kills
		SaveData(player, sessionData[player.UserId].Kills)
		sessionData[player.UserId] = nil
	end

	local function onClose()
		if RunService:IsStudio() then
			return
		end

		for _, player in pairs(Players:GetPlayers()) do
			task.spawn(onPlayerRemoving(player))
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	game:BindToClose(onClose)
end

--[[
	player is the one who made the kill
]]
function DataService:AddKill(player)
	local data = sessionData[player.UserId]
	if data then
		data.Kills += 1

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			leaderstats.Kills.Value += 1
		end
	end
end

return DataService