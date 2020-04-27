local StarterGui = game:GetService("StarterGui")
local Dispatcher = require(script.Parent.Shared.Dispatcher)
local Registry = require(script.Parent.Shared.Registry)
local Util = require(script.Parent.Shared.Util)
local Logger = require(script.Parent.Shared.Logger)
local DefaultEventHandlers = require(script.Parent.DefaultEventHandlers)
local CmdrInterface = require(script.Parent.CmdrInterface)

local CmdrClient = {}
CmdrClient.version = "1.5.0"
CmdrClient.__index = CmdrClient

function CmdrClient.new(config)
	local self = {
		config = config,
		ReplicatedRoot = config.ReplicatedRoot or script.Parent,
		RemoteFunction = nil;
		RemoteEvent = nil;
		ActivationKeys = {[Enum.KeyCode.Semicolon] = true};
		Enabled = true;
		MashToEnable = false;
		ActivationUnlocksMouse = false;
		PlaceName = "Cmdr";
		Util = Util;
		Events = {};
	}
	setmetatable(self, {
		__index = function (self, k)
			if not CmdrClient[k] then
				local r = self.Registry[k]
				if r and type(r) == "function" then
					return function (_, ...)
						return r(self.Registry, ...)
					end
				end
			else
				return CmdrClient[k]
			end

			return nil
		end,
	})

	self:_initialize()

	return self
end

function CmdrClient:_initialize()
	self.Registry = Registry(self)
	self.Dispatcher = Dispatcher(self)
	self.Logger = self.config.Logger or Logger

	self.RemoteFunction = self.config.RemoteFunction or self.ReplicatedRoot:WaitForChild("CmdrFunction");
	self.RemoteEvent = self.config.RemoteEvent or self.ReplicatedRoot:WaitForChild("CmdrEvent");

	local RunService = self.config.RunService or game:GetService("RunService")
	self.isClient = true --RunService:IsClient()
	self.isServer = false --RunService:IsServer()

	if not self.config.Gui then
		local player = self.config.player
		if player and StarterGui:WaitForChild("Cmdr") and wait() and player:WaitForChild("PlayerGui"):FindFirstChild("Cmdr") == nil then
			StarterGui.Cmdr:Clone().Parent = player.PlayerGui
		end

		local Interface = CmdrInterface(self)

		--- Sets a list of keyboard keys (Enum.KeyCode) that can be used to open the commands menu
		function self:SetActivationKeys (keysArray)
			self.ActivationKeys = Util.MakeDictionary(keysArray)
		end

		--- Sets the place name label on the interface
		function self:SetPlaceName (name)
			self.PlaceName = name
			Interface.Window:UpdateLabel()
		end

		--- Sets whether or not the console is enabled
		function self:SetEnabled (enabled)
			self.Enabled = enabled
		end

		--- Sets if activation will free the mouse.
		function self:SetActivationUnlocksMouse (enabled)
			self.ActivationUnlocksMouse = enabled
		end

		--- Shows Cmdr window
		function self:Show ()
			if not self.Enabled then
				return
			end

			Interface.Window:Show()
		end

		--- Hides Cmdr window
		function self:Hide ()
			Interface.Window:Hide()
		end

		--- Toggles Cmdr window
		function self:Toggle ()
			if not self.Enabled then
				return self:Hide()
			end

			Interface.Window:SetVisible(not Interface.Window:IsVisible())
		end

		--- Enables the "Mash to open" feature
		function self:SetMashToEnable(isEnabled)
			self.MashToEnable = isEnabled

			if isEnabled then
				self:SetEnabled(false)
			end
		end
	end

	self.Registry:RegisterTypesIn(self.ReplicatedRoot:WaitForChild("Types"))
	self.Registry:RegisterCommandsIn(self.ReplicatedRoot:WaitForChild("Commands"))

	-- Hook up event listener
	self.RemoteEvent.OnClientEvent:Connect(function(name, ...)
		if self.Events[name] then
			self.Events[name](...)
		end
	end)
end

--- Sets the handler for a certain event type
function CmdrClient:HandleEvent(name, callback)
	self.Events[name] = callback
end

function CmdrClient:SetDefaultEventHandlers()
	DefaultEventHandlers(self)
end

function CmdrClient:getVersion()
	return CmdrClient.version
end

return function(config)
	return CmdrClient.new(config)
end
