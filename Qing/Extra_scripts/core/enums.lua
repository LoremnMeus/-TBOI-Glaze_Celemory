local enums = {}

enums.Players = {
	wq = Isaac.GetPlayerTypeByName("W.Qing"),
	Spwq = Isaac.GetPlayerTypeByName("SP.W.Qing", true)
}

enums.Items = {
	-- Passives	
	Darkness = Isaac.GetItemIdByName("Darkness"),
	Touchstone = Isaac.GetItemIdByName("Touchstone"),
	My_Hat = Isaac.GetItemIdByName("My Hat"),
	Tech_9 = Isaac.GetItemIdByName("Tech 9"),
	Assassin_s_Eye = Isaac.GetItemIdByName("Assassin's Eye"),
	--[[Mental_Hypnosis = Isaac.GetItemIdByName("Mental Hypnosis"),
	My_Emblem = Isaac.GetItemIdByName("My Emblem"),
	Gold_Rush = Isaac.GetItemIdByName("Gold Rush"),
	Air_Flight = Isaac.GetItemIdByName("Air Flight"),
	The_Watcher = Isaac.GetItemIdByName("The Watcher"),
	Giant_Punch = Isaac.GetItemIdByName("Giant Punch"),
	Memory = Isaac.GetItemIdByName("Memory"),
	My_Best_Friend = Isaac.GetItemIdByName("My Best Friend"),
	Mega_Boom = Isaac.GetItemIdByName("Mega Boom"),
	Brimstream = Isaac.GetItemIdByName("Brimstream"),
	Blinding_of_Isaac = Isaac.GetItemIdByName("Blinding of Isaac"),
	Crown_of_the_glaze = Isaac.GetItemIdByName("Crown of the glaze")
	--]]
}

enums.Trinkets = {
	--DadsCharm = Isaac.GetTrinketIdByName("Dad's Charm"),
}

enums.Cards = {
	--AncientFragment = Isaac.GetCardIdByName("Ancient Fragment"),
}

enums.Costumes = {
	SPWQinghair = Isaac.GetCostumeIdByPath("gfx/characters/SPWQingHair.anm2"),
	Qingrobes = Isaac.GetCostumeIdByPath("gfx/characters/Qingrobes.anm2"),
}

enums.Familiars = {
	--JobWife = Isaac.GetEntityVariantByName("Job's Wife"),
}

enums.Enemies = {
	--AltarFiend = 1263, -- SubType
}

enums.Entities = {
	QingsAirs = Isaac.GetEntityVariantByName("QingsAir"),
	MeusLink = Isaac.GetEntityVariantByName("MeusLink"),
	QingsMarks = Isaac.GetEntityVariantByName("QingsMark"),
	StabberKnife = Isaac.GetEntityVariantByName("StabberKnife"),
	MeusSword = Isaac.GetEntityVariantByName("MeusSword"),
	ID_EFFECT_MeusFetus = Isaac.GetEntityVariantByName("MeusFetus"),
	ID_EFFECT_MeusRocket = Isaac.GetEntityVariantByName("MeusRocket"),
	ID_EFFECT_MeusNIL = Isaac.GetEntityVariantByName("MeusNil"),
	Qing_Bar = Isaac.GetEntityVariantByName("Qing Bar"),
}

enums.Pickups = {
	Glaze_heart = Isaac.GetEntityVariantByName("Glaze_heart"),
	Glaze_heart_half = Isaac.GetEntityVariantByName("Glaze_heart_half"),
	Glaze_key = Isaac.GetEntityVariantByName("Glaze_key"),
}

enums.Challenges = {
	--Resistance = Isaac.GetChallengeIdByName("Resistance"),
	--Shooting_Underground = Isaac.GetChallengeIdByName("Shooting Underground"),
	Fusion_Destiny = Isaac.GetChallengeIdByName("Fusion Destiny"),
}

enums.Slots = {
	--PrayingAltar = Isaac.GetEntityVariantByName("Praying Altar"),
}

enums.AchievementGraphics = {
	wq = {
		MomsHeart = "achievement_Darkness",
		--Isaac = "achievement_Darkness",
		--Satan = "achievement_Darkness",
		BlueBaby = "achievement_My_Hat",
		Lamb = "achievement_Touchstone",
		BossRush = "achievement_Assassin_s_Eye",
		Hush = "achievement_Tech_9",
		MegaSatan = "achievement_Darkness",
		Delirium = "achievement_Mental_Hypnosis",
		Mother = "achievement_Gold_Rush",
		Beast = "achievement_My_Emblem",
		GreedMode = "achievement_glass_door",
		Greedier = "achievement_glass_door2",
		Tainted = "achievement_tainted_WQ",
		FullCompletion = "achievement_resistance",
	},
	Spwq = {
		Lamb = "achievement_Air_Flight",
		BlueBaby = "achievement_The_Watcher",
		BossRush = "achievement_Giant_Punch",
		Hush = "achievement_Tech_9",
		MegaSatan = "achievement.praying_altar",
		Delirium = "achievement.jobs_leper_flesh",
		Mother = "achievement.sacred_assistance",
		Beast = "achievement.scorched_contract",
		Greedier = "achievement.forsaken_chalice",
		Haunted = "achievement.antibiotic",
		FullCompletion = "achievement.full_completion_b",
	},
}

return enums
