local json = require("json")

local g = require("Extra_scripts.core.globals")
local enums = require("Extra_scripts.core.enums")
local players = enums.Players
local costumes = enums.Costumes

local SaveData = {}
local modReference

local SAVE_STATE = {}
local Continue = false
SaveData.PERSISTENT_PLAYER_DATA = {}
SaveData.UnlockData = {
	wq = {},
	Spwq = {},
	Glaze = {},
}
SaveData.dss_menu = {
	HudOffset = 0,
	MenuControllerToggle = 1,
	MenuPalette = 1,
}
SaveData.objData = {}

local function getExtras()
	return {
		main = {
			BSide = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
			Birthright = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
			Touchstone = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
			Darkness = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
			My_Hat = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
			Assassin_s_Eye = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
			Tech_9 = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
			
		},
		tainted = {
			BSide = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
			Birthright = {
				Owned = false,
				Enabled = false,
				Active = false,
				Randomize = false,
			},
		},
		points = 0,
	}
end

local function getObjectives()		--这是干什么的？
	return {
		main = {
			NotToday = {
				Finished = false,
				Progress = 0,
			},
			SaddestManAlive = {
				Finished = false,
				Progress = 0,
			},
			Duality = {
				Finished = false,
				Progress = 0,
			},
			AshesToAshes = {
				Finished = false,
				Progress = 0,
			},
			Dontspair = {
				Finished = false,
				Progress = 0,
			},
			YouBrokeIt = {
				Finished = false,
				Progress = 0,
			},
			WhackEm = {
				Finished = false,
				Progress = 0,
			},
			ISeeDeadPeople = {
				Finished = false,
				Progress = 0,
			},
			AtlasWho = {
				Finished = false,
				Progress = 0,
			},
			BabyBabyBackRibs = {
				Finished = false,
				Progress = 0,
			},
		},
		tainted = {
			NoFaith = {
				Finished = false,
				Progress = 0,
			},
			TheCollector = {
				Finished = false,
				Progress = 0,
				Special = {
					[tostring(ItemPoolType.POOL_TREASURE)] = false,
					[tostring(ItemPoolType.POOL_SHOP)] = false,
					[tostring(ItemPoolType.POOL_BOSS)] = false,
					[tostring(ItemPoolType.POOL_DEVIL)] = false,
					[tostring(ItemPoolType.POOL_ANGEL)] = false,
					[tostring(ItemPoolType.POOL_SECRET)] = false,
					[tostring(ItemPoolType.POOL_LIBRARY)] = false,
					[tostring(ItemPoolType.POOL_CURSE)] = false,
					[tostring(ItemPoolType.POOL_PLANETARIUM)] = false,
					[tostring(ItemPoolType.POOL_GREED_TREASUREL)] = "POOL_TREASURE",
					[tostring(ItemPoolType.POOL_GREED_BOSS)] = "POOL_BOSS",
					[tostring(ItemPoolType.POOL_GREED_SHOP)] = "POOL_SHOP",
					[tostring(ItemPoolType.POOL_GREED_DEVIL)] = "POOL_DEVIL",
					[tostring(ItemPoolType.POOL_GREED_ANGEL)] = "POOL_ANGEL",
					[tostring(ItemPoolType.POOL_GREED_CURSE)] = "POOL_CURSE",
					[tostring(ItemPoolType.POOL_GREED_SECRET)] = "POOL_SECRET",
				},
			},
			HumbleBeginnings = {
				Finished = false,
				Progress = 0,
			},
			Diogenes = {
				Finished = false,
				Progress = 0,
			},
			BoldAndBrash = {
				Finished = false,
				Progress = 0,
			},
			NeverAgain = {
				Finished = false,
				Progress = 0,
			},
			HoardingMadness = {
				Finished = false,
				Progress = 0,
			},
			TheFallen = {
				Finished = false,
				Progress = 0,
			},
			Glutton = {
				Finished = false,
				Progress = 0,
				Special = {
					[tostring(CollectibleType.COLLECTIBLE_LUNCH)] = false,
					[tostring(CollectibleType.COLLECTIBLE_DINNER)] = false,
					[tostring(CollectibleType.COLLECTIBLE_DESSERT)] = false,
					[tostring(CollectibleType.COLLECTIBLE_BREAKFAST)] = false,
					[tostring(CollectibleType.COLLECTIBLE_ROTTEN_MEAT)] = false,
					[tostring(CollectibleType.COLLECTIBLE_SNACK)] = false,
					[tostring(CollectibleType.COLLECTIBLE_MIDNIGHT_SNACK)] = false,
					[tostring(CollectibleType.COLLECTIBLE_SUPPER)] = false,
				},
			},
			DarkCleansing = {
				Finished = false,
				Progress = 0,
			},
		},
	}
end

local function getSettings()
	return {
		CaregiverShader = 1,
	}
end

local function SaveModData()
	SAVE_STATE.PERSISTENT_PLAYER_DATA = SaveData.PERSISTENT_PLAYER_DATA
	SAVE_STATE.wq = SaveData.UnlockData.wq
	SAVE_STATE.Spwq = SaveData.UnlockData.Spwq
	--SAVE_STATE.DSS_MENU = SaveData.dss_menu
	SAVE_STATE.EXTRAS = SaveData.extras
	--SAVE_STATE.OBJECTIVES = SaveData.objectives
	--SAVE_STATE.OBJ_DATA = SaveData.objData
	--SAVE_STATE.SETTINGS = SaveData.settings
	--print("SAVEEE")
	modReference:SaveData(json.encode(SAVE_STATE))
end

function SaveData.GetData(plyr, plyrFailsafe)
	local player = type(plyr) == "table" and plyrFailsafe or plyr
	local data = player:GetData()
	
	if data.JobIndex then
		return SaveData.PERSISTENT_PLAYER_DATA[data.JobIndex]
	elseif player.Parent then
		return {}
	else
		Isaac.DebugString("[WARNING] - No (Job Modpack) Player Index set for [" .. player:GetPlayerType() .. "." .. player:GetName() .. "]")
	
		local pData = {
			__INDEX = #SaveData.PERSISTENT_PLAYER_DATA + 1,
			__META = {
				Index = player.ControllerIndex,
				PlayerType = player:GetPlayerType(),
			},
		}
		table.insert(SaveData.PERSISTENT_PLAYER_DATA, pData)
		data.JobIndex = #SaveData.PERSISTENT_PLAYER_DATA
		
		return SaveData.PERSISTENT_PLAYER_DATA[data.JobIndex]
	end
end

function SaveData.postPlayerInit(_,player)
	local TotPlayers = #Isaac.FindByType(EntityType.ENTITY_PLAYER)
	
	if TotPlayers == 0 then
		if Isaac.HasModData(modReference) then
			SAVE_STATE = json.decode(modReference:LoadData())
			--print("init")
			SaveData.PERSISTENT_PLAYER_DATA = SAVE_STATE.PERSISTENT_PLAYER_DATA or {}
			SaveData.UnlockData.wq = SAVE_STATE.wq
			SaveData.UnlockData.Spwq = SAVE_STATE.Spwq
			--SaveData.dss_menu = SAVE_STATE.DSS_MENU or {HudOffset = 0,MenuControllerToggle = 1,MenuPalette = 1,}
			
			SaveData.extras = getExtras()
			if SAVE_STATE.EXTRAS then
				for i, extra in pairs(SAVE_STATE.EXTRAS.main) do
					SaveData.extras.main[i].Owned = SAVE_STATE.EXTRAS.main[i].Owned or false
					SaveData.extras.main[i].Enabled = SAVE_STATE.EXTRAS.main[i].Enabled or false
					SaveData.extras.main[i].Active = SAVE_STATE.EXTRAS.main[i].Active or false
					SaveData.extras.main[i].Randomize = SAVE_STATE.EXTRAS.main[i].Randomize or false
				end
				for i, extra in pairs(SAVE_STATE.EXTRAS.tainted) do
					SaveData.extras.tainted[i].Owned = SAVE_STATE.EXTRAS.tainted[i].Owned or false
					SaveData.extras.tainted[i].Enabled = SAVE_STATE.EXTRAS.tainted[i].Enabled or false
					SaveData.extras.tainted[i].Active = SAVE_STATE.EXTRAS.tainted[i].Active or false
					SaveData.extras.tainted[i].Randomize = SAVE_STATE.EXTRAS.tainted[i].Randomize or false
				end
				SaveData.extras.points = SAVE_STATE.EXTRAS.points
			end
			
			--SaveData.objectives = getObjectives()
			if false and SAVE_STATE.OBJECTIVES then
				for i, objective in pairs(SAVE_STATE.OBJECTIVES.main) do
					SaveData.objectives.main[i].Finished = SAVE_STATE.OBJECTIVES.main[i].Finished or false
					SaveData.objectives.main[i].Progress = SAVE_STATE.OBJECTIVES.main[i].Progress or 0
					
					if objective.Special then
						for k, v in pairs(objective.Special) do
							SaveData.objectives.main[i].Special[k] = SAVE_STATE.OBJECTIVES.main[i].Special[k] or false
						end
					end
				end
				for i, objective in pairs(SAVE_STATE.OBJECTIVES.tainted) do
					SaveData.objectives.tainted[i].Finished = SAVE_STATE.OBJECTIVES.tainted[i].Finished or false
					SaveData.objectives.tainted[i].Progress = SAVE_STATE.OBJECTIVES.tainted[i].Progress or 0
					
					if objective.Special then
						for k, v in pairs(objective.Special) do
							SaveData.objectives.tainted[i].Special[k] = SAVE_STATE.OBJECTIVES.tainted[i].Special[k] or false
						end
					end
				end
			end
			
			--SaveData.objData = SAVE_STATE.OBJ_DATA
			
			--SaveData.settings = getSettings()
			if false and SAVE_STATE.SETTINGS then
				for i, setting in pairs(SAVE_STATE.SETTINGS) do
					SaveData.settings[i] = SAVE_STATE.SETTINGS[i] or false
				end
			end
		else
			SaveData.PERSISTENT_PLAYER_DATA = {}
			--SaveData.dss_menu = {HudOffset = 0,MenuControllerToggle = 1,MenuPalette = 1,}
			SaveData.extras = getExtras()
			--SaveData.objectives = getObjectives()
		end
		
		if g.game:GetFrameCount() == 0 then
			Continue = false
			SaveData.PERSISTENT_PLAYER_DATA = {}
			
			for i, extra in pairs(SaveData.extras.main) do
				if extra.Randomize then
					if g.Randomizer:RandomFloat() > 0.5 then
						SaveData.extras.main[i].Enabled = true
						SaveData.extras.main[i].Active = true
					else
						SaveData.extras.main[i].Enabled = false
						SaveData.extras.main[i].Active = false
					end
				else
					SaveData.extras.main[i].Active = extra.Enabled -- not a typo
				end
			end
			for i, extra in pairs(SaveData.extras.tainted) do
				if extra.Randomize then
					if g.Randomizer:RandomFloat() > 0.5 then
						SaveData.extras.tainted[i].Enabled = true
						SaveData.extras.tainted[i].Active = true
					else
						SaveData.extras.tainted[i].Enabled = false
						SaveData.extras.tainted[i].Active = false
					end
				else
					SaveData.extras.tainted[i].Active = extra.Enabled -- not a typo
				end
			end
			
			SaveModData()
		else
			Continue = true
		end
	end
	
	if player.Parent then return end
	
	local pType = player:GetPlayerType()
	
	if Continue then
		for i, plyr in ipairs(SaveData.PERSISTENT_PLAYER_DATA) do
			--if pType == plyr.__META.PlayerType
			--and player.ControllerIndex == plyr.__META.Index
			if player.ControllerIndex == plyr.__META.Index
			and (pType == PlayerType.PLAYER_ESAU and (pType == plyr.__META.PlayerType) or true)
			then
				player:GetData().JobIndex = i
				return
			end
		end
	end
	
	local pData = {
		__INDEX = #SaveData.PERSISTENT_PLAYER_DATA + 1,
		__META = {
			Index = player.ControllerIndex,
			PlayerType = pType,
		}
	}
	
	table.insert(SaveData.PERSISTENT_PLAYER_DATA, pData)
	player:GetData().JobIndex = #SaveData.PERSISTENT_PLAYER_DATA
end

function SaveData.postNewLevel()
	SaveModData()
end

function SaveData.preGameExit(_,shouldSave)
	SaveModData()
end

function SaveData.Init(mod)
	modReference = mod
	modReference:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SaveData.postPlayerInit)
	modReference:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SaveData.preGameExit)
	modReference:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, SaveData.postNewLevel)
end

function SaveData.LockAll()
end

return SaveData

