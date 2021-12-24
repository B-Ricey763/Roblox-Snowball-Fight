local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage.Packages
local TableUtil = require(packages.TableUtil)
local Knit = require(packages.Knit)
local Trove = require(packages.Trove)
local Signal = require(packages.Signal)
local Timer = require(packages.Timer)
local court = workspace.Court
local Constants = require(ReplicatedStorage.Common.Constants)

local RoundService = Knit.CreateService {
	Name = "RoundService",
	Client = {
		GameState = Knit.CreateProperty({
			State = "Waiting for Players",
			TimeLeft = "",
		})
	},
	_trove = Trove.new()
}

function RoundService:KnitStart()
	local function resetPlayers()
		for _, team in ipairs(Teams:GetTeams()) do
			for _, player in ipairs(team:GetPlayers()) do
				local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.Health = 0 -- Kill all players
				end
			end
		end
	end

	task.defer(function()
		task.wait(3) -- just to get everything started
		while true do
			self._trove:Add(resetPlayers)
			self:_waitForPlayers()
			self:_intermission()
			self:_begin()
			self:_yieldUntilFinished()
			self:_end()
		end
	end)
end

function RoundService:_waitForPlayers()
	self.Client.GameState:Set({
		State = "Waiting for Players...",
		TimeLeft = ""
	})
	local enoughPlayers = Signal.new()
	local count = 0
	local function updateCount()
		count = #Players:GetPlayers()
		if count > 1 
		--	or RunService:IsStudio() 
		then
			enoughPlayers:Fire()
		end
	end
	Players.PlayerAdded:Connect(updateCount)
	Players.PlayerRemoving:Connect(updateCount)
	task.delay(1, updateCount) -- just so the event wait can actually detect it
	enoughPlayers:Wait()
end

function RoundService:_intermission()
	for i = Constants.INTERMISSION_TIME, 0, -1 do
		self.Client.GameState:Set({
			State = "Intermission",
			TimeLeft = i,
		})
		task.wait(1)
	end
end

function RoundService:_begin()
	self:_generateTeams()
	self:_teleportTeam(Teams.Red)
	self:_teleportTeam(Teams.Blue)
end

function RoundService:_generateTeams()
	local players = Players:GetPlayers()
	-- Not sure if the shuffle is necessary, but I think it'll be fine
	for i, player in ipairs(TableUtil.Shuffle(players)) do
		if not player.Character then
			continue
		end

		player.Team = if i <= #players/2 then Teams.Red else Teams.Blue
		self:_watchPlayer(player)
	end
end

function RoundService:_watchPlayer(player)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		-- Remove them from their team, pretty easy,
		-- they will respawn out of the arena automatically 
		player.Team = nil
	end)
end

function RoundService:_teleportTeam(team)
	local function teleportPlayer(player, pos)
		local character = player.Character
		if character then
			character:SetPrimaryPartCFrame(CFrame.new(pos))
		end
	end

	local function getRandomPos(startPos, maxRadius)
		-- Get a random angle (in radians) around the unit circle
		local theta = math.random() * math.pi * 2
		local radius = math.random(1, maxRadius)
		local x = math.cos(theta) * radius
		local z = math.sin(theta) * radius
		return startPos + Vector3.new(x, 0, z)
	end

	local spawnPoint = court:FindFirstChild(team.Name).Start
	for _, player in ipairs(team:GetPlayers()) do
		-- Spawns players randomly in a circle around the start
		teleportPlayer(player, getRandomPos(spawnPoint.Position, 5))
	end
end

function RoundService:_yieldUntilFinished()
	for i = Constants.ROUND_TIME, 0, -1 do
		self.Client.GameState:Set({
			State = "Fight!",
			TimeLeft = i,
		})
		task.wait(1)
		local numRed = #Teams.Red:GetPlayers()
		local numBlue = #Teams.Blue:GetPlayers()
		if numBlue < 1 or numRed < 1 then
			-- One team completely died, move on!
			break
		end
	end
end

function RoundService:_end()
	local numRed = #Teams.Red:GetPlayers()
	local numBlue = #Teams.Blue:GetPlayers()
	local winner = if numBlue > numRed then Teams.Blue elseif numBlue == numRed then nil else Teams.Red
	for i = Constants.END_TIME, 0, -1 do
		self.Client.GameState:Set({
			State = if winner then "Winner: " .. winner.Name else "Tie!",
			TimeLeft = i
		})
		task.wait(1)
	end
	self._trove:Clean()
end

return RoundService