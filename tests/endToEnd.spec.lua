return function()
	local RunService = {
		IsClient = function()
			return false
		end,

		IsServer = function()
			return true
		end,
	}

	local warnings = {}
	local Logger = {
		warn = function(...)
			local warningString = table.concat({ ... }, " ")
			table.insert(warnings, warningString)
			warn(warningString)
		end,
	}
	it("SHOULD work for servers", function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

		local configuration = Cmdr.validateConfig({
			RunService = RunService,
			RemoteEvent = nil,
			RemoteFunction = nil,
			Player = nil,
			Gui = nil,
			Logger = Logger,
		})
		local CmdrServer = Cmdr.createServer(configuration)

		expect(CmdrServer.version).to.equal("1.5.0")
		expect(CmdrServer:getVersion()).to.equal("1.5.0")

		CmdrServer:RegisterDefaultCommands()
		CmdrServer:RegisterCommandObject({
			Name = "serverEcho";
			Aliases = {};
			Description = "";
			Group = "DefaultUtil";
			Args = {
				{
					Type = "string";
					Name = "Text";
					Description = "The text."
				},
			};

			Run = function(_, text)
				return text
			end
		})
		local response = CmdrServer.Dispatcher:EvaluateAndRun("serverEcho testing123", executor, options)
		expect(response).to.equal("testing123")
	end)

	it("SHOULD work for a second server", function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

		local configuration = Cmdr.validateConfig({
			RunService = RunService,
			RemoteEvent = nil,
			RemoteFunction = nil,
			Player = nil,
			Gui = nil,
			Logger = Logger,
		})
		local CmdrServer = Cmdr.createServer(configuration)

		expect(CmdrServer.version).to.equal("1.5.0")
		expect(CmdrServer:getVersion()).to.equal("1.5.0")

		CmdrServer:RegisterDefaultCommands()

		local response = CmdrServer.Dispatcher:EvaluateAndRun("serverEcho should fail", executor, options)
		expect(response:find("Invalid command")).to.be.ok()
	end)
end
