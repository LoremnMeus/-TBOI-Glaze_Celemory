local CharacterMeus = RegisterMod("QING",1)
--mod注册的地方
local SPWQinghair = Isaac.GetCostumeIdByPath("gfx/characters/SPWQingHair.anm2")
local Qingrobes = Isaac.GetCostumeIdByPath("gfx/characters/Qingrobes.anm2")

local QingsAirs = Isaac.GetEntityVariantByName("QingsAir")
local MeusLink = Isaac.GetEntityVariantByName("MeusLink")
local QingsMarks = Isaac.GetEntityVariantByName("QingsMark")
local StabberKnife = Isaac.GetEntityVariantByName("StabberKnife")
local MeusSword = Isaac.GetEntityVariantByName("MeusSword")
local ID_EFFECT_MeusFetus = Isaac.GetEntityVariantByName("MeusFetus")
local ID_EFFECT_MeusRocket = Isaac.GetEntityVariantByName("MeusRocket")
local ID_EFFECT_MeusNIL = Isaac.GetEntityVariantByName("MeusNil")

local ModConfig = require("Extra_scripts.Mod_Config_Menu_support")		--试着将程序包装出去。
ModConfig.init(CharacterMeus)

local ModConfigSettings = ModConfig.ModConfigSettings

local bomb_effe_list = {
	28,29,35,36,37,45,72,75,78
}
local bomb_effe_map = {
	{75,20},{30,10},{20,20},{50,15},{50,10},{75,15},{100,5},{100,15},{100,7}
}

require("Extra_scripts.achievement_display_api")
local enums = require("Extra_scripts.core.enums")
local tracker = require("Extra_scripts.core.achievement_tracker")
local unlockm = require("Extra_scripts.core.unlock_manager")
local save = require("Extra_scripts.core.savedata")
local item_manager = require("Extra_scripts.core.item_manager")
local pickup_manager = require("Extra_scripts.core.pickup_manager")
local challanges = require("Extra_scripts.challanges.challanges")
local translation = require("Extra_scripts.translations.zh")
local auxi = require("Extra_scripts.auxiliary.functions")
local sound_tracker = require("Extra_scripts.auxiliary.sound_tracker")
item_manager.Init(CharacterMeus)
pickup_manager.Init(CharacterMeus)
save.Init(CharacterMeus)
unlockm.init(CharacterMeus)
challanges.init(CharacterMeus)
translation.init(CharacterMeus)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_UPDATE,tracker.postUpdate)
------------------------------------------

local json = require("json")
local TO_BE_SAVED = {}
local canSaveData = false
local should_save = false

local Delay_buffer = {		--延迟轴。用于实现延迟生效的任何特效。
}

local SPWQing_BUFF = { 
    DAMAGE = 1,
    SPEED = 0 ,
    SHOTSPEED = 0.80,
    TEARHEIGHT = 0,
    TEARFALLINGSPEED = 0,
	RANGE = 0,
    LUCK = 0,
    FLYING = false,                                 
    TEARFLAG = 0,
    TEARCOLOR = Color(1.0, 1.0, 1.0, 1.0, 0, 0, 0)  -- Color(1.0, 1.0, 1.0, 1.0, 0, 0, 0) is default
}
--角色属性调整表

local actionofdebuglist = 0
local delayofdebuglist = 0

local Debuglist={}
for i=1,15 do
	Debuglist[i]= 0
end
function Debugtext()
	if actionofdebuglist == 0 then
		for i=1,15 do
			Isaac.RenderText(Debuglist[i],100,40+10*i,255,0,0,255)
		end
	end
end
--CharacterMeus:AddCallback(ModCallbacks.MC_POST_RENDER, Debugtext)
--------简易debug调试台--------
function CharacterMeus:OnDebuglistUpdate()	
	if Input.IsButtonTriggered(85,0) or Input.IsButtonPressed(85,0) then
		actionofdebuglist = 1 - actionofdebuglist
		delayofdebuglist = 100
	end
	if delayofdebuglist > 0 then
		delayofdebuglist = delayofdebuglist - 1
	end
end
--------调试开关(按U开关）--------
--CharacterMeus:AddCallback(ModCallbacks.MC_POST_UPDATE, CharacterMeus.OnDebuglistUpdate)

function CharacterMeus:OnPlayerInit(player)	--这里是初始化，已更新！
	math.randomseed(Game():GetSeeds():GetStartSeed())
	if player:GetName() == "SP.W.Qing" then
		player:AddNullCostume(SPWQinghair)
		--costumeEquipped = true
	end
	if player:GetName() == "W.Qing" then
		player:AddNullCostume(Qingrobes)
		--costumeEquipped = true
	end
end
--mod角色的初始化
function CharacterMeus:OnUseDice(item, itemRng, player, useFlags, activeSlot, customVarData)
	if item == 283 or item == 284 then
		if player:GetName() == "SP.W.Qing" then
			player:AddNullCostume(SPWQinghair)
		end
		if player:GetName() == "W.Qing" then
			player:AddNullCostume(Qingrobes)
		end
	end
end
CharacterMeus:AddCallback(ModCallbacks.MC_USE_ITEM, CharacterMeus.OnUseDice)

local function GetPlayers()
	local players = {}
	for i=0,Game():GetNumPlayers()-1 do
		local player = Game():GetPlayer(i)
		players[i] = player
	end
	return players
end
local function MakeBitSet(i)
	if i >= 64 then
		return BitSet128(0,1<<(i-64))
	else
		return BitSet128(1<<(i),0)
	end
end
local function bitset_flag(x,i)	--获取x第i位是否含有1。
	if i >= 64 then
		return (x & BitSet128(0,1<<(i-64)) == BitSet128(0,1<<(i-64)))
	else
		return (x & BitSet128(1<<(i),0) == BitSet128(1<<(i),0))
	end
end
local function random_1()
	return math.random(1000)/1000
end
local function Count_Flags(x)
	local ret = 0
	for i = 0, math.floor(math.log(x)/math.log(2)) +1 do
		if x%2==1 then
			ret = ret + 1
		end
		x = (x-x%2)/2
	end
	return ret
end
local function Get_Flags(x,fl)	--从第0位开始计算flag
	--Debuglist[1] = math.floor(x/(1<<fl))
	if (math.floor(x/(1<<fl)) %2 == 1) then
		return true
	end
	return false
end
local function Get__cos(vec)		--获取Vector类型的角度
	local t = (vec + Vector(vec:Length(),0)):Length()/2
	local q = t/vec:Length()
	return 1 - 2 * q * q
end
local function Get__sin(vec)		--获取Vector类型的角度
	local t=(vec + Vector(0,vec:Length())):Length()/2
	q = t/vec:Length()
	return 1 - 2 * q * q
end
local function Get__trans(t)			--获取cos对应的sin
	if t > 1 or t < -1 then
		return 0
	end
	return math.sqrt(1-t*t) 
end
local function Get_rotate(t)		--接收一个vector，获取旋转90度的vector
	--return Vector(-Get__sin(t)*m, Get__cos(t)*m)
	return Vector(-t.Y,t.X)
end
local function plu_s(v1,v2)
	return v1.X*v2.X+v1.Y*v2.Y
end
local function MakeVector(x)
	return Vector(math.cos(math.rad(x)),math.sin(math.rad(x)))
end
local function AddColor(col_1,col_2,x,y)		--加权相加。
	return Color(col_1.R * x + col_2.R * y,col_1.G * x+ col_2.G * y,col_1.B * x+ col_2.B * y,col_1.A * x+ col_2.A * y,col_1.RO * x+ col_2.RO * y,col_1.GO * x+ col_2.GO * y,col_1.BO * x+ col_2.BO * y)
end
local function TearsUp(firedelay, val)	--thx
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val
    return math.max((30 / newTears) - 1, -0.99)
end
local function getdir(player)		--修正后，可以获得八个方向了！
	if player == nil then
		print("Wrong player in function::getdir()")
		return Vector(0,0)
	end
	local ret = player:GetShootingInput()
	if ret:Length() > 0.05 then
		ret = ret / ret:Length()
	end
	return ret
end
local for_set_for_ggdir = {tim = 0,dir = Vector(0,0),ignore_marked = false}
local function ggdir(player,ignore_marked)		--这个函数忽略了实际上无视行动的策略。例如：某种无敌。
	if player:AreControlsEnabled() == false then
		return Vector(0,0)
	end
	if player:IsExtraAnimationFinished() == false or player.Visible == false then
		return Vector(0,0)
	end
	local nowtime = Game():GetFrameCount()
	if for_set_for_ggdir and for_set_for_ggdir.tim == nowtime and for_set_for_ggdir.ignore_marked == ignore_marked then
		return for_set_for_ggdir.dir
	end
	for_set_for_ggdir.tim = nowtime
	for_set_for_ggdir.ignore_marked = ignore_marked
	if ignore_marked == false then
		if player:HasCollectible(394) or player:HasCollectible(572) then
			local n_entity = Isaac.GetRoomEntities()
			for i = 1, #n_entity do
				if n_entity[i] and n_entity[i].Type == 1000 and (n_entity[i].Variant == 153 or n_entity[i].Variant == 30) then
					local dir = (n_entity[i].Position - player.Position):Normalized()
					for_set_for_ggdir.dir = dir
					return dir
				end
			end
		end
	end
	local dir = getdir(player)
	for_set_for_ggdir.dir = dir
	return dir
end
local function getpickups(ents,ignore_items)
	local pickups = {}
    for _, ent in ipairs(ents) do
        if ent.Type == 5 and (ignore_items == false or ent.Variant ~= 100) then
            pickups[#pickups + 1] = ent
        end
    end
	return pickups
end
local function getenemies(ents)
	local enemies = {}
    for _, ent in ipairs(ents) do
        if ent:IsVulnerableEnemy() and ent:IsActiveEnemy() and not ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
            enemies[#enemies + 1] = ent
        end
    end
	return enemies
end
local function isenemies(ent)
	if ent:IsVulnerableEnemy() and ent:IsActiveEnemy() and not ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
		return true
	end
	return false
end
local function getothers(ents,x,y,z)
	local targs = {}
    for _, ent in ipairs(ents) do
        if x == nil or ent.Type == x then
			if y == nil or ent.Variant == y then
				if z == nil or ent.SubType == z then
					targs[#targs + 1] = ent
				end
			end
        end
    end
	return targs
end
local function getmultishot(cnt1,cnt2,id,cnt3)		--cnt1:总数量；cnt2：巫师帽数量；cnt3：宝宝套
	local cnt = math.ceil(cnt1/cnt2)		--此为每一弹道发射的眼泪数。不计入宝宝套给予的额外2发。
	if cnt3 == 1 and cnt2 < 3 then
		cnt = math.ceil((cnt1-2)/cnt2)
	end
	if cnt2 > 2 then
		cnt3 = 0
	end
	local dir = 180 / (cnt2+1)
	local inv1 = 30			--非常奇怪，存在巫师帽的时候，那个间隔随着cnt增大而减小，并不是特别好测量，因此我也就意思一下了（，不存在的时候，大概是10到5度角左右。
	local inv2 = 5 + cnt
	local inv3 = 5
	if cnt3 == 1 then			--存在宝宝套
		if cnt2 == 1 then		--单弹道+宝宝套
			if id == 1 then			--冷知识：宝宝套两个方向的弹道实际上不对称！不过我才懒得做适配……
				return 45
			elseif id == cnt1 then
				return 135
			else
				return 90 - (cnt-1)/2 * inv3 + (id-2) * inv3			--考虑以5度为间隔，关于90度镜像阵列。
			end
		else		--巫师帽宝宝套，双弹道多发。
			if id - 1 > cnt then
				return 45 - (cnt-1)/2 * inv2 + (id - cnt - 1) * inv2
			else
				return 135 - (cnt-1)/2 *inv2 + (id - 1) * inv2
			end
		end
	else
		local grp = math.floor((id-1)/cnt)	--id号攻击属于的弹道数（0到cnt2-1）
		if cnt2 ~= 1 then
			return (grp + 1) * dir - (cnt-1)/2 * inv1 + (id-1 - grp * cnt) * inv1
		else
			return (grp + 1) * dir - (cnt-1)/2 * inv2 + (id-1 - grp * cnt) * inv2
		end
	end
end
local function trychangegrid(x)
	if x == nil or x.CollisionClass == nil then
		return
	end
	x.CollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
end
local getdisenemies = auxi.getdisenemies
local function getrandenemies(enemies)
	if #enemies == 0 then
		return nil
	else
		return enemies[math.random(#enemies)]
	end
end
local function getmultishots(player,allowrand)
	local cnt1 = 1
	if player:HasCollectible(153) or player:HasCollectible(2) or player:GetPlayerType() == 14 or player:GetPlayerType() == 33 then				--四眼、三眼、店长、里店长的特效：眼泪固定加1发，二者不叠加。有趣的是，对于眼泪而言，三、四眼和多个20/20叠加不完全一致，但科技的激光、妈刀等等却并非如此，说明程序员偷懒了（
		cnt1 = cnt1 + 1
	end
	local list = {	--硫磺火不再叠加，肺特殊处理，水球不叠加
		68,			--科技
		52,			--博士
		114,		--妈刀
		168,		--史诗
		395,		--科X
		579			--英灵剑
	}
	for i = 1,#list do
		cnt1 = cnt1 + math.max(0,player:GetCollectibleNum(list[i]) - 1)
	end
	cnt1 = cnt1 + math.max(0,player:GetCollectibleNum(153)* 2) + math.max(0,player:GetCollectibleNum(2)) + math.max(0,player:GetCollectibleNum(245)) + math.max(0,player:GetCollectibleNum(358))	--二、三、四眼与巫师帽
	if player:HasPlayerForm(PlayerForm.PLAYERFORM_BABY) and math.max(0,player:GetCollectibleNum(358)) < 2 then		--宝宝套：直接加2发
		cnt1 = cnt1 + 2
	end
	if allowrand == true then
		if player:HasPlayerForm(PlayerForm.PLAYERFORM_BOOK_WORM) and math.max(0,player:GetCollectibleNum(358)) < 2 then		--书套：随机加1发
			if math.random(4) > 3 then
				cnt1 = cnt1 + 1
			end
		end
	end
	return cnt1
end
local function check_rand(luck,maxum,zeroum,threshold)		--幸运；上限（0-100）；下限；幸运阈值
	local rand = math.random(10000)/10000
	if rand * 100 < math.exp(math.min(luck/5,threshold/5))/math.exp(threshold/5) * (maxum - zeroum) + zeroum then
		--Debuglist[14] = rand * maxum
		return true
	else
		return false
	end
end
local function getQingshots(player,allowrand)
	local ret = getmultishots(player,allowed)
	if ret == nil then
		return 1
	end
	ret = ret + player:GetCollectibleNum(619)*3		--长子权
	return ret
end
local function check(ent)
	return ent ~= nil and ent:Exists() and (not ent:IsDead())
end
local issolid = auxi.issolid
local copy = auxi.copy
local launch_Missile = auxi.launch_Missile
local fire_nil = auxi.fire_nil
local fire_knife = auxi.fire_knife
local fire_lung_Laser = auxi.fire_lung_Laser
local fire_Sword = auxi.fire_Sword
local fire_dowhatknife = auxi.fire_dowhatknife
local thor_attack = auxi.thor_attack
local kill_thenm_all = auxi.kill_thenm_all
local kill_thenm_all2  = auxi.kill_thenm_all2
local PrintTable = auxi.PrintTable

-----------功能性函数，只会被间接调用------------

function CharacterMeus:OnPostUpdate()		--只用于检测功能。
	local Sfx = SFXManager()
	for i = 1,1000 do 
		if Sfx:IsPlaying(i) then
			if i ~= 482 and i ~= 537 then
				Debuglist[1] = i
				Debuglist[2] = Sfx:GetAmbientSoundVolume(i)
			end
		end
	end
end
CharacterMeus:AddCallback(ModCallbacks.MC_POST_UPDATE, CharacterMeus.OnPostUpdate)

function CharacterMeus:GetShaders(name)		--只用于检测功能。
	print(name)
end
--CharacterMeus:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, CharacterMeus.GetShaders)

---------------------------------------------

function CharacterMeus:Init(continued)
	print("Qing, V1.0.0")
	actionofdebuglist = 1
	if should_save then
		if continued then
			LoadData()
			--if TO_BE_SAVED.playerData ~= nil then
			--print("Continue")
			--end
		else
			--print("Begin")
			SaveData()
		end
		canSaveData = true
	end
end

LoadData = function()
	local raw = CharacterMeus:LoadData()
	if raw and #raw ~= 0 then
		local data = json.decode(raw)
		print("Load")
		TO_BE_SAVED = data
		if data.modConfig ~= nil then
			for key,value in pairs(data.modConfig) do
				if data.modConfig[key] ~= nil then
					ModConfigSettings[key] = value
				end
			end
		end
	end
end

if should_save then LoadData() end

function CharacterMeus:Exit(shouldSave)
	if should_save then
		if shouldSave then
			SaveData()
		end
		canSaveData = false
	end
end

SaveData = function()
	if canSaveData then
        local data = {}
		local playerData = {}
		for playerIndex,player in pairs(GetPlayers()) do
			playerData[playerIndex] = playerData[playerIndex] or {}
		end
		data.playerData = playerData
		data.modConfig = ModConfigSettings
		print("Save")
        local encoded = json.encode(data)
        if encoded ~= nil and #encoded > 0 then
            CharacterMeus:SaveData( encoded )
        end
    end
end

----------------拷贝的存储功能。已废弃。-------------

function addeffe(func,params,tim)		--添加延迟效果。在tim之后，执行func（params）
	local del = #Delay_buffer
	for i = 1,#Delay_buffer do 
		if Delay_buffer[del - i] ~= nil and (Delay_buffer[del - i].TimeD == nil or Delay_buffer[del - i].TimeD < 0 or Delay_buffer[del - i].func == nil) then
			Delay_buffer[del - i] = nil 
		end
	end
	for i = 1,#Delay_buffer do
		if Delay_buffer[i] == nil or Delay_buffer[i].TimeD == nil or Delay_buffer[i].TimeD < 0 or Delay_buffer[i].func == nil then
			Delay_buffer[i] = {}
			Delay_buffer[i].TimeD = tim
			Delay_buffer[i].params = params
			Delay_buffer[i].func = func
			return
		end
	end
	local i = #Delay_buffer + 1
	Delay_buffer[i] = {}
	Delay_buffer[i].TimeD = tim
	Delay_buffer[i].params = params
	Delay_buffer[i].func = func
end

function CharacterMeus:OnDelayUpdate()			--已更新：适用于多人。
	for i = 1,#Delay_buffer do
		Debuglist[13] = Debuglist[13] + 1
		Debuglist[15] = #Delay_buffer
		if Delay_buffer[i] == nil then
			Debuglist[14] = Debuglist[14] + 1
		elseif Delay_buffer[i].TimeD ~= nil and Delay_buffer[i].TimeD >= 0 then
			Delay_buffer[i].TimeD = Delay_buffer[i].TimeD - 1
		end
		if Delay_buffer[i] ~= nil and Delay_buffer[i].TimeD ~= nil and Delay_buffer[i].TimeD <= 0 then
			if Delay_buffer[i].func ~= nil then
				local func = Delay_buffer[i].func
				func(Delay_buffer[i].params)
			end
			Delay_buffer[i] = {}
		end
	end
end
--------延迟生效的部分--------

-----------万青的内容---------
--目前尚未支持的部分：巧克力奶、诅咒之眼、大眼、煤块突眼（大部分关于史诗）、血凝块、鲁科、英灵剑、骨剑（做了一半）、BFFS！（还在考虑要不要做）、长子权：提供飞行，攻击模块增加3个。

function CharacterMeus:OnKnifeCollision(knife,colli,low)
	--Debuglist[11] = Debuglist[11] + 1
	if knife:GetData().Explosive_cnt and knife:GetData().Explosive_cnt > 0 then
		Debuglist[12] = Debuglist[12] + 1
		local player = knife:GetData().player
		if player == nil then
			if knife:GetData().params then
				player = knife:GetData().params.player
			end
		end
		if player == nil then
			player = Game():GetPlayer(0)
		end
		local dmg = knife.CollisionDamage
		local tearflags = knife:GetData().bomb_knife_flag
		if tearflags == nil and knife:GetData().params and knife:GetData().params.bomb_knife_flag then
			tearflags = knife:GetData().params.bomb_knife_flag
		end
		if tearflags == nil then
			tearflags = BitSet128(0,0)
		end
		Game():BombExplosionEffects(colli.Position,dmg * 10,tearflags,player.TearColor,player,1,false,false)		--耶耶耶！！！	
		knife:GetData().Explosive_cnt = knife:GetData().Explosive_cnt - 1
	end
end
CharacterMeus:AddCallback(ModCallbacks.MC_PRE_KNIFE_COLLISION, CharacterMeus.OnKnifeCollision)

function CharacterMeus:UpdateMeusNil(ent)		--介质
	local d = ent:GetData()
	if ent.Variant == ID_EFFECT_MeusNIL then
		if d.Params == nil then
			d.Params = {}
		end
		if d.removecd == nil then
			d.removecd = 60
		end
		if d.removecd > 0 then
			d.removecd = d.removecd - 1
		end
		if d.removecd == 0 then
			if d.Params.removeanimate then
				if ent.Child then
					local q1 = Isaac.Spawn(1000,15,0,ent.Child.Position,Vector(0,0),nil):ToEffect()
					q1:GetSprite().Scale = ent:GetSprite().Scale
				end
			end
			ent:Remove()
		end
		if d.follower then		--当有跟随者时，自动粘附敌人。否则追加加速度。
			if d.follower:Exists() then
				if d.nw_follow_pos == nil then
					d.nw_follow_pos = ent.Position - d.follower.Position
				end
				ent.Position = d.follower.Position + d.nw_follow_pos
				ent.Velocity = d.follower.Velocity
			else
				if ent.Velocity:Length() > 0.05 then		--强制停止。
					if (d.continue_after_follower and d.continue_after_follower == true) then
						if d.continue_and_resetvel ~= nil then
							ent.Velocity = d.continue_and_resetvel
						end
						d.follower = nil
					else
						d.Params.Accerate = -1
						if d.Accerate_flag == nil or d.Accerate_flag == false then
							d.Accerate_flag = true
						end
						d.follower = nil
					end
				end
			end
		else
			if d.Params.FollowInput and d.Params.FollowInput == true then
				local player = d.Params.player
				if player == nil then
					player = Game():GetPlayer(0)
				end
				local gdir = ggdir(player,false)
				if gdir:Length() < 0.05 and ent.Velocity:Length() > 0.0005 then
					ent.Velocity = ent.Velocity * 0.85
				else
					ent.Velocity = (gdir + ent.Velocity:Normalized()):Normalized() * math.min(20,(ent.Velocity:Length() * 1.5))
				end
			elseif d.Params.Accerate then
				if d.Accerate_flag == nil then
					d.Accerate_flag = true
				end
				if d.Accerate_avoid_lock == nil then
					d.Accerate_avoid_lock = false
				end
				if d.Accerate_flag == true or d.Accerate_avoid_lock == true then
					local leg_vel = ent.Velocity:Length() + d.Params.Accerate
					if leg_vel < 0.001 and d.Accerate_avoid_lock ~= true then
						ent.Velocity = ent.Velocity / 100000
						d.Accerate_flag = false
					else
						ent:AddVelocity(ent.Velocity:Normalized() * d.Params.Accerate)
					end
				end
			end
			if d.Params.Homing then		--可以传入的参数：HomingSpeed/HomingDistance
				local shouldHome = true
				if d.Homing_cnt and d.Homing_cnt > 0 then
					d.Homing_cnt = d.Homing_cnt - 1
					shouldHome = false
				end
				
				local nowpos = ent.Position
				if ent.Child then
					nowpos = ent.Child.Position
				end
				
				if d.Params.Homing_target == nil then-- or d.Params.Homing_target:Exists() == false or (d.Params.HomingDistance and d.Params.Homing_target.Position:DistanceSquared(ent.Position) < d.Params.HomingDistance) then
					--d.Params.Homing_target = nil	--只选择1次。
					--Debuglist[13] = Debuglist[13] + 1
					--Debuglist[14] = Debuglist[14] + 1
					local n_entity = Isaac.GetRoomEntities()
					local n_enemy = getenemies(n_entity)
					for i = 1,#n_enemy do
						if (d.Params.Homing_target == nil or (n_enemy[i].Position - nowpos):Length() < (d.Params.Homing_target.Position - nowpos):Length()) and (d.Params.HomingDistance == nil or (n_enemy[i].Position - nowpos):Length() < d.Params.HomingDistance) then
							d.Params.Homing_target = n_enemy[i]
						end
					end
					
				end
				
				if d.Params.Homing_target ~= nil then
					shouldHome = true
				else
					shouldHome = false
				end

				if shouldHome and d.Params.Homing_target and d.Params.Homing_target:Exists() == true then
					if d.Params.HomingAcce == nil then
						d.Params.HomingAcce = d.Params.Accerate
						d.Params.Accerate = -1
					end
					local direction = (d.Params.Homing_target.Position - nowpos):Normalized()
					if ent.Velocity:Length() > 0.5 then
						ent.Velocity = ent.Velocity + (direction * math.min(ent.Velocity:Length() * 0.75,(d.Params.HomingSpeed or 0.6)))
					else
						ent.Velocity = ent.Velocity:Normalized() + (direction * math.min(0.75,(d.Params.HomingSpeed or 0.6)))
					end
				end
			end
		end
		
		if ent:GetData().Is_Qing_Fetus and ent:GetData().Is_Qing_Fetus == true then		--只要有fetus标记就是婴儿。
			ent:GetData().Is_Qing_Fetus = false
			local s = ent:GetSprite()
			s:Load("gfx/1000.2338_NILL_Fetus.anm2")
			s:Play("IdleX")
		end
		if ent:GetData().Is_Qing_Fetus == false then
			local ang = ent.Velocity:GetAngleDegrees()
			if ent.Velocity:Length() < 0.05 or d.follower and d.follower:Exists() then
				if ent.Child then
					Debuglist[12] = Debuglist[12] + 1
					ang = (ent.Child.Position - ent.Position):GetAngleDegrees()
				end
			end
			local s = ent:GetSprite()
			--Debuglist[9] = ang
			if (ang > 60 and ang < 120) or (ang < -60 and ang > -120) then
				if ang < 0 then
					if s:IsPlaying("IdleX") == true or s:IsPlaying("IdleY2") == true then
						s:Play("IdleY1",true)
					end	
				else
					if s:IsPlaying("IdleX") == true or s:IsPlaying("IdleY1") == true then
						s:Play("IdleY2",true)
					end	
				end
			else
				if s:IsPlaying("IdleY") == true then
					s:Play("IdleX",true)
				end
				if ang > 90 or ang < -90 then
					s.FlipX = false
				else
					s.FlipX = true
				end
			end
		end
		
		if d.Is_Qing_Damo and d.Is_Qing_Damo == true then		--只要有达摩标记就是达摩
			local s = ent:GetSprite()
			s:Load("gfx/003.2020_damocles.anm2")
			s:Play("Idle")
			d.Is_Qing_Damo = false
		end
		if d.Is_Qing_Damo == false then
			local s = ent:GetSprite()
			if s:IsPlaying("Idle") == true or s:IsFinished("Idle") == true or s:IsPlaying("Idle2") == true or s:IsFinished("Idle2") == true or s:IsPlaying("Idle") == true or s:IsFinished("Idle2") == true then
				local rand = math.random(1000)
				if rand > 600 then
					s:Play("Idle3",true)
				elseif rand > 800 then
					s:Play("Idle2",true)
				else
					s:Play("Idle",true)
				end
			end	
			if d.follower == nil or d.follower:Exists() == false or d.follower.HitPoints < d.follower.MaxHitPoints * 0.1 or d.follower.HitPoints < 3 or d.should_be_kill_by_damo then
				--Debuglist[5] = Debuglist[5] + 1
				if s:IsPlaying("Fall") == false and s:IsFinished("Fall") == false then
					s:Play("Fall",true)
				elseif s:IsFinished("Fall") == true then
					d.removecd = 1
				end
				if s:IsEventTriggered("Hit") or s:WasEventTriggered("Hit") or s:IsFinished("Fall") == true then
					if d.follower and d.follower:Exists() == true then
						d.follower:Kill()
						d.should_be_kill_by_damo = true
					end
				end
			end
		end
		
	end
end

function CharacterMeus:UpdateMeusTarget(ent)	--史诗
	local d = ent:GetData()
    if ent.Variant == ID_EFFECT_MeusFetus and d.BossMissile then
        local s = ent:GetSprite()
        local boss = d.Boss
        local target
        if boss then
            target = d.Boss:GetPlayerTarget()
        end
		
		if d.follower and d.follower:Exists() then
			Debuglist[9] = Debuglist[9] + 1000
			if d.nw_follow_pos == nil then
				d.nw_follow_pos = ent.Position - d.follower.Position
			end
			ent.Position = d.follower.Position + d.nw_follow_pos
			ent.Velocity = d.follower.Velocity
		end
		
		if d.MissileParams == nil then		--缺少参数，无法运行。
			return
		end
		
        if d.MissileParams.Homing and target then
            local shouldHome = true
            if d.MissileParams.HomingWait and d.MissileParams.HomingWait > 0 then
                d.MissileParams.HomingWait = d.MissileParams.HomingWait - 1
                shouldHome = false
            end

            if d.MissileParams.HomingDistance then
                if not (target.Position:DistanceSquared(ent.Position) < d.MissileParams.HomingDistance) then
                    shouldHome = false
                end
            end

            if shouldHome then
                local direction = (target.Position - ent.Position):Normalized()
                ent:AddVelocity(direction * (d.MissileParams.HomingSpeed or 0.6))
            end
        end

        if d.MissileParams.Cooldown and d.MissileParams.Cooldown > 0 then
            d.MissileParams.Cooldown = d.MissileParams.Cooldown - 1
        elseif not d.Rocket then
            local rocket = Isaac.Spawn(EntityType.ENTITY_EFFECT, ID_EFFECT_MeusRocket, 0, ent.Position, Vector(0,0), d.Boss)
            rocket.SpriteOffset = rocket.SpriteOffset + Vector(0, -300)
            d.Rocket = rocket
			rocket:GetSprite().Scale = ent:GetSprite().Scale
        end

        if d.Rocket then
            d.Rocket.Position = ent.Position
            d.Rocket.SpriteOffset = d.Rocket.SpriteOffset + Vector(0, 30)
            if d.Rocket.SpriteOffset.Y >= 0 then
                --Isaac.Explode(d.Rocket.Position, d.Boss, d.Damage * 20)
				local tearflags = d.MissileParams.tearflags
				if tearflags == nil then
					tearflags = BitSet128(0,0)
				end
				local color = d.MissileParams.color
				if color == nil then
					color = Color(1,1,1,1)
				end
				if d.MissileParams.Player == nil then
					d.MissileParams.Player = Game():GetPlayer(0)
				end
				Game():BombExplosionEffects(d.Rocket.Position,d.Damage * 20,tearflags,color,d.MissileParams.Player,ent:GetSprite().Scale:Length()/math.sqrt(2),false,true)		--耶耶耶！！！	
				if d.MissileParams.knife and d.MissileParams.knife ~= 0 then
					local para = {
						cooldown = 30,
						Accerate = 0.7,
					}
					if d.MissileParams.Player then
						para.player = d.MissileParams.Player
					end
					local rand_cnt1 = math.random(4) + 4
					local rand_cnt2 = math.random(36000)/100
					for i = 0, rand_cnt1 do
						fire_knife(ent.Position,MakeVector(360/rand_cnt1 * i + rand_cnt2) * 10,d.Damage*0.65,nil,para)
					end
				end
				if d.MissileParams.brimstone and d.MissileParams.brimstone ~= 0 then
					if d.MissileParams.Player == nil then
						d.MissileParams.Player = Game():GetPlayer(0)
					end
					local q2 = Isaac.Spawn(1000,ID_EFFECT_MeusNIL,0,d.Rocket.Position,Vector(0,0),nil):ToEffect()
					q2:GetData().removecd = 60
					local rand_cnt1 = math.random(4) + 4
					local rand_cnt2 = math.random(36000)/100
					for i = 0, rand_cnt1 do
						local q1 = d.MissileParams.Player:FireBrimstone(MakeVector(360/rand_cnt1 * i + rand_cnt2))
						q1.Parent = q2
						q1.Position = q2.Position
					end
				end
				if d.MissileParams.Tech and d.MissileParams.Tech ~= 0 then
					if d.MissileParams.Player == nil then
						d.MissileParams.Player = Game():GetPlayer(0)
					end
					local q2 = Isaac.Spawn(1000,ID_EFFECT_MeusNIL,0,d.Rocket.Position,Vector(0,0),nil):ToEffect()
					q2:GetData().removecd = 60
					local rand_cnt1 = math.random(4) + 4
					local rand_cnt2 = math.random(36000)/100
					for i = 0, rand_cnt1 do
						local q1 = d.MissileParams.Player:FireTechLaser(ent.Position,1,MakeVector(360/rand_cnt1 * i + rand_cnt2),false,true)
						q1.Parent = q2
					end
				end
				if d.MissileParams.TechX and d.MissileParams.TechX ~= 0 then
					if d.MissileParams.Player == nil then
						d.MissileParams.Player = Game():GetPlayer(0)
					end
					local player = d.MissileParams.Player
					local rand_cnt1 = math.random(4) + 4
					local rand_cnt2 = math.random(36000)/100
					for i = 0, rand_cnt1 do
						local q1 = player:FireTechXLaser(ent.Position,MakeVector(360/rand_cnt1 * i + rand_cnt2) * 7 * player.ShotSpeed , player.Damage/3 + 30)
					end
				end
                d.Rocket:Remove()
                d.Rocket = nil
                d.RocketsFired = d.RocketsFired + 1

                if d.MissileParams.MultipleRockets and d.MissileParams.NumRockets and d.RocketsFired < d.MissileParams.NumRockets then
                    d.MissileParams.Cooldown = d.MissileParams.Cooldown + (d.MissileParams.TimeBetweenRockets or 1)
                else
                    ent:Remove()
                end
            end
        end
    end
end

function CharacterMeus:OnMarkUpdate(ent)		--准星
	local sprite = ent:GetSprite()
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = ent:GetData()
	local player = d.Player
	if player ~= nil then
		Debuglist[14] = Debuglist[14] + 1
		local d2 = player:GetData()
		if player:GetName() == "SP.W.Qing" then	
			if d2.focus_time == nil or Game():GetFrameCount() - d2.focus_time > 5 then		--每一个在5帧内成为控制目标的准星均可以成为辅助准星。
				d2.focus_target = ent
				d2.focus_time = Game():GetFrameCount()
				if d2.focus_type == nil then
					d2.focus_type = 0
				end
			end
			if ent.Variant == QingsMarks then
				ent.Velocity = ggdir(player,true) * player.ShotSpeed * 15
				--if ent.FrameCount > 60 and (ent.Position - player.Position):Length() < 20 then		--在准星移近，或是按下左ctrl的时候移除之。
					--d2.focus_target = nil
					--d2.focus_time = nil
					--ent:Remove()
					--return
				--end
				if Input.IsButtonTriggered(341,0) or Input.IsButtonPressed(341,0) then
					d2.focus_target = nil
					d2.focus_time = nil
					ent:Remove()
					return
				end
				if Input.IsButtonTriggered(342,0) or Input.IsButtonPressed(342,0) then				--按下alt时，切换攻击模式。
					if d2.focus_flag == nil or d2.focus_flag == true then 
						d2.focus_type = d2.focus_type + 1
						if d2.focus_type > 2 then			--3种模式。0：自主寻敌；1：目标优先；2：强制攻击。
							d2.focus_type = 0
						end
						d2.focus_flag = false
					end
				else
					d2.focus_flag = true			--要不要加一个长按可连续切换呢？
				end
				Debuglist[9] = d2.focus_type
				if d2.focus_type == 0 then
					ent:SetColor(Color(1,1,1,1,0,0,0),999,50,false,false)		--红色
				elseif d2.focus_type == 1 then
					ent:SetColor(Color(1,1,-1,1,1,1,1),999,50,false,false)		--白色
				else
					ent:SetColor(Color(-1,-1,1,1,-1,-1,-1),999,50,false,false)	--黑色
				end
			end
		end
	end
end

function CharacterMeus:OnQingUpdate(player)		--里万青总算法
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = player:GetData()
	if player:GetName() == "SP.W.Qing" then
		local is_mov_or_dir = auxi.ggmov_dir_is_zero(player,true)
		if d.Re_calculate_Air and d.Re_calculate_Air == true then
			local n_entity = Isaac.GetRoomEntities()
			local d = player:GetData()
			d.Air_buff = 0
			d.add_after_pickup = false
			d.Air_cnt = getQingshots(player,false)
			d.Air = {}
			local n_Airs = getothers(n_entity,3,QingsAirs,nil)
			for i = 1,#n_Airs do
				n_Airs[i]:Remove()
			end
			d.Re_calculate_Air = false
		end
		
		if d.mov_or_dir_buff == nil then
			d.mov_or_dir_buff = 0
		end
		if d.add_after_pickup and d.add_after_pickup == true and player:AreControlsEnabled() == true and player:IsExtraAnimationFinished() == true and player.Visible == true then
			d.Air_buff = d.Air_buff + 1
			d.add_after_pickup = false
			if d.pick_up_Air then 
				d.pick_up_Air:Remove()
				d.pick_up_Air = nil
			end
		end
		if is_mov_or_dir then
			d.mov_or_dir_buff = d.mov_or_dir_buff + 1
			if d.mov_or_dir_buff == 300 - 70 * 2 then
				d.Spwq_s_charge_bar = Isaac.Spawn(1000,enums.Entities.Qing_Bar,0,player.Position,player.Velocity,player):ToEffect()
				d.Spwq_s_charge_bar.PositionOffset = Vector(player.SpriteScale.X * (-20),-(player.SpriteScale.Y*33)-32)
			end
		else
			d.mov_or_dir_buff = 0
			if d.Spwq_s_charge_bar and d.Spwq_s_charge_bar:Exists() and d.Spwq_s_charge_bar:GetSprite():IsPlaying("Charge") then
				d.Spwq_s_charge_bar:GetSprite():Play("Disappear")
			end
		end
		if d.Air_buff == nil then d.Air_buff = 0 end
		if d.mov_or_dir_buff > 300 then
			d.mov_or_dir_buff = 0
			local q = Isaac.Spawn(3,2335,0,player.Position,Vector(0,0),player):ToFamiliar()
			q:GetData().MakeState = 4
			q.Position = Vector(2000,2000)
			player:AnimatePickup(q:GetSprite())
			sound_tracker.PlayStackedSound(SoundEffect.SOUND_POWERUP1,1,1,false,0,2)
			d.pick_up_Air = q
			d.add_after_pickup = true
		end
		local gdir = ggdir(player,true)
		if (d.focus_target == nil or check(d.focus_target) == false or d.focus_nowroom ~= level:GetCurrentRoomIndex()) and gdir:Length() > 0.05 then
			local q1 = Isaac.Spawn(1000,QingsMarks,0,player.Position,gdir,player)
			q1:GetData().Player = player
			q1.GridCollisionClass = 3
			d.focus_target = q1
			d.focus_time = Game():GetFrameCount()
			d.focus_nowroom = level:GetCurrentRoomIndex()
		end
		if d.focus_target ~= nil and check(d.focus_target) and d.nowroom == level:GetCurrentRoomIndex() and d.focus_target.Position ~= nil then
			d.focus_time = Game():GetFrameCount()
		end
		if d.Air_cnt == nil then
			d.Air_cnt = 1		--攻击次数、频率计数。
		end
		d.Air_cnt = getQingshots(player,false) + d.Air_buff
		if d.Air == nil then	
			d.Air = {}
		end
		for i = 1,d.Air_cnt do
			if d.Air[i] == nil then
				d.Air[i] = Isaac.Spawn(3,2335,0,player.Position,Vector(0,0),player):ToFamiliar()
			end
		end
		local cont = #d.Air
		for i = 1,cont do 
			if cont - i + 1 > d.Air_cnt then
				d.Air[cont - i + 1]:Remove()
				d.Air[cont - i + 1] = nil
			end
		end
		if d.focus_type == nil then
			d.focus_type = 1
		end
	end
end

function CharacterMeus:OnBarUpdate(ent)			--能量条
	if ent.Variant == enums.Entities.Qing_Bar then
		local s = ent:GetSprite()
		if s:IsFinished("Charge") or s:IsFinished("Disappear") then
			ent:Remove()
		end
	end
end

function CharacterMeus:OnAirUpdate(ent)			--浮游炮
	local sprite = ent:GetSprite()
	local room = Game():GetRoom()
	local player = ent.Player
	local level = Game():GetLevel()
	local d = ent:GetData()
	if player ~= nil then
		if true or player:GetName() == "SP.W.Qing" then		--第一步：寻找目标；第二步：移动；第三步：攻击。
			local d2 = player:GetData()
			--Debuglist[15] = Debuglist[15] + 1
			if ent.State == nil then
				ent.State = 0
			end
			
			if ent:GetData().MakeState then
				ent.State = ent:GetData().MakeState
			end
			
			local maintarg = player.Position		
			if ent.State == 0 then				--	0意味着寻找目标
				if d2.focus_target ~= nil then -- and check(d2.focus_target) then
					if d2.focus_target.Position ~= nil then
						maintarg = d2.focus_target.Position
					end
				end
				if d.targpos == nil then --or check(d.targpos) == false then
					d.targpos = player.Position
				end
				if d2.focus_type == 0 then				--0：自主寻敌；1：目标优先；2：强制攻击。
					d.targpos = maintarg 
				elseif d2.focus_type == 1 then
					d.targpos = maintarg 
				elseif d2.focus_type == 2 then
					d.targpos = maintarg 
				else
					d.targpos = d.targpos * 0.9 + maintarg * 0.1
				end
				local range = 10	--射程根据攻击模式确定。
				if d2.focus_type == 0 then				--0：自主寻敌；1：目标优先；2：强制攻击。
					range = 200
				elseif d2.focus_type == 1 then
					range = 30	
				elseif d2.focus_type == 2 then
					range = 10
				else
					range = 10
				end
				local focu = nil
				if d2.focus_type == 1 or d2.focus_type == 2 then
					focu = getdisenemies(getenemies(Isaac.FindInRadius(d.targpos,range * player.ShotSpeed,1<<3)),d.targpos,1000)
				elseif d2.focus_type == 0 then
					focu = getrandenemies(getenemies(Isaac.FindInRadius(d.targpos,range * player.ShotSpeed,1<<3)))
				end
				if focu ~= nil then --and check(focu) then
					if d2.focus_type ~= 3 then			--3：不攻击。
						ent.State = 1
						d.randpos = MakeVector(math.random(18000)/100)*100
						d.focu = focu		--确定目标。但不能确定是否还存活。
					end
					--Debuglist[14] = Debuglist[14] + 1
				else			--没有检查到敌人的情况下，环绕角色。
					if d2.focus_type == 2 then
						ent.State = 2
					end
					if d.ang == nil then
						d.ang = math.random(36000)/100
					end
					d.ang = d.ang + math.random(1000)/1000
					d.randpos = MakeVector(d.ang) * 150
					ent:FollowPosition(player.Position + d.randpos)
				end
			end
			
			if ent.State == 1 then				--	1意味着进行移动
				if d2.focus_type == 0 or d2.focus_type == 1 then
					if d.focu == nil then
						ent.State = 0
					else
						local tarpos = d.focu.Position + d.randpos
						ent:FollowPosition(tarpos)
						ent.Velocity = ent.Velocity * math.min(player.ShotSpeed,2)
						if (ent.Position - tarpos):Length() < 90 + 10 then		--试试这个判定条件
							d.Vel = math.random(1000)/500 + 4
							ent.State = 2
						end
					end
				elseif d2.focus_type == 2 then
					if d2.focus_target == nil then
						ent.State = 0
					else
						local tarpos = d2.focus_target.Position + d.randpos
						ent:FollowPosition(tarpos)
						ent.Velocity = ent.Velocity * math.min(player.ShotSpeed,2)
						if (ent.Position - tarpos):Length() < 90 + 10 then
							d.Vel = math.random(1000)/500 + 4
							ent.State = 2
						end
					end
				end
			end

			if ent.State == 2 then				--	2意味着发动攻击
				if d2.focus_type == 0 or d2.focus_type == 1 then
					if d.orbang == nil then
						d.orbang = 0
					end
					if d.focu ~= nil then -- and check(d.focu) then
						d.orbang = (ent.Position - d.focu.Position):GetAngleDegrees() + 90
						if d.Vel == nil then
							 d.Vel = math.random(1000)/500 + 4
						end
						local folopos = ent.Position
						folopos = folopos + MakeVector(d.orbang) * player.ShotSpeed * d.Vel * (10)
						--ent.Velocity = d.focu.Velocity + MakeVector(d.orbang) * player.ShotSpeed * d.Vel
						local leg = (ent.Position - d.focu.Position):Length()
						if leg < 80 and leg > 10 then
							folopos = folopos +	(ent.Position - d.focu.Position)/leg * 10 * (100 - leg)/10
							--ent.Velocity = ent.Velocity + (ent.Position - d.focu.Position)/leg * 10 * (100 - leg)/50
						elseif leg > 120 then	 
							folopos = folopos - (ent.Position - d.focu.Position)/leg * 10 * (math.min(200,leg) - 100)/10
							--ent.Velocity = ent.Velocity - (ent.Position - d.focu.Position)/leg * 10 * (math.min(200,leg) - 100)/50
						end
						--Debuglist[7] = folopos.X 
						--Debuglist[8] = folopos.Y 
						--Debuglist[9] = d.Position.X
						--Debuglist[10] = d.Position.Y 
						ent:FollowPosition(folopos)
						d.targ_Position = d.focu.Position
					else
						ent.State = 0
					end
				elseif d2.focus_type == 2 then
					if d2.focus_target == nil then --or check(d2.focus_target) == false then
						ent.State = 0
					else
						if d.orbang == nil then
							d.orbang = 0
						end
						if d2.focus_target ~= nil then --and check(d2.focus_target) then
							d.orbang = (ent.Position - d2.focus_target.Position):GetAngleDegrees() + 90
							if d.Vel == nil then
								 d.Vel = math.random(1000)/500 + 4
							end
							ent.Velocity = d2.focus_target.Velocity + MakeVector(d.orbang) * player.ShotSpeed * d.Vel
							local leg = (ent.Position - d2.focus_target.Position):Length()
							if leg < 80 and leg > 15 then
								ent.Velocity = ent.Velocity + (ent.Position - d2.focus_target.Position)/leg * 10 * (100 - leg)/50
							elseif leg > 120 then	 
								ent.Velocity = ent.Velocity - (ent.Position - d2.focus_target.Position)/leg * 10 * (math.min(200,leg) - 100)/50
							end
							d.targ_Position = d2.focus_target.Position
						else
							ent.State = 0
						end
					end
				end
				if d.firedelay ~= nil and d.firedelay < 0 then
					d.firedelay = player.MaxFireDelay
					if d.targ_Position == nil then -- or check(d2.focus_target) == false then
						d.targ_Position = -(2*ent.Position - player.Position)
					end
					local leg = (ent.Position - d.targ_Position):Length()
					local weap = 1								--	不太清楚是否会成功。也许需要修改。
					for i = 1,16 do 
						if player:HasWeaponType(i) == true then
							weap = i
						end
					end
					if player:HasCollectible(418) then
						weap = math.random(13)
					end
					--Debuglist[8] = weap
					local pepper_cnt = 1
					if weap == 1 or weap == 8 or weap == 14 then		--眼泪和悬浮
						if player:HasCollectible(69) then		--巧克力奶：翻倍攻击、子弹大小，或是减半攻击，快速发射。
							if player:HasCollectible(316) then		--诅咒之眼：增加小子弹（延续AB+的版本）
								local q1 = player:FireTear(ent.Position, -(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed,true,true,true)
								if weap == 14 then
									q1.TearFlags = q1.TearFlags | BitSet128(0,1<<(114-64))
								end
								q1.Parent = ent
								q1.Scale = q1.Scale * 2
								q1.CollisionDamage = q1.CollisionDamage * 3
								for i = 1,4 do 
									addeffe(function(params)
										local q1 = player:FireTear(ent.Position, -(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed,true,true,true)
										if weap == 14 then
											q1.TearFlags = q1.TearFlags | BitSet128(0,1<<(114-64))
										end
										q1.Parent = ent
										q1.Scale = q1.Scale * 0.4
										q1.CollisionDamage = q1.CollisionDamage * 0.2
									end,{},i*2)
								end
								d.firedelay = player.MaxFireDelay * 2.7
								pepper_cnt = pepper_cnt + 4		--多4发
							else
								local q1 = player:FireTear(ent.Position, -(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed,true,true,true)
								if weap == 14 then
									q1.TearFlags = q1.TearFlags | BitSet128(0,1<<(114-64))
								end
								q1.Parent = ent
								q1.Scale = q1.Scale * 2
								q1.CollisionDamage = q1.CollisionDamage * 3
								d.firedelay = player.MaxFireDelay * 2.5
							end
						elseif player:HasCollectible(316) then		--诅咒之眼：五次攻击，延迟3.5倍
							for i = 1,5 do 
								addeffe(function(params)
									local q1 = player:FireTear(ent.Position, -(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed,true,true,true)
									if weap == 14 then
										q1.TearFlags = q1.TearFlags | BitSet128(0,1<<(114-64))
									end
									q1.Parent = ent
								end,{},(i-1)*2)
							end
							d.firedelay = player.MaxFireDelay * 3.5
							pepper_cnt = pepper_cnt + 4		--多4发
						else
							local q1 = player:FireTear(ent.Position, -(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed,true,true,true)
							if weap == 14 then
								q1.TearFlags = q1.TearFlags | BitSet128(0,1<<(114-64))
							end
							q1.Parent = ent
						end
						
					elseif weap == 2 then		--硫磺火
						local q1 = player:FireBrimstone( -(ent.Position - d.targ_Position))
						q1.Parent = ent
						q1.Position = ent.Position
						local multitar = 0
						if player:HasCollectible(229) or player:HasCollectible(558) then
							for i = 1,player:GetCollectibleNum(229) do
								multitar = multitar + math.random(5) + 1
							end
							for i = 1,player:GetCollectibleNum(558) do
								multitar = multitar + math.random(1) 
							end
						end
						for i = 1,multitar do
							local q1 = player:FireBrimstone(MakeVector(math.random(36000)/100))
							q1.Parent = ent
							q1.Position = ent.Position
						end
						pepper_cnt = pepper_cnt + 4		--多4发
					elseif weap == 3 then		--科技：其实应该再做一下诅咒之眼的适配。但是之后吧。
						if player:HasCollectible(229) then
							local cnt = player:GetCollectibleNum(229)
							local params = {player = player,Direction = -(ent.Position - d.targ_Position):Normalized(),Position = ent.Position,delang = 30,Length = 40,length = 30,multi_cnt = 3,multi_shot = 3,cool_down = 3}
							params.loop_func = function(trans)fire_lung_Laser(trans) end
							addeffe(fire_lung_Laser,params,3)
							Debuglist[6] = Debuglist[6] + 1
							d.firedelay = player.MaxFireDelay * 3
						else
							local q1 = player:FireTechLaser(ent.Position,1,-(ent.Position - d.targ_Position),false,true)
							q1.Parent = ent
							local multitar = 0
							if player:HasCollectible(558) then
								for i = 1,player:GetCollectibleNum(558) do
									multitar = multitar + math.random(1) 
								end
							end
							for i = 1,multitar do
								local q1 = player:FireTechLaser(ent.Position,1,MakeVector(math.random(36000)/100),false,true)
								q1.Parent = ent
							end
						end
					elseif weap == 5 then		--博士
						local q1 = player:FireBomb(ent.Position,-(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed)
						q1.Parent = ent
						local multitar = 0
						if player:HasCollectible(558) then
							for i = 1,player:GetCollectibleNum(558) do
								multitar = multitar + math.random(2)
							end
						end
						for i = 1,multitar do
							local q1 = player:FireBomb(ent.Position,(MakeVector(math.random(36000)/100)) * 7 * player.ShotSpeed)
							q1.Parent = ent
						end
					elseif weap == 6 then		--史诗
						local params = {			--感谢堕胎。抄了一份过来。
							Cooldown = player.MaxFireDelay * 3 + 5,
							Spawner = ent,
							Player = player,
							tearflags = player.TearFlags | player:GetBombFlags()
						}
						if player:HasCollectible(114) then
							params.knife = player:GetCollectibleNum(114)
						end
						if player:HasCollectible(118) then
							params.brimstone = player:GetCollectibleNum(118)
						end
						if player:HasCollectible(68) and player:HasCollectible(118) == false then		--硫磺火+科技不需要额外配合
							params.Tech = player:GetCollectibleNum(68)
						end
						if player:HasCollectible(395) then
							params.TechX = player:GetCollectibleNum(395)
						end
						launch_Missile(ent.Position, -(ent.Position - d.targ_Position)/(params.Cooldown+0.1),player.Damage, nil, params)
						local multitar = 0
						if player:HasCollectible(229) or player:HasCollectible(558) then
							for i = 1,player:GetCollectibleNum(229) do
								multitar = multitar + math.random(5) + 1
							end
							for i = 1,player:GetCollectibleNum(558) do
								multitar = multitar + math.random(1) 
							end
						end
						for i = 1,multitar do
							launch_Missile(ent.Position, -(ent.Position - d.targ_Position)/(params.Cooldown+0.1) + MakeVector(math.random(36000)/100)* (math.random(10)/3 + 0.5),player.Damage, nil, params)
						end
						d.firedelay = player.MaxFireDelay * 5
					elseif weap == 9 then		--科技X
						local q1 = player:FireTechXLaser(ent.Position,-(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed,30)
						q1.Parent = ent
					elseif weap == 7 then		--肺
						if player:HasCollectible(52) then		--博士被肺覆盖
							local maxcnt = math.random(5) + 3
							for i = 1, maxcnt do 
								local ang = (ent.Position - d.targ_Position):GetAngleDegrees() + 180 + math.random(20) - 10
								local q1 = player:FireBomb(ent.Position,MakeVector(ang) * 7 * player.ShotSpeed * (math.random(100)+950)/1000)
							end
						else
							local maxcnt = math.random(10) + 15
							for i = 1, maxcnt do 
								local q1 = player:FireTear(ent.Position, MakeVector(180 + (ent.Position - d.targ_Position):GetAngleDegrees() + math.random(900)/15 - 30) * 7 * player.ShotSpeed * (math.random(1000)/400+0.3),true,true,true)
								--Debuglist[4] = q1.FallingAcceleration
								--Debuglist[5] = q1.FallingSpeed
								q1.FallingSpeed = -15
								q1.FallingAcceleration = 1.5
								q1.Scale = q1.Scale * (math.random(500)/1000 + 0.8)
							end
						end
						pepper_cnt = pepper_cnt + 1
					elseif weap == 4 then		--妈刀
						local params = {
							cooldown = 60,
							Accerate = 0.5,
							player = player,
							tearflags = player.TearFlags,
							Color = player.TearColor,
							Explosive = player:GetCollectibleNum(149) + player:GetCollectibleNum(52)
						}
						local q2 = fire_knife(ent.Position,-(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed,player.Damage,nil,copy(params))
						if q2:IsFlying() == false then
							q2:Shoot(0.3,100)
						end
						d.firedelay = player.MaxFireDelay * 2
						if player:HasCollectible(118) then
							params.tearflags = nil
							d.firedelay = player.MaxFireDelay * 4
							local cnt = math.random(3) + 1 + 2 * (player:GetCollectibleNum(118) - 1)
							for i = 1,cnt do
								local cnt2 = math.random(2) + (player:GetCollectibleNum(118) - 1)
								for j = 1,cnt2 do
									addeffe(function(params)
										if params.ent == nil or params.player == nil or params.dir == nil then
											return
										end
										local ent = params.ent
										local dir = params.dir
										local player = params.player
										--Debuglist[6] = Debuglist[6] + 1
										local ang = dir:Normalized()
										fire_knife(ent.Position + Get_rotate(ang) * (math.random(2)*2-3) * math.random(cnt2 * 10),dir,player.Damage,nil,copy(params))
									end,copy({ent = ent,player = player,dir = -(ent.Position - d.targ_Position)/leg * 12 * player.ShotSpeed}),i * 3)
								end
							end
						end
					elseif weap == 13 or weap == 10 then		--英灵剑
						local params = {
							cooldown = 10,
							Accerate = 0.5,
							player = player,
							tearflags = player.TearFlags,
							Color = player.TearColor
						}
						local q2 = fire_Sword(ent.Position,-(ent.Position - d.targ_Position)/leg * 7 * player.ShotSpeed,player.Damage/5,nil,copy(params))
					end
					
					if player:HasCollectible(616) then		--检查辣椒火焰
						if math.random(1000)/1000 * (math.exp(11/5) + 2) < math.exp(math.max(-3/5,math.min(11/5,player.Luck/5))) + 2.01 then
							for i = 1,pepper_cnt do
								addeffe(function(params)
									local q1 = Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.RED_CANDLE_FLAME,0,ent.Position,-(ent.Position - d.targ_Position):Normalized() * 9 * player.ShotSpeed,player):ToEffect()
									q1.CollisionDamage = player.Damage * 4
									q1:SetTimeout(600)
								end,{}, (i-1) * 3)
							end
						end
					end
					if player:HasCollectible(495) then
						if math.random(1000)/1000 * (math.exp(11/5) + 2) < math.exp(math.max(-3/5,math.min(11/5,player.Luck/5))) + 2.01 then
							for i = 1,pepper_cnt do
								addeffe(function(params)
									local q1 = Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.BLUE_FLAME,0,ent.Position,-(ent.Position - d.targ_Position):Normalized() * 9 * player.ShotSpeed,player):ToEffect()
									q1.CollisionDamage = player.Damage * (math.random(3000)/1000 + 3)
									q1:SetTimeout(120)
								end,{}, (i-1) * 3)
							end
						end
					end
					
					if math.random(1000) > 600 then				-- 小概率重新选择目标。
						ent.State = 0
					end
				end
				
				--附加攻击
				if player:HasCollectible(152) then		--科技2
					if d.tech_2 == nil then
						if player:HasCollectible(494) then
							d.tech_2 = Isaac.Spawn(7,10,0,ent.Position,Vector(0,0),player):ToLaser()
						else
							d.tech_2 = Isaac.Spawn(7,2,0,ent.Position,Vector(0,0),player):ToLaser()
						end
						d.tech_2.Parent = ent
						d.tech_2.TearFlags = player.TearFlags
						d.tech_2.PositionOffset = Vector(ent.PositionOffset.X,ent.PositionOffset.Y - 10)
						d.tech_2.Angle = (ent.Position - d.targ_Position):GetAngleDegrees() + 180
						d.tech_2.CollisionDamage = player.Damage * 0.2
					else
						d.tech_2:SetColor(player.LaserColor,3,60,false,false)
						d.tech_2.Angle = (ent.Position - d.targ_Position):GetAngleDegrees() + 180
					end
				end
				
				if player:HasCollectible(244) then		--科技.5：随机间隔发射激光攻击。
					if math.random(1000) > 900 and d.firedelay/2 > math.random(math.floor(player.MaxFireDelay) + 1) then
						local q1 = player:FireTechLaser(ent.Position,1,-(ent.Position - d.targ_Position),false,true)
						local random_cnt = math.random(1000)
						local buff_list = {BitSet128(1<<2,0),BitSet128(1<<16,0),BitSet128(1<<30,0),BitSet128(1<<19,0),BitSet128(1<<33,0),BitSet128(0,1<<5)}
						for i = 1,6 do 
							if math.random(1000) > 800 then
								q1:AddTearFlags(buff_list[i])
							end
						end
					end
				end
				
			end
			
			if ent.State ~= 2 and d.tech_2 then		
				d.tech_2:Remove()
				d.tech_2 = nil
			end
			if d.firedelay == nil then
				d.firedelay = 0
			end
						
			d.firedelay = d.firedelay - 1
			
			if d.focu == nil or d.focu:IsActiveEnemy(false) == false then
				d.focu = nil
				ent.State = 0
				--Debuglist[12] = Debuglist[12] + 10
			end
			if true then			--sprite的控制
				local ang = nil
				if d.focu ~= nil then
					if d.focu.Position ~= nil then
						ang = (ent.Position - d.focu.Position):GetAngleDegrees() + 90
					end
				end
				if ang == nil then
					if player ~= nil then
						ang = (ent.Position - player.Position):GetAngleDegrees() + 90
					end
				end
				if d2.focus_type == 2 and d2.focus_target ~= nil then
					ang = (ent.Position - d2.focus_target.Position):GetAngleDegrees() + 90
				end
				if ang == nil then
					ang = 0
				end
				
				if true then			
					if ang < 0 then			
						ang = ang + 360
					end
					if ang < 0 then
						ang = ang + 360
					end
					if ang > 360 then
						ang = ang - 360
					end
					if ang > 360 then
						ang = ang - 360
					end
					Debuglist[13] = ang
					if ang > 180 then
						ang = 360 - ang
						sprite.FlipX = true
					else
						sprite.FlipX = false
					end
					if ang < 30 then
						sprite:Play("FloatUp", true)
					elseif ang < 60 then
						sprite:Play("FloatDT", true)
					elseif ang < 120 then
						sprite:Play("FloatTo", true)
					elseif ang < 150 then
						sprite:Play("FloatUT", true)
					else
						sprite:Play("FloatDown", true)
					end
				end
				ent.PositionOffset = Vector(ent.PositionOffset.X,math.max(-30,math.min(-20,ent.PositionOffset.Y + math.random(1000)/10000)))
			end
		
			if d.nowroom ~= level:GetCurrentRoomIndex() then		--进入新房间后重置的部分
				d.nowroom = level:GetCurrentRoomIndex()
				d.ang = nil
			end
		else
			ent:Remove()
		end
	end
end

function CharacterMeus:OnQingRoom()				--已更新：适用于多人。
	---[[
	for playerNum = 1, Game():GetNumPlayers() do
		local player = Game():GetPlayer(playerNum - 1)
		
		if player:GetName() == "SP.W.Qing" then
			local d = player:GetData()
			if d.Air_cnt == nil then
				d.Air_cnt = 1
			end
			d.Air_buff = 0
			d.add_after_pickup = false
			d.Air_cnt = getQingshots(player,false)
			if d.Air == nil then
				d.Air = {}
			end
			local n_entity = Isaac.GetRoomEntities()
			local n_Airs = getothers(n_entity,3,QingsAirs,nil)
			if #n_Airs ~= d.Air_cnt then
				--Debuglist[10] = Debuglist[10] + 1
				for i = 1,#n_Airs do
					if n_Airs[i] then
						n_Airs[i]:Remove()
					end
				end
				for i = 1,d.Air_cnt do
					if d.Air[i] then
						d.Air[i]:Remove()
						d.Air[i] = nil
					end
				end
			end
		end
	end
	--]]
end

function CharacterMeus:OnQingInit(player)		--防止小退的情况。
	if player:GetName() == "SP.W.Qing" then
		player:GetData().Re_calculate_Air = true
	end
end

-----------表万青的内容---------
function CharacterMeus:OnWQingLaserUpdate(ent)
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = ent:GetData()
	if d.followParent then
		ent.Position = d.followParent.Position
	end
	if d.followRotation and d.followRotation:Exists() then
		local ang = 180
		if d.followRotation_aidang then
			ang = d.followRotation_aidang + ang
		end
		ent.Angle = ang + d.followRotation.Velocity:GetAngleDegrees()
	end
	if d.reset_startp and d.reset_startp == true then
		if d.reset_startp_source and d.reset_startp_source:Exists() == true then
			d.reset_startp_position = d.reset_startp_source.Position
		end
		if d.reset_startp_position == nil then
			d.reset_startp_position = room:GetCenterPos()
		end
		ent.EndPoint = d.reset_startp_position
		ent:SetMaxDistance((ent.Position - d.reset_startp_position):Length())
	end
end

function CharacterMeus:OnEntityDamage(ent, amt, flag, source, cooldown)
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = ent:GetData()
	local s = ent:GetSprite()
	if d.Damo_effect == true and amt > ent.HitPoints then
		Debuglist[5] = Debuglist[5] + 1
		ent:TakeDamage(ent.HitPoints - 1,0,EntityRef(player),0)
		return false
	end
end

function CharacterMeus:OnQingDamage(ent, amt, flag, source, cooldown)
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = ent:GetData()
	local s = ent:GetSprite()
	if d.invincible and d.invincible > 0 and Get_Flags(flag,28) == false and Get_Flags(flag,18) == false and Get_Flags(flag,5) == false then --不伤害恶魔房的，以及卖血的（先掉红心的）
		return false
	end
	if ent.Type == 1 and ent:ToPlayer():GetName() == "W.Qing" then
		local player = ent:ToPlayer()
		if player:HasCollectible(316) and player:HasCollectible(260) == false and d.cursed_delay and d.cursed_delay > 0 then	--受伤传送
			player:AnimateTeleport(true)
			player:UseActiveItem(CollectibleType.COLLECTIBLE_TELEPORT,false,true,false,false)
			d.cursed_delay = 0
		end
	end
end

function CharacterMeus:OnWQingKnifeCollision(ent,col,low)
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = ent:GetData()
	local s = ent:GetSprite()
	if ent.Variant == StabberKnife then
		if d.params then
			if d.params.repel then
				if col.Type == 4 then
					if (col.Velocity + d.params.repel):Length() < 20 then
						col:AddVelocity(d.params.repel)
					else
						col.Velocity = (col.Velocity + d.params.repel):Normalized() * 20
					end
				else
					col:AddVelocity(d.params.repel)
				end
				if d.player then
					if d.player.Velocity:Length() > 15 then
						d.player.Velocity = (d.player.Velocity + -d.params.repel / 10):Normalized() * 15
					else
						d.player:AddVelocity(-d.params.repel / 10)
					end
				end
			end
			if d.params.brimstone and (d.params.brimstone == true or d.params.brimstone > 0) and isenemies(col) == true then
				if ent.Parent then
					ent.Parent.Velocity = ent.Parent.Velocity:Normalized() * 5
				end
			end
			if d.params.knife and (d.params.knife == true or d.params.knife > 0) and isenemies(col) == true then
				if ent.Parent then
					if d.params.brimstone and d.params.brimstone == true then
						ent.Parent.Velocity = ent.Parent.Velocity:Normalized() * 8
					else
					ent.Parent.Velocity = ent.Parent.Velocity:Normalized() * 3
					end
				end
			end
			if d.params.epic and (d.params.epic == true or d.params.epic > 0) and isenemies(col) == true then
				if ent.Parent then
					if d.touch ~= nil then
						ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
						ent.CollisionDamage = 0
					else
						local player = Game():GetPlayer(0)
						if d.player then
							player = d.player
						end
						ent.Parent.Velocity = ent.Parent.Velocity:Normalized() * 3
						ent.Parent:GetData().Params.Accerate = -1
						ent.Parent:GetData().Params.Homing = false
						local tearflags = d.params.tearflags
						if tearflags == nil then
							tearflags = player.TearFlag
						end
						tearflags = tearflags | player:GetBombFlags()
						local q1 = launch_Missile(ent.Position,ent.Velocity,ent.CollisionDamage/2,nil,{color = d.params.color,Cooldown = 25,Spawner = ent,Player = player,tearflags = tearflags,knife = player:GetCollectibleNum(114),brimstone = player:GetCollectibleNum(118), Tech = player:GetCollectibleNum(68),TechX = player:GetCollectibleNum(395),MultipleRockets = d.params.multishot, NumRockets = d.params.multishot})
						q1.Visible = false
						q1:GetSprite().Scale = ent:GetSprite().Scale
						q1:GetData().follower = ent
						d.touch = true
						ent.Parent:GetData().Params.removeanimate = true
						ent.Parent:GetData().follower = col
						ent.Parent:GetData().Params.FollowInput = nil
						if s:IsPlaying("IdleUp") or s:IsFinished("IdleUp") then
							s:Play("ChargedUp",true)
						elseif s:IsPlaying("IdleUp2") or s:IsFinished("IdleUp2") then
							s:Play("ChargedUp2",true)
						end
					end
				end
			end
			if d.params.thor and d.params.thor == true and isenemies(col) == true then
				--Debuglist[12] = Debuglist[12] + 1
				if d.player then
					local player = d.player
					local d2 = player:GetData()
					d2.thor_target = ent.Parent
				end
				if ent.Parent then
					if d.touch ~= nil then
						ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
						ent.CollisionDamage = 0
					else
						ent.Parent.Velocity = ent.Parent.Velocity:Normalized() * 3
						ent.Parent:GetData().Params.Accerate = -1
						d.touch = true
						ent.Parent:GetData().Params.removeanimate = true
						ent.Parent:GetData().follower = col
						ent.Parent:GetData().Params.FollowInput = nil
						if s:IsPlaying("IdleUp") or s:IsFinished("IdleUp") then
							s:Play("ChargedUp",true)
						elseif s:IsPlaying("IdleUp2") or s:IsFinished("IdleUp2") then
							s:Play("ChargedUp2",true)
						end
					end
				end
			end
			if d.params.list and d.params.list.damo and d.params.list.damo > 0 and isenemies(col) == true then
				if ent.Parent and col:GetData().Damo_effect == nil then
					Debuglist[4] = Debuglist[4] + 1
					local damo = d.params.list.damo
					local q1 = fire_nil(col.Position,col.Velocity,{cooldown = 60000})
					local d2 = q1:GetData()
					d2.follower = col
					d2.Is_Qing_Damo = true
					col:GetData().Damo_effect = true
				end
			end
		end
		if d.tearflags and isenemies(col) and d.tearflags & BitSet128(1<<52,0) == BitSet128(1<<52,0) and d.belial and d.belial > 0 then		--彼列之眼：第一次攻击后，追加一发飞刀。
			Debuglist[12] = Debuglist[12] + 1
			d.belial = d.belial - 1
			local player = Game():GetPlayer(0)
			if d.player then
				player = d.player
			end
			if d.params == nil then
				d.params = {}
			end
			if d.params.color == nil then
				d.params.color = Color(1,1,1,1)
			end
			fire_dowhatknife(nil,ent.Position,ent.Velocity:Normalized() * 5,ent.CollisionDamage/2,"IdleUp","IdleUp2",{player = player,cooldown = 60,BitSet128(0,0),Accerate = 1,color = AddColor(d.params.color,Color(1,0,0,1,1,0,0),0.5,1),tech = d.params.tech,list = d.params.list,allow_belial = false})
		end
		if d.tearflags and isenemies(col) and d.tearflags & BitSet128(1<<33,0) == BitSet128(1<<33,0) then		--神秘液体
			if check_rand(5,100,30,10) == true then
				Isaac.Spawn(1000,53,0,ent.Position,Vector(0,0),player)
			end
		end
		if d.tearflags and isenemies(col) and (d.tearflags & BitSet128(1<<49,0) == BitSet128(1<<49,0)) then 	--中猫套
			--Debuglist[12] = Debuglist[12] + 1
			local rand = math.random(1000)/1000
			local player = Game():GetPlayer(0)
			if d.player then
				player = d.player
			end
			if rand *(math.exp(3) + 2.35) < math.exp(math.min(3,player.Luck/10)) + 2.35 then		--随着幸运上升，在30达到100%。基础值为 15%
				if math.random(1000) > 500 then
					player:ThrowBlueSpider(ent.Position,player.Position)
				else
					player:AddBlueFlies(math.random(2),ent.Position,player)
				end
				Isaac.Spawn(1000,44,0,ent.Position,Vector(0,0),player)
			elseif math.random(1000) > 950 then
				Isaac.Spawn(1000,44,0,ent.Position,Vector(0,0),player)
			end
		end
		if d.deadeye and d.deadeye > 0 then
			local player = Game():GetPlayer(0)
			if d.player then
				player = d.player
			end
			player:AddDeadEyeCharge()
			d.deadeye = 0
		end
		if d.fire_sound_effect and d.fire_sound_effect == true then
			--Debuglist[3] = Debuglist[3] + 1
			sound_tracker.PlayStackedSound(SoundEffect.SOUND_FIREDEATH_HISS,1.0,random_1() * 0.1 + 0.95,false,0,2)
		end
	end
end

function CharacterMeus:OnWQingKnifeUpdate(ent)
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = ent:GetData()
	local s = ent:GetSprite()
	if ent.Variant == StabberKnife then
		local n_entity = Isaac.GetRoomEntities()
		local n_enemy = getenemies(n_entity)
		local n_pickups = getpickups(n_entity,true)
		local n_bombs = getothers(n_entity,4,nil,nil)
		local n_projs = getothers(n_entity,9,nil,nil)
		if s:IsPlaying("SpinUp") and s:IsFinished("SpinUp") == false or (s:IsPlaying("SpinUp2") and s:IsFinished("SpinUp2") == false) then
			if s:GetFrame() == 1 then
				sound_tracker.PlayStackedSound(SoundEffect.SOUND_SWORD_SPIN,math.random(1000)/2000 + 1,math.random(1000)/5000 + 0.8,false,0,2)
			end
			local damage = ent.CollisionDamage
			local damageflag = 0
			if d.damage then
				damage = d.damage
			end
			if d.damageflag then
				damageflag = d.damageflag
			end
			local range = ent:GetSprite().Scale:Length()
			if d.nowroom == nil or d.nowroom == level:GetCurrentRoomIndex() then		--还是有问题。暂时不会解决了。
				for i = 1,#n_enemy do
					if (ent.Position - n_enemy[i].Position):Length() < 80 * range then
						if n_enemy[i]:GetData().Qing_blade_countdown == nil then
							n_enemy[i]:GetData().Qing_blade_countdown = -1
						end
						if n_enemy[i]:GetData().Qing_blade_countdown < 0 then
							if d.params and d.params.list and d.params.list.damo and d.params.list.damo > 0 and (ent.Position - n_enemy[i].Position):Length() < 80 * range then
								if ent.Parent and n_enemy[i]:GetData().Damo_effect == nil then
									Debuglist[4] = Debuglist[4] + 1
									local damo = d.params.list.damo
									local q1 = fire_nil(n_enemy[i].Position,n_enemy[i].Velocity,{cooldown = 60000})
									local d2 = q1:GetData()
									d2.follower = n_enemy[i]
									d2.Is_Qing_Damo = true
									n_enemy[i]:GetData().Damo_effect = true
								end
							end
							n_enemy[i]:TakeDamage(damage,damageflag,EntityRef(ent),6)
							n_enemy[i]:AddVelocity((ent.Position - n_enemy[i].Position):Normalized() * (-6))
							n_enemy[i]:GetData().Qing_blade_countdown = 2
							if ent:GetData().Explosive_cnt and ent:GetData().Explosive_cnt > 0 then		--引发爆炸
								local player = ent:GetData().player
								if player == nil then
									if ent:GetData().params then
										player = ent:GetData().params.player
									end
								end
								if player == nil then
									player = Game():GetPlayer(0)
								end
								local dmg = ent.CollisionDamage
								local tearflags = ent:GetData().bomb_knife_flag
								if tearflags == nil and ent:GetData().params and ent:GetData().params.bomb_knife_flag then
									tearflags = ent:GetData().params.bomb_knife_flag
								end
								if tearflags == nil then
									tearflags = BitSet128(0,0)
								end
								Game():BombExplosionEffects(n_enemy[i].Position,dmg * 15,tearflags,player.TearColor,player,1,false,false)		--耶耶耶！！！	
								ent:GetData().Explosive_cnt = ent:GetData().Explosive_cnt - 1
							end
							if d.fire_sound_effect and d.fire_sound_effect == true then
								sound_tracker.PlayStackedSound(SoundEffect.SOUND_FIREDEATH_HISS,1.0,random_1() * 0.3 + 0.8,false,0,2)
							end
							if d.deadeye and d.deadeye > 0 then			--死眼
								local player = Game():GetPlayer(0)
								if d.player then
									player = d.player
								end
								player:AddDeadEyeCharge()
								d.deadeye = 0
							end
						
							
						else
							n_enemy[i]:GetData().Qing_blade_countdown = n_enemy[i]:GetData().Qing_blade_countdown - 1
						end
					end
				end
				local player = Game():GetPlayer(0)
				if d.player then
					player = d.player
				end
				for i = 1,#n_pickups do
					if (ent.Position - n_pickups[i].Position):Length() < 80 * range and n_pickups[i]:ToPickup():IsShopItem() == false then
						n_pickups[i]:AddVelocity((ent.Position - n_pickups[i].Position):Normalized() * (-3))
						if (n_pickups[i].Variant > 49 and n_pickups[i].Variant < 70 and n_pickups[i].Variant ~= 51) or n_pickups[i].Variant == 360 or n_pickups[i].Variant == 390 then
							local s = n_pickups[i]:GetSprite()
							if n_pickups[i].Variant == 60 or n_pickups[i].Variant == 55 then
								if (s:IsPlaying("Idle") or s:IsFinished("Idle")) and (player:HasTrinket(19) or player:TryUseKey() == true) then
									n_pickups[i]:ToPickup():TryOpenChest()
								end
							elseif n_pickups[i].Variant == 57 then
								if (s:IsPlaying("Idle") or s:IsFinished("Idle") or s:IsFinished("UseKey") or s:IsFinished("UseGoldenKey")) and (player:HasTrinket(19) or player:TryUseKey() == true) then
									if math.random(1000) > 50 then
										s:Play("Idle",true)
										if player:HasGoldenKey() == true then
											s:Play("UseGoldenKey",true)
										else
											s:Play("UseKey",true)
										end
									else
										n_pickups[i]:ToPickup():TryOpenChest()
									end
								end
							elseif n_pickups[i].Variant == 53 then
								--Debuglist[11] = s:GetFrame()
								if (s:IsPlaying("Idle") or s:IsFinished("Idle") or s:IsFinished("Close"))and (player:HasTrinket(19) or player:TryUseKey() == true) then
									n_pickups[i]:ToPickup():TryOpenChest()
								end
							elseif n_pickups[i].Variant == 69 then
								if (s:IsPlaying("Idle") or s:IsFinished("Idle")) then
									n_pickups[i]:ToPickup():TryOpenChest()
									n_pickups[i]:Remove()
								end
							else
								if (s:IsPlaying("Idle") or s:IsFinished("Idle")) then
									n_pickups[i]:ToPickup():TryOpenChest()
								end
							end
						end
					end
				end
				for i = 1,#n_bombs do
					if (ent.Position - n_bombs[i].Position):Length() < 80 * range then
						n_bombs[i]:AddVelocity((ent.Position - n_bombs[i].Position):Normalized() * (-2))
					end
				end
			
				if d.tearflags and d.tearflags & BitSet128(1<<34,0) == BitSet128(1<<34,0) then		--泪盾
					for i = 1,#n_projs do
						if (ent.Position - n_projs[i].Position):Length() < 80 * range then
							n_projs[i]:AddVelocity((ent.Position - n_projs[i].Position):Normalized() * (-2))
						end
					end
				end
			
			end
		end
		if (s:IsPlaying("AttackUp") and s:IsFinished("AttackUp") == false) or (s:IsPlaying("AttackUp2") and s:IsFinished("AttackUp2") == false) then
			if s:GetFrame() == 1 then
				sound_tracker.PlayStackedSound(SoundEffect.SOUND_SWORD_SPIN,math.random(1000)/2000 + 0.5,math.random(1000)/5000 + 0.4,false,0,2)
			end
			local damage = ent.CollisionDamage
			local damageflag = 0
			if d.damage then
				damage = d.damage
			end
			if d.damageflag then
				damageflag = d.damageflag
			end
			local range = ent:GetSprite().Scale:Length()
			if d.nowroom == nil or d.nowroom == level:GetCurrentRoomIndex() then
				for i = 1,#n_enemy do
					if (ent.Position - n_enemy[i].Position):Length() < 60 * range and MakeVector((ent.Position - n_enemy[i].Position):GetAngleDegrees() - ent.RotationOffset).X < 0.05 then
						if n_enemy[i]:GetData().Qing_blade_countdown == nil then
							n_enemy[i]:GetData().Qing_blade_countdown = -1
						end
						if n_enemy[i]:GetData().Qing_blade_countdown < 0 then
							if d.params and d.params.list and d.params.list.damo and d.params.list.damo > 0 and (ent.Position - n_enemy[i].Position):Length() < 60 * range then
								if ent.Parent and n_enemy[i]:GetData().Damo_effect == nil then
									Debuglist[4] = Debuglist[4] + 1
									local damo = d.params.list.damo
									local q1 = fire_nil(n_enemy[i].Position,n_enemy[i].Velocity,{cooldown = 60000})
									local d2 = q1:GetData()
									d2.follower = n_enemy[i]
									d2.Is_Qing_Damo = true
									n_enemy[i]:GetData().Damo_effect = true
								end
							end
							n_enemy[i]:TakeDamage(damage,damageflag,EntityRef(ent),3)
							n_enemy[i]:AddVelocity((ent.Position - n_enemy[i].Position):Normalized() * (-3))
							n_enemy[i]:GetData().Qing_blade_countdown = 2
							if ent:GetData().Explosive_cnt and ent:GetData().Explosive_cnt > 0 then		--引发爆炸
								local player = ent:GetData().player
								if player == nil then
									if ent:GetData().params then
										player = ent:GetData().params.player
									end
								end
								if player == nil then
									player = Game():GetPlayer(0)
								end
								local dmg = ent.CollisionDamage
								local tearflags = ent:GetData().bomb_knife_flag
								if tearflags == nil and ent:GetData().params and ent:GetData().params.bomb_knife_flag then
									tearflags = ent:GetData().params.bomb_knife_flag
								end
								if tearflags == nil then
									tearflags = BitSet128(0,0)
								end
								Game():BombExplosionEffects(n_enemy[i].Position,dmg * 15,tearflags,player.TearColor,player,1,false,false)		--耶耶耶！！！	
								ent:GetData().Explosive_cnt = ent:GetData().Explosive_cnt - 1
							end
							if d.fire_sound_effect and d.fire_sound_effect == true then
								--Debuglist[3] = Debuglist[3] + 1
								sound_tracker.PlayStackedSound(SoundEffect.SOUND_FIREDEATH_HISS,1.0,random_1() * 0.3 + 0.8,false,0,2)
							end
							if d.deadeye and d.deadeye > 0 then
								local player = Game():GetPlayer(0)
								if d.player then
									player = d.player
								end
								player:AddDeadEyeCharge()
								d.deadeye = 0
							end
							
							
						else
							n_enemy[i]:GetData().Qing_blade_countdown = n_enemy[i]:GetData().Qing_blade_countdown - 1
						end
					end
				end
				local player = Game():GetPlayer(0)
				if d.player then
					player = d.player
				end
				for i = 1,#n_pickups do
					if (ent.Position - n_pickups[i].Position):Length() < 60 * range and MakeVector((ent.Position - n_pickups[i].Position):GetAngleDegrees() - ent.RotationOffset).X < 0.05 and n_pickups[i]:ToPickup():IsShopItem() == false then
						n_pickups[i]:AddVelocity((ent.Position - n_pickups[i].Position):Normalized() * (-3))
						if (n_pickups[i].Variant > 49 and n_pickups[i].Variant < 70 and n_pickups[i].Variant ~= 51) or n_pickups[i].Variant == 360 or n_pickups[i].Variant == 390 then
							local s = n_pickups[i]:GetSprite()
							if n_pickups[i].Variant == 60 or n_pickups[i].Variant == 55 then
								if (s:IsPlaying("Idle") or s:IsFinished("Idle")) and (player:HasTrinket(19) or player:TryUseKey() == true) then
									n_pickups[i]:ToPickup():TryOpenChest()
								end
							elseif n_pickups[i].Variant == 57 then
								if (s:IsPlaying("Idle") or s:IsFinished("Idle") or s:IsFinished("UseKey") or s:IsFinished("UseGoldenKey")) and (player:HasTrinket(19) or player:TryUseKey() == true) then
									if math.random(1000) > 50 then
										s:Play("Idle",true)
										if player:HasGoldenKey() == true then
											s:Play("UseGoldenKey",true)
										else
											s:Play("UseKey",true)
										end
									else
										n_pickups[i]:ToPickup():TryOpenChest()
									end
								end
							elseif n_pickups[i].Variant == 53 then
								--Debuglist[11] = s:GetFrame()
								if (s:IsPlaying("Idle") or s:IsFinished("Idle") or s:IsFinished("Close"))and (player:HasTrinket(19) or player:TryUseKey() == true) then
									n_pickups[i]:ToPickup():TryOpenChest()
								end
							elseif n_pickups[i].Variant == 69 then
								if (s:IsPlaying("Idle") or s:IsFinished("Idle")) then
									n_pickups[i]:ToPickup():TryOpenChest()
									n_pickups[i]:Remove()
								end
							else
								if (s:IsPlaying("Idle") or s:IsFinished("Idle")) then
									n_pickups[i]:ToPickup():TryOpenChest()
								end
							end
						end
					end
				end
				for i = 1,#n_bombs do
					if (ent.Position - n_bombs[i].Position):Length() < 60 * range and MakeVector((ent.Position - n_bombs[i].Position):GetAngleDegrees() - ent.RotationOffset).X < 0.05 then
						n_bombs[i]:AddVelocity((ent.Position - n_bombs[i].Position):Normalized() * (-2))
					end
				end
				
				if d.tearflags and d.tearflags & BitSet128(1<<34,0) == BitSet128(1<<34,0) then
					for i = 1,#n_projs do
						if (ent.Position - n_projs[i].Position):Length() < 60 * range and MakeVector((ent.Position - n_projs[i].Position):GetAngleDegrees() - ent.RotationOffset).X < 0.05 then
							n_projs[i]:AddVelocity((ent.Position - n_projs[i].Position):Normalized() * (-1))
						end
					end
				end
			end
		end
		
		if s:IsPlaying("IdleUp") or s:IsFinished("IdleUp") or s:IsPlaying("IdleUp2") or s:IsFinished("IdleUp2") then
			if d.params and d.params.knife and (d.params.knife == true or d.params.knife > 0) then
				if d.params.list and d.params.list.brimstone and d.params.list.brimstone > 0 then
					if d.brim_and_knife_firedelay == nil then
						d.brim_and_knife_firedelay = -1
					end
					if d.brim_and_knife_firedelay < 0 then
						local player = Game():GetPlayer(0)
						if d.player then
							player = d.player
						end
						local vel = ent.Parent.Velocity
						if vel:Length() < 0.005 then
							vel = MakeVector(ent.RotationOffset) * 0.005
						end
						local q1 = fire_knife(ent.Position, - vel * 0.5,ent.CollisionDamage / 3,nil,{cooldown = math.random(10),player = player,Color = Color(-1,-1,-1,0.3,0,0,0)})
						q1:SetColor(Color(-1,-1,-1,0.3,0,0,0),15,99,false,false)
						local s2 = q1:GetSprite()
						s2.Scale = Vector(2,2)
						q1.RotationOffset = 180 + q1.RotationOffset
						d.brim_and_knife_firedelay = math.random(6)
					end
					d.brim_and_knife_firedelay = d.brim_and_knife_firedelay - 1
				elseif d.params.knife2 and (d.params.knife2 == true or d.params.knife2 > 0) then
					if d.Only_knife_firedelay == nil then
						d.Only_knife_firedelay = -1
					end
					local d2 = ent.Parent:GetData()
					if d.Only_knife_firedelay < 0 and d2.Params and d2.Params.Homing_target and d2.Params.Homing_target:Exists() == true then
						local player = Game():GetPlayer(0)
						if d.player then
							player = d.player
						end
						local vel = ent.Parent.Velocity
						if vel:Length() < 0.005 then
							vel = MakeVector(ent.RotationOffset) * 0.005
						end
						local q1 = fire_knife(ent.Position,(d2.Params.Homing_target.Position - ent.Position):Normalized(),ent.CollisionDamage * 0.05,nil,{cooldown = 8,player = player,Color = Color(1,1,1,0.5,0,0,0)})
						q1:Shoot(1,player.TearRange/4)
						d.Only_knife_firedelay = math.random(20)
					end
					d.Only_knife_firedelay = d.Only_knife_firedelay - 1
				end
			end
			
			if d.params and d.params.Dr_fet and (d.params.Dr_fet == true or d.params.Dr_fet > 0) then
				local d2 = ent.Parent:GetData()
				if d2.Params and d2.Params.Homing_target and d2.Params.Homing_target:Exists() == true then
					if d.Dr_fetus_firedelay == nil then
						d.Dr_fetus_firedelay = -1
					end
					local player = Game():GetPlayer(0)
					if d.player then
						player = d.player
					end
					if d.Dr_fetus_firedelay < 0 then
						if math.random(1000) > 800 then
							
							local d2 = ent.Parent:GetData()
							local vel = (d2.Params.Homing_target.Position - ent.Parent.Position):Normalized() * ent.Parent.Velocity:Length()
							if vel:Length() < 0.005 then
								vel = MakeVector(ent.RotationOffset) * 0.005
							end
							local q1 = player:FireBomb(ent.Position,vel * (math.random(50)/10 + 2))
						end
						d.Dr_fetus_firedelay = math.random(65) + 10 + player.MaxFireDelay
					end
					d.Dr_fetus_firedelay = d.Dr_fetus_firedelay - 1
				end
			end
			
			if d.params and d.params.epic and (d.params.epic == true or d.params.epic > 0) then -- and isenemies(col) == true then
				if ent.Parent then
					if d.touch ~= nil then
						ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
						ent.CollisionDamage = 0
					else
						local grident = room:GetGridEntityFromPos(ent.Position)
						if grident ~= nil and issolid(grident) then
							local player = Game():GetPlayer(0)
							if d.player then
								player = d.player
							end
							ent.Parent.Velocity = ent.Parent.Velocity:Normalized() * 3
							ent.Parent:GetData().Params.Accerate = -1
							ent.Parent:GetData().Params.Homing = false		--强制停止跟踪
							ent.Parent:GetData().Accerate_flag = true
							local tearflags = d.params.tearflags
							if tearflags == nil then
								tearflags = player.TearFlag
							end
							tearflags = tearflags | player:GetBombFlags()		--强度大增！
							local q1 = launch_Missile(ent.Position,Vector(0,0),ent.CollisionDamage/2,nil,{color = d.params.color,Cooldown = 25,Spawner = ent,Player = player,tearflags = tearflags,knife = player:GetCollectibleNum(114),brimstone = player:GetCollectibleNum(118), Tech = player:GetCollectibleNum(68),TechX = player:GetCollectibleNum(395),MultipleRockets = d.params.multishot, NumRockets = d.params.multishot})
							q1.Visible = false
							q1:GetSprite().Scale = ent:GetSprite().Scale
							d.touch = true
							ent.Parent:GetData().Params.FollowInput = nil
							if s:IsPlaying("IdleUp") or s:IsFinished("IdleUp") then
								s:Play("ChargedUp",false)
							elseif s:IsPlaying("IdleUp2") or s:IsFinished("IdleUp2") then
								s:Play("ChargedUp2",false)
							end
						end
					end
				end
			end
		
			if d.params and ((d.params.tearflags and d.params.tearflags & BitSet128(1<<2,0) == BitSet128(1<<2,0)) or (d.params.shouldrotate and d.params.shouldrotate == true)) then
				local d2 = ent.Parent:GetData()
				if d2.Params then --and d2.Params.Homing_target and d2.Params.Homing_target:Exists() == true then
					ent.RotationOffset = ent.Parent.Velocity:GetAngleDegrees()
					if s:IsPlaying("IdleUp") or s:IsFinished("IdleUp") or s:IsPlaying("IdleUp2") or s:IsFinished("IdleUp2") then
						if ent.RotationOffset < -90.0001 or ent.RotationOffset > 90.0001 then
							ent:GetSprite():Play("IdleUp2",true)
						else
							ent:GetSprite():Play("IdleUp",true)
						end
					end
					d2.Params.removeanimate = true
				end
			end
		
			if d.start_sec ~= nil and d.start_sec == false and ent.Parent and ent.Parent.Velocity:Length() < 0.005 then
				local d2 = ent.Parent:GetData()
				--Debuglist[11] = Debuglist[11] + 1
				if d2.Params and (d2.Params.Homing_target and d2.Params.Homing_target:Exists() == false) then
					d2.Params.Homing_target = nil
					ent.Parent.Velocity = ent.Parent.Velocity:Normalized() * 3
					ent.Parent:GetData().Params.Accerate = 0
				end
			end
		
			if d.params and d.params.sword and (d.params.sword == true or d.params.sword > 0) then
				local d2 = ent.Parent:GetData()
				if d2.Params and d2.Params.Homing_target and d2.Params.Homing_target:Exists() == true then
					if d.Dr_fetus_firedelay == nil then
						d.Dr_fetus_firedelay = -1
					end
					local player = Game():GetPlayer(0)
					if d.player then
						player = d.player
					end
					if d.Dr_fetus_firedelay < 0 then
						if math.random(1000) > 400 then
							
							local d2 = ent.Parent:GetData()
							local vel = (d2.Params.Homing_target.Position - ent.Parent.Position):Normalized() * ent.Parent.Velocity:Length()
							if vel:Length() < 0.005 then
								vel = MakeVector(ent.RotationOffset) * 0.005
							end
							local q1 = fire_Sword(ent.Position,vel,ent.CollisionDamage/3,nil,{cooldown = 14,Accerate = 0.5,	player = player,tearflags = player.TearFlags,Color = player.TearColor,Qing = (player:GetName() == "W.Qing")})
							sound_tracker.PlayStackedSound(SoundEffect.SOUND_SWORD_SPIN,math.random(1000)/2000 + 1,math.random(1000)/5000 + 0.8,false,0,2)
						end
						d.Dr_fetus_firedelay = math.random(65) + 10 + player.MaxFireDelay
					end
					d.Dr_fetus_firedelay = d.Dr_fetus_firedelay - 1
				end
			end
		
			if d.params and d.params.Hae and (d.params.Hae == true or d.params.Hae > 0) then
				local d2 = ent.Parent:GetData()
				if d2.removecd and d2.removecd == 1 then
					local player = Game():GetPlayer(0)
					if d.player then
						player = d.player
					end
					local maxcnt = math.random(d.params.list.hae * 1 + 1) - 1
					for i = 1, maxcnt do 
						local q1 = player:FireTear(ent.Position, MakeVector(math.random(36000)/100) * 3 * player.ShotSpeed * (math.random(1000)/400+0.3),true,true,true)
						q1.FallingSpeed = 10
						q1.FallingAcceleration = 2.6
						q1.PositionOffset = Vector(0,0)
						q1.Scale = q1.Scale * (math.random(1500)/1000 + 0.8)
					end
				end
			end
		end
		
		if s:IsPlaying("StabDown") or s:IsFinished("StabDown") or s:IsPlaying("StabDown2") or s:IsFinished("StabDown2") then
			if d.params and ((d.params.tearflags and d.params.tearflags & BitSet128(1<<2,0) == BitSet128(1<<2,0)) or (d.params.shouldrotate and d.params.shouldrotate == true)) then
				local d2 = ent.Parent:GetData()
				if d2.Params and d2.Params.Homing_target and d2.Params.Homing_target:Exists() == true then
					ent.RotationOffset = ent.Parent.Velocity:GetAngleDegrees()
					if s:IsPlaying("IdleUp") or s:IsFinished("IdleUp") or s:IsPlaying("IdleUp2") or s:IsFinished("IdleUp2") then
						if ent.RotationOffset < -90.0001 or ent.RotationOffset > 90.0001 then
							ent:GetSprite():Play("IdleUp2",true)
						else
							ent:GetSprite():Play("IdleUp",true)
						end
					end
					d2.Params.removeanimate = true
				end
			end
			if d.params and d.params.lung_and_tech and d.params.lung_and_tech > 0 and d.params.lung_and_tech_cnt and d.params.lung_and_tech_cnt> 0 then
				if s:GetFrame() == 2 then
					local dirang = (ent.Velocity):GetAngleDegrees()
					local rang = math.random(60) + 30
					local leap = rang/(d.params.lung_and_tech_cnt - 1)
					local length = (ent.Velocity):Length()
					--Debuglist[11] = length
					for i = 1,d.params.lung_and_tech_cnt do 
						local q1 = fire_dowhatknife(nil,ent.Position + ent.Velocity,MakeVector(dirang - rang/2 + (i-1) * leap) * math.max(0.001,(length + math.random(10000)/1000 - 5)),ent.CollisionDamage,"StabDown","StabDown2",{source = d.params.source,player = d.params.player,tearflags = d.params.tearflags,color = d.params.color,repel = d.params.repel/2,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = d.params.size,size1 = d.params.size1,size2 = d.params.size2,list = d.params.list,tech = d.params.tech,lung_and_tech = d.params.lung_and_tech - math.random(d.params.lung_and_tech + 1),lung_and_tech_cnt = math.max(1,d.params.lung_and_tech_cnt + math.random(3) - 2)})
					end
				end
			end
		end

		if d.params and d.params.list and d.params.list.pro and d.params.list.pro > 0 then
			if d.damage_float == nil then
				d.damage_float = 3
				d.damage_count = ent.CollisionDamage
			end
			local player = Game():GetPlayer(0)
			if d.player then
				player = d.player
			end
			d.damage_float = d.damage_float - 0.15 / player.ShotSpeed		--15帧后减少至0。
			if d.damage_float < 0 then
				d.damage_float = 0
			end
			Debuglist[14] = d.damage_float
			ent.CollisionDamage = d.damage_float * d.damage_count
		end
		
		if d.params and d.params.list and d.params.list.coal and d.params.list.coal > 0 then
			if d.damage_float == nil then
				d.damage_float = 0.4
				d.damage_count = ent.CollisionDamage
			end
			local player = Game():GetPlayer(0)
			if d.player then
				player = d.player
			end
			d.damage_float = d.damage_float + 0.05 / player.ShotSpeed
			ent.CollisionDamage = d.damage_float * d.damage_count
		end
		
		if d.deadeye and d.deadeye > 0 and ent.Parent then		--死眼
			local d2 = ent.Parent:GetData()
			if d2.removecd and d2.removecd == 1 then
				local player = Game():GetPlayer(0)
				if d.player then
					player = d.player
				end
				if math.random(1000) > 750 then		--随便取个参数
					--Debuglist[4] = Debuglist[4] + 1
					player:ClearDeadEyeCharge()
				end
				d.deadeye = 0
			end
		end
		
		if true then		--反复运行。
			local player = Game():GetPlayer(0)
			if d.player then
				player = d.player
			end
			if s:IsFinished("ChargedUp") then
				s:Play("ChargedUp")
			end
			if s:IsFinished("ChargedUp2") then
				s:Play("ChargedUp2")
			end
			if s:IsFinished("AttackUp") and d.params and d.params.continueafter and d.params.continueafter == true then
				s:Play("AttackUp",true)
			end
			if d.params and d.params.list and d.params.list.sec and d.params.list.sec > 0 and ent.Parent then			--转化为飞刀攻击！只会成功一次！
				if (s:IsFinished("AttackUp") or s:IsFinished("SpinUp") or s:IsFinished("StabUp")) or (s:IsPlaying("StabDown") and ent.FrameCount > 8) then
					d.start_sec = true
					s:Play("IdleUp")
				elseif (s:IsFinished("AttackUp2") or s:IsFinished("SpinUp2") or s:IsFinished("StabUp2")) or (s:IsPlaying("StabDown2") and ent.FrameCount > 8) then
					d.start_sec = true
					s:Play("IdleUp2")
				end
				if d.start_sec and d.start_sec == true then
					ent.Parent:GetData().Is_Qing_Fetus = true
					d.start_sec = false
					if ent.Parent:GetData().Params == nil then
						ent.Parent:GetData().Params = {}
					end
					ent.Parent:GetData().Params.Homing = true
					ent.Parent:GetData().Params.HomingSpeed = 2.5
					ent.Parent:GetData().Params.HomingDistance = 100		--跟踪距离为100。
					ent.Parent:GetData().Params.Accerate = 0.1
					ent.Parent.Velocity = ent.Velocity:Normalized() * 3
					d.params.shouldrotate = true
					d.params.repel = Vector(0,0)
					if d.params.thor_effe == nil or d.params.thor_effe ~= true then		--对飞雷神攻击的附加特效是无效的
						d.params.epic = d.params.list.epic
						d.params.sword = d.params.list.sword
						d.params.knife = d.params.list.knife
						d.params.knife2 = d.params.list.knife		--独属于剖腹产和妈刀配合的特效
						d.params.brimstone = d.params.list.brimstone
						d.params.TechX = d.params.list.techX
						d.params.Tech = d.params.list.tech
						d.params.Hae = d.params.list.hae
						d.params.Dr_fet = d.params.list.dr + d.params.list.epic
					end
					if d.params.knife and d.params.brimstone and d.params.knife == 0 and d.params.brimstone > 0 then
						local q2 = player:FireBrimstone(-ent.Parent.Velocity)
						q2.PositionOffset = Vector(0,0)
						q2:SetTimeout(ent.Parent:GetData().removecd - 1)
						q2:SetMaxDistance(player.TearRange/4)
						q2.Parent = ent
						q2.Position = ent.Position
						q2:GetData().followRotation = ent.Parent
					elseif d.params.Tech and d.params.Tech > 0 then
						local q2 = player:FireTechLaser(ent.Position,1,(player.Position - ent.Position):Normalized(),false,true)
						q2.Parent = ent
						q2.PositionOffset = Vector(0,0)
						q2:GetData().followParent = ent
						--q2.CollisionDamage = ent.CollisionDamage/10
						q2:GetData().followRotation = ent.Parent
						--q2:GetData().followRotation_aidang = 180
						q2:GetData().reset_startp = true
						q2:GetData().reset_startp_source = player
						q2:SetMaxDistance((player.Position - ent.Position):Length())
						q2:SetTimeout(ent.Parent:GetData().removecd - 1)
					end
					if d.params.TechX and d.params.TechX > 0 and d.params.Tech and d.params.Tech == 0then
						local q2 = player:FireTechXLaser(ent.Position,ent.Velocity,player.TearRange/10)
						q2.PositionOffset = Vector(0,0)
						q2:GetData().followParent = ent
						q2:SetTimeout(ent.Parent:GetData().removecd - 1)
					end
				end
			end
			if s:IsFinished("AttackUp2") and d.params and d.params.continueafter and d.params.continueafter == true then
				s:Play("AttackUp2",true)
			end
			if s:IsFinished("SpinUp") and d.params and d.params.continueafter and d.params.continueafter == true then
				s:Play("SpinUp",true)
			end
			if s:IsFinished("SpinUp2") and d.params and d.params.continueafter and d.params.continueafter == true then
				s:Play("SpinUp2",true)
			end
		end
	
		if s:IsPlaying("IdleUp") or s:IsFinished("IdleUp") or s:IsPlaying("IdleUp2") or s:IsFinished("IdleUp2") then		--特效们
			local player = Game():GetPlayer(0)
			if d.player then
				player = d.player
			end
			if d.tearflags and d.tearflags & BitSet128(1<<16,0) == BitSet128(1<<16,0) and ent.Parent then		--原版星球
				local leg = ent.Parent.Velocity:Length()
				ent.Parent.Velocity = (Get_rotate(ent.Parent.Velocity):Normalized() * 0.2 + ent.Parent.Velocity:Normalized()):Normalized() * leg
				ent.RotationOffset = ent.Parent.Velocity:GetAngleDegrees()
				if ent.RotationOffset < -90.0001 or ent.RotationOffset > 90.0001 then
					ent:GetSprite():Play("IdleUp2",true)
				else
					ent:GetSprite():Play("IdleUp",true)
				end
			end
			if d.tearflags and d.tearflags & BitSet128(0,1<<(69-64)) == BitSet128(0,1<<(69-64)) and ent.Parent then		--星球2
				if (ent.Parent.Position - player.Position):Length() > 100 then
					local leg = ent.Parent.Velocity:Length()
					ent.Parent.Velocity = Get_rotate(ent.Parent.Position - player.Position):Normalized() * leg
				end
			end
			if d.tearflags and d.tearflags & BitSet128(1<<30,0) == BitSet128(1<<30,0) and ent.Parent then		--方蛇
				if d.Addition_Pulse_flag == nil then
					d.Addition_Pulse_flag = math.random(2) * 2 - 1
					d.Addition_Pulse_cnt = 5
					d.OriginalVelocity = ent.Parent.Velocity
				end
				if d.Addition_Pulse_flag == 0 or d.Addition_Pulse_flag == 1 and d.Addition_Pulse_cnt < 0 then
					ent.Parent.Velocity = Get_rotate(ent.Parent.Velocity)
					d.Addition_Pulse_flag = d.Addition_Pulse_flag + 1
					d.Addition_Pulse_cnt = 5
				elseif d.Addition_Pulse_flag == 2 or d.Addition_Pulse_flag == 3 and d.Addition_Pulse_cnt < 0 then
					ent.Parent.Velocity = - Get_rotate(ent.Parent.Velocity)
					d.Addition_Pulse_flag = d.Addition_Pulse_flag + 1
					d.Addition_Pulse_cnt = 5
				end
				if d.Addition_Pulse_flag > 3 then
					d.Addition_Pulse_flag = 0
				end
				d.Addition_Pulse_cnt = d.Addition_Pulse_cnt - 1
			end
			if d.tearflags and d.tearflags & BitSet128(1<<26,0) == BitSet128(1<<26,0) and ent.Parent then		--环蛇
				if d.AdditionVelocity == nil then
					d.AdditionVelocity = 0
					d.OriginalVelocity = ent.Parent.Velocity
				end
				local leg = ent.Parent.Velocity:Length()
				ent.Parent.Velocity = (d.OriginalVelocity:Normalized() + MakeVector(d.AdditionVelocity) * 2):Normalized() * leg
				d.AdditionVelocity = d.AdditionVelocity + 20
			end
			if d.tearflags and d.tearflags & BitSet128(1<<46,0) == BitSet128(1<<46,0) and ent.Parent then		--黑蛇
				if d.AdditionVelocity == nil then
					d.AdditionVelocity = 0
					d.OriginalVelocity = ent.Parent.Velocity
				end
				local leg = ent.Parent.Velocity:Length()
				ent.Parent.Velocity = (d.OriginalVelocity:Normalized() + MakeVector(d.AdditionVelocity) * 2):Normalized() * leg
				d.AdditionVelocity = d.AdditionVelocity + 10
			end
			if d.tearflags and d.tearflags & BitSet128(1<<10,0) == BitSet128(1<<10,0) and ent.Parent then		--弯虫（共用了也没关系对吧？）
				if d.AdditionVelocity == nil then
					d.AdditionVelocity = 0
					d.OriginalVelocity = ent.Parent.Velocity
				end
				local leg = ent.Parent.Velocity:Length()
				ent.Parent.Velocity = (d.OriginalVelocity:Normalized() + MakeVector(d.AdditionVelocity) * 0.6):Normalized() * leg
				d.AdditionVelocity = d.AdditionVelocity + 20
			end
			if d.tearflags and d.tearflags & BitSet128(1<<17,0) == BitSet128(1<<17,0) and ent.Parent then		--反重力
				if ent.Parent:GetData().Params == nil then
					ent.Parent:GetData().Params = {}
				end
				if ent.Parent:GetData().Params.Accerate == nil then
					ent.Parent:GetData().Params.Accerate = 0
				end
				if d.Antig_velo == nil and ent.FrameCount > 1 then
					d.Antig_velo = ent.Parent.Velocity
					d.Antig_acce = ent.Parent:GetData().Params.Accerate
					d.Antig_flag = false
				end
				Debuglist[9] = ent.Parent:GetData().Params.Accerate
				if ggdir(player,false):Length() > 0.05 and d.Antig_flag ~= nil and d.Antig_flag == false and ent.FrameCount > 1 then
					ent.Parent.Velocity = ent.Parent.Velocity/100000
					ent.Parent:GetData().Params.Accerate = 0	
				elseif d.Antig_flag ~= nil and d.Antig_flag == false then
					ent.Parent.Velocity = d.Antig_velo
					ent.Parent:GetData().Params.Accerate = d.Antig_acce
					d.Antig_flag = true
				end
			end
			if d.tearflags and d.tearflags & BitSet128(1<<8,0) == BitSet128(1<<8,0) and ent.Parent then		--镜子
				if d.Mirror_counter == nil then
					d.Mirror_counter = 3
					d.Mirror_Velocity = ent.Parent.Velocity
				end
				if ent.Parent:GetData().Params == nil then
					ent.Parent:GetData().Params = {}
				end
				if ent.Parent:GetData().Params.Accerate == nil then
					ent.Parent:GetData().Params.Accerate = 0
				end
				if d.Mirror_counter == 0 then
					ent.Parent:GetData().Params.Accerate =  - ent.Parent:GetData().Params.Accerate * 3
				end
				if ent.Parent.Velocity:Length() < 0.01 then
					ent.Parent:AddVelocity(-d.Mirror_Velocity:Normalized() * 2)
					ent.Parent:GetData().Params.Accerate =  - ent.Parent:GetData().Params.Accerate / 3
					ent.Parent:GetData().Accerate_flag = true
				end
				d.Mirror_counter = d.Mirror_counter - 1
			end
			if d.tearflags and d.tearflags & BitSet128(1<<38,0) == BitSet128(1<<38,0) and ent.Parent and ent:GetData().Continum_flag == nil then		--连续集：似乎还有小bug。
				local btrp = room:GetBottomRightPos()
				--Debuglist[8] = player.Position.X
				--Debuglist[11] = btrp.X
				--Debuglist[9] = player.Position.Y
				--Debuglist[12] = btrp.Y
				if ent.Parent.Position.X < 0 or ent.Parent.Position.X > btrp.X - 0 then
					if ent.Parent.Position.Y < 50 or ent.Parent.Position.Y > btrp.Y - 50 then
						ent.Parent.Position = Vector(btrp.X - ent.Parent.Position.X,btrp.Y - ent.Parent.Position.Y)
					else
						ent.Parent.Position = Vector(btrp.X - ent.Parent.Position.X,ent.Parent.Position.Y)
					end
					ent:GetData().Continum_flag = true
				elseif ent.Parent.Position.Y < 0 or ent.Parent.Position.Y > btrp.Y - 0 then
					if ent.Parent.Position.X < 50 or ent.Parent.Position.X > btrp.X - 50 then
						ent.Parent.Position = Vector(btrp.X - ent.Parent.Position.X,btrp.Y - ent.Parent.Position.Y)
					else
						ent.Parent.Position = Vector(ent.Parent.Position.X,btrp.Y - ent.Parent.Position.Y)
					end
					ent:GetData().Continum_flag = true
				end
			end
			if d.tearflags and d.tearflags & BitSet128(0,(1<<(71-64))) == BitSet128(0,(1<<(71-64))) and ent.Parent and ent.FrameCount > 7 then		--脑虫
				local d2 = ent.Parent:GetData()
				if d2.Params and d2.Params.Homing == nil then
					d.brain_worm_effect = true
					d2.Params.Homing = true
					d2.Params.HomingDistance = 200
				end
				if d.brain_worm_effect and d.brain_worm_effect == true and d2.Params and d2.Params.Homing_target and d2.Params.Homing_target:Exists() == true then
					d2.Params.Homing = false
					d.brain_worm_effect = false
					local dir = d2.Params.Homing_target.Position - ent.Position
					ent.Parent.Velocity = dir:Normalized() * ent.Parent.Velocity:Length()/2
					ent.RotationOffset = ent.Parent.Velocity:GetAngleDegrees()
					if s:IsPlaying("IdleUp") or s:IsFinished("IdleUp") or s:IsPlaying("IdleUp2") or s:IsFinished("IdleUp2") then
						if ent.RotationOffset < -90.0001 or ent.RotationOffset > 90.0001 then
							ent:GetSprite():Play("IdleUp2",true)
						else
							ent:GetSprite():Play("IdleUp",true)
						end
					end
					d2.Params.Accerate = 1
				end
			end
			if d.tearflags and d.tearflags & BitSet128(0,(1<<(68-64))) == BitSet128(0,(1<<(68-64))) and ent.Parent then		--魔眼
				local d2 = ent.Parent:GetData()
				if d2.Params == nil then
					d2.Params = {}
				end
				d2.Params.FollowInput = true
				d.params.shouldrotate = true
			end
		end
	end
end

function CharacterMeus:OnWQingUpdate(player)		--表万青总算法
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = player:GetData()
	if player:GetName() == "W.Qing" then
		gdir = ggdir(player,false)
		
		if d.invincible and d.invincible > -10 then
			d.invincible = d.invincible - 1
		end
		
		local list = {		--重要道具数量
				brimstone = player:GetCollectibleNum(118),
				tech = player:GetCollectibleNum(68),
				techX = player:GetCollectibleNum(395),
				knife = player:GetCollectibleNum(114),
				lung = player:GetCollectibleNum(229),
				dr = player:GetCollectibleNum(52),
				epic = player:GetCollectibleNum(168),
				sword = player:GetCollectibleNum(579),
				ludo = player:GetCollectibleNum(329),
				pol = player:GetCollectibleNum(169),
				cho = player:GetCollectibleNum(69),
				soy = player:GetCollectibleNum(330),
				soy2 = player:GetCollectibleNum(561),
				para = player:GetCollectibleNum(461),
				damo = player:GetCollectibleNum(577) + player:GetCollectibleNum(656),
				ice = player:GetCollectibleNum(596),
				dual = player:GetCollectibleNum(498) + player:GetCollectibleNum(304),
				redfire = player:GetCollectibleNum(616),
				bluefire = player:GetCollectibleNum(495),
				loki = player:GetCollectibleNum(87),
				momeye = player:GetCollectibleNum(55),
				wiz = player:GetCollectibleNum(358),
				eye = player:GetCollectibleNum(558),
				coal = player:GetCollectibleNum(132),
				pro = player:GetCollectibleNum(261),
				hae = player:GetCollectibleNum(531),
				sec = player:GetCollectibleNum(678),
				ipec = player:GetCollectibleNum(149),
				deadeye = player:GetCollectibleNum(373),
				finger = player:GetCollectibleNum(467),
				spear = player:GetCollectibleNum(400),
				backstab = player:GetCollectibleNum(506) + player:GetCollectibleNum(enums.Items.Assassin_s_Eye),
				divi = player:GetCollectibleNum(453) + player:GetCollectibleNum(224) + player:GetCollectibleNum(104),
				godhead = player:GetCollectibleNum(331),
				repel_effect = math.max(-10,(player:GetCollectibleNum(4) + player:GetCollectibleNum(309) + player:GetCollectibleNum(359)) * 4 - player:GetCollectibleNum(330) * 6 - 3 + player.TearRange/200),
				tri = player:GetCollectibleNum(533),
				bone = player:GetCollectibleNum(453) + player:GetCollectibleNum(544) + player:GetCollectibleNum(549) + player:GetCollectibleNum(541) + player:GetCollectibleNum(542) + player:GetCollectibleNum(548) + player:GetCollectibleNum(683),
				dea = player:GetCollectibleNum(237) + player:GetCollectibleNum(446),
			}
		
		if player:AreControlsEnabled() and (Input.IsButtonTriggered(ModConfigSettings.thor_key,0) or Input.IsButtonPressed(ModConfigSettings.thor_key,0)) then		--按下alt时，使用瞬移。
			if player:HasCollectible(619) then
				if player:GetData().birth_delay == nil then
					player:GetData().birth_delay = 0
				end
			end
			if d.thor_target ~= nil and d.thor_target:Exists() then
				if player:HasCollectible(619) and player:GetData().birth_delay < 0 then
					kill_thenm_all(player,d.thor_target.Position,player.Damage * 0.25,list)
					kill_thenm_all2(player,d.thor_target.Position,player.Damage * 0.75,list,15,200)		--伤害调低点。
					player:GetData().birth_delay = 150
					d.thor_target:Remove()
					d.thor_target = nil
				else
					thor_attack(player,list)
					d.thor_target:Remove()
					d.thor_target = nil
				end
			elseif player:HasCollectible(619) and player:GetData().birth_delay < 0 then -- and player:GetData().Birth_Flag and player:GetData().Birth_Flag == true then
				local n_entity = Isaac.GetRoomEntities()
				local n_enemy = getenemies(n_entity)
				local posi = room:GetRandomPosition(10)
				local wait = false
				--Debuglist[12] = Debuglist[12] + 1
				if #n_enemy > 0 then
					if gdir:Length() < 0.05 then
						posi = n_enemy[math.random(#n_enemy)].Position
					else
						posi = player.Position + gdir * 100
						for i = 1,#n_enemy do
							local lg = (n_enemy[i].Position - player.Position):Length()
							local the = (n_enemy[i].Position - player.Position):GetAngleDegrees()
							local cal = math.sin(math.rad(the)) * lg
							if cal > -10 and (player:GetData().birthright_counter == nil or player:GetData().birthright_counter > cal) then
								player:GetData().birthright_counter = cal
								posi = n_enemy[i].Position
								wait = true
							end
							player:GetData().birthright_counter = nil
						end
					end
				else
					if gdir:Length() > 0.05 then
						posi = player.Position + gdir * 100
					end
				end
				--if (player.Position - target.Position):Length() > 100 then
					kill_thenm_all(player,posi,0,list)
					if wait == true then
						kill_thenm_all2(player,posi,player.Damage/2,list,10,150)
						player:GetData().birth_delay = 150
					else
						player:GetData().birth_delay = 30
					end
				--end
			end
		end
		
		if player:HasCollectible(619) then
			if player:GetData().birth_delay == nil then
				player:GetData().birth_delay = 0
			end
			player:GetData().birth_delay = player:GetData().birth_delay - 1
		end
		
		if d.firedelay == nil then
			d.firedelay = -1
		end
		if d.firedelay > 1800 then		
			d.firedelay = 1800
		end
		if d.fire_state == nil then
			d.fire_state = 0	--0代表平A
		end
		if gdir:Length() < 0.05 then
			d.fire_state = 0
			if d.fire_delay_puni and d.fire_delay_puni > 0 then		--防止了停止连招来加速攻击的情况。
				d.firedelay = d.firedelay + d.fire_delay_puni
				d.fire_delay_puni = -1
			end
		end
		
		local damage_of_player = player.Damage
		if player:HasCollectible(154) then		--化学蜕变
			if math.random(1000) > 500 then
				damage_of_player = damage_of_player + 1.5
			end
		end
		if player:HasCollectible(254) then		--血块
			if math.random(1000) > 500 then
				damage_of_player = damage_of_player + 1
			end
		end
		if player:HasCollectible(155) then		--小圣心
			if math.random(1000) > 500 then
				damage_of_player = damage_of_player * 1.33
			end
		end
		if player:HasCollectible(731) then		--新道具
			if math.random(1000) > 500 then
				damage_of_player = damage_of_player * 1.285
			end
		end
		local multishot_of_player = getmultishots(player,true)		--还没做这个。所以暂时不要拿此类道具。
		local cho_ccounter = 1		--记录增、减幅
		if player:HasCollectible(69) then --and player:HasWeaponType(13) == false then		--巧克力牛奶的效果：第一击可以不考虑延迟进行攻击，但那一击的伤害下降对应的蓄力的量。		--注意！巧克力牛奶配合诅咒之眼非常优秀！！为了防止其与英灵剑组合后出现爆炸局面，已经修复。
			if d.fire_state == 0 and d.firedelay > 0 and gdir:Length() > 0.05 then
				d.damage_of_player = damage_of_player * 1 / (d.firedelay + 2)
				cho_ccounter = 1 / (d.firedelay + 2)
				list.repel_effect = (10 + list.repel_effect) / (d.firedelay + 2) - 10
				d.firedelay = -1
			end
		end
		
		if player:HasCollectible(69) and d.firedelay < 0 and gdir:Length() < 0.05 then		--角色不在攻击的时候，自动蓄力。
			if d.cho_delay == nil then
				d.cho_delay = 0
			end
			if d.cho_delay < player.MaxFireDelay * 10 then
				d.cho_delay = d.cho_delay + 1
			end
			if d.cho_delay > player.MaxFireDelay * 10 then
				d.cho_delay = player.MaxFireDelay * 10
			end
			local delay_cnt = d.cho_delay / player.MaxFireDelay / 10
			if delay_cnt < 0.9999 then
				if player:GetData().is_setting_color == nil or player:GetData().is_setting_color == false then
					player:SetColor(Color(1-(1-0.33) * delay_cnt,1-(1-0.18) * delay_cnt,1-(1-0.18) * delay_cnt,1,0.25 * delay_cnt,0.15 * delay_cnt,0.15 * delay_cnt),2,60,false,false)
				end
			else
				if d.cho_fini == nil or d.cho_fini == false then
					d.cho_fini = true
					player:GetData().is_setting_color = true
					player:SetColor(Color(1,1,1,1,1,1,1),4,99,true,false)
					addeffe(function(para)
						player:GetData().is_setting_color = false
						end,{player = player},4)
				end
			end
		end
		
		if d.firedelay ~= nil and d.firedelay < 0 and gdir:Length() > 0.05 then		--发动攻击
			if player:HasCollectible(69) then		--巧克力牛奶的效果：可以不考虑延迟进行攻击，但伤害不足。
				if d.damage_of_player and d.damage_of_player ~= nil then
					damage_of_player = d.damage_of_player
					d.damage_of_player = nil
				end
				if d.cho_delay and d.cho_delay > 0 then
					cho_ccounter = 1 + d.cho_delay/(player.MaxFireDelay * 5)
					damage_of_player = damage_of_player *(1+d.cho_delay/(player.MaxFireDelay * 5))
					list.repel_effect = list.repel_effect + cho_ccounter * 2
					d.cho_delay = 0
					d.cho_fini = false
				end
				list.cho_counter = cho_ccounter
			end
			Debuglist[3] = list.repel_effect
			local stabknifevar = nil
			local weap = 1
			Debuglist[11] = 0
			for i = 1,16 do 			--奇怪的是，三位一体盾占据了18和19两个端口。但不清楚究竟有什么用。
				if player:HasWeaponType(i) == true then
					weap = i
					Debuglist[11] = Debuglist[11] * 100 + i
				end
			end
			
			--Debuglist[15] = weap
			
			if player:HasCollectible(258) then		--编号错误：每一发都是随机攻击。
				weap = math.random(14)
			end
			
			if player:HasCollectible(191) then		--三美刀：每一轮随机攻击方式。覆盖编号丢失。
				if d.doll_weapon_set == nil or (d.fire_state and d.fire_state == 1) then
					d.doll_weapon_set = math.random(14)
				end
				weap = d.doll_weapon_set
			end
			
			local should_attack = true
			if should_attack and should_attack == true then
				local gggdir = gdir
				local gdir_ang = gdir:GetAngleDegrees()
				local attack_params = {gdir}
				--Debuglist[8] = getmultishot(multishot_of_player,list.wiz + 1,1,0)
				local cnt3 = 0
				if player:HasPlayerForm(PlayerForm.PLAYERFORM_BABY) then
					cnt3 = 1
				end
				for i = 1,multishot_of_player do
					attack_params[i] = MakeVector(gdir_ang + getmultishot(multishot_of_player,list.wiz + 1,i,cnt3) - 90)
				end
				if list.loki and list.loki > 0 and check_rand(player.Luck,100,10,15) == true then
					for i = 1,3 do
						attack_params[#attack_params + 1] = MakeVector(gdir_ang + 90 * i)
					end
				end
				if list.momeye and list.momeye > 0 and check_rand(player.Luck,100,10,5) == true then
					attack_params[#attack_params + 1] = MakeVector(gdir_ang + 180)
				end
				if list.eye and list.eye > 0 and check_rand(player.Luck,50,10,20) == true then
					attack_params[#attack_params + 1] = MakeVector(math.random(36000)/100)
				end
				if attack_params then
					for i = 1, #attack_params do
						gdir = attack_params[i]
						--Debuglist[8] = d.fire_state
						--Debuglist[12] = weap
						if player:HasCollectible(418) and math.random(1000) > 500 then		--水果蛋糕：有50%概率每一次都是随机攻击。覆盖三美刀和编号丢失。
							weap = math.random(14)
						end

						if weap == 1 or weap == 2 or weap == 8 or weap == 4 or weap == 14 then		--通常，鲁科，硫磺火，妈刀，剖腹产（暂定）：平A攻击
							if weap == 1 or weap == 4 or weap == 8 or weap == 14 then			--普通眼泪：5段斩击
								if d.fire_state > 4 then
									d.fire_state = 0
								end
							elseif weap == 2 then		--有硫磺火：额外发射激光
								if d.fire_state > 2 then
									d.fire_state = 0
								end
							end
							if d.fire_state == 0 then
								d.firedelay = player.MaxFireDelay
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,player.Velocity + gdir * 10,damage_of_player/3,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
							elseif d.fire_state == 1 then
								d.firedelay = player.MaxFireDelay
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized()/1000,damage_of_player/3,"AttackUp","AttackUp2",{source = nil,cooldown = 8,player = player,tearflags = player.TearFlags,color = player.TearColor,list = list,tech = player:HasCollectible(68)})
							elseif d.fire_state == 2 then
								d.firedelay = player.MaxFireDelay * 2
								local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
								local length = (player.Velocity + gdir * 10):Length()
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(dirang + 90) * 60 + MakeVector(dirang) * (-20),MakeVector(dirang - 30) * length,damage_of_player/3,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
								local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(dirang - 90) * 60 + MakeVector(dirang) * (-20),MakeVector(dirang + 30) * length,damage_of_player/3,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
							elseif d.fire_state == 3 then
								d.firedelay = player.MaxFireDelay * 3	
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized()/1000,damage_of_player/2,"SpinUp","SpinUp2",{source = nil,cooldown = 14,player = player,tearflags = player.TearFlags,color = player.TearColor,list = list,tech = player:HasCollectible(68)})
							elseif d.fire_state == 4 then
								d.firedelay = player.MaxFireDelay
								local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
								local length = (player.Velocity + gdir * 10):Length()
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,thor = true,Accerate = 2,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = player:HasCollectible(68)})
							end
							if weap == 14 then
								d.firedelay = d.firedelay * 1.8
							end
							if weap == 2 then
								d.firedelay = d.firedelay * 1.3
							end
							if weap == 4 then
								d.firedelay = (d.firedelay * 1.4 + 20 * math.sqrt(player.MaxFireDelay/10))/2
							end
							if weap == 2 or weap == 4 then
								addeffe(function(params)
									local dir = params.dir
									local player = params.player
									local list = params.list
									if player == nil or dir == nil or player:Exists() == false then
										return
									end
									if list.knife and list.knife > 0 then
										local rand_cnt = list.knife * 2 + 1
										local refang = dir:GetAngleDegrees() + 90
										for i = 1, rand_cnt do 
											if list.brimstone and list.brimstone > 0 then
												local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(refang) * (i-rand_cnt/2) * 15,(player.Velocity + dir * 10):Normalized() * 20 * player.ShotSpeed,math.sqrt(damage_of_player * 0.65 * 3.5),"IdleUp","IdleUp2",{source = nil,cooldown = 30,player = player,tearflags = player.TearFlags,color = player.TearColor,knife = true,Accerate = 2,list = list,tech = player:HasCollectible(68),Explosive = list.ipec + list.dr})		--显式传入的kinfe、birmstone含义为生成时附带，而隐式传入的则只作为标记作用。
											else
												local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(refang) * (i-rand_cnt/2) * 15,(player.Velocity + dir * 10):Normalized() * 20 * player.ShotSpeed,math.sqrt(damage_of_player * 0.25 * 3.5),"IdleUp","IdleUp2",{source = nil,cooldown = 30,player = player,tearflags = player.TearFlags,color = player.TearColor,knife = true,Accerate = 2,list = list,tech = player:HasCollectible(68),Explosive = list.ipec + list.dr})		--显式传入的kinfe、birmstone含义为生成时附带，而隐式传入的则只作为标记作用。
											end
										end
									elseif list.brimstone and list.brimstone > 0 then
										local rand_cnt = math.floor(math.random(list.brimstone)/2) + 1
										local refang = dir:GetAngleDegrees() + 90
										for i = 1, rand_cnt do 
											local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(refang) * (i-rand_cnt/2) * 15,(player.Velocity + dir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player/2,"IdleUp","IdleUp2",{source = nil,cooldown = 30,player = player,tearflags = player.TearFlags,color = player.TearColor,brimstone = true,Accerate = 2,list = list,tech = player:HasCollectible(68),Explosive = list.ipec + list.dr})
											if damage_of_player > player.Damage / 2 then
												local q2 = player:FireBrimstone( - (player.Velocity + dir * 10):Normalized())
												q2.PositionOffset = Vector(0,0)
												if list.brimstone > 1 then
													q2:SetTimeout(25)
												else
													q2:SetTimeout(13)
												end
												q2.Parent = q1
												q2.Position = q1.Position
											end
										end
									end
								end,{dir = gdir,player = player,list = copy(list)},d.firedelay / 4)
								local multitar = 0
								if player:HasCollectible(229) or player:HasCollectible(558) then
									for i = 1,player:GetCollectibleNum(229) do
										multitar = multitar + math.random(3)
									end
									for i = 1,player:GetCollectibleNum(558) do
										multitar = multitar + math.random(1) 
									end
								end
								for i = 1,multitar do
									addeffe(function(params)
									local dir = params.dir
									local player = params.player
									local list = params.list
									if player == nil or dir == nil or player:Exists() == false then
										return
									end
									if list.knife and list.knife > 0 then
										local rand_cnt = list.knife * 2 + 1
										local refang = dir:GetAngleDegrees() + 90
										for i = 1, rand_cnt do 
											if list.brimstone and list.brimstone > 0 then
												local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(refang) * (i-rand_cnt/2) * 15,(player.Velocity + dir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player,"IdleUp","IdleUp2",{source = nil,cooldown = 50,player = player,tearflags = player.TearFlags,color = player.TearColor,knife = true,Accerate = 2})		--显式传入的kinfe、birmstone含义为生成时附带，而隐式传入的则只作为标记作用。
											else
												local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(refang) * (i-rand_cnt/2) * 15,(player.Velocity + dir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player/2,"IdleUp","IdleUp2",{source = nil,cooldown = 50,player = player,tearflags = player.TearFlags,color = player.TearColor,knife = true,Accerate = 2})		--显式传入的kinfe、birmstone含义为生成时附带，而隐式传入的则只作为标记作用。
											end
										end
									elseif list.brimstone and list.brimstone > 0 then
										local refang = dir:GetAngleDegrees() + 90
										local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(refang) * 15,(player.Velocity + dir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player/2,"IdleUp","IdleUp2",{source = nil,cooldown = 50,player = player,tearflags = player.TearFlags,color = player.TearColor,brimstone = true,Accerate = 2})
										local q2 = player:FireBrimstone( - (player.Velocity + dir * 10):Normalized())
										q2.PositionOffset = Vector(0,0)
										q2:SetMaxDistance(100)
										q2:SetTimeout(30)
										q2.Parent = q1
										q2.Position = q1.Position
									end
								end,{dir = MakeVector(math.random(18000)/100 - 90 + gdir:GetAngleDegrees()),player = player,list = copy(list)},d.firedelay / 8)
								end
							end
							d.fire_delay_puni = player.MaxFireDelay * 0			--无后摇
						elseif weap == 3 then		--科技1：科技剑光+新剑法
							if list.lung and list.lung > 0 then			--科技1+肺：特殊攻击。
								if d.fire_state > 2 then
									d.fire_state = 0
								end
								if d.fire_state == 0 then
									d.firedelay = player.MaxFireDelay * 1.5
									d.fire_delay_puni = player.MaxFireDelay * 1
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-40) + gdir:Normalized() * -30,player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
									local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (20) + gdir:Normalized() * 10,player.Velocity * 2 + gdir * 20,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
									local q3 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (40) + gdir:Normalized() * -30,player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
									local q4 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-20) + gdir:Normalized() * 10,player.Velocity * 2 + gdir * 20,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
									local q5 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player * 2,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,thor = true,Accerate = 2,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = true})
								elseif d.fire_state == 1 then
									d.firedelay = player.MaxFireDelay * 2
									d.fire_delay_puni = player.MaxFireDelay * 0.5
									local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
									local length = (player.Velocity + gdir * 10):Length()
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,MakeVector(dirang) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list,tech = true})
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(dirang + 90) * 60,MakeVector(dirang - 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list,tech = true})
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity - MakeVector(dirang + 90) * 60,MakeVector(dirang + 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list,tech = true})
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(dirang + 90) * 120,MakeVector(dirang - 60) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list,tech = true})
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity - MakeVector(dirang + 90) * 120,MakeVector(dirang + 60) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list,tech = true})
								elseif d.fire_state == 2 then
									d.firedelay = player.MaxFireDelay * 2.6
									d.fire_delay_puni = player.MaxFireDelay * 0
									local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
									local length = (player.Velocity + gdir * 10):Length()
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity - MakeVector(dirang) * length,MakeVector(dirang) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list,tech = true,lung_and_tech = 4,lung_and_tech_cnt = 3})
								end
							else
								if weap == 3 then
									if d.fire_state > 4 then
										d.fire_state = 0
									end
								end
								if d.fire_state == 0 then
									d.firedelay = player.MaxFireDelay * 0.75
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,player.Velocity + gdir * 10,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,4),size2 = 13})	--科技
								elseif d.fire_state == 1 then
									d.firedelay = player.MaxFireDelay * 1.25
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-20),player.Velocity + gdir * 10,damage_of_player * 0.75,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
									local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (20),player.Velocity + gdir * 10,damage_of_player * 0.75,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
								elseif d.fire_state == 2 then
									d.firedelay = player.MaxFireDelay * 1.75
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-40),player.Velocity + gdir * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
									local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (0),player.Velocity + gdir * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,4),size2 = 13})
									local q3 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (40),player.Velocity + gdir * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
								elseif d.fire_state == 3 then
									d.firedelay = player.MaxFireDelay * 2.25
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-60),player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
									local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (20),player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
									local q3 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (60),player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
									local q4 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-20),player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
								elseif d.fire_state == 4 then
									d.firedelay = player.MaxFireDelay * 2.75
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-40) + gdir:Normalized() * -30,player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
									local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (20) + gdir:Normalized() * 10,player.Velocity * 2 + gdir * 20,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
									local q3 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (40) + gdir:Normalized() * -30,player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
									local q4 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-20) + gdir:Normalized() * 10,player.Velocity * 2 + gdir * 20,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
									local q5 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player * 2,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,thor = true,Accerate = 2,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = true})
								end
								d.fire_delay_puni = player.MaxFireDelay * 0			--无后摇
							end
						elseif weap == 5 then		--博士：没灵感了，权且就这样了
							if d.fire_state > 3 then
								d.fire_state = 0
							end
							if d.fire_state == 0 then
								d.firedelay = player.MaxFireDelay * 0.5
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,player.Velocity + gdir * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68),Explosive = 1})
							elseif d.fire_state == 2 then
								d.firedelay = player.MaxFireDelay * 0.8
								local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
								local length = (player.Velocity + gdir * 10):Length()
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(dirang + 90) * 60 + MakeVector(dirang) * (-20),MakeVector(dirang - 30) * length,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
								local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + MakeVector(dirang - 90) * 60 + MakeVector(dirang) * (-20),MakeVector(dirang + 30) * length,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
								local q3 = player:FireBomb(player.Position + player.Velocity,player.Velocity + gdir * 10 * player.ShotSpeed)
							elseif d.fire_state == 1 then
								d.firedelay = player.MaxFireDelay * 1
								local refang = gdir:GetAngleDegrees() + 90
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player/2,"IdleUp","IdleUp2",{source = nil,cooldown = 30,player = player,tearflags = player.TearFlags,color = player.TearColor,Accerate = 2,list = list,tech = player:HasCollectible(68),Explosive = 1})
								if list.brimstone and list.brimstone > 0 then
									local rand_cnt = math.floor(math.random(list.brimstone)/2) + 1
									if damage_of_player > player.Damage / 2 then
										local q2 = player:FireBrimstone(  Get_rotate(player.Velocity + gdir * 10):Normalized())
										local q3 = player:FireBrimstone(  - Get_rotate(player.Velocity + gdir * 10):Normalized())
										q2.PositionOffset = Vector(0,0)
										q3.PositionOffset = Vector(0,0)
										if list.brimstone > 1 then
											q2:SetTimeout(25)
											q3:SetTimeout(25)
										else
											q2:SetTimeout(13)
											q3:SetTimeout(13)
										end
										q2.Parent = q1
										q3.Parent = q1
										q2.Position = q1.Position
										q3.Position = q1.Position
									end
								end
							elseif d.fire_state == 3 then
								d.firedelay = player.MaxFireDelay * 1.5
								for i = 1,4 do 
									local dir = (player.Velocity + gdir * 10):GetAngleDegrees() - 30 + 60/3 * (i-1)
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,MakeVector(dir) * 20 * player.ShotSpeed,damage_of_player/2,"IdleUp","IdleUp2",{source = nil,cooldown = 30,player = player,tearflags = player.TearFlags,color = player.TearColor,Accerate = 2,list = list,tech = player:HasCollectible(68),Explosive = 1})
									if list.tech and list.tech > 0 then
										local q3 = player:FireTechLaser(player.Position,1,-MakeVector(dir),false,false)
										q3.PositionOffset = Vector(0,0)
										q3:SetTimeout(30)
										q3.Parent = q1
										q3:SetMaxDistance((player.Position - q1.Position):Length())
										--q3:SetMaxDistance(0.01)
										--q3.Position = q1.Position
										q3:GetData().followParent = q1
									end
								end
							end
							d.fire_delay_puni = 0
						elseif weap == 6 then		--史诗：飞雷神转化为史诗标记。
							if d.fire_state > 0 then
								d.fire_state = 0
							end
							if d.fire_state == 0 then
								d.firedelay = player.MaxFireDelay * 4
								d.fire_delay_puni = player.MaxFireDelay * 1
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player * 0.85,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,epic = true,Accerate = 2,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = player:HasCollectible(68),multishot = multishot_of_player - 1})
							end
						elseif weap == 9 then		--科X：与科技X光环配合的帅气攻击。	还差得远呢。
							if d.fire_state > 2 then
								d.fire_state = 0
							end
							if d.fire_state == 0 then
								d.firedelay = player.MaxFireDelay * 2
								d.fire_delay_puni = player.MaxFireDelay * 4
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,player.Velocity + gdir * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
								for i = 1, 10 do
									fire_dowhatknife(nil,player.Position + player.Velocity + gdir:Normalized() * math.sin(math.rad(i/10 * 360)) * -30 + Get_rotate(gdir):Normalized() * math.cos(math.rad(i/10 * 360)) * -30,player.Velocity + gdir * (10) + gdir:Normalized() * math.sin(math.rad(i/10 * 360)) * 10 + Get_rotate(gdir):Normalized() * math.cos(math.rad(i/10 * 360)) * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
								end
								local q2 = player:FireTechXLaser(player.Position + player.Velocity + (player.Velocity + gdir * 10) * 4,player.Velocity + gdir * (10),30)
								q2.Velocity = Vector(0,0)
								q2.PositionOffset = Vector(0,0)
								q2:SetTimeout(10)
							elseif d.fire_state == 1 then
								d.firedelay = player.MaxFireDelay * 2.5
								d.fire_delay_puni = player.MaxFireDelay * 7
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,player.Velocity + gdir * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
								for i = 1, 10 do
									fire_dowhatknife(nil,player.Position + player.Velocity + gdir:Normalized() * math.sin(math.rad(i/10 * 360)) * -30 + Get_rotate(gdir):Normalized() * math.cos(math.rad(i/10 * 360)) * -30,(player.Velocity + gdir * (10) + gdir:Normalized() * math.sin(math.rad(i/10 * 360)) * 10 + Get_rotate(gdir):Normalized() * math.cos(math.rad(i/10 * 360)) * 10)/1000,damage_of_player/2,"AttackUp","AttackUp2",{source = nil,cooldown = 8,player = player,tearflags = player.TearFlags,color = player.TearColor,list = list,tech = player:HasCollectible(68)})
								end
								local q2 = player:FireTechXLaser(player.Position + player.Velocity + (player.Velocity + gdir * 10) * 4,player.Velocity + gdir * (10),30)
								q2.Velocity = Vector(0,0)
								q2.PositionOffset = Vector(0,0)
								q2:SetTimeout(10)
							elseif d.fire_state == 2 then
								d.firedelay = player.MaxFireDelay * 6.5
								d.fire_delay_puni = player.MaxFireDelay * 0
								local q2 = player:FireTechXLaser(player.Position + player.Velocity + (player.Velocity + gdir * 10) * 4,player.Velocity + gdir * (10),30)
								--local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,player.Velocity + gdir * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
								for i = 1, 10 do
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + gdir:Normalized() * math.sin(math.rad(i/10 * 360)) * -30 + Get_rotate(gdir):Normalized() * math.cos(math.rad(i/10 * 360)) * -30,(player.Velocity + gdir * (10) - gdir:Normalized() * math.sin(math.rad(i/10 * 360)) * 10 - Get_rotate(gdir):Normalized() * math.cos(math.rad(i/10 * 360)) * 10),damage_of_player/2,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,list = list,Accerate = 2,brimstone = player:HasCollectible(118),tech = player:HasCollectible(68)})
									if list.brimstone and list.brimstone > 0 then
										local q3 = player:FireBrimstone( - (player.Velocity + gdir * 10):Normalized())
										q3.PositionOffset = Vector(0,0)
										if list.brimstone > 1 then
											q3:SetTimeout(40)
										else
											q3:SetTimeout(25)
										end
										q3.Parent = q1
										q3.Position = q1.Position
									end
									if list.tech and list.tech > 0 then
										Debuglist[12] = Debuglist[12] + 1
										local q3 = player:FireTechLaser(player.Position,1,(player.Velocity + gdir * (10) - gdir:Normalized() * math.sin(math.rad(i/10 * 360)) * 10 - Get_rotate(gdir):Normalized() * math.cos(math.rad(i/10 * 360)) * 10),false,false)
										q3.PositionOffset = Vector(0,0)
										q3:SetTimeout(30)
										q3.Parent = q1
										q3:SetMaxDistance((player.Position - q1.Position):Length())
										--q3:SetMaxDistance(0.01)
										--q3.Position = q1.Position
										q3:GetData().followParent = q1
									end
									q1.Parent:GetData().follower = q2
									q1.Parent:GetData().continue_after_follower = true
									q1.Parent:GetData().continue_and_resetvel = (player.Velocity + gdir * (10) - gdir:Normalized() * math.sin(math.rad(i/10 * 360)) * 10 - Get_rotate(gdir):Normalized() * math.cos(math.rad(i/10 * 360)) * 10)
								end
								--q2.Velocity = Vector(0,0)
								q2.PositionOffset = Vector(0,0)
								q2:SetTimeout(math.floor(player.ShotSpeed) * 10)
							end
							if list.lung and list.lung > 0 or list.eye and list.eye > 0 then
								local multitar = 0
								if list.lung and list.lung > 0 then
									d.firedelay = d.firedelay * 0.5
								end
								if player:HasCollectible(229) or player:HasCollectible(558) then
									for i = 1,player:GetCollectibleNum(229) do
										if math.random(1000) > 300 then
											multitar = multitar + math.random(3)
										end
									end
									for i = 1,player:GetCollectibleNum(558) do
										if math.random(1000) > 950 then
											multitar = multitar + 1
										end
									end
								end
								for i = 1, multitar do
									local rand_ang = math.random(18000)/100 - 90 + gdir:GetAngleDegrees()
									local rand_dir = MakeVector(rand_ang)
									local q2 = player:FireTechXLaser(player.Position + player.Velocity + (player.Velocity + rand_dir * 10) * 4,player.Velocity + rand_dir * (10),30)
									for i = 1, 10 do
										local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + rand_dir:Normalized() * math.sin(math.rad(i/10 * 360)) * -30 + Get_rotate(rand_dir):Normalized() * math.cos(math.rad(i/10 * 360)) * -30,(player.Velocity + rand_dir * (10) - rand_dir:Normalized() * math.sin(math.rad(i/10 * 360)) * 10 - Get_rotate(rand_dir):Normalized() * math.cos(math.rad(i/10 * 360)) * 10),damage_of_player/2,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,list = list,Accerate = 2,brimstone = player:HasCollectible(118),tech = player:HasCollectible(68)})
										if list.brimstone and list.brimstone > 0 then
											local q3 = player:FireBrimstone( - (player.Velocity + rand_dir * 10):Normalized())
											q3.PositionOffset = Vector(0,0)
											if list.brimstone > 1 then
												q3:SetTimeout(40)
											else
												q3:SetTimeout(25)
											end
											q3.Parent = q1
											q3.Position = q1.Position
										end
										if list.tech and list.tech > 0 then
											Debuglist[12] = Debuglist[12] + 1
											local q3 = player:FireTechLaser(player.Position,1,(player.Velocity + rand_dir * (10) - rand_dir:Normalized() * math.sin(math.rad(i/10 * 360)) * 10 - Get_rotate(rand_dir):Normalized() * math.cos(math.rad(i/10 * 360)) * 10),false,false)
											q3.PositionOffset = Vector(0,0)
											q3:SetTimeout(30)
											q3.Parent = q1
											q3:SetMaxDistance((player.Position - q1.Position):Length())
											--q3:SetMaxDistance(0.01)
											--q3.Position = q1.Position
											q3:GetData().followParent = q1
										end
										q1.Parent:GetData().follower = q2
										q1.Parent:GetData().continue_after_follower = true
										q1.Parent:GetData().continue_and_resetvel = (player.Velocity + rand_dir * (10) - rand_dir:Normalized() * math.sin(math.rad(i/10 * 360)) * 10 - Get_rotate(rand_dir):Normalized() * math.cos(math.rad(i/10 * 360)) * 10)
									end
									--q2.Velocity = Vector(0,0)
									q2.PositionOffset = Vector(0,0)
									q2:SetTimeout(math.floor(player.ShotSpeed) * 10)
								end
							end
						elseif weap == 7 then		--肺：暴力近身剑舞。稍微提升了判定大小。目前设定为6段。多个肺叠加与其他不同。
							if d.fire_state > 5 then
								d.fire_state = 0
							end
							damage_of_player = damage_of_player
							local multitar = 1 + math.max(0,player:GetCollectibleNum(229)-1)
							local multi_pos = gdir * 20
							for mul_i = 1,multitar do
								local multi_posi = (mul_i-1) * multi_pos
								if d.fire_state == 0 then
									d.firedelay = player.MaxFireDelay * 0.5
									d.fire_delay_puni = player.MaxFireDelay * 0.25
									local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
									local length = (player.Velocity + gdir * 10):Length()
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,MakeVector(dirang) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + MakeVector(dirang + 90) * 60,MakeVector(dirang - 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity - MakeVector(dirang + 90) * 60,MakeVector(dirang + 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + MakeVector(dirang + 90) * 120,MakeVector(dirang - 60) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity - MakeVector(dirang + 90) * 120,MakeVector(dirang + 60) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
								elseif d.fire_state == 1 then
									d.firedelay = player.MaxFireDelay * 0.5
									d.fire_delay_puni = player.MaxFireDelay * 1
									local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
									local length = (player.Velocity + gdir * 10):Length()
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,MakeVector(dirang) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,MakeVector(dirang - 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,MakeVector(dirang + 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,MakeVector(dirang - 60) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,MakeVector(dirang + 60) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
								elseif d.fire_state == 2 then
									d.firedelay = player.MaxFireDelay * 0.6
									d.fire_delay_puni = player.MaxFireDelay * 1.4
									local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
									local length = (player.Velocity + gdir * 10):Length()
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized()/1000,damage_of_player,"AttackUp","AttackUp2",{source = nil,cooldown = 8,player = player,tearflags = player.TearFlags,color = player.TearColor,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									for i = 1, 7 do
										addeffe(function(params)
											local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,MakeVector(dirang - 120 + i * 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
										end,{},(i))
									end
								elseif d.fire_state == 3 then
									d.firedelay = player.MaxFireDelay * 0.4
									d.fire_delay_puni = player.MaxFireDelay * 1.8
									local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
									local length = (player.Velocity + gdir * 10):Length()
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + MakeVector(dirang + 90) * (60) + MakeVector(dirang) * (0) ,MakeVector(dirang - 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									local q2 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + MakeVector(dirang - 90) * (60) + MakeVector(dirang) * (0),MakeVector(dirang + 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
									for i = 1,9 do
										addeffe(function(params)
											local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + MakeVector(dirang + 90) * (55 + 5 * i) + MakeVector(dirang) * (25 - 5 *i) ,MakeVector(dirang - 30 - 5 * i) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
											local q2 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + MakeVector(dirang - 90) * (55 + 5 * i) + MakeVector(dirang) * (25 - 5 *i),MakeVector(dirang + 30 + 5 * i) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
										end,{},9 - i)
									end
								elseif d.fire_state == 4 then
									d.firedelay = player.MaxFireDelay * 0.6
									d.fire_delay_puni = player.MaxFireDelay * 2.4
									local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
									local length = (player.Velocity + gdir * 10):Length()
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized()/1000,damage_of_player/2,"SpinUp","SpinUp2",{source = nil,cooldown = 14,player = player,tearflags = player.TearFlags,color = player.TearColor,list = list,tech = player:HasCollectible(68)})
									for i = 1, 16 do
										addeffe(function(params)
											local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,MakeVector(dirang - 120 + i * 30) * length,damage_of_player,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,size = 7,size1 = Vector(1,3),size2 = 13,list = list})
										end,{},(i/2))
									end
								elseif d.fire_state == 5 then		--最后一击，类似肺的攻击。
									d.firedelay = player.MaxFireDelay * 4
									d.fire_delay_puni = player.MaxFireDelay * 0
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-40) + gdir:Normalized() * -30,player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list})
									local q2 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (20) + gdir:Normalized() * 10,player.Velocity * 2 + gdir * 20,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,size = 7,size1 = Vector(1,2),size2 = 13})
									local q3 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (40) + gdir:Normalized() * -30,player.Velocity + gdir * 10,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 5,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,size = 7,size1 = Vector(1,2),size2 = 13})
									local q4 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-20) + gdir:Normalized() * 10,player.Velocity * 2 + gdir * 20,damage_of_player * 0.4,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list})
									local rand_cnt = math.random(list.lung * 6 + 1) + 2
									local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized() * player.ShotSpeed,damage_of_player,"IdleUp","IdleUp2",{source = nil,cooldown = 50,player = player,tearflags = player.TearFlags,color = player.TearColor,thor = true,Accerate = 2,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = player:HasCollectible(68)})
									for i = 1, rand_cnt do
										local q1 = fire_dowhatknife(nil,multi_posi + player.Position + player.Velocity + MakeVector(math.random(36000)/360) * math.random(60),(player.Velocity + gdir * 10):Normalized() * player.ShotSpeed,damage_of_player * 2,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,Accerate = 1.5,size = 6,size1 = Vector(1,3),size2 = 13,list = list})
									end
								end
							
								if list.dr and list.dr > 0 and (d.fire_state == 1 or d.fire_state == 3) then		--博士与肺的配合。
									local dirang = (player.Velocity + gdir * 10):GetAngleDegrees()
									local length = (player.Velocity + gdir * 10):Length()
									local q3 = player:FireBomb(multi_posi + player.Position + player.Velocity + MakeVector(dirang) * 20,MakeVector(dirang) * 0.0001)
									if list.brimstone and list.brimstone > 0 then
										local q2 = player:FireBrimstone(Get_rotate(player.Velocity + gdir * 10):Normalized())
										local q4 = player:FireBrimstone(-Get_rotate(player.Velocity + gdir * 10):Normalized())
										q2.PositionOffset = Vector(0,0)
										q4.PositionOffset = Vector(0,0)
										if list.brimstone > 1 then
											q2:SetTimeout(25)
											q4:SetTimeout(25)
										else
											q2:SetTimeout(13)
											q4:SetTimeout(13)
										end
										q2.Parent = q3
										q4.Parent = q3
										q2.Position = q3.Position
										q4.Position = q3.Position
									end
								end
							end
						elseif weap == 13 then		--英灵剑：斩击与瞬移。可以与肺配合了。可以与博士配合了。
							if list.dr and list.dr > 0 then
								if d.fire_state > 1 then
									d.fire_state = 0
								end
							elseif d.fire_state > 0 then
								d.fire_state = 0
							end
							if d.fire_state == 0 then
								d.firedelay = player.MaxFireDelay * 2
								local q0 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized()/1000,damage_of_player/4,"SpinUp","SpinUp2",{source = nil,cooldown = 14,player = player,tearflags = player.TearFlags,color = player.TearColor,list = list,tech = player:HasCollectible(68),knife2 = player:HasCollectible(114)})
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player * 0.75,"IdleUp","IdleUp2",{source = nil,cooldown = 50,player = player,tearflags = player.TearFlags,color = player.TearColor,thor = true,knife = player:HasCollectible(114),epic = player:HasCollectible(168),Accerate = 2,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = player:HasCollectible(68)})
								if player:HasCollectible(118) and damage_of_player > player.Damage / 2 then
									d.firedelay = d.firedelay * 1.5
									local q2 = player:FireBrimstone( - (player.Velocity + gdir * 10):Normalized())
									q2.PositionOffset = Vector(0,0)
									if list.brimstone > 1 then
										q2:SetTimeout(25)
									else
										q2:SetTimeout(13)
									end
									q2.Parent = q1
									q2.Position = q1.Position
								end
								local multitar = 0
								if player:HasCollectible(229) or player:HasCollectible(558) then
									for i = 1,player:GetCollectibleNum(229) do
										if math.random(1000) > 500 then
											multitar = multitar + math.random(2)
										end
									end
									for i = 1,player:GetCollectibleNum(558) do
										if math.random(1000) > 700 then
											multitar = multitar + 1
										end
									end
								end
								for i = 1,multitar do
									fire_dowhatknife(nil,player.Position + player.Velocity,MakeVector(math.random(36000)/100) * 20 * player.ShotSpeed,damage_of_player * 0.75,"IdleUp","IdleUp2",{source = nil,cooldown = 50,player = player,tearflags = player.TearFlags,color = player.TearColor,thor = true,knife = player:HasCollectible(114),epic = player:HasCollectible(168),Accerate = 2,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = player:HasCollectible(68)})
								end
							elseif d.fire_state == 1 then
								d.firedelay = player.MaxFireDelay * 2
								for i = 1,4 do 
									local dir = (player.Velocity + gdir * 10):GetAngleDegrees() - 30 + 60/3 * (i-1)
									local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,MakeVector(dir) * 20 * player.ShotSpeed,damage_of_player/4,"SpinUp","SpinUp2",{source = nil,cooldown = 14,player = player,tearflags = player.TearFlags,color = player.TearColor,Accerate = 2,list = list,tech = player:HasCollectible(68),Explosive = 1})
								end
							end
							d.fire_delay_puni = player.MaxFireDelay * 0		--无后摇
						elseif weap == 10 then		--骨棒：瞬杀之术
							if d.fire_state > 2 then
								d.fire_state = 0
							end
							if d.fire_state == 1 then
								d.firedelay = player.MaxFireDelay * 0.5
								d.fire_delay_puni = player.MaxFireDelay * 5
								local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,player.Velocity + gdir * 10,damage_of_player/2,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = player:HasCollectible(68)})
							elseif d.fire_state == 2 then
								d.firedelay = player.MaxFireDelay * 5.5
								d.fire_delay_puni = player.MaxFireDelay * 0
								local q0 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized()/1000,damage_of_player/2,"SpinUp","SpinUp2",{source = nil,cooldown = 14,player = player,tearflags = player.TearFlags,color = player.TearColor,list = list,tech = player:HasCollectible(68),knife2 = player:HasCollectible(114)})
							elseif d.fire_state == 0 then
								d.firedelay = player.MaxFireDelay * 0.5
								d.fire_delay_puni = player.MaxFireDelay * 4.5
								local posi = room:GetRandomPosition(10)
								local n_entity = Isaac.GetRoomEntities()
								local n_enemy = getenemies(n_entity)
								if #n_enemy > 0 then
									if gdir:Length() < 0.05 then
										posi = n_enemy[math.random(#n_enemy)].Position
									else
										posi = player.Position + gdir * 100
										for i = 1,#n_enemy do
											local lg = (n_enemy[i].Position - player.Position):Length()
											local the = (n_enemy[i].Position - player.Position):GetAngleDegrees()
											local cal = math.sin(math.rad(the)) * lg
											if cal > 0 and (player:GetData().birthright_counter2 == nil or player:GetData().birthright_counter2 > cal) then
												player:GetData().birthright_counter2 = cal
												posi = n_enemy[i].Position
											end
											player:GetData().birthright_counter2 = nil
										end
									end
								else
									if gdir:Length() > 0.05 then
										posi = player.Position + gdir * 100
									end
								end
								kill_thenm_all(player,posi,player.Damage * 0.5,list)
								kill_thenm_all2(player,posi,player.Damage * 1.5,list,7,150)
							end
						elseif weap == 11 then
							if d.fire_state > 0 then
								d.fire_state = 0
							end
						elseif weap == 12 then
							if d.fire_state > 0 then
								d.fire_state = 0
							end
						end
					end
				end
				d.fire_state = d.fire_state + 1
				gdir = gggdir
			end
			
			if player:HasCollectible(316) then 		--诅咒之眼：5次快速攻击，那些延迟累加并在之后计算。
				if d.cursed_delay == nil or d.cursed_counter == nil then
					d.cursed_delay = 0 
					d.cursed_counter = 0
				end
				if d.firedelay > 0 and d.cursed_counter < 5 then --and d.cursed_delay < 240 then
					d.cursed_delay = d.cursed_delay + d.firedelay - 1
					if d.fire_delay_puni then
						d.cursed_delay = d.cursed_delay + d.fire_delay_puni
						d.fire_delay_puni = 0
					end
					d.firedelay = 3
					d.cursed_counter = d.cursed_counter + 1
				end
				if d.cursed_counter == 5 then --or d.cursed_delay > 240 then
					d.firedelay = d.cursed_delay * 0.7
					d.cursed_delay = 0
					d.cursed_counter = 0
				end
			end
		end
		
		if gdir:Length() > 0.05 and player:HasCollectible(152) then		--科技2
			if d.tech_2_firedelay == nil then
				d.tech_2_firestate = 0
				d.tech_2_firedelay = 0
			end
			if d.tech_2_firestate > 4 then
				d.tech_2_firestate = 0
			end
			if d.tech_2_firedelay < 0 then
				local dmg_float = 0.05
				if d.tech_2_firestate == 0 then
					local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,4),size2 = 13})	--科技
				elseif d.tech_2_firestate == 1 then
					local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-10),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
					local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (10),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
				elseif d.tech_2_firestate == 2 then
					local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-20),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
					local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (0),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 1,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,4),size2 = 13})
					local q3 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (20),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
				elseif d.tech_2_firestate == 3 then
					local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-20),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
					local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (10),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
					local q3 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (20),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
					local q4 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-10),player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
				elseif d.tech_2_firestate == 4 then
					local q1 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-20) + gdir:Normalized() * -30,player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
					local q2 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (10) + gdir:Normalized() * 10,player.Velocity * 2 + gdir * 100,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
					local q3 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (20) + gdir:Normalized() * -30,player.Velocity + gdir * 50,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true,size = 7,size1 = Vector(1,2),size2 = 13})
					local q4 = fire_dowhatknife(nil,player.Position + player.Velocity + Get_rotate(gdir):Normalized() * (-10) + gdir:Normalized() * 10,player.Velocity * 2 + gdir * 100,damage_of_player * dmg_float,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = gdir * 3,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,list = list,tech = true})
				end
				d.tech_2_firedelay = 5
				d.tech_2_firestate = d.tech_2_firestate + 1
			end
			d.tech_2_firedelay = d.tech_2_firedelay - 1
		end
		
		if gdir:Length() > 0.05 and player:HasCollectible(244) then		--科技.5
			if math.random(1000) > 950 and d.firedelay/2 > math.random(math.floor(player.MaxFireDelay) + 1) then
				local q1 = fire_dowhatknife(nil,player.Position + player.Velocity,(player.Velocity + gdir * 10):Normalized() * 20 * player.ShotSpeed,damage_of_player * 0.5,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,Accerate = 2.5,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = player:HasCollectible(68)})
				local q2 = player:FireTechLaser(player.Position,1,-(player.Velocity + gdir * 10),false,true)
				q2.PositionOffset = Vector(0,0)
				q2:GetData().followParent = q1
				q2:SetTimeout(13)
				local random_cnt = math.random(1000)
				local buff_list = {BitSet128(1<<2,0),BitSet128(1<<16,0),BitSet128(1<<30,0),BitSet128(1<<19,0),BitSet128(1<<33,0),BitSet128(0,1<<5)}
				for i = 1,6 do 
					if math.random(1000) > 800 then
						q2:AddTearFlags(buff_list[i])
					end
				end
			end
		end
		
		if d.firedelay > -10 then
			d.firedelay = d.firedelay - 1
		end
		if player:HasCollectible(316) and d.firedelay < -3 and d.cursed_delay and d.cursed_delay > 0 then		--诅咒之眼
			d.cursed_delay = d.cursed_delay - 1
		end	
		if player:HasCollectible(316) and d.cursed_counter and d.cursed_counter == 0 and d.firedelay < 0 then
			if (d.cursed_counterdelay == nil or d.cursed_counterdelay == false)  then
				player:GetData().is_setting_color = true
				player:SetColor(Color(1,1,1,1,1,1,1),10,99,true,false)
				addeffe(function(para)
						player:GetData().is_setting_color = false
						end,{player = player},10)
				d.cursed_counterdelay = true
			end
		else
			d.cursed_counterdelay = false
		end
		
		Debuglist[10] = d.firedelay
	end
end

function CharacterMeus:OnLinkUpDate(ent)
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	local d = ent:GetData()
	local s = ent:GetSprite()
	if ent.Variant == enums.Entities.MeusLink then
		if s:IsFinished("Link") or s:IsFinished("Link2") then
			ent:Remove()
		end
	end
end

-------
--[[

	还要做的内容：
	狗身、寄生虫、骨裂
	妈刀+科技X、英灵剑+科技X。
	弹弹弹、跳石	
	独角兽、金牛的无敌。
	多维宝宝（不一定做）
	双瞳之类增大眼泪大小的道具。
	
	神庙逃亡中的发型？
	
	可以增加的特效：
	达摩剑：被飞刀标记的敌人头上将生成一把达摩剑。生命低于10%时将掉落并斩杀。
	阴阳：伤害*85%。被阴、阳剑命中的敌人将会被标记。受到另一剑的伤害时，该伤害会爆发出来。
	两种火的音效：已完成
	冰的特效：附带减速
	三圣颂的特效。
	神性的特效。
	
	
	死眼、.5、血块、小圣心、科技2、多重射击、洛基角和后眼已完成。

	考虑小青的攻击方式与眼泪特效的配合。
	0、1：自带双穿，没效果。
	2.弯勺：已完成。
	3.减速：有效果。
	4.中毒：有效果。
	5.石化：有效果。(后不再列出。
	6.骨裂
	7.煤块：已完成。
	8.镜像：已完成。
	9.大眼：已完成。
	10.弯虫：已完成。
	11.中猫套：
	12.吐根：已完成。
	13.魅惑：
	14.眩晕：
	15.掉落红心？
	16.小星球：已完成。
	17.反重力：已完成。
	18.狗身：没做。
	19.橡胶：
	20.恐惧：没效果？
	21.突眼：已完成。
	22.燃烧：
	23.黑磁铁：
	24.击退：
	25.变大变小虫：无效。
	26.旋涡：已完成。
	27.扁平：
	28.伤心炸弹
	29.便便炸弹
	30.方波：已完成。
	31.神性：
	32.吉仕：
	33.神秘液体：已完成。
	34.泪盾：已完成。
	35.炸弹
	36.炸弹
	37.炸弹
	38.连续集：已完成。
	39.圣光：
	40.掉钱
	41.掉黑心
	42.牵引光束：无效。
	43.缩小
	44.贪婪头
	45.十字雷
	46.黑蛇：已完成
	47.青光眼(永久眩晕):
	48.鼻涕
	49.中猫套2：已完成
	50.硫酸：
	51.骨裂
	52.彼列：已完成。
	53.点金：
	54.黑针
	55.天梯
	56.黑角
	57.科技0：没做
	58.眼球：没做
	59.噬泪：没做
	60.三圣颂：
	61.跳石
	62.血泪
	63.鲍勃的膀胱？

	64.拳头
	65.冰：冰居然没有用！！
	66.磁石
	67.烂番茄
	68.神秘之眼：已完成。
	69.真·环绕
	70.石头眼泪
	71.脑虫：已完成。
	72.血炸弹
	73.大肠杆菌
	74.倒位倒吊人
	75.硫磺火炸弹
	76.黑洞眼
	77.毛霉菌
	78.鬼炸弹
	79.掉落塔罗牌
	80.掉落符文
	81.传送
	
	114.婴儿
	115.roll石头？
	116.妈妈践踏？
	117.
	118.D10
	119.超大炸弹
	120.更多内脏物
	121.镭射自动变色
	122.远程控制（炸弹爆炸）
	123.血田
	124.黑暗艺术？
	125.金炸弹
	126.快速炸弹
	127.鲁科
	
	l local player = Game():GetPlayer(0);player.Damage = 0;player.TearFlags = BitSet128((1<<25),0);
-]]
-------

function CharacterMeus:QingExit()
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	for playerNum = 1, Game():GetNumPlayers() do
		local player = Game():GetPlayer(playerNum - 1)
		if player:GetName() == "SP.W.Qing" then
			local d = player:GetData()
			cont = #d.Air
			for i = 1,cont do
				d.Air[cont - i + 1]:Remove()
				d.Air[cont - i + 1] = nil
			end
			print(#d.Air)
		end
	end
end

function CharacterMeus:OnNewRoom()			--没有办法。除非把服装黏在脑袋上。
	local room = Game():GetRoom()
	local level = Game():GetLevel()
	for playerNum = 1, Game():GetNumPlayers() do
		local player = Game():GetPlayer(playerNum - 1)
		if player:GetName() == "W.Qing" then
			if room:HasCurseMist() == true then
				player:AddNullCostume(Qingrobes)
				Debuglist[5] = Debuglist[5] + 1
			end
		end
	end
end

CharacterMeus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, CharacterMeus.OnQingRoom)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, CharacterMeus.UpdateMeusNil,ID_EFFECT_MeusNIL)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, CharacterMeus.OnBarUpdate,enums.Entities.Qing_Bar)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, CharacterMeus.UpdateMeusTarget,ID_EFFECT_MeusFetus)
CharacterMeus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CharacterMeus.OnEntityDamage)
CharacterMeus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CharacterMeus.OnQingDamage, EntityType.ENTITY_PLAYER)
CharacterMeus:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, CharacterMeus.OnAirUpdate,QingsAirs)
CharacterMeus:AddCallback(ModCallbacks.MC_PRE_KNIFE_COLLISION, CharacterMeus.OnWQingKnifeCollision)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, CharacterMeus.OnWQingLaserUpdate)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, CharacterMeus.OnWQingKnifeUpdate)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, CharacterMeus.OnQingUpdate)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, CharacterMeus.OnWQingUpdate)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, CharacterMeus.OnLinkUpDate,enums.Entities.MeusLink)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, CharacterMeus.OnMarkUpdate,30)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, CharacterMeus.OnMarkUpdate,QingsMarks)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, CharacterMeus.OnMarkUpdate,153)
CharacterMeus:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, CharacterMeus.QingExit)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, CharacterMeus.Init)
CharacterMeus:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, CharacterMeus.Exit)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, CharacterMeus.OnPlayerInit)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_UPDATE, CharacterMeus.OnDelayUpdate)
CharacterMeus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, CharacterMeus.OnQingInit)
--------重复调用的时刻--------