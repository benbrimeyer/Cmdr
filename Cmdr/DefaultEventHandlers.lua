local StarterGui = game:GetService("StarterGui")

return function (Cmdr)
	Cmdr:HandleEvent("Message", function (text)
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = ("[Announcement] %s"):format(text);
			Color = Color3.fromRGB(249, 217, 56);
		})
	end)

	Cmdr:HandleEvent("AddLine", function (...)
		local Window = require(script.Parent.CmdrInterface.Window)
		Window:AddLine(...)
	end)
end
