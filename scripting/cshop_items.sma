/*
	* This plugin contains all the default items Custom Shop has to offer.
	* I don't suggest making any changes here, since they will be gone in future updates.
	* If you want to change something, use the in-game menu editor or the CustomShopItems.ini file.
*/

#include <amxmodx>
#include <cromchat>
#include <cstrike>
#include <customshop>
#include <fun>
#include <hamsandwich>

#define PLUGIN_VERSION "4.1+"
#define TASK_HEALTHREGEN 400040
#define TASK_ARMORREGEN 400140
#define m_pActiveItem 373

additem DEFAULT_ITEMS[MAX_ITEMS]

enum
{
	ITEM_HEALTH = 0, ITEM_ARMOR, ITEM_UNLCLIP, ITEM_UNLAMMO, ITEM_BOMBER, ITEM_SILENTSTEPS, ITEM_SPEED, ITEM_GRAVITY, ITEM_CHAMELEON, ITEM_DRUGS, ITEM_TRANSPARENCY,
	ITEM_INVIS, ITEM_DOUBLEDAMAGE, ITEM_GODMODE, ITEM_HEALTHREGEN, ITEM_ARMORREGEN, ITEM_AWP
}

enum _:Items
{
	Id[32],
	Name[64],
	Price,
	Limit,
	Sound[128],
	Float:Duration
}

enum _:Settings
{
	Health_Amount,
	Armor_Amount,
	UnlClip_Ammo,
	UnlAmmo_Ammo,
	Bomber_Amount,
	Bomber_Type[20],
	Bomber_CSW,
	Float:Speed_Amount,
	Float:Gravity_Amount,
	Drugs_Health,
	Drugs_FOV,
	Float:Drugs_Speed,
	Transparency_Amount,
	Invis_Amount,
	DoubleDamage_Multiplier,
	HealthRegen_PerSec,
	HealthRegen_MaxHP,
	Float:HealthRegen_Frequency,
	ArmorRegen_PerSec,
	ArmorRegen_MaxAP,
	Float:ArmorRegen_Frequency,
	AWP_Ammo
}

new const g_eItems[][Items] = 
{
	{ "health", "+50 Health Points", 1500, 5, "items/smallmedkit1.wav" },
	{ "armor", "+100 Armor Points", 1000, 8, "items/ammopickup2.wav" },
	{ "unlclip", "Unlimited Clip", 3000, 3, DEFAULT_SOUND },
	{ "unlammo", "Unlimited Ammo", 200, 5, DEFAULT_SOUND },
	{ "bomber", "Bomber", 1600, 3, "x/x_pain2.wav" },
	{ "silentsteps", "Silent Footsteps", 3000, 1, DEFAULT_SOUND },
	{ "speed", "Faster Speed", 4300, 1, "misc/bipbip.wav" },
	{ "gravity", "Low Gravity", 2800, 1, DEFAULT_SOUND },
	{ "chameleon", "Chameleon", 9000, 1, DEFAULT_SOUND },
	{ "drugs", "Drugs (Speed + Health)", 8000, 2, DEFAULT_SOUND },
	{ "transparency", "Transparency", 2500, 1, DEFAULT_SOUND },
	{ "invis", "Invisibility (15 Seconds)", 16000, 1, "hornet/ag_buzz1.wav", 15.0 },
	{ "doubledamage", "Double Damage", 10000, 1, DEFAULT_SOUND },
	{ "godmode", "Godmode (5 Seconds)", 16000, 1, "misc/stinger12.wav", 5.0 },
	{ "healthregen", "Health Regeneration", 1800, 1, "items/suitchargeok1.wav" },
	{ "armorregen", "Armor Regeneration", 2000, 1, "items/suitchargeok1.wav" },
	{ "awp", "AWP Sniper", 4750, 1, DEFAULT_SOUND }
}

new g_iSetFOV
new g_eSettings[Settings]
new bool:g_bHasItem[33][MAX_ITEMS]
new const CHAMELEON_MODELS[][][] = { { "gign", "gsg9", "sas", "urban" }, { "arctic", "guerilla", "leet", "terror" } }

public plugin_init()
{
	register_plugin("CSHOP: Default Items", PLUGIN_VERSION, "OciXCrom")
	register_dictionary("CustomShop.txt")
	register_event("CurWeapon", "OnChangeWeapon", "be", "1=1")
	RegisterHam(Ham_TakeDamage, "player", "PreTakeDamage")
	g_iSetFOV = get_user_msgid("SetFOV")
	
	new szPrefix[CC_MAX_PREFIX_SIZE]
	cshop_get_prefix(szPrefix, charsmax(szPrefix))
	CC_SetPrefix(szPrefix)
	
	g_eSettings[Health_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_HEALTH], "Amount")
	g_eSettings[Armor_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_ARMOR], "Amount")
	g_eSettings[UnlClip_Ammo] = cshop_get_int(DEFAULT_ITEMS[ITEM_UNLCLIP], "Backpack Ammo")
	g_eSettings[UnlAmmo_Ammo] = cshop_get_int(DEFAULT_ITEMS[ITEM_UNLAMMO], "Backpack Ammo")
	g_eSettings[Bomber_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_BOMBER], "Amount")
	cshop_get_string(DEFAULT_ITEMS[ITEM_BOMBER], "Type", g_eSettings[Bomber_Type], charsmax(g_eSettings[Bomber_Type]))
	g_eSettings[Bomber_CSW] = get_weaponid(g_eSettings[Bomber_Type])
	g_eSettings[Speed_Amount] = _:cshop_get_float(DEFAULT_ITEMS[ITEM_SPEED], "Amount")
	g_eSettings[Gravity_Amount] = _:cshop_get_float(DEFAULT_ITEMS[ITEM_GRAVITY], "Amount")
	g_eSettings[Drugs_Health] = cshop_get_int(DEFAULT_ITEMS[ITEM_DRUGS], "Health")
	g_eSettings[Drugs_FOV] = cshop_get_int(DEFAULT_ITEMS[ITEM_DRUGS], "FOV")
	g_eSettings[Drugs_Speed] = _:cshop_get_float(DEFAULT_ITEMS[ITEM_DRUGS], "Speed")
	g_eSettings[Transparency_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_TRANSPARENCY], "Amount")
	g_eSettings[Invis_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_INVIS], "Amount")
	g_eSettings[DoubleDamage_Multiplier] = cshop_get_int(DEFAULT_ITEMS[ITEM_DOUBLEDAMAGE], "Multiplier")
	g_eSettings[HealthRegen_PerSec] = cshop_get_int(DEFAULT_ITEMS[ITEM_HEALTHREGEN], "HP Per Second")
	g_eSettings[HealthRegen_MaxHP] = cshop_get_int(DEFAULT_ITEMS[ITEM_HEALTHREGEN], "Max HP")
	g_eSettings[HealthRegen_Frequency] = _:cshop_get_float(DEFAULT_ITEMS[ITEM_HEALTHREGEN], "Frequency")
	g_eSettings[ArmorRegen_PerSec] = cshop_get_int(DEFAULT_ITEMS[ITEM_ARMORREGEN], "AP Per Second")
	g_eSettings[ArmorRegen_MaxAP] = cshop_get_int(DEFAULT_ITEMS[ITEM_ARMORREGEN], "Max AP")
	g_eSettings[ArmorRegen_Frequency] = _:cshop_get_float(DEFAULT_ITEMS[ITEM_ARMORREGEN], "Frequency")
	g_eSettings[AWP_Ammo] = cshop_get_int(DEFAULT_ITEMS[ITEM_AWP], "Backpack Ammo")
}

public plugin_precache()
{
	for(new i; i < sizeof(g_eItems); i++)
		DEFAULT_ITEMS[i] = cshop_register_item(g_eItems[i][Id], g_eItems[i][Name], g_eItems[i][Price], g_eItems[i][Limit], g_eItems[i][Sound], g_eItems[i][Duration])
	
	cshop_set_int(DEFAULT_ITEMS[ITEM_HEALTH], "Amount", 50)
	cshop_set_int(DEFAULT_ITEMS[ITEM_ARMOR], "Amount", 100)
	cshop_set_int(DEFAULT_ITEMS[ITEM_UNLCLIP], "Backpack Ammo", 97280)
	cshop_set_int(DEFAULT_ITEMS[ITEM_UNLAMMO], "Backpack Ammo", 97280)
	cshop_set_int(DEFAULT_ITEMS[ITEM_BOMBER], "Amount", 20)
	cshop_set_string(DEFAULT_ITEMS[ITEM_BOMBER], "Type", "weapon_hegrenade")
	cshop_set_float(DEFAULT_ITEMS[ITEM_SPEED], "Amount", 300.0)
	cshop_set_float(DEFAULT_ITEMS[ITEM_GRAVITY], "Amount", 0.5)
	cshop_set_int(DEFAULT_ITEMS[ITEM_DRUGS], "Health", 200)
	cshop_set_int(DEFAULT_ITEMS[ITEM_DRUGS], "FOV", 180)
	cshop_set_float(DEFAULT_ITEMS[ITEM_DRUGS], "Speed", 300.0)
	cshop_set_int(DEFAULT_ITEMS[ITEM_TRANSPARENCY], "Amount", 75)
	cshop_set_int(DEFAULT_ITEMS[ITEM_INVIS], "Amount", 0)
	cshop_set_int(DEFAULT_ITEMS[ITEM_DOUBLEDAMAGE], "Multiplier", 2)
	cshop_set_int(DEFAULT_ITEMS[ITEM_HEALTHREGEN], "HP Per Second", 1)
	cshop_set_int(DEFAULT_ITEMS[ITEM_HEALTHREGEN], "Max HP", 150)
	cshop_set_float(DEFAULT_ITEMS[ITEM_HEALTHREGEN], "Frequency", 0.5)
	cshop_set_int(DEFAULT_ITEMS[ITEM_ARMORREGEN], "AP Per Second", 10)
	cshop_set_int(DEFAULT_ITEMS[ITEM_ARMORREGEN], "Max AP", 150)
	cshop_set_float(DEFAULT_ITEMS[ITEM_ARMORREGEN], "Frequency", 0.5)
	cshop_set_int(DEFAULT_ITEMS[ITEM_AWP], "Backpack Ammo", 30)
}

public client_putinserver(id)
	arrayset(g_bHasItem[id], false, sizeof(g_bHasItem[]))

public cshop_item_selected(id, iItem)
{
	if(iItem == DEFAULT_ITEMS[ITEM_HEALTH]) 			{ set_user_health(id, get_user_health(id) + g_eSettings[Health_Amount]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_ARMOR]) 		{ set_user_armor(id, get_user_armor(id) + g_eSettings[Armor_Amount]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_BOMBER])
	{
		give_item(id, "weapon_hegrenade")
		cs_set_user_bpammo(id, g_eSettings[Bomber_CSW], g_eSettings[Bomber_Amount])
	}
	else if(iItem == DEFAULT_ITEMS[ITEM_UNLCLIP])
	{
		new iWeapon = get_user_weapon(id)
		
		if(!weapon_uses_ammo(iWeapon))
		{
			new szName[64]
			cshop_get_item_data(DEFAULT_ITEMS[ITEM_UNLCLIP], CSHOP_DATA_NAME, szName, charsmax(szName))
			CC_SendMessage(id, "%L", id, "CSHOP_CANT_ACTIVATE", szName)
			cshop_error_sound(id)
			return DONT_BUY
		}
		
		cs_set_weapon_ammo(get_pdata_cbase(id, m_pActiveItem), g_eSettings[UnlClip_Ammo])
		cs_set_user_bpammo(id, iWeapon, 0)
	}
	else if(iItem == DEFAULT_ITEMS[ITEM_UNLAMMO])
	{
		new iWeapon = get_user_weapon(id)
		
		if(!weapon_uses_ammo(iWeapon))
		{
			new szName[64]
			cshop_get_item_data(DEFAULT_ITEMS[ITEM_UNLAMMO], CSHOP_DATA_NAME, szName, charsmax(szName))
			CC_SendMessage(id, "%L", id, "CSHOP_CANT_ACTIVATE", szName)
			cshop_error_sound(id)
			return DONT_BUY
		}
		
		cs_set_user_bpammo(id, iWeapon, g_eSettings[UnlAmmo_Ammo])
	}
	else if(iItem == DEFAULT_ITEMS[ITEM_SILENTSTEPS]) 		{ set_user_footsteps(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_SPEED]) 			{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_SPEED]] = true; set_user_maxspeed(id, g_eSettings[Speed_Amount]); OnChangeWeapon(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_GRAVITY]) 			{ set_user_gravity(id, g_eSettings[Gravity_Amount]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_CHAMELEON]) 		{ cs_set_user_model(id, CHAMELEON_MODELS[(get_user_team(id) - 1)][random(4)]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_DRUGS])
	{
		g_bHasItem[id][DEFAULT_ITEMS[ITEM_DRUGS]] = true
		set_user_health(id, get_user_health(id) + g_eSettings[Drugs_Health])
		set_user_maxspeed(id, g_eSettings[Drugs_Speed])
		set_user_drugs(id, g_eSettings[Drugs_FOV])
		OnChangeWeapon(id)
	}
	else if(iItem == DEFAULT_ITEMS[ITEM_TRANSPARENCY]) 		{ set_user_glow(id, .iAlpha = g_eSettings[Transparency_Amount]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_INVIS]) 			{ set_user_glow(id, .iAlpha = g_eSettings[Invis_Amount]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_DOUBLEDAMAGE]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_DOUBLEDAMAGE]] = true; }
	else if(iItem == DEFAULT_ITEMS[ITEM_GODMODE]) 			{ set_user_godmode(id, 1); }
	else if(iItem == DEFAULT_ITEMS[ITEM_HEALTHREGEN]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_HEALTHREGEN]] = true; set_task(g_eSettings[HealthRegen_Frequency], "RegenerateHealth", id + TASK_HEALTHREGEN, .flags = "b"); }
	else if(iItem == DEFAULT_ITEMS[ITEM_ARMORREGEN]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_ARMORREGEN]] = true; set_task(g_eSettings[ArmorRegen_Frequency], "RegenerateArmor", id + TASK_ARMORREGEN, .flags = "b"); }
	else if(iItem == DEFAULT_ITEMS[ITEM_AWP]) 				{ give_item(id, "weapon_awp"); cs_set_user_bpammo(id, CSW_AWP, g_eSettings[AWP_Ammo]); }
	
	return BUY_ITEM
}

public cshop_item_removed(id, iItem)
{
	if(!is_user_alive(id))
		return
		
	if(iItem == DEFAULT_ITEMS[ITEM_SILENTSTEPS]) 			{ set_user_footsteps(id, 0); }
	else if(iItem == DEFAULT_ITEMS[ITEM_SPEED]) 			{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_SPEED]] = false; OnChangeWeapon(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_GRAVITY]) 			{ set_user_gravity(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_CHAMELEON]) 		{ cs_reset_user_model(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_DRUGS]) 			{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_DRUGS]] = false; OnChangeWeapon(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_INVIS]) 			{ remove_user_glow(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_DOUBLEDAMAGE]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_DOUBLEDAMAGE]] = false; }
	else if(iItem == DEFAULT_ITEMS[ITEM_GODMODE]) 			{ set_user_godmode(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_HEALTHREGEN]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_HEALTHREGEN]] = false; }
	else if(iItem == DEFAULT_ITEMS[ITEM_ARMORREGEN]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_ARMORREGEN]] = false; }
}

public OnChangeWeapon(id)
{
	if(g_bHasItem[id][DEFAULT_ITEMS[ITEM_DRUGS]])
		set_user_maxspeed(id, g_eSettings[Drugs_Speed])
	else if(g_bHasItem[id][DEFAULT_ITEMS[ITEM_SPEED]])
		set_user_maxspeed(id, g_eSettings[Speed_Amount])
}

public PreTakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageBits)
{
	if(is_user_alive(iAttacker) && iAttacker != iVictim)
	{
		if(g_bHasItem[iAttacker][DEFAULT_ITEMS[ITEM_DOUBLEDAMAGE]])
			SetHamParamFloat(4, flDamage * g_eSettings[DoubleDamage_Multiplier])
	}
}

public RegenerateHealth(id)
{
	id -= TASK_HEALTHREGEN
	
	if(!is_user_alive(id) || !g_bHasItem[id][DEFAULT_ITEMS[ITEM_HEALTHREGEN]])
	{
		remove_task(id + TASK_HEALTHREGEN)
		return
	}
		
	static iHealth
	iHealth = get_user_health(id)
	
	if(iHealth >= g_eSettings[HealthRegen_MaxHP])
		return
		
	set_user_health(id, clamp(iHealth + g_eSettings[HealthRegen_PerSec], .max = g_eSettings[HealthRegen_MaxHP]))
}

public RegenerateArmor(id)
{
	id -= TASK_ARMORREGEN
	
	if(!is_user_alive(id) || !g_bHasItem[id][DEFAULT_ITEMS[ITEM_ARMORREGEN]])
	{
		remove_task(id + TASK_ARMORREGEN)
		return
	}
	
	static iArmor
	iArmor = get_user_armor(id)
	
	if(iArmor >= g_eSettings[ArmorRegen_MaxAP])
		return
		
	set_user_armor(id, clamp(iArmor + g_eSettings[ArmorRegen_PerSec], .max = g_eSettings[ArmorRegen_MaxAP]))
}

bool:weapon_uses_ammo(iWeapon)
	return (iWeapon == CSW_KNIFE|CSW_HEGRENADE|CSW_FLASHBANG|CSW_SMOKEGRENADE) ? false : true

set_user_glow(id, iRed = 0, iGreen = 0, iBlue = 0, iAlpha)
	set_user_rendering(id, kRenderFxGlowShell, iRed, iGreen, iBlue, kRenderTransAlpha, iAlpha)
	
remove_user_glow(id)
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)

set_user_drugs(id, iAmount)
{
	message_begin(MSG_ONE, g_iSetFOV, {0, 0, 0}, id)
	write_byte(iAmount)
	message_end()
}