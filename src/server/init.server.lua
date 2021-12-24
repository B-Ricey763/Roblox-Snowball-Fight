local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local packages = game:GetService("ReplicatedStorage").Packages
local Knit = require(packages.Knit)
local Loader = require(packages.Loader)

Knit.AddServices(script.Services)

Knit.Start():andThen(function()
	Loader.LoadChildren(script.Components)
end):catch(warn)
