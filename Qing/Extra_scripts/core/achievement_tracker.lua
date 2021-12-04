local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
--local cheats = require("Extra_scripts.extras.cheat_codes")		--尝试关上一些功能
--local objHandler = require("Extra_scripts.extras.objective_handler")
local enums = require("Extra_scripts.core.enums")
local ModConfig = require("Extra_scripts.Mod_Config_Menu_support")
local players = enums.Players
local items = enums.Items
local trinkets = enums.Trinkets
local ModConfigSettings = ModConfig.ModConfigSettings

local Tracker = {}

local UnlocksTemplate = {
	MomsHeart = {Unlock = false, Hard = false},
	Isaac = {Unlock = false, Hard = false},
	Satan = {Unlock = false, Hard = false},
	BlueBaby = {Unlock = false, Hard = false},
	Lamb = {Unlock = false, Hard = false},
	BossRush = {Unlock = false, Hard = false},
	Hush = {Unlock = false, Hard = false},
	MegaSatan = {Unlock = false, Hard = false},
	Delirium = {Unlock = false, Hard = false},
	Mother = {Unlock = false, Hard = false},
	Beast = {Unlock = false, Hard = false},
	GreedMode = {Unlock = false, Hard = false},
	FullCompletion = {Unlock = false, Hard = false},
}

local function UpdateCompletion(name, difficulty)
	--print(name)
	for p = 0, g.game:GetNumPlayers() - 1 do
		local pType = Isaac.GetPlayer(p):GetPlayerType()
				
		if pType == players.wq then
			local TargetTab = save.UnlockData.wq
			
			if TargetTab[name].Unlock == false then
				TargetTab[name].Unlock = true
				
				if enums.AchievementGraphics.wq[name] then
					CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/Some achievements/" .. enums.AchievementGraphics.wq[name] .. ".png")
					--if name == "Satan" then
					--	CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/Some achievements/achievement.whack_a_mole.png")
					--end
				end
			end
			if difficulty == Difficulty.DIFFICULTY_HARD then
				TargetTab[name].Hard = true
			elseif difficulty == Difficulty.DIFFICULTY_GREEDIER then
				if TargetTab[name].Hard == false then
					TargetTab[name].Hard = true
					
					CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/Some achievements/" .. enums.AchievementGraphics.wq.Greedier .. ".png")
				end
			end
			
			if false then
			
			local MissingUnlock = false
			local MissingHard = false
			for boss, tab in pairs(TargetTab) do
				if boss ~= "FullCompletion"
				and type(tab) == "table"
				then
					if tab.Unlock == false then
						MissingUnlock = true
						break
					end
					if tab.Hard == false then
						MissingHard = true
						
						if boss == "GreedMode" then
							MissingUnlock = true
							break
						end
					end
				end
			end
			
			if (not MissingUnlock)
			and TargetTab.WhackAMole
			then
				if not TargetTab.FullCompletion.Unlock then
					TargetTab.FullCompletion.Unlock = true
					CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/job achievements/" .. enums.AchievementGraphics.PlayerJob.FullCompletion .. ".png")
					
					local data = save.objectives.main
					local HasObj = false
					
					--for i, obj in ipairs(cheats.Objectives.main) do
						--if data[obj.Title].Finished then
							--HasObj = true
							--objHandler.displayObjective(obj.Name)
						--end
					--end
					
					if HasObj then
						g.sound:Play(SoundEffect.SOUND_SUPERHOLY, 1, 0, false, 1)
					end
				end
				
				if (not MissingHard)
				and (not TargetTab.FullCompletion.Hard)
				then
					TargetTab.FullCompletion.Hard = true
				end
			end
			
			end
		elseif false and pType == players.Job_B then
			local TargetTab = save.UnlockData.PlayerJob_B

			if TargetTab[name].Unlock == false then
				TargetTab[name].Unlock = true
				
				if enums.AchievementGraphics.PlayerJob_B[name] then
					CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/job achievements/" .. enums.AchievementGraphics.PlayerJob_B[name] .. ".png")
				end
			end
			if difficulty == Difficulty.DIFFICULTY_HARD then
				TargetTab[name].Hard = true
			elseif difficulty == Difficulty.DIFFICULTY_GREEDIER then
				if TargetTab[name].Hard == false then
					TargetTab[name].Hard = true
					
					CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/job achievements/" .. enums.AchievementGraphics.PlayerJob_B.Greedier .. ".png")
				end
			end
			
			if TargetTab.PolNegPath == false
			and TargetTab.Isaac.Unlock == true
			and TargetTab.BlueBaby.Unlock == true
			and TargetTab.Satan.Unlock == true
			and TargetTab.Lamb.Unlock == true
			then
				TargetTab.PolNegPath = true
				
				CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/job achievements/" .. enums.AchievementGraphics.PlayerJob_B.PolNegPath .. ".png")
			end
			
			if TargetTab.SoulPath == false
			and TargetTab.BossRush.Unlock == true
			and TargetTab.Hush.Unlock == true
			then
				TargetTab.SoulPath = true
				
				CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/job achievements/" .. enums.AchievementGraphics.PlayerJob_B.SoulPath .. ".png")
			end
			
			local MissingUnlock = false
			local MissingHard = false
			for boss, tab in pairs(TargetTab) do
				if boss ~= "FullCompletion"
				and type(tab) == "table"
				then
					if tab.Unlock == false then
						MissingUnlock = true
						break
					end
					if tab.Hard == false then
						MissingHard = true
						
						if boss == "GreedMode" then
							MissingUnlock = true
							break
						end
					end
				end
			end
			
			if (not MissingUnlock)
			and TargetTab.Haunted
			then
				if not TargetTab.FullCompletion.Unlock then
					TargetTab.FullCompletion.Unlock = true
					CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/job achievements/" .. enums.AchievementGraphics.PlayerJob_B.FullCompletion .. ".png")
					
					local data = save.objectives.tainted
					local HasObj = false
					
					--for i, obj in ipairs(cheats.Objectives.tainted) do
					--	if data[obj.Title].Finished then
					--		HasObj = true
					--		objHandler.displayObjective(obj.Name)
					--	end
					--end
					
					if HasObj then
						g.sound:Play(SoundEffect.SOUND_SUPERHOLY, 1, 0, false, 1)
					end
				end
				
				if (not MissingHard)
				and (not TargetTab.FullCompletion.Hard)
				then
					TargetTab.FullCompletion.Hard = true
				end
			end
		end
	end
end

local UnlockFunctions = {
	[LevelStage.STAGE4_2] = function(room, stageType, difficulty, desc) -- Heart / Mother
		if room:IsClear() then
			local Name
			if stageType >= StageType.STAGETYPE_REPENTANCE
			and desc.SafeGridIndex == -1
			then
				Name = "Mother"
			elseif stageType <= StageType.STAGETYPE_AFTERBIRTH
			and room:IsCurrentRoomLastBoss()
			then
				Name = "MomsHeart"
			end
		
			if Name then
				UpdateCompletion(Name, difficulty)
			end
		end
	end,
	[LevelStage.STAGE4_3] = function(room, stageType, difficulty, desc) -- Hush
		if room:IsClear() then
			local Name = "Hush"
		
			UpdateCompletion(Name, difficulty)
		end
	end,
	[LevelStage.STAGE5] = function(room, stageType, difficulty, desc) -- Satan / Isaac
		if room:IsClear() then
			local Name = "Satan"
			if stageType == StageType.STAGETYPE_WOTL then
				Name = "Isaac"
			end
		
			UpdateCompletion(Name, difficulty)
		end
	end,
	[LevelStage.STAGE6] = function(room, stageType, difficulty, desc) -- Mega Satan / Lamb / Blue Baby
		if desc.SafeGridIndex == -7 then
			local MegaSatan
			for _, satan in ipairs(Isaac.FindByType(EntityType.ENTITY_MEGA_SATAN_2, 0)) do
				MegaSatan = satan
				break
			end
		
			if not MegaSatan then return end
			
			local sprite = MegaSatan:GetSprite()
			
			if sprite:IsPlaying("Death") and sprite:GetFrame() == 110 then
				local Name = "MegaSatan"
			
				UpdateCompletion(Name, difficulty)
			end
		else
			if room:IsClear() then
				local Name = "Lamb"
				if stageType == StageType.STAGETYPE_WOTL then
					Name = "BlueBaby"
				end
			
				UpdateCompletion(Name, difficulty)
			end
		end
	end,
	[LevelStage.STAGE7] = function(room, stageType, difficulty, desc) -- Delirium
		if desc.Data.Subtype == 70 and room:IsClear() then
			local Name = "Delirium"
		
			UpdateCompletion(Name, difficulty)
		end
	end,
	
	BossRush = function(room, stageType, difficulty, desc) -- Boss Rush
		if room:IsAmbushDone() then
			local Name = "BossRush"
		
			UpdateCompletion(Name, difficulty)
		end
	end,
	Beast = function(room, stageType, difficulty, desc) -- Beast
		local Beast
		for _, beast in ipairs(Isaac.FindByType(EntityType.ENTITY_BEAST, 0)) do
			Beast = beast
			break
		end
	
		if not Beast then return end
		
		local sprite = Beast:GetSprite()
		
		if sprite:IsPlaying("Death") and sprite:GetFrame() == 30 then
			local Name = "Beast"
		
			UpdateCompletion(Name, difficulty)
		end
	end,
	Greed = function(room, stageType, difficulty, desc) -- Greed
		if room:IsClear() then
			local Name = "GreedMode"
			
			UpdateCompletion(Name, difficulty)
		end
	end,
}

function Tracker.postUpdate()
	if ModConfigSettings.Achievement_allow == false then return end
	
	local level = g.game:GetLevel()
	local room = g.game:GetRoom()
	local desc = level:GetCurrentRoomDesc()
	local levelStage = level:GetStage()
	local roomType = room:GetType()
	local difficulty = g.game.Difficulty
	
	if Isaac.GetChallenge() > 0
	or g.game:GetVictoryLap() > 0
	then
		return
	end
	
	if difficulty <= Difficulty.DIFFICULTY_HARD then
		local stageType = level:GetStageType()
		
		if levelStage == LevelStage.STAGE4_1
		and level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH > 0
		then
			levelStage = levelStage + 1
		end
		
		if roomType == RoomType.ROOM_BOSS and UnlockFunctions[levelStage] then
			UnlockFunctions[levelStage](room, stageType, difficulty, desc)
		elseif roomType == RoomType.ROOM_BOSSRUSH then
			UnlockFunctions.BossRush(room, stageType, difficulty, desc)
		elseif levelStage == LevelStage.STAGE8 and roomType == RoomType.ROOM_DUNGEON then
			UnlockFunctions.Beast(room, stageType, difficulty, desc)
		end
	else
		if levelStage == LevelStage.STAGE7_GREED
		and roomType == RoomType.ROOM_BOSS
		and desc.SafeGridIndex == 45
		then
			UnlockFunctions.Greed(room, nil, difficulty, desc)
		end
	end
end

function Tracker.CreateUnlocksTemplate()
	local UnlockTab = {}
	
	for i, v in pairs(UnlocksTemplate) do
		UnlockTab[i] = {Unlock = false, Hard = false}
	end
	
	return UnlockTab
end

return Tracker
