local g = require("Extra_scripts.core.globals")
local save = require("Extra_scripts.core.savedata")
local enums = require("Extra_scripts.core.enums")
local auxi = require("Extra_scripts.auxiliary.functions")

local modReference
local Translation = {
	zh = {},
	isshowingsomething = false,
}

local Items = enums.Items
Translation.zh.Collectibles ={
    --[Collectibles.YinYangOrb.Item] = {Name="阴阳玉" , Description="弹跳粉碎者"},
    [Items.Darkness] = {Name="暗之六面" , Description="湮灭于未知"},
    [Items.Touchstone] = {Name="无名刃：弑金" , Description="一击远遁"},
    [Items.My_Hat] = {Name="小青的帽子" , Description="太大了！"},
    [Items.Tech_9] = {Name="科技IX" , Description="被跳过的产品"},
    [Items.Assassin_s_Eye] = {Name="暗杀者之泪" , Description="彗星袭月"},
}

Translation.zh.Trinkets ={
    --[Trinkets.FrozenFrog.Trinket] = {Name="冻青蛙" , Description="冰冷触摸"},
}

function Translation.init(mod)
	modReference = mod

    local function PostPlayerPickupUpdate(_, player)
		if (not player:IsItemQueueEmpty()) then
			if Translation.isshowingsomething == false then
				local item = player.QueuedItem;
				local language = Options.Language;
				local translation = Translation[language];
				if (item.Item.Type == ItemType.ITEM_TRINKET) then
					if (translation) then
						local info = translation.Trinkets and translation.Trinkets[item.Item.ID];
						if (info) then
							g.game:GetHUD():ShowItemText(info.Name or "", info.Description or "");
							Translation.isshowingsomething = true
						end
					end	
				else
					if (translation) then
						local info = translation.Collectibles and translation.Collectibles[item.Item.ID];
						if (info) then
							g.game:GetHUD():ShowItemText(info.Name or "", info.Description or "");
							Translation.isshowingsomething = true
						end
					end
				end
			end
		else
			Translation.isshowingsomething = false
		end
	
	end
    modReference:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE,PostPlayerPickupUpdate);
end

return Translation;