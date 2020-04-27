return function (registry)
	local Util = registry.Cmdr.Util

	local stringType = {
		Validate = function (value)
			return value ~= nil
		end;

		Parse = function (value)
			return tostring(value)
		end;
	}

	local numberType = {
		Transform = function (text)
			return tonumber(text)
		end;

		Validate = function (value)
			return value ~= nil
		end;

		Parse = function (value)
			return value
		end;
	}

	local intType = {
		Transform = function (text)
			return tonumber(text)
		end;

		Validate = function (value)
			return value ~= nil and value == math.floor(value), "Only whole numbers are valid."
		end;

		Parse = function (value)
			return value
		end
	}

	local boolType do
		local truthy = Util.MakeDictionary({"true", "t", "yes", "y", "on", "enable", "enabled", "1", "+"});
		local falsy = Util.MakeDictionary({"false"; "f"; "no"; "n"; "off"; "disable"; "disabled"; "0"; "-"});

		boolType = {
			Transform = function (text)
				return text:lower()
			end;

			Validate = function (value)
				return truthy[value] ~= nil or falsy[value] ~= nil, "Please use true/yes/on or false/no/off."
			end;

			Parse = function (value)
				if truthy[value] then
					return true
				elseif falsy[value] then
					return false
				else
					error("Unknown boolean value.")
				end
			end;
		}
	end

	registry:RegisterType("string", stringType)
	registry:RegisterType("number", numberType)
	registry:RegisterType("integer", intType)
	registry:RegisterType("boolean", boolType)

	registry:RegisterType("strings", Util.MakeListableType(stringType))
	registry:RegisterType("numbers", Util.MakeListableType(numberType))
	registry:RegisterType("integers", Util.MakeListableType(intType))
	registry:RegisterType("booleans", Util.MakeListableType(boolType))
end
