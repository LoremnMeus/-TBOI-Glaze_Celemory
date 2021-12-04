local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")
local item_manager = require("Extra_scripts.core.item_manager")
local auxi = require("Extra_scripts.auxiliary.functions")

local item = {}

function item.OnPostUpdate()
	for playerNum = 1, Game():GetNumPlayers() do
		local player = Game():GetPlayer(playerNum - 1)
		if player:HasCollectible(enums.Items.My_Hat) then
			if player:GetData().My_Hat_costume_added == nil then
				player:GetData().My_Hat_costume_added = false
			end
			if player:GetData().My_Hat_costume_added ~= true then
				player:AddNullCostume(enums.Costumes.Qingrobes)
				player:GetData().My_Hat_costume_added = true
			end
		elseif player:GetData().My_Hat_costume_added == true and player:HasCollectible(enums.Items.My_Hat) == false then
			player:TryRemoveNullCostume(enums.Costumes.Qingrobes)
			player:GetData().My_Hat_costume_added = false
		end
	end
end

function item.OnPlayerDamage(_,ent, amt, flag, source, cooldown)
	if ent.Type == 1 then
		local player = ent:ToPlayer()
		if player:HasCollectible(enums.Items.My_Hat) then
			if source ~= nil and source.Type == 9 and source.Entity and source.Entity.PositionOffset then
				local proj = source.Entity:ToProjectile()
				if proj.FallingSpeed > 1 and proj.FallingAccel > 0.2 then
					player:SetColor(Color(1,1,1,1,0.5,0.5,0.5),20,30,true,false)
					return false
				end
			end
			if source ~= nil and source.Entity ~= nil and auxi.isenemies(source.Entity) then
				local col = source.Entity
				local d = source.Entity:GetData()
				if d.is_jumpping and d.is_jumpping > 0 then
					--print("hit1")
					col.Velocity = (player.Position - col.Position):Normalized() * (-30)
					local dmg = player.Damage + 3
					col:TakeDamage(dmg,0,EntityRef(player),10)
					col:SetColor(Color(2,0,0,1,0,0,0),10,30,true,false)
					return false
				end
			end
		end
	end
end

function item.OnNPCUpdate(_,npc)
	local s = npc:GetSprite()
	--print(s:GetFrame())
	local check = false
	for playerNum = 1, Game():GetNumPlayers() do
		if Game():GetPlayer(playerNum - 1):HasCollectible(enums.Items.My_Hat) then
			check = true
		end
	end
	if check == true then
		local d = npc:GetData()
		if s:IsEventTriggered ("Jump") or ((s:IsPlaying("JumpDown") or s:IsPlaying("Land")) and (s:WasEventTriggered ("Land") == false and s:WasEventTriggered ("Landed") == false and s:WasEventTriggered("Hit") == false and s:WasEventTriggered("Shoot") == false)) then
			--print("jump")
			d.is_land = false
			d.is_jumpping = 5
		end
		if s:IsEventTriggered ("Land") or s:IsEventTriggered ("Landed") or (npc.Type == 209 and s:IsEventTriggered("Hit")) or (npc.Type == 68 and s:IsEventTriggered("Shoot")) then
			--print("land")
			d.is_land = true
		end
		if d.is_land and d.is_land == true and d.is_jumpping and d.is_jumpping > 0 then d.is_jumpping = d.is_jumpping - 1 end
	end
end
--209号流血胖胖没有jump和land标记。妈手需要特判。

function item.OnPlayerCollision(_,player,col,low)
	if player:HasCollectible(enums.Items.My_Hat) then
		if col ~= nil then
			local d = col:GetData()
			if d.is_jumpping and d.is_jumpping > 0 then
				--print("hit2")
				local dmg = player.Damage * 0.5
				col:TakeDamage(dmg,0,EntityRef(player),10)
				col.Velocity = (player.Position - col.Position):Normalized() * (-30)
				return true
			end
		end
	end
end

return item