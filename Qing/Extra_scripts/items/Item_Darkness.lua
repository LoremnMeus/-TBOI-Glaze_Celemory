local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")
local item_manager = require("Extra_scripts.core.item_manager")
local auxi = require("Extra_scripts.auxiliary.functions")

local item = {}

function item.OnPostUpdate()
	for playerNum = 1, Game():GetNumPlayers() do
		local player = Game():GetPlayer(playerNum - 1)
		if player:HasCollectible(enums.Items.Darkness) then
			local q = player:GetMaxHearts()
			if q > 0 then
				player:AddMaxHearts(-q,true)
				player:AddBlackHearts(q)
			end
			if item.black_hearts == nil or item.black_hearts ~= auxi.Count_Flags(player:GetBlackHearts()) then
				if item.black_hearts and item.black_hearts > auxi.Count_Flags(player:GetBlackHearts()) then
					local n_entity = Isaac.GetRoomEntities()
					local n_enemy = auxi.getenemies(n_entity)
					for i = 1,#n_enemy do
						n_enemy[i]:AddFear(EntityRef(player),600)
					end
				end
				item.black_hearts = auxi.Count_Flags(player:GetBlackHearts())
			end
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			--player:EvaluateItems()	--先不考虑这个问题。
			item_manager.params.should_add_cache_on_update = true
		end
	end
end

function item.OnCacheUpdate(_,player,cacheFlag)
	if player:HasCollectible(enums.Items.Darkness) then
		local cnt = player:GetCollectibleNum(enums.Items.Darkness)
		if cacheFlag == CacheFlag.CACHE_DAMAGE then
			local q1 = auxi.Count_Flags(player:GetBlackHearts())
			local q2 = 0
			local n_entity = Isaac.GetRoomEntities()
			local n_enemy = auxi.getenemies(n_entity)
			for i = 1,#n_enemy do
				if n_enemy[i]:HasEntityFlags(EntityFlag.FLAG_FEAR) then
					q2 = q2 + 1
				end
			end
			if #n_enemy ~= 0 then
				q2 = q2 * 0.1
			end
			player.Damage = player.Damage * (1 + q1 * 0.003) * (1 + q2) + q1 * 0.8 * (cnt + 3)/4
        end
		if cacheFlag == CacheFlag.CACHE_TEARFLAG then
            player.TearFlags = player.TearFlags | BitSet128(1<<(20),0) 
        end
		if cacheFlag == CacheFlag.CACHE_TEARCOLOR then
			--print(1111)
            player.TearColor = auxi.AddColor(player.TearColor,Color(1,1,1,1,-1,-1,-1),0,1)
            player.LaserColor = auxi.AddColor(player.LaserColor,Color(1,1,1,1,-1,-1,-1),0,1)
        end
	end
end

return item