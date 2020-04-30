return function()
	local warnings = {}
	local Logger = {
		warn = function(...)
			local warningString = table.concat({ ... }, " ")
			table.insert(warnings, warningString)
			warn(warningString)
		end,
	}

	local RemoteEvent = {
		OnClientEvent = {
			Connect = function()

			end,
		},
	}

	local RemoteFunction = {

	}

	describe("SERVER", function()
		-- We dont need this anymore, though we still need Heartbeat for mock
		local RunService = {
			IsClient = function()
				return false
			end,

			IsServer = function()
				return true
			end,
		}

		it("SHOULD work for servers", function()
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

			local configuration = Cmdr.validateConfig({
				ReplicatedRoot = Instance.new("Folder"),
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
				ReplicatedRoot = Instance.new("Folder"),
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
	end)

	describe("CLIENT", function()
		local RunService = {
			IsClient = function()
				return true
			end,

			IsServer = function()
				return true
			end,
		}

		it("SHOULD work for client", function()
			local folder = Instance.new("Folder")
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

			local configuration = Cmdr.validateConfig({
				ReplicatedRoot = folder,
				RemoteEvent = RemoteEvent,
				RemoteFunction = RemoteFunction,
				Player = nil,
				Gui = true,
				Logger = Logger,
			})

			local CmdrServer = Cmdr.createServer(configuration)
			CmdrServer:RegisterDefaultCommands()

			local CmdrClient = Cmdr.createClient(configuration)

			local response = CmdrClient.Dispatcher:EvaluateAndRun("echo should work")
			expect(response).to.equal("should work")
		end)

		it("SHOULD work for multiple clients", function()
			local folder = Instance.new("Folder")
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

			local configuration = Cmdr.validateConfig({
				ReplicatedRoot = folder,
				RemoteEvent = RemoteEvent,
				RemoteFunction = RemoteFunction,
				Player = nil,
				Gui = true,
				Logger = Logger,
			})

			local CmdrServer = Cmdr.createServer(configuration)
			CmdrServer:RegisterDefaultCommands()

			local firstClient = Cmdr.createClient(configuration)

			local firstResponse = firstClient.Dispatcher:EvaluateAndRun("echo should work")
			expect(firstResponse).to.equal("should work")

			local secondClient = Cmdr.createClient(configuration)
			local secondResponse = secondClient.Dispatcher:EvaluateAndRun("echo should work as well")
			expect(secondResponse).to.equal("should work as well")
		end)
	end)
end
