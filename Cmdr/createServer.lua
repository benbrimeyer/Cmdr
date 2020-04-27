local StarterGui = game:GetService("StarterGui")
local CreateGui = require(script.Parent.CreateGui)
local Dispatcher = require(script.Parent.Shared.Dispatcher)
local Registry = require(script.Parent.Shared.Registry)
local Util = require(script.Parent.Shared.Util)
local Logger = require(script.Parent.Shared.Logger)

local CmdrServer = {}
CmdrServer.version = "1.5.0"
CmdrServer.__index = CmdrServer

function CmdrServer.new(config)
	local self = {
		config = config,
		Registry = nil,
		ReplicatedRoot = config.ReplicatedRoot or script.Parent,
		RemoteFunction = nil,
		RemoteEvent = nil,
		Util = Util,
		DefaultCommandsFolder = script.Parent.BuiltInCommands,
	}
	setmetatable(self, {
		__index = function (self, k)
			if not CmdrServer[k] then
				local r = self.Registry[k]
				if r and type(r) == "function" then
					return function (_, ...)
						return r(self.Registry, ...)
					end
				end
			else
				return CmdrServer[k]
			end

			return nil
		end,
	})

	self:_initialize()

	return self
end

function CmdrServer:_initialize()
	local function Create(class, name, parent)
		local object = Instance.new(class)
		object.Name = name
		object.Parent = parent or self.ReplicatedRoot

		return object
	end

	self.Registry = Registry(self)
	self.Dispatcher = Dispatcher(self)
	self.Logger = self.config.Logger or Logger

	self.RemoteFunction = self.config.RemoteFunction or Create("RemoteFunction", "CmdrFunction")
	self.RemoteEvent = self.config.RemoteEvent or Create("RemoteEvent", "CmdrEvent")

	Create("Folder", "Commands")
	Create("Folder", "Types")

	self:RegisterTypesIn(script.Parent.BuiltInTypes)

	local RunService = self.config.RunService or game:GetService("RunService")
	self.isClient = false --RunService:IsClient()
	self.isServer = true --RunService:IsServer()

	self.player = nil

	if not StarterGui:FindFirstChild("Cmdr") then
		if self.config.CreateGui then
			self.config.CreateGui()
		else
			CreateGui()
		end
	end
end

function CmdrServer:getVersion()
	return CmdrServer.version
end

return function(config)
	return CmdrServer.new(config)
end
