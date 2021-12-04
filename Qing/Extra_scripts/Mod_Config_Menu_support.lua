local json = require("json")

local g = require("Extra_scripts.core.globals")
local enums = require("Extra_scripts.core.enums")

local Mod_Config = {}
function Mod_Config.initlist()
	return {
		mouseSupport = true,
		Items_allow = true,
		Achievement_allow = true,
		thor_key = 342,
	}
end

local modReference

function Mod_Config.init(mod)
	modReference = mod
	Mod_Config.ModConfigSettings = Mod_Config.initlist()
	if ModConfigMenu then
		local ModConfigQingCategory = ".W.Q."
		ModConfigMenu.UpdateCategory(ModConfigQingCategory, {
				Info = {"Settings for the W.Q character mod.",}
			})
		ModConfigMenu.AddText( ModConfigQingCategory, "Settings", function() return "My Qing" end )
		ModConfigMenu.AddSpace( ModConfigQingCategory, "Settings" )
		ModConfigMenu.AddSetting( ModConfigQingCategory, "Settings", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return Mod_Config.ModConfigSettings.Items_allow
				end,
				Display = function()
					return 'Allow Mod items appear:' .. (Mod_Config.ModConfigSettings.Items_allow and "Yes" or "No")
				end,
				OnChange = function(currentBool)
					Mod_Config.ModConfigSettings.Items_allow = currentBool
				end,
				Info = {"If true, All items unlocked will show up in the basement.(this won't work until the next run.) "}
			})
		ModConfigMenu.AddSetting( ModConfigQingCategory, "Settings", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return Mod_Config.ModConfigSettings.Achievement_allow
				end,
				Display = function()
					return 'Allow Achievements to be Unlocked:' .. (Mod_Config.ModConfigSettings.Achievement_allow and "Yes" or "No")
				end,
				OnChange = function(currentBool)
					Mod_Config.ModConfigSettings.Achievement_allow = currentBool
				end,
				Info = {"If true, Achievements will be unlocked after require satisfied. "}
			})
		ModConfigMenu.AddKeyboardSetting(
		ModConfigQingCategory, --category
		"Settings", 
		"Qing\'s key",--attribute in table
		Mod_Config.ModConfigSettings.thor_key, --default value
		"W.Qing\' now teleport by pressing", --display text
		false, --if (keyboard) is displayed after the key text
		"Choose what button on your keyboard will lead to the final attack from W.Q.")
		local function ToChange_keys()
			Mod_Config.ModConfigSettings.thor_key = ModConfigMenu.Config[ModConfigQingCategory]["Qing\'s key"]
		end
		modReference:AddCallback(ModCallbacks.MC_POST_UPDATE,ToChange_keys)
	end
end

return Mod_Config

	--[[
	ModConfigMenu.AddSetting( ModConfigQingCategory, "Settings", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return ModConfigSettings.mouseSupport
			end,
			Display = function()
				return 'W.Qing\' mouse input support: ' .. (ModConfigSettings.mouseSupport and "On" or "Off")
			end,
			OnChange = function(currentBool)
				ModConfigSettings.mouseSupport = currentBool
			end,
			Info = {"If true, moving the mouse will enable mouse input. "}
		})
	
	ModConfigMenu.AddSetting( ModConfigQingCategory, "Settings", {
		Type = ModConfigMenu.OptionType.KEYBIND_KEYBOARD,
		CurrentSetting = function()
			return ModConfigSettings.thor_key
		end,
		Display = function()
			if InputHelper and InputHelper.KeyboardToString[ModConfigSettings.thor_key] then
				return 'W.Qing\' now use '.. InputHelper.KeyboardToString[ModConfigSettings.thor_key]
			else
				return 'You have to fix the ModConfigMenu\'s input helper first!!'
			end
		end,
		OnChange = function(currentkey)
			Debuglist[12] = currentkey
			ModConfigSettings.thor_key = currentkey
		end,
		Info = {"Choose what button on your keyboard will lead to the final strike of W.Q."}
	})
	-]]