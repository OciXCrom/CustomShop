/*
	* This plugin contains all the default items Custom Shop has to offer.
	* I don't suggest making any changes here, since they will be gone in future updates.
	* If you want to change something, use the in-game menu editor or the CustomShopItems.ini file.
*/

#include <amxmodx>
#include <cromchat>
#include <cstrike>
#include <customshop>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

#define PLUGIN_VERSION "4.2.2"
#define TASK_HEALTHREGEN 400040
#define TASK_ARMORREGEN 400140
#define m_pActiveItem 373

additem DEFAULT_ITEMS[MAX_ITEMS]
new const g_iMaxClip[] = { 0, 13, 0, 10, 0, 7, 0, 30, 30, 0, 15, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 0, 7, 30, 30, 0, 50 }

enum
{
	ITEM_HEALTH = 0, ITEM_ARMOR, ITEM_UNLCLIP, ITEM_UNLAMMO, ITEM_BOMBER, ITEM_SILENTSTEPS, ITEM_SPEED, ITEM_GRAVITY, ITEM_CHAMELEON, ITEM_DRUGS, ITEM_TRANSPARENCY,
	ITEM_INVIS, ITEM_MOREDAMAGE, ITEM_GODMODE, ITEM_HEALTHREGEN, ITEM_ARMORREGEN, ITEM_AWP
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
	Speed_Add,
	Float:Gravity_Amount,
	Drugs_Health,
	Drugs_FOV,
	Float:Drugs_Speed,
	Drugs_Speed_Add,
	Transparency_Amount,
	Invis_Amount,
	MoreDamage_Amount[10],
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
	{ "moredamage", "Double Damage", 10000, 1, DEFAULT_SOUND },
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
	RegisterHam(Ham_Item_PreFrame, "player", "OnPlayerResetMaxSpeed", 1) 
	
	g_iSetFOV = get_user_msgid("SetFOV")
	
	new szPrefix[CC_MAX_PREFIX_SIZE]
	cshop_get_prefix(szPrefix, charsmax(szPrefix))
	CC_SetPrefix(szPrefix)
	
	g_eSettings[Health_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_HEALTH], "Amount")
	g_eSettings[Armor_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_ARMOR], "Amount")
	g_eSettings[UnlClip_Ammo] = cshop_get_int(DEFAULT_ITEMS[ITEM_UNLCLIP], "Clip Ammo")
	g_eSettings[UnlAmmo_Ammo] = cshop_get_int(DEFAULT_ITEMS[ITEM_UNLAMMO], "Backpack Ammo")
	g_eSettings[Bomber_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_BOMBER], "Amount")
	cshop_get_string(DEFAULT_ITEMS[ITEM_BOMBER], "Type", g_eSettings[Bomber_Type], charsmax(g_eSettings[Bomber_Type]))
	g_eSettings[Bomber_CSW] = get_weaponid(g_eSettings[Bomber_Type])
	g_eSettings[Speed_Amount] = _:cshop_get_float(DEFAULT_ITEMS[ITEM_SPEED], "Amount")
	g_eSettings[Speed_Add] = cshop_get_int(DEFAULT_ITEMS[ITEM_SPEED], "Add To Current")
	g_eSettings[Gravity_Amount] = _:cshop_get_float(DEFAULT_ITEMS[ITEM_GRAVITY], "Amount")
	g_eSettings[Drugs_Health] = cshop_get_int(DEFAULT_ITEMS[ITEM_DRUGS], "Health")
	g_eSettings[Drugs_FOV] = cshop_get_int(DEFAULT_ITEMS[ITEM_DRUGS], "FOV")
	g_eSettings[Drugs_Speed] = _:cshop_get_float(DEFAULT_ITEMS[ITEM_DRUGS], "Speed")
	g_eSettings[Drugs_Speed_Add] = cshop_get_int(DEFAULT_ITEMS[ITEM_DRUGS], "Add Speed To Current")
	g_eSettings[Transparency_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_TRANSPARENCY], "Amount")
	g_eSettings[Invis_Amount] = cshop_get_int(DEFAULT_ITEMS[ITEM_INVIS], "Amount")
	cshop_get_string(DEFAULT_ITEMS[ITEM_MOREDAMAGE], "Amount", g_eSettings[MoreDamage_Amount], charsmax(g_eSettings[MoreDamage_Amount]))
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
	cshop_set_int(DEFAULT_ITEMS[ITEM_UNLCLIP], "Clip Ammo", -1)
	cshop_set_int(DEFAULT_ITEMS[ITEM_UNLAMMO], "Backpack Ammo", 97280)
	cshop_set_int(DEFAULT_ITEMS[ITEM_BOMBER], "Amount", 20)
	cshop_set_string(DEFAULT_ITEMS[ITEM_BOMBER], "Type", "weapon_hegrenade")
	cshop_set_float(DEFAULT_ITEMS[ITEM_SPEED], "Amount", 300.0)
	cshop_set_int(DEFAULT_ITEMS[ITEM_SPEED], "Add To Current", 0)
	cshop_set_float(DEFAULT_ITEMS[ITEM_GRAVITY], "Amount", 0.5)
	cshop_set_int(DEFAULT_ITEMS[ITEM_DRUGS], "Health", 200)
	cshop_set_int(DEFAULT_ITEMS[ITEM_DRUGS], "FOV", 180)
	cshop_set_float(DEFAULT_ITEMS[ITEM_DRUGS], "Speed", 300.0)
	cshop_set_int(DEFAULT_ITEMS[ITEM_DRUGS], "Add Speed To Current", 0)
	cshop_set_int(DEFAULT_ITEMS[ITEM_TRANSPARENCY], "Amount", 75)
	cshop_set_int(DEFAULT_ITEMS[ITEM_INVIS], "Amount", 0)
	cshop_set_string(DEFAULT_ITEMS[ITEM_MOREDAMAGE], "Amount", "*2")
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
	else if(iItem == DEFAULT_ITEMS[ITEM_ARMOR]) 		{ cs_set_user_armor(id, get_user_armor(id) + g_eSettings[Armor_Amount], CS_ARMOR_VESTHELM); }
	else if(iItem == DEFAULT_ITEMS[ITEM_BOMBER])
	{
		give_item(id, "weapon_hegrenade")
		cs_set_user_bpammo(id, g_eSettings[Bomber_CSW], g_eSettings[Bomber_Amount])
	}
	else if(iItem == DEFAULT_ITEMS[ITEM_UNLCLIP])
	{		
		if(!weapon_uses_ammo(get_user_weapon(id)))
		{
			new szName[64]
			cshop_get_item_data(DEFAULT_ITEMS[ITEM_UNLCLIP], CSHOP_DATA_NAME, szName, charsmax(szName))
			CC_SendMessage(id, "%L", id, "CSHOP_CANT_ACTIVATE", szName)
			cshop_error_sound(id)
			return DONT_BUY
		}
		
		g_bHasItem[id][DEFAULT_ITEMS[ITEM_UNLCLIP]] = true
		OnChangeWeapon(id)
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
	else if(iItem == DEFAULT_ITEMS[ITEM_SPEED]) 			{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_SPEED]] = true; OnPlayerResetMaxSpeed(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_GRAVITY]) 			{ set_user_gravity(id, g_eSettings[Gravity_Amount]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_CHAMELEON]) 		{ cs_set_user_model(id, CHAMELEON_MODELS[(get_user_team(id) - 1)][random(4)]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_DRUGS])
	{
		g_bHasItem[id][DEFAULT_ITEMS[ITEM_DRUGS]] = true
		set_user_health(id, get_user_health(id) + g_eSettings[Drugs_Health])
		set_user_drugs(id, g_eSettings[Drugs_FOV])
		OnPlayerResetMaxSpeed(id)
	}
	else if(iItem == DEFAULT_ITEMS[ITEM_TRANSPARENCY]) 		{ set_user_glow(id, .iAlpha = g_eSettings[Transparency_Amount]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_INVIS]) 			{ set_user_glow(id, .iAlpha = g_eSettings[Invis_Amount]); }
	else if(iItem == DEFAULT_ITEMS[ITEM_MOREDAMAGE]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_MOREDAMAGE]] = true; }
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
	
	if(iItem == DEFAULT_ITEMS[ITEM_UNLCLIP]) 				{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_UNLCLIP]] = false; }
	else if(iItem == DEFAULT_ITEMS[ITEM_SILENTSTEPS]) 		{ set_user_footsteps(id, 0); }
	else if(iItem == DEFAULT_ITEMS[ITEM_SPEED]) 			{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_SPEED]] = false; ExecuteHamB(Ham_Item_PreFrame, id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_GRAVITY]) 			{ set_user_gravity(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_CHAMELEON]) 		{ cs_reset_user_model(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_DRUGS]) 			{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_DRUGS]] = false; ExecuteHamB(Ham_Item_PreFrame, id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_TRANSPARENCY]) 		{ remove_user_glow(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_INVIS]) 			{ remove_user_glow(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_MOREDAMAGE]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_MOREDAMAGE]] = false; }
	else if(iItem == DEFAULT_ITEMS[ITEM_GODMODE]) 			{ set_user_godmode(id); }
	else if(iItem == DEFAULT_ITEMS[ITEM_HEALTHREGEN]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_HEALTHREGEN]] = false; }
	else if(iItem == DEFAULT_ITEMS[ITEM_ARMORREGEN]) 		{ g_bHasItem[id][DEFAULT_ITEMS[ITEM_ARMORREGEN]] = false; }
}

public OnPlayerResetMaxSpeed(id)
{
	if(!is_user_alive(id))
		return
		
	if(g_bHasItem[id][DEFAULT_ITEMS[ITEM_DRUGS]])
		set_user_maxspeed(id, g_eSettings[Drugs_Speed_Add] ? get_user_maxspeed(id) + g_eSettings[Drugs_Speed] : g_eSettings[Drugs_Speed])
	else if(g_bHasItem[id][DEFAULT_ITEMS[ITEM_SPEED]])
		set_user_maxspeed(id, g_eSettings[Speed_Add] ? get_user_maxspeed(id) + g_eSettings[Speed_Amount] : g_eSettings[Speed_Amount])
}

public OnChangeWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if(g_bHasItem[id][DEFAULT_ITEMS[ITEM_UNLCLIP]])
	{
		new iWeapon = read_data(2)

		if(iWeapon < 0 || iWeapon > sizeof(g_iMaxClip) - 1)
			return
		
		if(weapon_uses_ammo(iWeapon))
		{
			new iActiveItem = get_pdata_cbase(id, m_pActiveItem)

			if(pev_valid(iActiveItem))
				cs_set_weapon_ammo(iActiveItem, g_eSettings[UnlClip_Ammo] == -1 ? g_iMaxClip[iWeapon] : g_eSettings[UnlClip_Ammo])
		}
	}
}

public PreTakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageBits)
{
	if(is_user_alive(iAttacker) && iAttacker != iVictim)
	{
		if(g_bHasItem[iAttacker][DEFAULT_ITEMS[ITEM_MOREDAMAGE]])
			SetHamParamFloat(4, math_add_f(flDamage, g_eSettings[MoreDamage_Amount]))
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
		
	cs_set_user_armor(id, clamp(iArmor + g_eSettings[ArmorRegen_PerSec], .max = g_eSettings[ArmorRegen_MaxAP]), CS_ARMOR_VESTHELM)
}

Float:math_add_f(Float:fNum, const szMath[])
{
    static szNewMath[16], Float:fMath, bool:bPercent, cOperator
   
    copy(szNewMath, charsmax(szNewMath), szMath)
    bPercent = szNewMath[strlen(szNewMath) - 1] == '%'
    cOperator = szNewMath[0]
   
    if(!isdigit(szNewMath[0]))
        szNewMath[0] = ' '
   
    if(bPercent)
        replace(szNewMath, charsmax(szNewMath), "%", "")
       
    trim(szNewMath)
    fMath = str_to_float(szNewMath)
   
    if(bPercent)
        fMath *= fNum / 100
       
    switch(cOperator)
    {
        case '+': fNum += fMath
        case '-': fNum -= fMath
        case '/': fNum /= fMath
        case '*': fNum *= fMath
        default: fNum = fMath
    }
   
    return fNum
}

bool:weapon_uses_ammo(iWeapon)
	return ((1 << iWeapon) & ((1 << CSW_KNIFE) | (1 << CSW_HEGRENADE) | (1 << CSW_FLASHBANG) | (1 << CSW_SMOKEGRENADE) | (1 << CSW_C4))) ? false : true

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