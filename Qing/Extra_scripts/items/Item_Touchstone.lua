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
		if player:HasCollectible(enums.Items.Touchstone) and player:HasWeaponType(8) == false then
			if ent.SpawnerType == 1 or (ent.SpawnerType == 3 and ent.SpawnerEntity ~= nil and (ent.SpawnerEntity.Variant == 80 or ent.SpawnerEntity.Variant == 235)) then
				if math.random(1000)>500 then
					local gdir = ent.Velocity/10--auxi.ggdir(player,true)
					local q1 = auxi.fire_dowhatknife(nil,ent.Position + ent.Velocity,player.Velocity + gdir * 10,ent.CollisionDamage/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = {}})
					ent.Position = Vector(2000,2000)
					ent:Remove()
					return
				end
			end
		end
	end
end

return item