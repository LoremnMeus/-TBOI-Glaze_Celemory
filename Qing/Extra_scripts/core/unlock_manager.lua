local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local tracker = require("Extra_scripts.core.achievement_tracker")
local enums = require("Extra_scripts.core.enums")
local ModConfig = require("Extra_scripts.Mod_Config_Menu_support")
local players = enums.Players
local items = enums.Items
local trinkets = enums.Trinkets
local cards = enums.Cards
local ModConfigSettings = ModConfig.ModConfigSettings

local modReference 
local Manager = {}

local itemToUnlock = {
	--[items.BookofDespair] = {Unlock = "Isaac"},
	[items.My_Hat] = {Unlock = "BlueBaby"},
	--[items.DadsMallet] = {Unlock = "Satan"},
	[items.Touchstone] = {Unlock = "Lamb"},
	[items.Assassin_s_Eye] = {Unlock = "BossRush"},
	[items.Tech_9] = {Unlock = "Hush"},
	[items.Darkness] = {Unlock = "MegaSatan"},
	--[items.Mental_Hypnosis] = {Unlock = "Delirium"},
	--[items.Gold_Rush] = {Unlock = "Mother"},
	--[items.My_Emblem] = {Unlock = "Beast"},
	--[items._5g] = {Unlock = "GreedMode"},
	--[items.FierceMask] = {Special = function()
	--	return save.UnlockData.PlayerJob.WhackAMole
	--end},
	--[[
	[items.JobsLeperFlesh] = {Unlock = "Delirium", Tainted = true},
	[items.ScorchedContract] = {Unlock = "Beast", Tainted = true},
	[items.ForsakenChalice] = {Special = function()
		return (save.UnlockData.PlayerJob_B.GreedMode.Unlock and save.UnlockData.PlayerJob_B.GreedMode.Hard)
	end},
	
	[items.BookofWisdom] = {Special = function()
		return save.extras.main.BSide.Owned
	end},
	[items.BookofWisdomOn] = {Special = function()
		return save.extras.main.BSide.Owned
	end},
	[items.BookofWisdomLock] = {Special = function()
		return save.extras.main.BSide.Owned
	end},
	[items.SanctiPoenas] = {Special = function()
		return save.extras.tainted.BSide.Owned
	end},
	--]]
}

local trinketToUnlock = {
--[[
	[trinkets.DadsCharm] = {Unlock = "MomsHeart"},
	[trinkets.GoldenRing] = {Special = function()
		return (save.UnlockData.PlayerJob.GreedMode.Unlock and save.UnlockData.PlayerJob.GreedMode.Hard)
	end},
	
	[trinkets.Blasphemy] = {Special = function()
		return save.UnlockData.PlayerJob_B.PolNegPath
	end},
	[trinkets.SacredAssistance] = {Unlock = "Mother", Tainted = true},
	[trinkets.Antibiotic] = {Special = function()
		return save.UnlockData.PlayerJob_B.Haunted
	end},
	--]]
}

local checkTaintedItem = {
	[items.Darkness] = function()
		return save.extras.main.Darkness.Active
	end,
	[items.Touchstone] = function()
		return save.extras.main.Touchstone.Active
	end,
	[items.Tech_9] = function()
		return save.extras.main.Tech_9.Active
	end,
	[items.Assassin_s_Eye] = function()
		return save.extras.main.Assassin_s_Eye.Active
	end,
	[items.My_Hat] = function()
		return save.extras.main.My_Hat.Active
	end,
	--[[
	[items.DadsMallet] = function()
		return save.extras.main.AltDadsMallet.Active
	end,
	[items.JobsFamily] = function()
		return save.extras.main.AltJobsFamily.Active
	end,
	[items.Buttermilk] = function()
		return save.extras.main.AltButtermilk.Active
	end,
	[items.JobsRags] = function()
		return save.extras.main.AltJobsRags.Active
	end,
	[items.CurseofSaturn] = function()
		return save.extras.main.AltCurseofSaturn.Active
	end,
	[items.Caregiver] = function()
		return save.extras.main.AltCaregiver.Active
	end,
	[items.Sisyphus] = function()
		return save.extras.main.AltSisyphus.Active
	end,
	[items.Prosperity] = function()
		return save.extras.main.AltProsperity.Active
	end,
	[items._5g] = function()
		return save.extras.main.Alt_5g.Active
	end,
	[items.FierceMask] = function()
		return save.extras.main.AltGoldenRing.Active
	end,
	
	[items.JobsLeperFlesh] = function()
		return save.extras.tainted.AltJobsLeperFlesh.Active
	end,
	[items.ScorchedContract] =  function()
		return save.extras.tainted.AltScorchedContract.Active
	end,
	[items.ForsakenChalice] = function()
		return save.extras.tainted.AltForsakenChalice.Active
	end,
	-]]
}

local checkTaintedTrinket = {
	--[[
	[trinkets.DadsCharm] = function()
		return save.extras.main.AltDadsCharm.Active
	end,
	[trinkets.GoldenRing] = function()
		return save.extras.main.AltGoldenRing.Active
	end,
	
	[trinkets.Blasphemy] = function()
		return save.extras.tainted.AltBlasphemy.Active
	end,
	[trinkets.SacredAssistance] = function()
		return save.extras.tainted.AltSacredAssistance.Active
	end,
	[trinkets.Antibiotic] = function()
		return save.extras.tainted.AltAntibiotic.Active
	end,
	-]]
}


local questionMarkSprite = Sprite()
questionMarkSprite:Load("gfx/005.100_collectible.anm2", true)
questionMarkSprite:ReplaceSpritesheet(1, "gfx/items/collectibles/questionmark.png")
questionMarkSprite:LoadGraphics()

local function IsAltChoice(pickup)
	if pickup:GetData() == nil then
		return false
	end
	
	if EID and EID:getEntityData(pickup, "EID_IsAltChoice") ~= nil then
		return EID:getEntityData(pickup, "EID_IsAltChoice")
	end

	if not REPENTANCE or g.game:GetLevel():GetStageType() < 4 or g.game:GetRoom():GetType() ~= RoomType.ROOM_TREASURE then
		pickup:GetData()["EID_IsAltChoice"] = false
		return false
	end

	local entitySprite = pickup:GetSprite()
	local name = entitySprite:GetAnimation()

	if name ~= "Idle" and name ~= "ShopIdle" then
		-- Collectible can be ignored. its definetly not hidden
		pickup:GetData()["EID_IsAltChoice"] = false
		return false
	end
	
	questionMarkSprite:SetFrame(name, entitySprite:GetFrame())
	-- check some point in entitySprite
	for i = -70, 0, 2 do
		local qcolor = questionMarkSprite:GetTexel(Vector(0, i), g.ZeroV, 1, 1)
		local ecolor = entitySprite:GetTexel(Vector(0, i), g.ZeroV, 1, 1)
		if qcolor.Red ~= ecolor.Red or qcolor.Green ~= ecolor.Green or qcolor.Blue ~= ecolor.Blue then
			-- it is not same with question mark sprite
			pickup:GetData()["EID_IsAltChoice"] = false
			return false
		end
	end

	--this may be a question mark, however, we will check it again to ensure it
	for j = -3, 3, 2 do
		for i = -71, 0, 2 do
			local qcolor = questionMarkSprite:GetTexel(Vector(j, i), g.ZeroV, 1, 1)
			local ecolor = entitySprite:GetTexel(Vector(j, i), g.ZeroV, 1, 1)
			if qcolor.Red ~= ecolor.Red or qcolor.Green ~= ecolor.Green or qcolor.Blue ~= ecolor.Blue then
				pickup:GetData()["EID_IsAltChoice"] = false
				return false
			end
		end
	end
	pickup:GetData()["EID_IsAltChoice"] = true
	return true
end

local function isBlindPickup(pickup)
	return (g.game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0 and not pickup.Touched) or (not pickup.Touched and IsAltChoice(pickup)) or (g.game.Challenge == Challenge.CHALLENGE_APRILS_FOOL)
end

--这里会处理所有不应该生成的内容。

function Manager.postPlayerInit(_,player)
	local TotPlayers = #Isaac.FindByType(EntityType.ENTITY_PLAYER)
	
	if TotPlayers == 0 then
		if save.UnlockData.wq.MomsHeart == nil then
			save.UnlockData.wq = tracker.CreateUnlocksTemplate()
			
			save.UnlockData.Spwq = tracker.CreateUnlocksTemplate()
		end
		
		if g.game:GetFrameCount() > 0 then return end
		
		for item, tab in pairs(itemToUnlock) do
			local Prefix = tab.Tainted and "SP" or ""
			local Unlocked = false
			
			if tab.Special then
				Unlocked = tab.Special()
			else
				Unlocked = save.UnlockData[Prefix .. "wq"][tab.Unlock].Unlock
			end
			if ModConfigSettings.Items_allow == false then
				Unlocked = false
			end
			if not Unlocked then
				g.ItemPool:RemoveCollectible(item)
			end
		end
		for trinket, tab in pairs(trinketToUnlock) do
			local Prefix = tab.Tainted and "SP" or ""
			local Unlocked = false
			
			if tab.Special then
				Unlocked = tab.Special()
			else
				Unlocked = save.UnlockData[Prefix .. "wq"][tab.Unlock].Unlock
			end
			if ModConfigSettings.Items_allow == false then
				Unlocked = false
			end
			if not Unlocked then
				g.ItemPool:RemoveTrinket(trinket)
			end
		end
	end
end

function Manager.postPickupInit(_,pickup)
	if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE or pickup.Variant == PickupVariant.PICKUP_TRINKET then
		local tab
		local tainted = false
		if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
			tab = itemToUnlock[pickup.SubType]
			tainted = checkTaintedItem[pickup.SubType]
		else
			tab = trinketToUnlock[pickup.SubType]
			tainted = checkTaintedTrinket[pickup.SubType]
		end
		
		if (not tab) then return end
		if false then		--某些地方可以自带。
			if tab.Type == "Item"
			and pickup.SubType == items.BookofDespair
			and not save.UnlockData.PlayerJob.Isaac.Unlock
			then
				for p = 0, g.game:GetNumPlayers() - 1 do
					if Isaac.GetPlayer(p):GetPlayerType() == players.Job then
						return
					end
				end
			end
		end
		
		local Prefix = tab.Tainted and "SP" or ""
		local Unlocked = false
		
		if tab.Special then
			Unlocked = tab.Special()
		else
			Unlocked = save.UnlockData[Prefix .. "wq"][tab.Unlock].Unlock
		end
		
		if not Unlocked then
			if tab.Type == "Item"
			and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE
			then
				local roomPool = g.ItemPool:GetPoolForRoom(g.game:GetRoom():GetType(), g.game:GetLevel():GetCurrentRoomDesc().SpawnSeed)
				local targetItem = g.ItemPool:GetCollectible(roomPool, true, pickup.InitSeed)
				
				g.ItemPool:RemoveCollectible(pickup.SubType)
				pickup:Morph(pickup.Type, pickup.Variant, targetItem, true, true, true)
			elseif tab.Type == "Trinket"
			and pickup.Variant == PickupVariant.PICKUP_TRINKET
			then
				g.ItemPool:RemoveTrinket(pickup.SubType)
				pickup:Morph(pickup.Type, pickup.Variant, g.ItemPool:GetTrinket(), true, true, true)
			end
		elseif tainted and tainted() and not isBlindPickup(pickup) then
			local spr = pickup:GetSprite()
			local anim = spr:GetAnimation()
			
			if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
				local pedestal = spr:GetOverlayFrame()
				local itemGfx = g.ItemConfig:GetCollectible(pickup.SubType).GfxFileName
				spr:Load("gfx/job.tainted_collectible.anm2", true)
				spr:ReplaceSpritesheet(1, itemGfx)
				spr:LoadGraphics()
				
				if pedestal >= 0 then
					spr:SetOverlayFrame("Alternates", pedestal)
				end
			else
				local itemGfx = g.ItemConfig:GetTrinket(pickup.SubType).GfxFileName
				spr:Load("gfx/job.tainted_trinket.anm2", true)
				spr:ReplaceSpritesheet(0, itemGfx)
				spr:LoadGraphics()
			end
			
			spr:Play(anim, true)
		end
	elseif pickup.Variant == PickupVariant.PICKUP_TAROTCARD then
		if false then
		if pickup.SubType == cards.AncientFragment then
			for p = 0, g.game:GetNumPlayers() - 1 do
				if Isaac.GetPlayer(p):HasCollectible(items.Sisyphus) then
					if save.extras.main.AltSisyphus.Active then
						local spr = pickup:GetSprite()
						spr:ReplaceSpritesheet(1, "gfx/items/pick ups/pickup.ancient_fragment2.png")
						spr:LoadGraphics()
						spr:Update()
					end
				
					return
				end
			end
			
			local Counter = 10000
			local TargetCard = g.ItemPool:GetCard(pickup.InitSeed + Counter, false, false, false)
			
			while TargetCard == cards.AncientFragment do
				Counter = Counter + 10000
				TargetCard = g.ItemPool:GetCard(pickup.InitSeed + Counter, false, false, false)
			end
			pickup:Morph(pickup.Type, pickup.Variant, TargetCard, true, true, true)
		elseif pickup.SubType == cards.SoulofJob then
			if not save.UnlockData.PlayerJob_B.SoulPath then
				local Counter = 10000
				local TargetCard = g.ItemPool:GetCard(pickup.InitSeed + Counter, false, true, true)
			
				while TargetCard == cards.SoulofJob do
					Counter = Counter + 10000
					TargetCard = g.ItemPool:GetCard(pickup.InitSeed + Counter, false, true, true)
				end
				
				pickup:Morph(pickup.Type, pickup.Variant, TargetCard, true, true, true)
			else
				if save.extras.tainted.AltSoulofJob.Active then
					local spr = pickup:GetSprite()
					spr:ReplaceSpritesheet(1, "gfx/items/pick ups/pickup.soul_of_job2.png")
					spr:LoadGraphics()
					spr:Update()
				end
			end
		end
		end
	end
end

function Manager.postPlayerUpdate(_,player)
	if false then
	for item, tab in pairs(itemToUnlock) do
		local HasIt = player:HasCollectible(item)
		
		if HasIt then
			local Prefix = tab.Tainted and "SP" or ""
			local Unlocked = false
			
			if tab.Special then
				Unlocked = tab.Special()
			else
				Unlocked = save.UnlockData[Prefix .. "WQ"][tab.Unlock].Unlock
			end
			
			if not Unlocked then
				local targetItem = g.ItemPool:GetCollectible(ItemPoolType.POOL_TREASURE, true, player.InitSeed)
				player:RemoveCollectible(item)
				player:AddCollectible(targetItem, g.ItemConfig:GetCollectible(targetItem).MaxCharges)		--还是可能使伊甸拥有2个主动，结果顶掉一个。
			end
		end
	end
	for trinket, tab in pairs(trinketToUnlock) do
		local HasIt = player:HasTrinket(trinket)
		
		if HasIt then
			local Prefix = tab.Tainted and "SP" or ""
			local Unlocked = false
			
			if tab.Special then
				Unlocked = tab.Special()
			else
				Unlocked = save.UnlockData[Prefix .. "WQ"][tab.Unlock].Unlock
			end
			
			if not Unlocked then
				local targetTrinket = g.ItemPool:GetTrinket()
				player:TryRemoveTrinket(trinket)
				player:AddTrinket(targetTrinket)
			end
		end
	end
	for i = 0, 3 do
		if player:GetCard(i) == cards.SoulofJob
		and (not save.UnlockData.PlayerJob_B.SoulPath)
		then
			local Counter = 10000
			local TargetCard = g.ItemPool:GetCard(player.InitSeed + Counter, false, true, true)
		
			while TargetCard == cards.SoulofJob do
				Counter = Counter + 10000
				TargetCard = g.ItemPool:GetCard(player.InitSeed + Counter, false, true, true)
			end
			
			player:SetCard(i, TargetCard)
		elseif player:GetCard(i) == cards.AncientFragment then
			local hasSisyphus = false
			for p = 0, g.game:GetNumPlayers() - 1 do
				if Isaac.GetPlayer(p):HasCollectible(items.Sisyphus) then
					hasSisyphus = true
					break
				end
			end
			
			if hasSisyphus then return end
			
			local Counter = 10000
			local TargetCard = g.ItemPool:GetCard(player.InitSeed + Counter, false, false, false)
			
			while TargetCard == cards.AncientFragment do
				Counter = Counter + 10000
				TargetCard = g.ItemPool:GetCard(player.InitSeed + Counter, false, false, false)
			end
			
			player:SetCard(i, TargetCard)
		end
	end
	end
end

function Manager.init(mod)
	modReference = mod
	modReference:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Manager.postPlayerInit)
	modReference:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, Manager.postPickupInit)
	--modReference:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Manager.postPlayerUpdate)
end

return Manager