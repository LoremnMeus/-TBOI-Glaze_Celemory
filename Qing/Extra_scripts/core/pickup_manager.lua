local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")

local modReference
local Pickup_manager = {
	pickups = {},
	params = {should_add_cache_on_update = false},
}

function Pickup_manager.Init(mod)
	modReference = mod
	Pickup_manager.pickups[1] = require("Extra_scripts.pickups.pickup_glaze_heart")
	--Pickup_manager.pickups[2] = require("Extra_scripts.pickups.pickup_glaze_key")
	Pickup_manager.MakeItems()
end

function Pickup_manager.MakeItems()	--没有传入参数。
	for i = 1,#Pickup_manager.pickups do
		if Pickup_manager.pickups[i].OnPostUpdate then
			modReference:AddCallback(ModCallbacks.MC_POST_UPDATE,Pickup_manager.pickups[i].OnPostUpdate)
		end
		if Pickup_manager.pickups[i].OnCacheUpdate then
			modReference:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,Pickup_manager.pickups[i].OnCacheUpdate)
		end
		if Pickup_manager.pickups[i].OnPlayerDamage then
			modReference:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Pickup_manager.pickups[i].OnPlayerDamage, EntityType.ENTITY_PLAYER)
		end
		if Pickup_manager.pickups[i].OnPlayerCollision then
			modReference:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, Pickup_manager.pickups[i].OnPlayerCollision)
		end
		if Pickup_manager.pickups[i].OnNPCUpdate then
			modReference:AddCallback(ModCallbacks.MC_NPC_UPDATE, Pickup_manager.pickups[i].OnNPCUpdate)
		end
		if Pickup_manager.pickups[i].OnPickUpCollision then
			if Pickup_manager.pickups[i].pickup then
				modReference:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, Pickup_manager.pickups[i].OnPickUpCollision,Pickup_manager.pickups[i].pickup)
			else
				modReference:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, Pickup_manager.pickups[i].OnPickUpCollision)
			end
		end
		if Pickup_manager.pickups[i].OnPickUpUpdate then
			if Pickup_manager.pickups[i].pickup then
				modReference:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, Pickup_manager.pickups[i].OnPickUpUpdate,Pickup_manager.pickups[i].pickup)
			else
				modReference:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, Pickup_manager.pickups[i].OnPickUpUpdate)
			end
		end
	end
end

return Pickup_manager
