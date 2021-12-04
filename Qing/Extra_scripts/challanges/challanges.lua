local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")
local auxi = require("Extra_scripts.auxiliary.functions")

local modReference
local Challanges = {
	
	roomsteak = 0
}

function Challanges.OnKnifeCollision(_,ent,col,low)
	if Game().Challenge == enums.Challenges.Fusion_Destiny then
		if ent.Variant == 4 and auxi.isenemies(col) and col:IsBoss() == false then
			Isaac.Spawn(5,0,0,col.Position,Vector(0,0),nil)
			col:Remove()
		end
	end
end

function Challanges.OnEntityDamage(_,ent, amt, flag, source, cooldown)
	if Game().Challenge == enums.Challenges.Fusion_Destiny then
		print(source.Type)
		if math.abs(amt - 3.00) < 0.00005 and source ~= nil and source.Type == 4 and source.Variant == 8 then
			if auxi.isenemies(ent) and ent:IsBoss() == false then
				Isaac.Spawn(5,0,0,col.Position,Vector(0,0),nil)
				ent:Remove()
			end
		end
	end
end

function Challanges.OnKnifeUpdate(_,ent)
	
	if Game().Challenge == enums.Challenges.Fusion_Destiny and Challanges.roomsteak > 0 then
		if ent.Variant ~= 4 then print(ent.Variant) end
		local room = Game():GetRoom()
		local level = Game():GetLevel()
		local d = ent:GetData()
		local s = ent:GetSprite()
		if ent.Type == 8 and ent.Variant == 4 and ent.Parent and room:IsFirstVisit() then
			if s:IsPlaying("Swing") or s:IsPlaying("Swing2") or s:IsPlaying("SwingDown") or s:IsPlaying("SwingDown2") and s:GetFrame() < 8 then
				local dir = (ent.Position - ent.Parent.Position):Normalized()
				local n_enemies = Isaac.FindInRadius (ent.Position + dir * 30,30,1<<3)
				for i = 1,#n_enemies do
					if auxi.isenemies(n_enemies[i]) and n_enemies[i]:IsBoss() == false then
						local targ = auxi.get_random_pickup()
						local q = Isaac.Spawn(5,targ.X,targ.Y,ent.Position + dir * 30,Vector(0,0),nil):ToPickup()
						Challanges.roomsteak = Challanges.roomsteak - 1
						n_enemies[i]:Remove()
						--l Game():GetPlayer(0):SetSize(50,Vector(0,0),12)
						q.Visible = false
						--q.Timeout = 5
						q.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL 
					end
				end
			end
		end
	end
end

function Challanges.OnNewRoom()
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	if Game().Challenge == enums.Challenges.Fusion_Destiny and room:IsFirstVisit() then
		Challanges.roomsteak = 15
	else
		Challanges.roomsteak = 0
	end
end

function Challanges.init(mod)
	modReference = mod
	--modReference:AddCallback(ModCallbacks.MC_PRE_KNIFE_COLLISION, Challanges.OnKnifeCollision)
	modReference:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, Challanges.OnKnifeUpdate)
	modReference:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Challanges.OnNewRoom)
	--modReference:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Challanges.OnEntityDamage)
end

return Challanges
