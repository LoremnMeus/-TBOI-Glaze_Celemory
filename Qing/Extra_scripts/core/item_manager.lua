local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")

local modReference
local Item_manager = {
	items = {},
	params = {should_add_cache_on_update = false},
}

function Item_manager.OnPostPlayerUpdate(_,player)
	if Item_manager.params.should_add_cache_on_update then
		player:EvaluateItems()
	end
end

function Item_manager.Init(mod)
	modReference = mod
	Item_manager.items[1] = require("Extra_scripts.items.Item_Darkness")
	Item_manager.items[2] = require("Extra_scripts.items.Item_Touchstone")
	Item_manager.items[3] = require("Extra_scripts.items.Item_My_Hat")
	Item_manager.items[4] = require("Extra_scripts.items.Item_Assassin_s_Eye")
	Item_manager.items[5] = require("Extra_scripts.items.Item_Tech_9")
	Item_manager.MakeItems()
	modReference:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE,Item_manager.OnPostPlayerUpdate)
end

function Item_manager.MakeItems()	--没有传入参数。
	for i = 1,#Item_manager.items do
		if Item_manager.items[i].OnPostUpdate then
			modReference:AddCallback(ModCallbacks.MC_POST_UPDATE,Item_manager.items[i].OnPostUpdate)
		end
		if Item_manager.items[i].OnCacheUpdate then
			modReference:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,Item_manager.items[i].OnCacheUpdate)
		end
		if Item_manager.items[i].OnTearInit then
			modReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT,Item_manager.items[i].OnTearInit)
		end
		if Item_manager.items[i].OnTearUpDate then
			modReference:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, Item_manager.items[i].OnTearUpDate)
		end
		if Item_manager.items[i].OnPlayerDamage then
			modReference:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Item_manager.items[i].OnPlayerDamage, EntityType.ENTITY_PLAYER)
		end
		if Item_manager.items[i].OnPlayerCollision then
			modReference:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, Item_manager.items[i].OnPlayerCollision)
		end
		if Item_manager.items[i].OnNPCUpdate then
			modReference:AddCallback(ModCallbacks.MC_NPC_UPDATE, Item_manager.items[i].OnNPCUpdate)
		end
		if Item_manager.items[i].OnNPCRender then
			modReference:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, Item_manager.items[i].OnNPCRender)
		end
	end
end

return Item_manager
