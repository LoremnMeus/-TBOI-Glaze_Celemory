local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")
local item_manager = require("Extra_scripts.core.item_manager")
local auxi = require("Extra_scripts.auxiliary.functions")
local sound_tracker = require("Extra_scripts.auxiliary.sound_tracker")

local item = {
	pickup = enums.Pickups.Glaze_heart,
}

--还存在的问题：骨棒不能拾取这些心。

function item.try_collect(player,toHeal)
	local toplay = {id = SoundEffect.SOUND_HOLY,vol = 1,pit = 1}
	if player:GetBrokenHearts() > 0 then
		player:AddBrokenHearts(-1)
		if toHeal == 2 then
			player:AddSoulHearts(1)
		end
	elseif player:GetRottenHearts() > 0 then
		player:AddRottenHearts(-1)
		if toHeal == 1 then
			player:AddHearts(-1)
		end
	elseif player:GetEternalHearts() > 0 and math.random(1000) > 900 then
		player:AddEternalHearts(1)
		if toHeal == 2 then
			player:AddSoulHearts(1)
		end
		toplay.id = SoundEffect.SOUND_SUPERHOLY
	elseif player:GetBlackHearts() > 0 and player:CanPickBlackHearts() and math.random(1000) > 700 then
		player:AddBlackHearts(1)
	elseif player:GetBoneHearts() > 0 and player:CanPickBoneHearts() and math.random(1000) > 950 then
		player:AddBoneHearts(1)
		toplay.id = SoundEffect.SOUND_BONE_HEART
	elseif player:GetGoldenHearts() > 0 and player:CanPickGoldenHearts() and math.random(1000) > 600 then
		player:AddGoldenHearts(1)
		toplay.id = SoundEffect.SOUND_GOLD_HEART
	elseif player:GetSoulHearts() > 0 and player:CanPickSoulHearts() and math.random(1000) > 700 then
		player:AddSoulHearts(toHeal)
	elseif player:CanPickRedHearts() then
		player:AddHearts(toHeal)
		toplay.id = SoundEffect.SOUND_BOSS2_BUBBLES
	elseif player:GetSoulHearts() > 0 and player:CanPickSoulHearts() then
		player:AddSoulHearts(toHeal)
	elseif player:GetBlackHearts() > 0 and player:CanPickBlackHearts() then
		player:AddBlackHearts(1)
	elseif player:GetGoldenHearts() > 0 and player:CanPickGoldenHearts() then
		player:AddGoldenHearts(1)
		toplay.id = SoundEffect.SOUND_GOLD_HEART
	elseif player:GetBoneHearts() > 0 and player:CanPickBoneHearts() then
		player:AddBoneHearts(1)
		toplay.id = SoundEffect.SOUND_BONE_HEART
	elseif player:GetEternalHearts() > 0 then
		player:AddEternalHearts(1)
		if toHeal == 2 then
			player:AddSoulHearts(1)
		end
		toplay.id = SoundEffect.SOUND_SUPERHOLY
	else
		return false
	end
	sound_tracker.PlayStackedSound(toplay.id,toplay.vol,toplay.pit,false,0,2)
	return true
end

function item.OnPickUpCollision(_,ent, col, low)
    local player = col:ToPlayer()
    if player then
        local pinkType = ent.SubType
        local toHeal = 0
        if pinkType == 1 then
            toHeal = 1
        elseif pinkType == 0 then
            toHeal = 2
        end
		local should_collect = item.try_collect(player,toHeal)
		if should_collect == true then
			ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			ent:GetSprite():Play("Collect", true)
			return true
		else
			return nil
		end
	end
end

function item.OnPickUpUpdate(_,ent)
    if ent:GetSprite():IsEventTriggered("DropSound") then
		sound_tracker.PlayStackedSound(SoundEffect.SOUND_MEAT_FEET_SLOW0,1,1,false,0,2)
    end
    if ent:GetSprite():IsFinished("Collect") then
        ent:Remove()
    end
end

return item