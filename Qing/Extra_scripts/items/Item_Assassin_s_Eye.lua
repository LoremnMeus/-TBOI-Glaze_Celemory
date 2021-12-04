local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")
local item_manager = require("Extra_scripts.core.item_manager")
local auxi = require("Extra_scripts.auxiliary.functions")

local item = {}

function item.OnTearUpDate(_,ent)
	local room = Game():GetRoom()
	
	if ent.SpawnerEntity~= nil and ent.SpawnerEntity.Type == 1 then
		local player = ent.SpawnerEntity:ToPlayer()
		if player:HasCollectible(enums.Items.Assassin_s_Eye) then
			if ent.SpawnerType == 1 or (ent.SpawnerType == 3 and ent.SpawnerEntity ~= nil and (ent.SpawnerEntity.Variant == 80 or ent.SpawnerEntity.Variant == 235)) then
				local d = ent:GetData()
				if d.asin == nil then d.asin = 5 end
				d.asin = d.asin - 1
				if d.asin <= 0 then
					local range = math.min(180,player.TearRange * 0.3)
					local n_entity = Isaac.FindInRadius(ent.Position,range,1<<3)
					local n_enemy = auxi.getenemies(n_entity)
					if #n_enemy > 0 then
						local rand = math.random(1000)
						local targ = auxi.getdisenemies(n_enemy,ent.Position,100)
						if rand > 900 then
							targ = auxi.getrandenemies(n_enemy)
						end
						if targ ~= nil and targ:Exists() then
							local q1 = Isaac.Spawn(1000,enums.Entities.MeusLink,0,ent.Position/2  + targ.Position/2,Vector(0,0),player)
							--local q2 = Isaac.Spawn(1000,enums.Entities.MeusLink,0,ent.Position/2  + targ.Position/2,Vector(0,0),player)
							--q2.CollisionDamage = 0.1
							local s1 = q1:GetSprite()
							--local s2 = q2:GetSprite()
							local dir = (targ.Position - ent.Position)
							local ang = dir:GetAngleDegrees() + math.random(20000)/1000 - 10
							local leg = dir:Length() + targ.Size * 1.3 + 5
							s1.Rotation = ang - 90;
							--s2.Rotation = ang - 90;
							s1.Scale = Vector(leg/120,1/10 * ent.Scale) 
							--s2.Scale = Vector(leg/180,5/10 * ent.Scale)
							--s2:Play("Link2")
							q1.PositionOffset = Vector(0,ent.PositionOffset.Y)
							--q2.PositionOffset = Vector(0,ent.Height)
							ent.Position = ent.Position + auxi.MakeVector(ang) * (leg)
							targ:TakeDamage(ent.CollisionDamage * 0.75,0,EntityRef(player),0)
							ent.Velocity = auxi.MakeVector(ang)
							ent:SetColor(Color(1,1,1,1,-2,-2,-2),15,99,true,false)
							-- l print(Game():GetPlayer(0).SizeMulti.X)
						end
						d.asin = math.max(4,player.MaxFireDelay * 0.75)
					end

				end
			end
		end
	end
end

return item