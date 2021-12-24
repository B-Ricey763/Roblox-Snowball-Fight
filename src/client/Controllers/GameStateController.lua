--[[
	UI display for game state
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage.Packages
local Knit = require(packages.Knit)
local player = Players.LocalPlayer

local GameStateController = Knit.CreateController {
	Name = "GameStateController"
}

function GameStateController:KnitStart()
	local gameStateUI = player.PlayerGui:WaitForChild("GameState")
	local stateLabel = gameStateUI.Frame.State
	local timeLabel = gameStateUI.Frame.TimeLeft
	Knit.GetService("RoundService").GameState:Observe(function(gameState)
		stateLabel.Text = gameState.State
		timeLabel.Text = gameState.TimeLeft
	end)
end

return GameStateController