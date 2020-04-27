-- luacheck: globals __LEMUR__

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local isRobloxCli, ProcessService = pcall(game.GetService, game, "ProcessService")

local TestEZ = require(ReplicatedStorage.Packages.Dev.TestEZ)

local results = TestEZ.TestBootstrap:run({
	game.Tests,
}, TestEZ.Reporters.TextReporterQuiet)

local statusCode = results.failureCount == 0 and 0 or 1

if __LEMUR__ then
	if results.failureCount > 0 then
		os.exit(statusCode)
	end
elseif isRobloxCli then
	ProcessService:Exit(statusCode)
else
	if results.failureCount > 0 then
		error("Test failures")
	end
end
