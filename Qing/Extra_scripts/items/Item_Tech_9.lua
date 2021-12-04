local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")
local item_manager = require("Extra_scripts.core.item_manager")
local auxi = require("Extra_scripts.auxiliary.functions")

local item = {}

function item.OnTearInit(_,ent)
	local room = Game():GetRoom()
	
	if ent.SpawnerEntity~= nil and ent.SpawnerEntity.Type == 1 then
		local player = ent.SpawnerEntity:ToPlayer()
		if player:HasCollectible(enums.Items.Tech_9) and player:HasWeaponType(8) == false then
			if ent.SpawnerType == 1 or (ent.SpawnerType == 3 and ent.SpawnerEntity ~= nil and (ent.SpawnerEntity.Variant == 80 or ent.SpawnerEntity.Variant == 235)) then
				local cnt = player:GetCollectibleNum(enums.Items.Tech_9)
				local rand = math.random(1000)
				if rand > math.max(600,1000 - cnt *60 - player.Luck * 10) then
					local sz = math.random(50) + 20
					local q = player:FireTechXLaser(ent.Position,ent.Velocity * (auxi.random_1() + 1)/2,sz,player,sz/70)
					ent.Position = Vector(2000,2000)
					ent:Remove()
					return
				end
				rand = math.random(1000)
				if rand > math.max(800,1000 - cnt * 100 - player.Luck * 5) then
					local q = player:FireTechLaser(ent.Position,1,ent.Velocity,false,false,player,0.75)
					ent.Position = Vector(2000,2000)
					ent:Remove()
					return
				end
				rand = math.random(1000)
				if rand > math.max(900,1000 - cnt * 30 - player.Luck * 3) then
					local q = player:FireTechLaser(ent.Position,1,ent.Velocity,true,false,player,0.75)
					ent.Position = Vector(2000,2000)
					ent:Remove()
					return
				end
				rand = math.random(1000)
				if rand > math.max(500,1000 - cnt * 50 - player.Luck * 35) then
					local q = player:FireTechLaser(ent.Position,1,ent.Velocity,false,true,player,1.3)
					ent.Position = Vector(2000,2000)
					ent:Remove()
					return
				end
			end
		end
	end
end

return item