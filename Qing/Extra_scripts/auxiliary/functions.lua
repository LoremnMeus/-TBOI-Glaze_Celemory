local funct = {}

local QingsAirs = Isaac.GetEntityVariantByName("QingsAir")
local MeusLink = Isaac.GetEntityVariantByName("MeusLink")
local QingsMarks = Isaac.GetEntityVariantByName("QingsMark")
local StabberKnife = Isaac.GetEntityVariantByName("StabberKnife")
local MeusSword = Isaac.GetEntityVariantByName("MeusSword")
local ID_EFFECT_MeusFetus = Isaac.GetEntityVariantByName("MeusFetus")
local ID_EFFECT_MeusRocket = Isaac.GetEntityVariantByName("MeusRocket")
local ID_EFFECT_MeusNIL = Isaac.GetEntityVariantByName("MeusNil")

function funct.GetPlayers()
	local players = {}
	for i=0,Game():GetNumPlayers()-1 do
		local player = Game():GetPlayer(i)
		players[i] = player
	end
	return players
end
function funct.MakeBitSet(i)
	if i >= 64 then
		return BitSet128(0,1<<(i-64))
	else
		return BitSet128(1<<(i),0)
	end
end function funct.bitset_flag(x,i)	--获取x第i位是否含有1。
	if i >= 64 then
		return (x & BitSet128(0,1<<(i-64)) == BitSet128(0,1<<(i-64)))
	else
		return (x & BitSet128(1<<(i),0) == BitSet128(1<<(i),0))
	end
end
function funct.random_1()
	return math.random(1000)/1000
end
function funct.Count_Flags(x)
	local ret = 0
	for i = 0, math.floor(math.log(x)/math.log(2)) +1 do
		if x%2==1 then
			ret = ret + 1
		end
		x = (x-x%2)/2
	end
	return ret
end
function funct.Get_Flags(x,fl)	--从第0位开始计算flag
	--Debuglist[1] = math.floor(x/(1<<fl))
	if (math.floor(x/(1<<fl)) %2 == 1) then
		return true
	end
	return false
end
function funct.Get__cos(vec)		--获取Vector类型的角度
	local t = (vec + Vector(vec:Length(),0)):Length()/2
	local q = t/vec:Length()
	return 1 - 2 * q * q
end
function funct.Get__sin(vec)		--获取Vector类型的角度
	local t=(vec + Vector(0,vec:Length())):Length()/2
	q = t/vec:Length()
	return 1 - 2 * q * q
end
function funct.Get__trans(t)			--获取cos对应的sin
	if t > 1 or t < -1 then
		return 0
	end
	return math.sqrt(1-t*t) 
end
function funct.Get_rotate(t)		--接收一个vector，获取旋转90度的vector
	return Vector(-t.Y,t.X)
end
function funct.plu_s(v1,v2)
	return v1.X*v2.X+v1.Y*v2.Y
end
function funct.MakeVector(x)
	return Vector(math.cos(math.rad(x)),math.sin(math.rad(x)))
end
function funct.AddColor(col_1,col_2,x,y)		--加权相加。
	return Color(col_1.R * x + col_2.R * y,col_1.G * x+ col_2.G * y,col_1.B * x+ col_2.B * y,col_1.A * x+ col_2.A * y,col_1.RO * x+ col_2.RO * y,col_1.GO * x+ col_2.GO * y,col_1.BO * x+ col_2.BO * y)
end
function funct.TearsUp(firedelay, val)	--thx
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val
    return math.max((30 / newTears) - 1, -0.99)
end
function funct.getdir(player)		--修正后，可以获得八个方向了！
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
function funct.getmov(player)
	if player == nil then
		print("Wrong player in function::getmov()")
		return Vector(0,0)
	end
	local ret = player:GetMovementInput()
	if ret:Length() > 0.05 then
		ret = ret / ret:Length()
	end
	return ret
end
local for_set_for_ggdir = {tim = 0,dir = Vector(0,0),ignore_marked = false}
function funct.ggdir(player,ignore_marked)		--这个函数忽略了实际上无视行动的策略。例如：某种无敌。
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
	local dir = funct.getdir(player)
	for_set_for_ggdir.dir = dir
	return dir
end
function funct.ggmov_dir_is_zero(player,SPQinghelper)		--传入player与一个辅助参数。
	if SPQinghelper == nil then SPQinghelper = false end
	if player:AreControlsEnabled() == false and SPQinghelper == true then
		return false
	end
	if (player:IsExtraAnimationFinished() == false or player.Visible == false) and SPQinghelper == true then
		return false
	end
	local dir = funct.getdir(player)
	local mov = funct.getmov(player)
	return (dir:Length() < 0.05 and mov:Length() < 0.05)
end
function funct.getpickups(ents,ignore_items)
	local pickups = {}
    for _, ent in ipairs(ents) do
        if ent.Type == 5 and (ignore_items == false or ent.Variant ~= 100) then
            pickups[#pickups + 1] = ent
        end
    end
	return pickups
end
function funct.getenemies(ents)
	local enemies = {}
    for _, ent in ipairs(ents) do
        if ent:IsVulnerableEnemy() and ent:IsActiveEnemy() and not ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
            enemies[#enemies + 1] = ent
        end
    end
	return enemies
end
function funct.isenemies(ent)
	if ent:IsVulnerableEnemy() and ent:IsActiveEnemy() and not ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
		return true
	end
	return false
end
function funct.getothers(ents,x,y,z)
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
function funct.getmultishot(cnt1,cnt2,id,cnt3)		--cnt1:总数量；cnt2：巫师帽数量；cnt3：宝宝套
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
function funct.trychangegrid(x)
	if x == nil or x.CollisionClass == nil then
		return
	end
	x.CollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
end
function funct.getdisenemies(enemies,pos,rang)
	local ret = nil
	local ran = rang
	if ran == nil then
		ran = 1000
	end
	for _,ent in ipairs(enemies) do
		if ent ~= nil and (ent.Position - pos):Length()< ran then
			ran = (ent.Position - pos):Length()
			ret = ent
		end
	end
	return ret
end
function funct.getrandenemies(enemies)
	if #enemies == 0 then
		return nil
	else
		return enemies[math.random(#enemies)]
	end
end
function funct.getmultishots(player,allowrand)
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
function funct.check_rand(luck,maxum,zeroum,threshold)		--幸运；上限（0-100）；下限；幸运阈值
	local rand = math.random(10000)/10000
	if rand * 100 < math.exp(math.min(luck/5,threshold/5))/math.exp(threshold/5) * (maxum - zeroum) + zeroum then
		--Debuglist[14] = rand * maxum
		return true
	else
		return false
	end
end
function funct.getQingshots(player,allowrand)
	local ret = funct.getmultishots(player,allowed)
	if ret == nil then
		return 1
	end
	ret = ret + player:GetCollectibleNum(619)*3		--长子权
	return ret
end
function funct.check(ent)
	return ent ~= nil and ent:Exists() and (not ent:IsDead())
end
function funct.issolid(grident)
	local list = {
		2,3,4,5,6,11,12,13,14,21,22,24,25,26,27
	}
	for i = 1,#list do
		if grident:GetType() == list[i] then
			return grident.CollisionClass ~= 0
		end
	end
	return false
end
function funct.copy(tbl)
    local ret = {}
    for key, val in pairs(tbl) do
        ret[key] = val
    end
    return ret
end
function funct.launch_Missile(position, velocity, dmg, targ, params)
    local q1 = Isaac.Spawn(EntityType.ENTITY_EFFECT, ID_EFFECT_MeusFetus, 0, position, velocity, nil)
    local d = q1:GetData()
    local s = q1:GetSprite()
    s:Play("Blink", true)

    d.Boss = targ
    q1.Parent = targ
    d.BossMissile = true
    d.RocketsFired = 0
	d.Damage = dmg
	
    d.MissileParams = funct.copy(params)
	return q1
end
function funct.fire_nil(position,velocity,params)		--可以传入的是cooldown和player，其他参数将在之后添加。
	if position == nil or velocity == nil then
		return nil
	end
	local q1 = Isaac.Spawn(EntityType.ENTITY_EFFECT, ID_EFFECT_MeusNIL, 0, position, velocity, nil)
	local d = q1:GetData()
    local s = q1:GetSprite()
    s:Play("Idle", true)
	
	if params.cooldown then
		d.removecd = params.cooldown
	else
		d.removecd = 60
	end
	if params.player then
		d.player = params.player
	end
	d.Params = funct.copy(params)
	return q1
end
function funct.fire_knife(position,velocity,dmg,targ,params)	--p·arams可以传入：cooldown，player，tearflags，Color,Explosive
	local q1 = Isaac.Spawn(EntityType.ENTITY_EFFECT, ID_EFFECT_MeusNIL, 0, position, velocity, nil)
	local d = q1:GetData()
    local s = q1:GetSprite()
    s:Play("Idle", true)
	
	q1.Parent = targ
	if params.cooldown then
		d.removecd = params.cooldown
	else
		d.removecd = 1000
	end
	if params.player then
		d.player = params.player
	end
	d.Damage = dmg
    d.Params = funct.copy(params)
	
	local q2 = Isaac.Spawn(EntityType.ENTITY_KNIFE, 0, 0, Vector(2000,0),velocity:Normalized(), nil):ToKnife()
	local s = q2:GetSprite()
	s:Play("Idle")
	q2.Parent = q1
	q1.Child = q2
	q2.CollisionDamage = dmg
	q2.RotationOffset = velocity:GetAngleDegrees()
	if params.player then
		q2:GetData().player = params.player
	end
	if params.Explosive and params.Explosive > 0 then
		q2:GetData().Explosive_cnt = params.Explosive
	end
	if params.tearflags then
		q2.TearFlags = params.tearflags
	end
	if params.Color then
		q2:SetColor(params.Color,3,99,false,false)
	end
	return q2
end
function funct.fire_lung_Laser(params)	--params传入：player/Direction/Position/delang/Length/loop_func/multi_cnt/multi_shot/cool_down
	if params.player == nil then
		params.player = Game():GetPlayer(0)
	end
	if params.Direction == nil or params.Position == nil then
		return
	end
	if params.delang == nil then
		params.delang = 1
	end
	if params.Length == nil then
		params.Length = 30
	end
	if params.length == nil then
		params.length = 0
	end
	--Debuglist[5] = Debuglist[5] + 1
	local player = params.player
	local actu_Dis = params.Length + math.random(10 * params.length + 1)/5 - params.length
	if actu_Dis < 5 then
		actu_Dis = 5
	end
	local q1 = player:FireTechLaser(params.Position,1,params.Direction,false,true)
	q1:SetMaxDistance(actu_Dis)
	if params.loop_func and params.multi_cnt and params.multi_cnt > 0 then
		if params.multi_shot == nil then
			params.multi_shot = 3
		end
		if params.cool_down == nil then
			params.cool_down = 3
		end
		--Debuglist[7] = Debuglist[7] + 1
		params.multi_cnt = params.multi_cnt - 1
		params.Position = params.Position + params.Direction * actu_Dis
		local rand_cnt1 = math.random(params.multi_shot) + 1
		local ang = params.Direction:GetAngleDegrees() - rand_cnt1 * params.delang / 2
		for i = 1,rand_cnt1 do
			params.Direction = funct.MakeVector(ang + i * params.delang)
			local trans = funct.copy(params)
			addeffe(params.loop_func,trans,params.cool_down)
		end
	end
end
function funct.fire_Sword(position,velocity,dmg,targ,params)
	
	if true then
		local q1 = funct.fire_knife(position,velocity,dmg,targ,params)		--???
		local s = q1:GetSprite()
		if params.Tech then
			s:Load("gfx/008.011_tech sword.anm2", true)
		else
			s:Load("gfx/008.010_spirit sword.anm2", true)
		end
		if params.Qing then
			s:Load("gfx/008.2335_NormalSword.anm2", true)
		end
		s:Play("SpinRight",true)
		if true then		--大小控制
			local tosetsize = {size1 = 80,size2 = Vector(1,1),size3 = 5,scale = Vector(1,1)}
			
			if params.size and params.size2 and params.size1 then
				tosetsize.size1 = params.size
				tosetsize.size2 = params.size1
				tosetsize.size3 = params.size2
			end
			if params and params.list and params.list.pol and params.list.pol ~= 0 then
				local pol = params.list.pol
				tosetsize.size1 = tosetsize.size1 * (1 + pol)
				tosetsize.size2 = Vector(tosetsize.size2.X * 2,tosetsize.size2.Y * 2)
				tosetsize.size3 = tosetsize.size3 * (1 + pol)
				tosetsize.scale = Vector(2,(1 + pol))
			end
			if params and params.list and ((params.list.soy and params.list.soy ~= 0) or (params.list.soy2 and params.list.soy2 ~= 0))  then
				local rang = 1
				if (params.list.soy and params.list.soy ~= 0) then
					rang = 0.25
				end
				if (params.list.soy2 and params.list.soy2 ~= 0) then
					rang = 0.35
				end
				local cho_counter = params.list.cho_counter
				tosetsize.size1 = tosetsize.size1 * rang
				tosetsize.size3 = tosetsize.size3
				tosetsize.scale = tosetsize.scale * rang
			end
			if params and params.list and params.list.hae and params.list.hae ~= 0 then
				local hae = params.list.hae
				tosetsize.size1 = tosetsize.size1 * (1 + hae * 0.4)
				tosetsize.size3 = tosetsize.size3 
				tosetsize.scale = tosetsize.scale * (1 + hae * 0.4)
			end
			
			if tosetsize then
				q1:SetSize(tosetsize.size1,tosetsize.size2,tosetsize.size3)
				s.Scale = tosetsize.scale
			end
		end
		return q1
	end
end
function funct.fire_dowhatknife(variant,position,velocity,dmg,dowhatstring1,dowhatstring2,params)		--pos，vel，dmg，targ，params
	local var = StabberKnife
	if variant ~= nil then
		var = variant
	end
	if position == nil or velocity == nil or dowhatstring1 == nil then	--直接解除
		return
	end
	if dowhatstring2 == nil then
		dowhatstring2 = dowhatstring1
	end
	local player = nil
	if params.player then
		player = params.player
	end
	local source = params.source
	local q1 = nil
	local coold = 8
	if params.cooldown then
		coold = params.cooldown
	end
	if params and params.list and params.list.sec and params.list.sec > 0 then
		if params.epic and params.epic == true then
			params.sec_effect2 = true		--史诗、剖腹产有特殊配合。
			dmg = dmg * 0.75
		else
			coold = coold * (3 + math.floor((params.list.sec - 1))) + 20
			--params.continueafter = true
			params.sec_effect = true
		end
	end
	if params and params.list and params.list.ludo and params.list.ludo > 0 then
		coold = coold * (2 + math.floor((params.list.ludo - 1)/3))
		params.continueafter = true
	end
	if params and params.knife2 then
		coold = coold * 4
		params.continueafter = true
	end
	if source == nil then
		q1 = funct.fire_nil(position - velocity * 3,velocity,{cooldown = coold})
		source = q1
		source:GetData().Params = params
	end
	local q1 = Isaac.Spawn(8,var,0,Vector(2000,0),velocity,player):ToKnife()		--q1被重新赋值了！！
	local s2 = q1:GetSprite()
	local d2 = q1:GetData()
	q1.Parent = source
	source.Child = q1
	q1.RotationOffset = velocity:GetAngleDegrees()
	if player then
		d2.player = player
		d2.tearflags = player.TearFlags
	end
	if params.tearflags then
		d2.tearflags = params.tearflags
		if params.tearflags & BitSet128(1<<2,0) == BitSet128(1<<2,0) and dowhatstring1 == "IdleUp" then		--弯勺
			source:GetData().Params.Homing = true
			source:GetData().Params.HomingSpeed = 5
			--source:GetData().Params.HomingDistance = 30
		end
		if params.tearflags & BitSet128(1<<52,0) == BitSet128(1<<52,0) and params.allow_belial == nil or params.allow_belial == true then
			d2.belial = 1
		end
		
	end
	if params and params.list and params.list.divi and params.list.divi ~= 0 then		--分裂
		d2.tearflags = d2.tearflags | BitSet128(1<<6,0)		--不知道为什么没有办法找到。
	end
	if params and params.list and params.list.para and params.list.para ~= 0 then		--中猫套
		d2.tearflags = d2.tearflags | BitSet128(1<<49,0)		--不知道为什么没有办法找到。
	end
	if params and params.room then
		d2.nowroom = params.room
	else
		d2.nowroom = Game():GetLevel():GetCurrentRoomIndex()
	end
	if params and params.knife2 and params.knife2 == true then
		if source ~= nil then
			source:AddVelocity(velocity:Normalized() * 10)
			if source:GetData().Params == nil then
				source:GetData().Params = {}
			end
			source:GetData().Params.Accerate = -1
		end
	end
	if params and params.Explosive == nil and params.list then
		params.Explosive = params.list.ipec
	end
	if params and params.Explosive and params.Explosive > 0 then
		d2.Explosive_cnt = params.Explosive
		params.bomb_knife_flag = BitSet128(0,0)
		local bfl = player:GetBombFlags()
		for i = 1,#bomb_effe_list do
			local list_1 = bomb_effe_map[i]
			if bitset_flag(bfl,bomb_effe_list[i]) and funct.check_rand(player.Luck,list_1[1],0,list_1[2]) == true then
				--Debuglist[12] = bomb_effe_list[i]
				params.bomb_knife_flag = params.bomb_knife_flag | funct.MakeBitSet(bomb_effe_list[i])
			end
		end
	end
	if params and params.list and params.list.deadeye and params.list.deadeye > 0 then
		d2.deadeye = 1		--只有一次机会。
	end
	if params and params.repel and params.repel:Length() > 0.005 and params.list and params.list.repel_effect and params.list.repel_effect > 0 then		--附加的击退效果。
		params.repel = params.repel * (1 + params.list.repel_effect/10)
	end
	
	if params.color then
		local fadeout = false
		if params.color_fadeout then
			fadeout = params.color_fadeout
		end
		local duration = coold + 2
		if params.color_dur then
			duration = params.color_dur
		end
		q1:SetColor(params.color,duration,99,fadeout,false)
	end
	
	if true then		--大小控制
		local tosetsize = {size1 = 5,size2 = Vector(1,1),size3 = 5,scale = Vector(1,1)}
		
		if params.size and params.size2 and params.size1 then
			tosetsize.size1 = params.size
			tosetsize.size2 = params.size1
			tosetsize.size3 = params.size2
		end
		if params and params.list and params.list.knife and params.list.knife ~= 0 then
			local knife = params.list.knife
			tosetsize.size1 = tosetsize.size1 * (2 + knife)
			tosetsize.size2 = Vector(0.3,2)
			tosetsize.size3 = tosetsize.size3 * (1 + knife)
		end
		if params and params.list and params.list.pol and params.list.pol ~= 0 then
			local pol = params.list.pol
			tosetsize.size1 = tosetsize.size1 * (1 + pol)
			tosetsize.size2 = Vector(tosetsize.size2.X * 2,tosetsize.size2.Y * 2)
			tosetsize.size3 = tosetsize.size3 * (1 + pol)
			tosetsize.scale = Vector(2,(1 + pol))
		end
		if params and params.list and params.list.cho and params.list.cho ~= 0 and params.list.cho_counter then
			local cho_counter = params.list.cho_counter
			tosetsize.size1 = tosetsize.size1 * (0.25 + cho_counter)
			tosetsize.size3 = tosetsize.size3
			tosetsize.scale = tosetsize.scale * (0.15 + cho_counter)
			--Debuglist[9] = tosetsize.scale:Length()
		end
		if params and params.list and ((params.list.soy and params.list.soy ~= 0) or (params.list.soy2 and params.list.soy2 ~= 0))  then
			local rang = 1
			if (params.list.soy and params.list.soy ~= 0) then
				rang = 0.25
			end
			if (params.list.soy2 and params.list.soy2 ~= 0) then
				rang = 0.35
			end
			local cho_counter = params.list.cho_counter
			tosetsize.size1 = tosetsize.size1 * rang
			tosetsize.size3 = tosetsize.size3
			tosetsize.scale = tosetsize.scale * rang
			Debuglist[9] = tosetsize.scale:Length()
		end
		if params and params.list and params.list.hae and params.list.hae ~= 0 then
			local hae = params.list.hae
			tosetsize.size1 = tosetsize.size1 * (1 + hae * 0.4)
			tosetsize.size3 = tosetsize.size3 
			tosetsize.scale = tosetsize.scale * (1 + hae * 0.4)
		end
		
		if tosetsize then
			q1:SetSize(tosetsize.size1,tosetsize.size2,tosetsize.size3)
			s2.Scale = tosetsize.scale
		end
	end
	
	if params.tech and params.tech == true then		--换皮肤
		s2:Load("gfx/008.2335_stabberknife_tech.anm2", true)		--其实有空可以试试ReplaceSpritesheet (integer LayerId, string PngFilename)。
	end
	if params and params.list and params.list.dual and params.list.dual > 0 then
		if player:GetData().Dual_cnt == nil then
			player:GetData().Dual_cnt = 0
		end
		if player:GetData().Dual_cnt == 1 then
			s2:Load("gfx/008.2335_stabberknife_yang.anm2", true)
		else
			s2:Load("gfx/008.2335_stabberknife_yin.anm2", true)
		end
		player:GetData().Dual_cnt = 1 - player:GetData().Dual_cnt
	end
	if params and params.list and params.list.ice and params.list.ice > 0 then
		s2:Load("gfx/008.2335_stabberknife_ice.anm2", true)
	end
	if params and params.list and params.list.damo and params.list.damo > 0 then
		s2:Load("gfx/008.2335_stabberknife_damo.anm2", true)
		--s2:ReplaceSpritesheet(0,"gfx/effects/Damo_Stabknife.png")
		--s2:LoadGraphics()
	end
	if params and params.list and params.list.dea and params.list.dea > 0 then
		s2:Load("gfx/008.2335_stabberknife_death.anm2", true)
	end
	if params and params.list and params.list.spear and params.list.spear > 0 then
		s2:Load("gfx/008.2335_stabberknife_spear.anm2", true)
	end
	if params and params.list and params.list.bone and params.list.bone > 1 then
		s2:Load("gfx/008.2335_stabberknife_bone.anm2", true)
	end
	if params and params.list and params.list.tri and params.list.tri > 0 then
		s2:Load("gfx/008.2335_stabberknife_trisagon.anm2", true)
	end
	if params and params.list and params.list.godhead and params.list.godhead > 0 then
		s2:Load("gfx/008.2335_stabberknife_godhead.anm2", true)
	end
	if params and params.list and params.list.finger and params.list.finger > 0 then
		s2:Load("gfx/008.2335_stabberknife_finger.anm2", true)
	end
	
	if params and params.list and params.list.redfire and params.list.redfire > 0 then		--两种辣椒的特效。
		if math.random(1200)/1000 * (math.exp(11/5) + 2) < math.exp(math.max(-3/5,math.min(11/5,player.Luck/5))) + 2.01 then
			dmg = dmg * 2
			s2:Load("gfx/008.2335_stabberknife_redfire.anm2",true)
			d2.fire_sound_effect = true
		end
	end
	if params and params.list and params.list.bluefire and params.list.bluefire > 0 then
		if math.random(1200)/1000 * (math.exp(11/5) + 2) < math.exp(math.max(-3/5,math.min(11/5,player.Luck/5))) + 2.01 then
			dmg = dmg * 3
			s2:Load("gfx/008.2335_stabberknife_bluefire.anm2",true)
			d2.fire_sound_effect = true
		end
	end
	
	
	if params.Entitycollision then		--似乎没啥用
		q1.EntityCollisionClass = params.Entitycollision
	end
	
	q1.CollisionDamage = dmg
	local ang = velocity:GetAngleDegrees() + 360
	s2:Play(dowhatstring1,true)			--呜呜这样做就好了吧……
	if q1.RotationOffset < -90.0001 or q1.RotationOffset > 90.0001 then
		s2:Play(dowhatstring2,true)
	end
	
	d2.damage = dmg
	d2.params = funct.copy(params)
	d2.TimeOut = coold		--调用了自动删除装置。
	return q1
end
function funct.thor_attack(player,list)		--飞雷神！！具有三种攻击方式。目前只做了一种的说。
	local room = Game():GetRoom()
	if player == nil or player:GetData().thor_target == nil then
		return
	end
	if list.backstab == nil or list.backstab == 0 then
		local targ = player:GetData().thor_target
		local loop_cnt = 10
		if (targ.Position - player.Position):Length() < 100 then
			loop_cnt = 5
		end
		if (targ.Position - player.Position):Length() < 40 then
			loop_cnt = 3
		end
		player:GetData().is_setting_color = true
		player:SetColor(Color(-1,-1,-1,1,0,0,0),loop_cnt,99,false,true)
		local dir = (targ.Position - player.Position):Normalized()
		for i = 1,loop_cnt do				
			addeffe(function(params)
				local player = params.player
				local position = params.position
				if player == nil or position == nil then
					return
				end
				local dirang = (player.Velocity + dir * 10):GetAngleDegrees()
				local length = (player.Velocity + dir * 10):Length()
				local q1 = funct.fire_dowhatknife(nil,player.Position + dir * 30 + player.Velocity + funct.MakeVector(dirang + 90) * 60 + funct.MakeVector(dirang) * (-20),funct.MakeVector(dirang - 30) * length,player.Damage/10,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = dir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,tech = player:HasCollectible(68),list = funct.copy(list),thor_effe = true})
				local q2 = funct.fire_dowhatknife(nil,player.Position + dir * 30 + player.Velocity + funct.MakeVector(dirang - 90) * 60 + funct.MakeVector(dirang) * (-20),funct.MakeVector(dirang + 30) * length,player.Damage/10,"StabDown","StabDown2",{source = nil,player = player,tearflags = player.TearFlags,color = player.TearColor,repel = dir * 10,Entitycollision = EntityCollisionClass.ENTCOLL_ALL,tech = player:HasCollectible(68),list = funct.copy(list),thor_effe = true})
				player.Position = position
				player.Velocity = Vector(0,0)
				player:AddControlsCooldown(1)
				end,{player = player,position = player.Position + i/loop_cnt * (targ.Position - player.Position)},i-1)
		end
		if player.CanFly == false then
			player.GridCollisionClass = GridCollisionClass.COLLISION_WALL
			addeffe(function(para)
				player.GridCollisionClass = GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER
				end,{player = player},60)
		end
		addeffe(function(para)
			player:SetColor(Color(1,1,1,0.5,1,1,1),15,30,true,true)
			player.Position = room:GetClampedPosition(player.Position,10)
			end,{player = player},loop_cnt)
		addeffe(function(para)
			player:GetData().is_setting_color = false
			end,{player = player},loop_cnt + 15)
		player:GetData().invincible = 25 + loop_cnt
	else
		local targ = player:GetData().thor_target
		local q1 = Isaac.Spawn(1000,MeusLink,0,player.Position/2 + targ.Position/2,Vector(0,0),player)
		local s1 = q1:GetSprite()
		local dir = (targ.Position - player.Position)
		local ang = dir:GetAngleDegrees()
		local leg = dir:Length() + 30
		s1.Rotation = ang - 90;
		s1.Scale = Vector(leg/45,1/6)
		player.Position = player.Position + funct.MakeVector(ang) * (leg)
		player.Velocity = Vector(0,0)
		for i = 1, 16 do
			local q1 = funct.fire_dowhatknife(nil,player.Position,funct.MakeVector(ang + i * 360/16) * 20 * player.ShotSpeed,player.Damage/3,"IdleUp","IdleUp2",{source = nil,cooldown = 60,player = player,tearflags = player.TearFlags,color = player.TearColor,epic = player:HasCollectible(168),Accerate = 2,size = 5,size1 = Vector(1,3),size2 = 13,list = list,tech = player:HasCollectible(68)})
		end
		if player.CanFly == false then
			player.GridCollisionClass = GridCollisionClass.COLLISION_WALL
			addeffe(function(para)
				player.GridCollisionClass = GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER
				end,{player = player},60)
		end
		player:GetData().invincible = 30
	end
end
function funct.kill_thenm_all(player,pos,dmg,list)
	local room = Game():GetRoom()
	local q1 = Isaac.Spawn(1000,MeusLink,0,player.Position,Vector(0,0),player)
	local s1 = q1:GetSprite()
	
	local dir = pos - player.Position
	if player:GetData().last_attack_pos then
		 dir = player:GetData().last_attack_pos - player.Position
		 player:GetData().last_attack_pos = nil
	else
		--player:GetData().last_attack_pos = player.Position
	end
	if dir:Length() < 0.5 then
		dir = funct.MakeVector(math.random(36000)/100) * 1000
	end
	s1.Rotation = dir:GetAngleDegrees() - 90;
	s1.Scale = Vector(dir:Length(),1/10)
	player.Position = room:GetClampedPosition(player.Position + dir:Normalized() * (dir:Length() + 50),10)
	if player:GetData().invincible == nil then
		player:GetData().invincible = 0
	end
	player:GetData().invincible = player:GetData().invincible + 20
	--player.PositionOffset = Vector(0,-60)
	local n_entity = Isaac.GetRoomEntities()
	local n_enemy = funct.getenemies(n_entity)
	for i = 1,#n_enemy do 
		if (n_enemy[i].Position - pos):Length() < 30 then
			n_enemy[i]:TakeDamage(dmg,0,EntityRef(player),0)
		end
	end
end
function funct.kill_thenm_all2(player,pos,dmg,params,max_hit,max_range)
	local target_enemy = {}
	local n_entity = Isaac.GetRoomEntities()
	local n_enemy = funct.getenemies(n_entity)
	if max_range == nil then
		max_range = 100
	end
	for i = 1,#n_enemy do 
		if (n_enemy[i].Position - pos):Length() < max_range then
			target_enemy[#target_enemy + 1] = n_enemy[i]
		end
	end
	if max_hit == nil then
		max_hit = 5
	end
	if #target_enemy < max_hit and #target_enemy > 0 then
		for i = #target_enemy,max_hit + 2 do 
			target_enemy[#target_enemy + 1] = target_enemy[math.random(#target_enemy)]
		end
	end
	--Debuglist[12] = #target_enemy
	if #target_enemy > 0 then
		player.Visible = false
		if player:GetData().invincible == nil then
			player:GetData().invincible = 0
		end
		player:GetData().invincible = player:GetData().invincible + #target_enemy * 2 + 30
		player:GetData().bone_Position = player.Position
		player:AddControlsCooldown(#target_enemy * 2 + 10)
		for i = 1,#target_enemy do
			addeffe(function(params)
			
			if true then
				local q1 = Isaac.Spawn(1000,MeusLink,0,params.player:GetData().bone_Position/2 + params.target_enemy.Position/2,Vector(0,0),player)
				local s1 = q1:GetSprite()
				local dir = (params.target_enemy.Position - params.player:GetData().bone_Position)
				local ang = dir:GetAngleDegrees() + math.random(60000)/1000 - 30
				local leg = dir:Length() + 30
				s1.Rotation = ang - 90;
				s1.Scale = Vector(leg/90,1/10)
				params.player:GetData().bone_Position = params.player:GetData().bone_Position + funct.MakeVector(ang) * (leg)
				if params.target_enemy:Exists() then
					params.target_enemy:TakeDamage(dmg,0,EntityRef(player),0)
				end
			end
			
			end,{target_enemy = target_enemy[i],player = player},i * 2)
		end
		addeffe(function(params)
			player.Visible = true
			if false then		--放弃了，不懂怎么调整狂暴头时间。
				local bers = player:GetEffects():GetCollectibleEffect(704)
				if bers ~= nil then
					local cnt = 0
					for i = 1,#n_enemy do 
						if n_enemy[i]:Exists() == false then
							cnt = cnt + 1
						end
					end
					bers = player:GetEffects():GetCollectibleEffect(704)
					if bers and bers.Cooldown and cnt * 10 + bers.Cooldown > 140 then
						--player:GetEffects():RemoveCollectibleEffect(704,true,-1)		--没看懂怎么用
						--player:GetEffects():AddCollectibleEffect(704,true,1)
					end
				end
			end
		end,{},#target_enemy * 1.5 + 2)
	end
end
function funct.PrintTable( tbl , level, filteDefault)
  local msg = ""
  filteDefault = filteDefault or true --默认过滤关键字（DeleteMe, _class_type）
  level = level or 1
  local indent_str = ""
  for i = 1, level do
    indent_str = indent_str.."  "
  end

  print(indent_str .. "{")
  for k,v in pairs(tbl) do
    if filteDefault then
      if k ~= "_class_type" and k ~= "DeleteMe" and type(v) ~= "boolean" then
        local item_str = string.format("%s%s = %s", indent_str .. " ",tostring(k), tostring(v))
        print(item_str)
        if type(v) == "table" then
          funct.PrintTable(v, level + 1)
        end
      end
    else
      local item_str = string.format("%s%s = %s", indent_str .. " ",tostring(k), tostring(v))
      print(item_str)
      if type(v) == "table" then
        funct.PrintTable(v, level + 1)
      end
    end
  end
  print(indent_str .. "}")
end
function funct.get_random_pickup()
	local rand = math.random(1000)
	if rand < 400 then
		if rand < 300 then 
			return Vector(20,1)
		elseif rand < 350 then
			return Vector(20,4)
		elseif rand < 370 then
			return Vector(20,2)
		elseif rand < 380 then
			return Vector(20,3)
		elseif rand < 385 then
			return Vector(20,5)
		else 
			return Vector(20,7)
		end
	elseif rand < 600 then
		return Vector(10,0)
	elseif rand < 700 then
		return Vector(30,0)
	elseif rand < 800 then
		if rand < 780 then 
			return Vector(40,1)
		elseif rand < 790 then
			return Vector(40,2)
		elseif rand < 797 then
			return Vector(40,4)
		else 
			return Vector(40,7)
		end
	elseif rand < 830 then
		return Vector(90,0)
	elseif rand < 900 then
		return Vector(80,0)
	elseif rand < 970 then
		return Vector(300,0)
	else
		return Vector(42,0)
	end
end

return funct