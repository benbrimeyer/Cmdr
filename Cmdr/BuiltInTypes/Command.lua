return function (registry)
	local Util = registry.Cmdr.Util

	local commandType = {
		Transform = function (text)
			local findCommand = Util.MakeFuzzyFinder(registry:GetCommandsAsStrings())

			return findCommand(text)
		end;

		Validate = function (commands)
			return #commands > 0, "No command with that name could be found."
		end;

		Autocomplete = function (commands)
			return commands
		end;

		Parse = function (commands)
			return commands[1]
		end;
	}

	registry:RegisterType("command", commandType)
	registry:RegisterType("commands", Util.MakeListableType(commandType))
end
