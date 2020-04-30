local RunService = game:GetService("RunService")

local Util = require(script.Parent.Util)

--- The registry keeps track of all the commands and types that Cmdr knows about.
local Registry = {}
Registry.__index = Registry

function Registry.new(cmdr)
	local self = {
		TypeMethods = Util.MakeDictionary({"Transform", "Validate", "Autocomplete", "Parse", "DisplayName", "Listable", "ValidateOnce", "Prefixes"});
		CommandMethods = Util.MakeDictionary({"Name", "Aliases", "AutoExec", "Description", "Args", "Run", "ClientRun", "Data", "Group"});
		CommandArgProps = Util.MakeDictionary({"Name", "Type", "Description", "Optional", "Default"});
		Types = {};
		TypeAliases = {};
		Commands = {};
		CommandsArray = {};
		Cmdr = cmdr;
		Hooks = {
			BeforeRun = {};
			AfterRun = {}
		};
		Stores = setmetatable({}, {
			__index = function (self, k)
				self[k] = {}
				return self[k]
			end
		});
		AutoExecBuffer = {};
	}
	setmetatable(self, Registry)

	return self
end

--- Registers a type in the system.
-- name: The type Name. This must be unique.
function Registry:RegisterType (name, typeObject)
	if not name or not typeof(name) == "string" then
		error("Invalid type name provided: nil")
	end

	if not name:find("^[%d%l]%w*$") then
		error(('Invalid type name provided: "%s", type names must be alphanumeric and start with a lower-case letter or a digit.'):format(name))
	end

	for key in pairs(typeObject) do
		if self.TypeMethods[key] == nil then
			error("Unknown key/method in type \"" .. name .. "\": " .. key)
		end
	end

	if self.Types[name] ~= nil then
		error(('Type "%s" has already been registered.'):format(name))
	end

	typeObject.Name = name
	typeObject.DisplayName = typeObject.DisplayName or name

	self.Types[name] = typeObject

	if typeObject.Prefixes then
		self:RegisterTypePrefix(name, typeObject.Prefixes)
	end
end

function Registry:RegisterTypePrefix (name, union)
	if not self.TypeAliases[name] then
		self.TypeAliases[name] = name
	end

	self.TypeAliases[name] = ("%s %s"):format(self.TypeAliases[name], union)
end

function Registry:RegisterTypeAlias (name, alias)
	assert(self.TypeAliases[name] == nil, ("Type alias %s already exists!"):format(alias))
	self.TypeAliases[name] = alias
end

--- Helper method that registers types from all module scripts in a specific container.
function Registry:RegisterTypesIn (container)
	for _, object in pairs(container:GetChildren()) do
		if object:IsA("ModuleScript") then
			-- We clone here so we can have multiple Cmdr server instances
			local clone = object:Clone()
			-- We need to keep track if a previous server instance has replicated before us
			local removeWhenDone = self.Cmdr.ReplicatedRoot.Types:FindFirstChild(object.Name)
			-- To ensure all moduleScripts execute with the same Parent
			clone.Parent = self.Cmdr.ReplicatedRoot.Types

			require(clone)(self)

			-- Remove clone so clients don't see duplicates and throw
			if removeWhenDone then
				removeWhenDone:Destroy()
			end
		else
			self:RegisterTypesIn(object)
		end
	end
end

-- These are exactly the same thing. No one will notice. Except for you, dear reader.
Registry.RegisterHooksIn = Registry.RegisterTypesIn

--- Registers a command based purely on its definition.
-- Prefer using Registry:RegisterCommand for proper handling of server/client model.
function Registry:RegisterCommandObject (commandObject, fromCmdr)
	for key in pairs(commandObject) do
		if self.CommandMethods[key] == nil then
			error("Unknown key/method in command " .. (commandObject.Name or "unknown command") .. ": " .. key)
		end
	end

	if commandObject.Args then
		for i, arg in pairs(commandObject.Args) do
			if type(arg) == "table" then
				for key in pairs(arg) do
					if self.CommandArgProps[key] == nil then
						error(('Unknown propery in command "%s" argument #%d: %s'):format(commandObject.Name or "unknown", i, key))
					end
				end
			end
		end
	end

	if not fromCmdr and self.Cmdr.isClient and commandObject.Run then
		self.Cmdr.Logger.warn(commandObject.Name, "command has `Run` in its command definition; prefer using `ClientRun` for new work.")
	end

	if commandObject.AutoExec and self.Cmdr.isClient then
		table.insert(self.AutoExecBuffer, commandObject.AutoExec)
		self:FlushAutoExecBufferDeferred()
	end

	-- Unregister the old command if it exists...
	local oldCommand = self.Commands[commandObject.Name:lower()]
	if oldCommand and oldCommand.Aliases then
		for _, alias in pairs(oldCommand.Aliases) do
			self.Commands[alias:lower()] = nil
		end
	elseif not oldCommand then
		self.CommandsArray[#self.CommandsArray + 1] = commandObject
	end

	self.Commands[commandObject.Name:lower()] = commandObject

	if commandObject.Aliases then
		for _, alias in pairs(commandObject.Aliases) do
			self.Commands[alias:lower()] = commandObject
		end
	end
end

--- Registers a command definition and its server equivalent.
-- Handles replicating the definition to the client.
function Registry:RegisterCommand (commandScript, commandServerScript, filter)
	local clonedCommandScript = commandScript:Clone()
	local commandObject = require(clonedCommandScript)

	if commandServerScript then
		commandObject.Run = require(commandServerScript)
	end

	if filter and not filter(commandObject) then
		return
	end

	self:RegisterCommandObject(commandObject)

	clonedCommandScript.Parent = self.Cmdr.ReplicatedRoot.Commands
end

--- A helper method that registers all commands inside a specific container.
function Registry:RegisterCommandsIn (container, filter)
	local skippedServerScripts = {}
	local usedServerScripts = {}

	for _, commandScript in pairs(container:GetChildren()) do
		if commandScript:IsA("ModuleScript") then
			if not commandScript.Name:find("Server") then
				local serverCommandScript = container:FindFirstChild(commandScript.Name .. "Server")

				if serverCommandScript then
					usedServerScripts[serverCommandScript] = true
				end

				self:RegisterCommand(commandScript, serverCommandScript, filter)
			else
				skippedServerScripts[commandScript] = true
			end
		else
			self:RegisterCommandsIn(commandScript, filter)
		end
	end

	for skippedScript in pairs(skippedServerScripts) do
		if not usedServerScripts[skippedScript] then
			self.Cmdr.Logger.warn("Command script " .. skippedScript.Name .. " was skipped because it has 'Server' in its name, and has no equivalent shared script.")
		end
	end
end

--- Registers the default commands, with an optional filter function or array of groups.
function Registry:RegisterDefaultCommands (arrayOrFunc)
	local isArray = type(arrayOrFunc) == "table"

	if isArray then
		arrayOrFunc = Util.MakeDictionary(arrayOrFunc)
	end

	self:RegisterCommandsIn(self.Cmdr.DefaultCommandsFolder, isArray and function (command)
		return arrayOrFunc[command.Group] or false
	end or arrayOrFunc)
end

--- Gets a command definition by name. (Can be an alias)
function Registry:GetCommand (name)
	name = name or ""
	return self.Commands[name:lower()]
end

--- Returns a unique array of all registered commands (not including aliases)
function Registry:GetCommands ()
	return self.CommandsArray
end

--- Returns an array of the names of all registered commands (not including aliases)
function Registry:GetCommandsAsStrings ()
	local commands = {}

	for _, command in pairs(self.CommandsArray) do
		commands[#commands + 1] = command.Name
	end

	return commands
end

--- Gets a type definition by name.
function Registry:GetType (name)
	return self.Types[name]
end

--- Returns a type name, parsing aliases.
function Registry:GetTypeName (name)
	return self.TypeAliases[name] or name
end

--- Adds a hook to be called when any command is run
function Registry:RegisterHook(hookName, callback, priority)
	if not self.Hooks[hookName] then
		error(("Invalid hook name: %q"):format(hookName), 2)
	end

	table.insert(self.Hooks[hookName], { callback = callback; priority = priority or 0; } )
	table.sort(self.Hooks[hookName], function(a, b) return a.priority < b.priority end)
end

-- Backwards compatability (deprecated)
Registry.AddHook = Registry.RegisterHook

--- Returns the store with the given name
-- Used for commands that require persistent state, like bind or ban
function Registry:GetStore(name)
	return self.Stores[name]
end

--- Calls self:FlushAutoExecBuffer at the end of the frame
function Registry:FlushAutoExecBufferDeferred()
	if self.AutoExecFlushConnection then
		return
	end

	self.AutoExecFlushConnection = RunService.Heartbeat:Connect(function()
		self.AutoExecFlushConnection:Disconnect()
		self.AutoExecFlushConnection = nil
		self:FlushAutoExecBuffer()
	end)
end

--- Runs all pending auto exec commands in Registry.AutoExecBuffer
function Registry:FlushAutoExecBuffer()
	for _, commandGroup in ipairs(self.AutoExecBuffer) do
		for _, command in ipairs(commandGroup) do
			self.Cmdr.Dispatcher:EvaluateAndRun(command)
		end
	end
end

return function (cmdr)
	return Registry.new(cmdr)
end
