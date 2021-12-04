local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")
local item_manager = require("Extra_scripts.core.item_manager")
local auxi = require("Extra_scripts.auxiliary.functions")
local sound_tracker = require("Extra_scripts.auxiliary.sound_tracker")

local item = {
	pickup = enums.Pickups.Glaze_key,
}

function item.try_collect(player)
	player:AddKeys(1)
	local level = Game():GetLevel()
	local targs = {}
	local rooms = level:GetRooms()
    for i = 1, rooms.Size do
        local targ = rooms:Get(i)
		if targ ~= nil and targ.GridIndex >= 0 and targ.DisplayFlags == 0 then
			targs[#targs + 1] = targ
		end
	end
	--if #targs > 0 then
		--trags[math.random(#targs)].DisplayFlags = 1
		--level:Update()
	--end
	--l print(Game():GetLevel():GetCurrentRoomDesc().ListIndex)
	--l print(Game():GetLevel():GetLastRoomDesc().DisplayFlags)
	--l print(Game():GetLevel():GetRooms():Get(1).DisplayFlags)
	--l Game():GetLevel():GetRooms():Get(1).Data:TriggerClear(true)
	--l Game():GetLevel():GetCurrentRoom():TriggerClear(true)
	--l Game():ShowHallucination(0,1)
	--sound_tracker.PlayStackedSound(toplay.id,toplay.vol,toplay.pit,false,0,2)
	return true
end

function item.OnPickUpCollision(_,ent, col, low)
    local player = col:ToPlayer()
    if player then
		local should_collect = item.try_collect(player)
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
		--sound_tracker.PlayStackedSound(SoundEffect.SOUND_MEAT_FEET_SLOW0,1,1,false,0,2)
    end
    if ent:GetSprite():IsFinished("Collect") then
        ent:Remove()
    end
end

return item