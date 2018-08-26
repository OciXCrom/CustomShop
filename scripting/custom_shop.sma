#include <amxmodx>
#include <amxmisc>
#include <cromchat>
#include <customshop>
#include <formatin>
#include <fun>
#include <hamsandwich>
#include <nvault>

#define PLUGIN_VERSION "4.2.3"
#define TASK_HUDBAR 388838
#define mtop(%1) floatround(float(%1) / 10.0, floatround_floor)
#define nvault_clear(%1) nvault_prune(%1, 0, get_systime() + 1)

#if defined client_disconnected
	#define client_disconnect client_disconnected
#endif

enum _:Items
{
	Id[32],
	Name[64],
	Price,
	Limit,
	Sound[128],
	Float:Duration,
	Team,
	Flags[32],
	bool:Disabled,
	Array:aSettings,
	Trie:tSettings,
	Trie:tTypes,
	SettingsNum
}

enum _:Settings
{
	CSHOP_TITLE[128],
	CSHOP_TITLE_PAGE[128],
	CSHOP_SOUND_ERROR[128],
	CSHOP_SOUND_EXPIRE[128],
	CSHOP_SOUND_OPEN[128],
	CSHOP_BUYSOUND_TYPE,
	CSHOP_EXPIRESOUND_TYPE,
	CSHOP_OPENSOUND_TYPE,
	CSHOP_PREVPAGE[32],
	CSHOP_NEXTPAGE[32],
	CSHOP_EXITMENU[32],
	CSHOP_PERPAGE,
	CSHOP_FLAG,
	CSHOP_TEAM,
	bool:CSHOP_POINTS_ENABLE,
	CSHOP_MONEY_NAME[32],
	CSHOP_MONEY_NAME_UC[32],
	CSHOP_CURRENCY[16],
	bool:CSHOP_POINTS_SAVE,
	CSHOP_SAVE_TYPE,
	bool:CSHOP_SHOW_TEAMED,
	CSHOP_ITEM_TEAMED[32],
	bool:CSHOP_SHOW_FLAGGED,
	CSHOP_ITEM_FLAGGED[32],
	CSHOP_LIMIT_TYPE,
	bool:CSHOP_SAVE_LIMIT,
	bool:CSHOP_HIDE_LIMITED,
	bool:CSHOP_OPEN_AT_SPAWN,
	bool:CSHOP_REOPEN_AFTER_USE,
	CSHOP_REWARD_NORMAL,
	CSHOP_REWARD_HEADSHOT,
	CSHOP_REWARD_KNIFE,
	CSHOP_REWARD_VIP,
	CSHOP_VIP_FLAG,
	bool:CSHOP_POINTS_TEAMKILL,
	bool:CSHOP_KILL_MESSAGE,
	bool:CSHOP_HUD_ENABLED,
	CSHOP_HUD_RED,
	CSHOP_HUD_GREEN,
	CSHOP_HUD_BLUE,
	Float:CSHOP_HUD_X,
	Float:CSHOP_HUD_Y
}

enum _:Fields
{
	FIELD_TEAM,
	FIELD_MONEY,
	FIELD_CURRENCY,
	FIELD_NEWLINE,
	FIELD_PAGE
}

enum _:Options
{
	OPTION_NAME,
	OPTION_PRICE,
	OPTION_LIMIT,
	OPTION_SOUND,
	OPTION_DURATION,
	OPTION_TEAM,
	OPTION_FLAG
}

enum _:Editor
{
	EDIT_STATUS,
	EDIT_NAME,
	EDIT_PRICE,
	EDIT_LIMIT,
	EDIT_SOUND,
	EDIT_DURATION,
	EDIT_TEAM,
	EDIT_FLAG
}

enum
{
	ST_INT = 0,
	ST_FLOAT,
	ST_STRING
}

new const g_szVaults[][] = { "CustomShop", "CustomShopIP", "CustomShopSI" }

new g_szFields[Fields][16] = { "%team%", "%money%", "%currency%", "%newline%", "%page%" },
	g_szOptionsL[Options][16] = { "CSHOP_NAME", "CSHOP_PRICE", "CSHOP_LIMIT", "CSHOP_SOUND", "CSHOP_DURATION", "CSHOP_TEAM", "CSHOP_FLAG" }

new Array:g_aItems,
	Trie:g_tItemIds,
	Trie:g_tLimit
	
new bool:g_bHasItem[33][MAX_ITEMS],
	bool:g_bAllowEdit[33],
	bool:g_bUnsaved,
	g_eSettings[Settings],	
	g_szOptions[Options][16],
	g_szStatus[2][16],
	g_iLimit[33][MAX_ITEMS],
	g_iItemTeamLimit[4][MAX_ITEMS],
	g_iItemLimit[MAX_ITEMS],
	g_szTeams[4][32],
	g_szInfo[33][35],
	g_szConfigsName[256],
	g_szItemsFile[256],
	g_szItemsLoaded[192],
	g_iEditItem[33],
	g_iEditChoice[33],
	g_szEditSetting[33][32],
	g_eEditArray[33][Items],
	g_iPoints[33],
	g_iPage[33],
	g_iTotalItems,
	g_fwdSelectItem,
	g_fwdRemoveItem,
	g_fwdMenuOpened,
	g_fwdSetPrice,
	g_iVault,
	g_iHUD

public plugin_init()
{
	register_plugin("Custom Shop", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CustomShop", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("CustomShop.txt")
	
	register_logevent("OnRoundStart", 2, "0=World triggered", "1=Round_Start")
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1)
	
	if(g_eSettings[CSHOP_POINTS_ENABLE])
	{
		register_event("DeathMsg", "OnPlayerKilled", "a")
		register_concmd("cshop_points", "Cmd_GivePoints", FLAG_ADMIN, "<nick|#userid> <points to give/take>")
		register_concmd("cshop_reset_points", "Cmd_ResetPoints", FLAG_ADMIN, "-- resets all points")
	}
	
	register_concmd("cshop_items", "Cmd_ListItems", FLAG_ADMIN, "-- lists all loaded items")
	register_clcmd("cshop_edit", "Menu_Editor", FLAG_ADMIN, "-- open the editor")
	register_clcmd("cshop_edit_item", "Cmd_Edit")
	
	g_fwdSelectItem = CreateMultiForward("cshop_item_selected", ET_STOP, FP_CELL, FP_CELL)
	g_fwdRemoveItem = CreateMultiForward("cshop_item_removed", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwdMenuOpened = CreateMultiForward("cshop_menu_opened", ET_STOP, FP_CELL)
	g_fwdSetPrice = CreateMultiForward("cshop_set_price", ET_STOP, FP_CELL, FP_CELL, FP_CELL)
	
	formatex(g_szItemsFile, charsmax(g_szItemsFile), "%s/CustomShopItems.ini", g_szConfigsName)
	formatex(g_szStatus[0], charsmax(g_szStatus[]), "%L", LANG_SERVER, "CSHOP_DISABLED")
	formatex(g_szStatus[1], charsmax(g_szStatus[]), "%L", LANG_SERVER, "CSHOP_ENABLED")
	
	if(g_eSettings[CSHOP_POINTS_ENABLE] && g_eSettings[CSHOP_POINTS_SAVE])
		g_iVault = nvault_open(g_szVaults[g_eSettings[CSHOP_SAVE_TYPE]])
	
	g_iHUD = CreateHudSyncObj()
	g_tLimit = TrieCreate()
	
	for(new i; i < sizeof(g_szOptions); i++)
		formatex(g_szOptions[i], charsmax(g_szOptions[]), "%L", LANG_SERVER, g_szOptionsL[i])
	
	if(g_iTotalItems > 0)
		loadItems(0)
		
	formStuff()
}

formStuff()
{
	formatex(g_szItemsLoaded, charsmax(g_szItemsLoaded), "%L", LANG_TYPE, "CSHOP_ITEMS_LOADED", g_iTotalItems)
	
	replace_all(g_eSettings[CSHOP_TITLE], charsmax(g_eSettings[CSHOP_TITLE]), g_szFields[FIELD_CURRENCY], g_eSettings[CSHOP_MONEY_NAME_UC])
	replace_all(g_eSettings[CSHOP_TITLE], charsmax(g_eSettings[CSHOP_TITLE]), g_szFields[FIELD_NEWLINE], "^n")
	replace_all(g_eSettings[CSHOP_TITLE_PAGE], charsmax(g_eSettings[CSHOP_TITLE_PAGE]), g_szFields[FIELD_NEWLINE], "^n")
		
	if(contain(g_eSettings[CSHOP_TITLE_PAGE], g_szFields[FIELD_PAGE]) != -1)
		replace_all(g_eSettings[CSHOP_TITLE_PAGE], charsmax(g_eSettings[CSHOP_TITLE_PAGE]), g_szFields[FIELD_PAGE], formatin("%L", LANG_TYPE, "CSHOP_PAGE"))
}

public plugin_precache()
{
	get_configsdir(g_szConfigsName, charsmax(g_szConfigsName))
	g_aItems = ArrayCreate(Items)
	g_tItemIds = TrieCreate()
	readSettings()
}

public plugin_end()
{		
	loadItems(0)
	loadItems(1)
	
	new eItem[Items]
	
	for(new i; i < g_iTotalItems; i++)
	{
		ArrayGetArray(g_aItems, i, eItem)
		ArrayDestroy(eItem[aSettings])
		TrieDestroy(eItem[tSettings])
		TrieDestroy(eItem[tTypes])
	}
	
	ArrayDestroy(g_aItems)
	TrieDestroy(g_tItemIds)
	
	if(g_eSettings[CSHOP_POINTS_ENABLE] && g_eSettings[CSHOP_POINTS_SAVE])
		nvault_close(g_iVault)
		
	DestroyForward(g_fwdSelectItem)
	DestroyForward(g_fwdRemoveItem)
	DestroyForward(g_fwdMenuOpened)
	DestroyForward(g_fwdSetPrice)
}

loadItems(iWrite)
{
	new iFilePointer
	
	switch(iWrite)
	{
		case 0:
		{
			iFilePointer = fopen(g_szItemsFile, "rt")
			
			if(iFilePointer)
			{
				new szData[192], szValue[160], szKey[32], szItemId[32], szStatus[16]
				new eItem[Items], iItem = -1, iType
				
				while(!feof(iFilePointer))
				{						
					fgets(iFilePointer, szData, charsmax(szData))
					trim(szData)
					
					switch(szData[0])
					{
						case EOS, ';', '/': continue
						case '[':
						{								
							if(szData[strlen(szData) - 1] == ']')
							{
								if(iItem + 1 == g_iTotalItems)
									continue
									
								if(iItem >= 0)
									ArraySetArray(g_aItems, iItem, eItem)
								
								replace(szData, charsmax(szData), "[", "")
								replace(szData, charsmax(szData), "]", "")
								trim(szData)
								
								iItem++
								parse(szData, szItemId, charsmax(szItemId), szStatus, charsmax(szStatus))
								TrieGetCell(g_tItemIds, szItemId, iItem)
								ArrayGetArray(g_aItems, iItem, eItem)
								eItem[Disabled] = szStatus[0] == g_szStatus[0][0]
							}
							else continue
						}
						default:
						{
							strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), ':')
							trim(szKey); trim(szValue)
							
							if(is_blank(szValue))
								continue
								
							if(equal(szKey, g_szOptions[OPTION_NAME]))
								copy(eItem[Name], charsmax(eItem[Name]), szValue)
							else if(equal(szKey, g_szOptions[OPTION_PRICE]))
								eItem[Price] = str_to_num(szValue)
							else if(equal(szKey, g_szOptions[OPTION_LIMIT]))
								eItem[Limit] = str_to_num(szValue)
							else if(equal(szKey, g_szOptions[OPTION_SOUND]))
								copy(eItem[Sound], charsmax(eItem[Sound]), szValue)
							else if(equal(szKey, g_szOptions[OPTION_DURATION]))
								eItem[Duration] = _:str_to_float(szValue)
							else if(equal(szKey, g_szOptions[OPTION_TEAM]))
								eItem[Team] = str_to_num(szValue)
							else if(equal(szKey, g_szOptions[OPTION_FLAG]))
								copy(eItem[Flags], charsmax(eItem[Flags]), szValue)
							else if(TrieKeyExists(eItem[tSettings], szKey))
							{
								TrieGetCell(eItem[tTypes], szKey, iType)
								
								switch(iType)
								{
									case ST_INT: TrieSetCell(eItem[tSettings], szKey, str_to_num(szValue))
									case ST_FLOAT: TrieSetCell(eItem[tSettings], szKey, str_to_float(szValue))
									case ST_STRING: TrieSetString(eItem[tSettings], szKey, szValue)
								}
							}
						}
					}
				}
				
				if(iItem >= 0)
					ArraySetArray(g_aItems, iItem, eItem)
					
				fclose(iFilePointer)
			}
		}
		case 1:
		{
			delete_file(g_szItemsFile)
			iFilePointer = fopen(g_szItemsFile, "wt")
			
			if(iFilePointer)
			{
				new szSetting[32], eItem[Items], iType, i, j
				new szValue[128], Float:fValue, iValue
				
				for(i = 0; i < g_iTotalItems; i++)
				{
					ArrayGetArray(g_aItems, i, eItem)
					
					if(eItem[Disabled])
					{
						fprintf(iFilePointer, "%s[%s %s]", i == 0 ? "" : "^n^n", eItem[Id], g_szStatus[0])
						continue
					}
					else
						fprintf(iFilePointer, "%s[%s %s]", i == 0 ? "" : "^n^n", eItem[Id], g_szStatus[1])
						
					fprintf(iFilePointer, "^n%s: %s", g_szOptions[OPTION_NAME], eItem[Name])
					fprintf(iFilePointer, "^n%s: %i", g_szOptions[OPTION_PRICE], eItem[Price])
					
					fprintf(iFilePointer, "^n%s: %i", g_szOptions[OPTION_LIMIT], eItem[Limit])
						
					if(!equal(eItem[Sound], DEFAULT_SOUND))
						fprintf(iFilePointer, "^n%s: %s", g_szOptions[OPTION_SOUND], eItem[Sound])
						
					if(eItem[Duration])
						fprintf(iFilePointer, "^n%s: %.1f", g_szOptions[OPTION_DURATION], eItem[Duration])
						
					if(eItem[Team])
						fprintf(iFilePointer, "^n%s: %i", g_szOptions[OPTION_TEAM], eItem[Team])
						
					if(!is_blank(eItem[Flags]))
						fprintf(iFilePointer, "^n%s: %s", g_szOptions[OPTION_FLAG], eItem[Flags])
					
					for(j = 0; j < eItem[SettingsNum]; j++)
					{
						ArrayGetString(eItem[aSettings], j, szSetting, charsmax(szSetting))
						TrieGetCell(eItem[tTypes], szSetting, iType)
						
						switch(iType)
						{
							case ST_INT:
							{
								TrieGetCell(eItem[tSettings], szSetting, iValue)
								fprintf(iFilePointer, "^n%s: %i", szSetting, iValue)
							}
							case ST_FLOAT:
							{
								TrieGetCell(eItem[tSettings], szSetting, fValue)
								fprintf(iFilePointer, "^n%s: %.1f", szSetting, fValue)
							}
							case ST_STRING:
							{
								TrieGetString(eItem[tSettings], szSetting, szValue, charsmax(szValue))
								fprintf(iFilePointer, "^n%s: %s", szSetting, szValue)
							}
						}
					}
				}
				
				fclose(iFilePointer)
			}
		}
	}
}	
	
readSettings()
{
	new szFilename[256], iFilePointer
	formatex(szFilename, charsmax(szFilename), "%s/CustomShop.ini", g_szConfigsName)
	iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[160], szKey[32], szValue[128], i
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			switch(szData[0])
			{
				case EOS, ';', '/': continue
				default:
				{
					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)
					
					if(is_blank(szValue))
						continue
					
					if(equal(szKey, "CSHOP_PREFIX"))
						CC_SetPrefix(szValue)
					else if(equal(szKey, "CSHOP_TITLE"))
						copy(g_eSettings[CSHOP_TITLE], charsmax(g_eSettings[CSHOP_TITLE]), szValue)
					else if(equal(szKey, "CSHOP_TITLE_PAGE"))
						copy(g_eSettings[CSHOP_TITLE_PAGE], charsmax(g_eSettings[CSHOP_TITLE_PAGE]), szValue)
					else if(equal(szKey, "CSHOP_TEAM_NAMES"))
					{
						for(i = 0; i < 4; i++)
						{
							strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ',')
							trim(szKey); trim(szValue)
							copy(g_szTeams[i], charsmax(g_szTeams[]), szKey)
						}
					}
					else if(equal(szKey, "CSHOP_SOUND_ERROR"))
					{
						copy(g_eSettings[CSHOP_SOUND_ERROR], charsmax(g_eSettings[CSHOP_SOUND_ERROR]), szValue)
						precache_sound(szValue)
					}
					else if(equal(szKey, "CSHOP_SOUND_EXPIRE"))
					{
						copy(g_eSettings[CSHOP_SOUND_EXPIRE], charsmax(g_eSettings[CSHOP_SOUND_EXPIRE]), szValue)
						precache_sound(szValue)
					}
					else if(equal(szKey, "CSHOP_SOUND_OPEN"))
					{
						copy(g_eSettings[CSHOP_SOUND_OPEN], charsmax(g_eSettings[CSHOP_SOUND_OPEN]), szValue)
						precache_sound(szValue)
					}
					else if(equal(szKey, "CSHOP_BUYSOUND_TYPE"))
						g_eSettings[CSHOP_BUYSOUND_TYPE] = clamp(str_to_num(szValue), 0, 1)
					else if(equal(szKey, "CSHOP_EXPIRESOUND_TYPE"))
						g_eSettings[CSHOP_EXPIRESOUND_TYPE] = clamp(str_to_num(szValue), 0, 1)
					else if(equal(szKey, "CSHOP_OPENSOUND_TYPE"))
						g_eSettings[CSHOP_OPENSOUND_TYPE] = clamp(str_to_num(szValue), 0, 1)
					else if(equal(szKey, "CSHOP_PREVPAGE"))
						copy(g_eSettings[CSHOP_PREVPAGE], charsmax(g_eSettings[CSHOP_PREVPAGE]), szValue)
					else if(equal(szKey, "CSHOP_NEXTPAGE"))
						copy(g_eSettings[CSHOP_NEXTPAGE], charsmax(g_eSettings[CSHOP_NEXTPAGE]), szValue)
					else if(equal(szKey, "CSHOP_EXITMENU"))
						copy(g_eSettings[CSHOP_EXITMENU], charsmax(g_eSettings[CSHOP_EXITMENU]), szValue)
					else if(equal(szKey, "CSHOP_PERPAGE"))
						g_eSettings[CSHOP_PERPAGE] = clamp(str_to_num(szValue), 0, 7)
					else if(equal(szKey, "CSHOP_COMMANDS"))
					{
						while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
						{
							trim(szKey); trim(szValue)
							register_clcmd(szKey, "Menu_Shop")
						}
					}
					else if(equal(szKey, "CSHOP_FLAG"))
						g_eSettings[CSHOP_FLAG] = szValue[0] == '!' ? ADMIN_ALL : read_flags(szValue)
					else if(equal(szKey, "CSHOP_TEAM"))
						g_eSettings[CSHOP_TEAM] = clamp(str_to_num(szValue), 0, 3)
					else if(equal(szKey, "CSHOP_POINTS_ENABLE"))
						g_eSettings[CSHOP_POINTS_ENABLE] = boolclamp(szValue)
					else if((g_eSettings[CSHOP_POINTS_ENABLE] && equal(szKey, "CSHOP_POINTS_NAME")) || (!g_eSettings[CSHOP_POINTS_ENABLE] && equal(szKey, "CSHOP_MONEY_NAME")))
					{
						copy(g_eSettings[CSHOP_MONEY_NAME], charsmax(g_eSettings[CSHOP_MONEY_NAME]), szValue)
						copy(g_eSettings[CSHOP_MONEY_NAME_UC], charsmax(g_eSettings[CSHOP_MONEY_NAME_UC]), szValue)
						ucfirst(g_eSettings[CSHOP_MONEY_NAME_UC])
					}
					else if((g_eSettings[CSHOP_POINTS_ENABLE] && equal(szKey, "CSHOP_POINTS_CURRENCY")) || (!g_eSettings[CSHOP_POINTS_ENABLE] && equal(szKey, "CSHOP_MONEY_CURRENCY")))
						copy(g_eSettings[CSHOP_CURRENCY], charsmax(g_eSettings[CSHOP_CURRENCY]), szValue)
					else if(equal(szKey, "CSHOP_POINTS_SAVE"))
						g_eSettings[CSHOP_POINTS_SAVE] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_SAVE_TYPE"))
						g_eSettings[CSHOP_SAVE_TYPE] = clamp(str_to_num(szValue), 0, 2)
					else if(equal(szKey, "CSHOP_POINTS_COMMANDS"))
					{
						while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
						{
							trim(szKey); trim(szValue)
							register_clcmd(szKey, "Cmd_Points")
						}
					}
					else if(equal(szKey, "CSHOP_SHOW_TEAMED"))
						g_eSettings[CSHOP_SHOW_TEAMED] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_ITEM_TEAMED"))
						copy(g_eSettings[CSHOP_ITEM_TEAMED], charsmax(g_eSettings[CSHOP_ITEM_TEAMED]), szValue)
					else if(equal(szKey, "CSHOP_SHOW_FLAGGED"))
						g_eSettings[CSHOP_SHOW_FLAGGED] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_ITEM_FLAGGED"))
						copy(g_eSettings[CSHOP_ITEM_FLAGGED], charsmax(g_eSettings[CSHOP_ITEM_FLAGGED]), szValue)
					else if(equal(szKey, "CSHOP_LIMIT_TYPE"))
						g_eSettings[CSHOP_LIMIT_TYPE] = clamp(str_to_num(szValue), 0, 2)
					else if(equal(szKey, "CSHOP_SAVE_LIMIT"))
						g_eSettings[CSHOP_SAVE_LIMIT] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_HIDE_LIMITED"))
						g_eSettings[CSHOP_HIDE_LIMITED] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_OPEN_AT_SPAWN"))
						g_eSettings[CSHOP_OPEN_AT_SPAWN] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_REOPEN_AFTER_USE"))
						g_eSettings[CSHOP_REOPEN_AFTER_USE] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_REWARD_NORMAL"))
						g_eSettings[CSHOP_REWARD_NORMAL] = str_to_num(szValue)
					else if(equal(szKey, "CSHOP_REWARD_HEADSHOT"))
						g_eSettings[CSHOP_REWARD_HEADSHOT] = str_to_num(szValue)
					else if(equal(szKey, "CSHOP_REWARD_KNIFE"))
						g_eSettings[CSHOP_REWARD_KNIFE] = str_to_num(szValue)
					else if(equal(szKey, "CSHOP_REWARD_VIP"))
						g_eSettings[CSHOP_REWARD_VIP] = str_to_num(szValue)
					else if(equal(szKey, "CSHOP_VIP_FLAG"))
						g_eSettings[CSHOP_VIP_FLAG] = read_flags(szValue)
					else if(equal(szKey, "CSHOP_POINTS_TEAMKILL"))
						g_eSettings[CSHOP_POINTS_TEAMKILL] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_KILL_MESSAGE"))
						g_eSettings[CSHOP_KILL_MESSAGE] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_HUD_ENABLED"))
						g_eSettings[CSHOP_HUD_ENABLED] = boolclamp(szValue)
					else if(equal(szKey, "CSHOP_HUD_RED"))
						g_eSettings[CSHOP_HUD_RED] = clamp(str_to_num(szValue), 0, 255)
					else if(equal(szKey, "CSHOP_HUD_GREEN"))
						g_eSettings[CSHOP_HUD_GREEN] = clamp(str_to_num(szValue), 0, 255)
					else if(equal(szKey, "CSHOP_HUD_BLUE"))
						g_eSettings[CSHOP_HUD_BLUE] = clamp(str_to_num(szValue), 0, 255)
					else if(equal(szKey, "CSHOP_HUD_X"))
						g_eSettings[CSHOP_HUD_X] = _:floatclamp(str_to_float(szValue), -1.0, 1.0)
					else if(equal(szKey, "CSHOP_HUD_Y"))
						g_eSettings[CSHOP_HUD_Y] = _:floatclamp(str_to_float(szValue), -1.0, 1.0)
				}
			}	
		}
		
		fclose(iFilePointer)
	}
}

public client_disconnect(id)
{
	if(!g_eSettings[CSHOP_LIMIT_TYPE] && g_eSettings[CSHOP_SAVE_LIMIT])
		TrieSetArray(g_tLimit, g_szInfo[id], g_iLimit[id], sizeof(g_iLimit[]))
		
	if(g_eSettings[CSHOP_POINTS_ENABLE] && g_eSettings[CSHOP_POINTS_SAVE])
		use_vault(id, 0, g_szInfo[id])
}
	
public client_connect(id)
{
	get_user_saveinfo(id)
	arrayset(g_bHasItem[id], false, sizeof(g_bHasItem[]))
	
	if(g_eSettings[CSHOP_REOPEN_AFTER_USE])
		g_iPage[id] = 0
	
	if(g_eSettings[CSHOP_SAVE_LIMIT])
	{
		if(!g_eSettings[CSHOP_LIMIT_TYPE])
			TrieSetArray(g_tLimit, g_szInfo[id], g_iLimit[id], sizeof(g_iLimit[]))
	}
	else
		arrayset(g_iLimit[id], 0, sizeof(g_iLimit[]))

	if(g_eSettings[CSHOP_POINTS_ENABLE])
	{
		if(g_eSettings[CSHOP_HUD_ENABLED])
			set_task(1.0, "showHUD", id + TASK_HUDBAR, _, _, "b")
		
		if(g_eSettings[CSHOP_POINTS_SAVE])
			use_vault(id, 1, g_szInfo[id])
	}
}

public client_infochanged(id)
{
	if(!g_eSettings[CSHOP_POINTS_ENABLE] || g_eSettings[CSHOP_SAVE_TYPE] > 0)
		return
		
	static szNewName[32], szOldName[32]
	get_user_info(id, "name", szNewName, charsmax(szNewName))
	get_user_name(id, szOldName, charsmax(szOldName))
	
	if(!equal(szNewName, szOldName))
	{
		use_vault(id, 0, szOldName)
		use_vault(id, 1, szNewName)
		
		if(!g_eSettings[CSHOP_SAVE_TYPE])
			get_user_saveinfo(id)
	}
}

use_vault(id, iType, szInfo[])
{
	if(is_blank(szInfo))
		return
	
	switch(iType)
	{
		case 0:
		{
			static szPoints[20]
			num_to_str(g_iPoints[id], szPoints, charsmax(szPoints))
			nvault_set(g_iVault, szInfo, szPoints)
		}
		case 1:	g_iPoints[id] = nvault_get(g_iVault, szInfo)
	}
}

public showHUD(id)
{
	id -= TASK_HUDBAR
	
	if(!is_user_connected(id))
	{
		remove_task(id + TASK_HUDBAR)
		return
	}
	
	set_hudmessage(g_eSettings[CSHOP_HUD_RED], g_eSettings[CSHOP_HUD_GREEN], g_eSettings[CSHOP_HUD_BLUE], g_eSettings[CSHOP_HUD_X], g_eSettings[CSHOP_HUD_Y], 0, 1.0, 1.5)
	ShowSyncHudMsg(id, g_iHUD, "%s: %i", g_eSettings[CSHOP_MONEY_NAME_UC], g_iPoints[id])
}

public OnRoundStart()
{
	if(g_eSettings[CSHOP_SAVE_LIMIT])
		return
		
	switch(g_eSettings[CSHOP_LIMIT_TYPE])
	{
		case 1:
		{		
			for(new i; i < 4; i++)
				arrayset(g_iItemTeamLimit[i], 0, sizeof(g_iItemTeamLimit[]))
		}
		case 2:	arrayset(g_iItemLimit, 0, sizeof(g_iItemLimit))
	}
}

public OnPlayerSpawn(id)
{
	if(!g_eSettings[CSHOP_LIMIT_TYPE] && !g_eSettings[CSHOP_SAVE_LIMIT])
	{
		static i
		arrayset(g_iLimit[id], 0, sizeof(g_iLimit[]))
		
		for(i = 0; i < g_iTotalItems; i++)
		{
			if(g_bHasItem[id][i])
				remove_item(id, i)
		}
	}
	
	if(g_eSettings[CSHOP_OPEN_AT_SPAWN] && has_access_flag(id) && has_access_team(id) && is_user_alive(id))
		Menu_Shop(id)
}

public OnPlayerKilled()
{
	static iAttacker, iVictim
	iAttacker = read_data(1)
	iVictim = read_data(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim || !is_user_connected(iVictim))
		return
	
	if(!has_access_flag(iAttacker))
		return
		
	if((get_user_team(iAttacker) == get_user_team(iVictim)) && !g_eSettings[CSHOP_POINTS_TEAMKILL])
		return
	
	static iReward
	iReward = g_eSettings[CSHOP_REWARD_NORMAL]
	
	if(read_data(3))
		iReward += g_eSettings[CSHOP_REWARD_HEADSHOT]
	
	if(g_eSettings[CSHOP_REWARD_KNIFE])
	{
		static szWeapon[16]
		read_data(4, szWeapon, charsmax(szWeapon))
	
		if(equal(szWeapon, "knife"))
			iReward += g_eSettings[CSHOP_REWARD_KNIFE]
	}
		
	if(g_eSettings[CSHOP_REWARD_VIP] && (get_user_flags(iAttacker) & g_eSettings[CSHOP_VIP_FLAG]))
		iReward += g_eSettings[CSHOP_REWARD_VIP]
		
	g_iPoints[iAttacker] += iReward
	
	if(g_eSettings[CSHOP_KILL_MESSAGE])
	{
		static szName[32]
		get_user_name(iVictim, szName, charsmax(szName))
		CC_SendMessage(iAttacker, "%L", iAttacker, "CSHOP_KILL", iReward, g_eSettings[CSHOP_CURRENCY], szName)
	}
}

public Cmd_Points(id)
{
	CC_SendMessage(id, g_eSettings[CSHOP_POINTS_ENABLE] ? formatin("%L", id, "CSHOP_POINTS", g_iPoints[id], g_eSettings[CSHOP_CURRENCY]) : formatin("%L", id, "CSHOP_POINTS_DISABLED"))	
	return PLUGIN_HANDLED
}

public Cmd_GivePoints(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED

	new szPlayer[32]
	read_argv(1, szPlayer, charsmax(szPlayer))
	
	new iPlayer
	iPlayer = cmd_target(id, szPlayer, 0)
	
	if(!iPlayer)
		return PLUGIN_HANDLED
	
	new szAmount[10]
	read_argv(2, szAmount, charsmax(szAmount))
	
	new iAmount = str_to_num(szAmount), bool:bGive = szAmount[0] == '-' ? false : true
	g_iPoints[iPlayer] += iAmount
	
	if(!bGive)
		iAmount *= -1
	
	new szMessage[192], szName[2][32]
	get_user_name(id, szName[0], charsmax(szName[]))
	get_user_name(iPlayer, szName[1], charsmax(szName[]))
	formatex(szMessage, charsmax(szMessage), "%L", LANG_TYPE, bGive ? "CSHOP_CMD_GIVE" : "CSHOP_CMD_TAKE", szName[0], iAmount, g_eSettings[CSHOP_CURRENCY], szName[1])
	CC_LogMessage(0, _, szMessage)
	return PLUGIN_HANDLED
}

public Cmd_ResetPoints(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED
	
	if(g_eSettings[CSHOP_POINTS_SAVE])
		nvault_clear(g_iVault)
	
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	arrayset(g_iPoints, 0, sizeof(g_iPoints))
	CC_LogMessage(0, _, "%L", LANG_PLAYER, "CSHOP_POINTS_RESET", szName)
	return PLUGIN_HANDLED
}

public Cmd_ListItems(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED
		
	new szItem[192], eItem[Items], i
	client_print(id, print_console, g_szItemsLoaded)
	
	for(i = 0; i < g_iTotalItems; i++)
	{
		ArrayGetArray(g_aItems, i, eItem)
		
		if(eItem[Disabled])
			continue
			
		formatex(szItem, charsmax(szItem), "#%i: %s [ %L: %i%s", i + 1, eItem[Name], id, "CSHOP_PRICE", eItem[Price], g_eSettings[CSHOP_CURRENCY])
		
		if(eItem[Limit])
			format(szItem, charsmax(szItem), "%s | %L: %i", szItem, id, "CSHOP_LIMIT", eItem[Limit])
			
		if(eItem[Duration])
			format(szItem, charsmax(szItem), "%s | %L: %.1f", szItem, id, "CSHOP_DURATION", eItem[Duration])
			
		if(eItem[Team])
			format(szItem, charsmax(szItem), "%s | %L: %i", szItem, id, "CSHOP_TEAM", eItem[Team])
			
		if(eItem[Flags])
			format(szItem, charsmax(szItem), "%s | %L: %s", szItem, id, "CSHOP_FLAG", eItem[Flags])
			
		add(szItem, charsmax(szItem), " ]")
		client_print(id, print_console, szItem)
	}
	
	client_print(id, print_console, g_szItemsLoaded)
	return PLUGIN_HANDLED
}

public Menu_Shop(id)
{
	static iReturn
	ExecuteForward(g_fwdMenuOpened, iReturn, id)
	
	if(iReturn)
		return iReturn
		
	if(!has_access_flag(id))
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOTALLOWED_FLAG")
		play_error_sound(id)
		return PLUGIN_HANDLED
	}
	
	static iUserTeam
	iUserTeam = get_user_team(id)
	
	if(!has_access_team(id))
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOTALLOWED_TEAM")
		play_error_sound(id)
		return PLUGIN_HANDLED
	}
	
	if(!is_user_alive(id))
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOTALLOWED_DEAD")
		play_error_sound(id)
		return PLUGIN_HANDLED
	}
	
	if(!is_blank(g_eSettings[CSHOP_SOUND_OPEN]))
	{
		switch(g_eSettings[CSHOP_OPENSOUND_TYPE])
		{
			case 0: sound_emit(id, g_eSettings[CSHOP_SOUND_OPEN])
			case 1: sound_speak(id, g_eSettings[CSHOP_SOUND_OPEN])
		}
	}
	
	static szTitle[256], szItem[128], szData[10], eItem[Items], iMoney
	iMoney = g_eSettings[CSHOP_POINTS_ENABLE] ? g_iPoints[id] : get_user_money(id)
	
	copy(szTitle, charsmax(szTitle), g_eSettings[CSHOP_TITLE])
	
	if(contain(szTitle, g_szFields[FIELD_TEAM]) != -1)
		replace_all(szTitle, charsmax(szTitle), g_szFields[FIELD_TEAM], g_szTeams[iUserTeam])
	
	if(contain(szTitle, g_szFields[FIELD_MONEY]) != -1)
	{
		static szMoney[16]
		num_to_str(iMoney, szMoney, charsmax(szMoney))
		replace_all(szTitle, charsmax(szTitle), g_szFields[FIELD_MONEY], szMoney)
	}
		
	static iMenu, iUserLimit, iPrice, i
	iMenu = menu_create(szTitle, "Shop_Handler")
	
	for(i = 0; i < g_iTotalItems; i++)
	{
		ArrayGetArray(g_aItems, i, eItem)
		
		if(eItem[Disabled])
			continue
		
		if(eItem[Team] && eItem[Team] != iUserTeam)
		{
			if(g_eSettings[CSHOP_SHOW_TEAMED])
			{
				formatex(szItem, charsmax(szItem), "\d%s %s", eItem[Name], g_eSettings[CSHOP_ITEM_TEAMED])
				goto @ADD_ITEM
			}
			
			continue
		}
		
		if(!has_all_flags(id, eItem[Flags]))
		{
			if(g_eSettings[CSHOP_SHOW_FLAGGED])
			{
				formatex(szItem, charsmax(szItem), "\d%s %s", eItem[Name], g_eSettings[CSHOP_ITEM_FLAGGED])
				goto @ADD_ITEM
			}
				
			continue
		}
		
		iUserLimit = get_user_limit(id, i)
		
		if(g_eSettings[CSHOP_HIDE_LIMITED] && (eItem[Limit] && iUserLimit == eItem[Limit]))
			continue
			
		ExecuteForward(g_fwdSetPrice, iReturn, id, i, eItem[Price])
		
		if(iReturn)
			iPrice = iReturn
		else
			iPrice = eItem[Price]
		
		if(eItem[Limit])
			formatex(szItem, charsmax(szItem), "%s%s \r[\y%i%s\r] [\y%i\r/\y%i\r]", 
			(iMoney >= iPrice && iUserLimit < eItem[Limit]) ? "" : "\d", eItem[Name], iPrice, g_eSettings[CSHOP_CURRENCY], iUserLimit, eItem[Limit])
		else
			formatex(szItem, charsmax(szItem), "%s%s \r[\y%i%s\r]", 
			(iMoney >= iPrice) ? "" : "\d", eItem[Name], iPrice, g_eSettings[CSHOP_CURRENCY])
		
		@ADD_ITEM:
		num_to_str(i, szData, charsmax(szData))
		add(szData, charsmax(szData), formatin(" %i", iPrice))
		menu_additem(iMenu, szItem, szData)
	}
	
	static iPages
	iPages = menu_pages(iMenu)
	
	if(!iPages)
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOITEMS")
		play_error_sound(id)
	}
	else
	{
		if(iPages > 1)
		{
			add(szTitle, charsmax(szTitle), g_eSettings[CSHOP_TITLE_PAGE])
			menu_setprop(iMenu, MPROP_TITLE, szTitle)
		}
			
		menu_setprop(iMenu, MPROP_BACKNAME, g_eSettings[CSHOP_PREVPAGE])
		menu_setprop(iMenu, MPROP_NEXTNAME, g_eSettings[CSHOP_NEXTPAGE])
		menu_setprop(iMenu, MPROP_EXITNAME, g_eSettings[CSHOP_EXITMENU])
		menu_setprop(iMenu, MPROP_PERPAGE, g_eSettings[CSHOP_PERPAGE])
		
		if(g_eSettings[CSHOP_REOPEN_AFTER_USE])
		{
			menu_display(id, iMenu, clamp(g_iPage[id], .max = iPages - 1))
			g_iPage[id] = 0
		}
		else menu_display(id, iMenu)
	}
	
	return PLUGIN_HANDLED
}

public Shop_Handler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT || !is_user_alive(id))
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
	
	static iReturn
	ExecuteForward(g_fwdMenuOpened, iReturn, id)
	
	if(iReturn == PLUGIN_HANDLED)
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
		
	static szData[10], szPrice[7], szKey[3], iUnused, iPrice, iKey
	menu_item_getinfo(iMenu, iItem, iUnused, szData, charsmax(szData), .callback = iUnused)
	parse(szData, szKey, charsmax(szKey), szPrice, charsmax(szPrice))
	iKey = str_to_num(szKey)
	iPrice = str_to_num(szPrice)
	
	static eItem[Items], iMoney, iUserLimit
	iMoney = g_eSettings[CSHOP_POINTS_ENABLE] ? g_iPoints[id] : get_user_money(id)
	iUserLimit = get_user_limit(id, iKey)
	ArrayGetArray(g_aItems, iKey, eItem)
	
	if(eItem[Team] && eItem[Team] != get_user_team(id))
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOT_TEAM")
		play_error_sound(id)
	}
	else if(!has_all_flags(id, eItem[Flags]))
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOT_FLAG")
		play_error_sound(id)
	}
	else if(iMoney < iPrice)
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOT_MONEY", g_eSettings[CSHOP_MONEY_NAME], iMoney, iPrice, g_eSettings[CSHOP_CURRENCY])
		play_error_sound(id)
	}
	else if(eItem[Limit] && (iUserLimit == eItem[Limit]))
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOT_LIMIT", iUserLimit, eItem[Limit])
		play_error_sound(id)
	}
	else if(eItem[Duration] && g_bHasItem[id][iKey])
	{
		CC_SendMessage(id, "%L", id, "CSHOP_NOT_DELAY", eItem[Duration])
		play_error_sound(id)
	}
	else buyItem(id, iKey, iPrice)
	
	menu_destroy(iMenu)
	
	if(g_eSettings[CSHOP_REOPEN_AFTER_USE])
	{
		static iUnused
		player_menu_info(id, iUnused, iUnused, g_iPage[id])
		Menu_Shop(id)
	}
		
	return PLUGIN_HANDLED
}

public Menu_Editor(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED
		
	static eItem[Items], szTitle[128], szItem[34], iMenu, i
	formatex(szTitle, charsmax(szTitle), "%L", id, "CSHOP_EDITOR_TITLE")
	iMenu = menu_create(szTitle, "Handler_Editor")
	formatex(szItem, charsmax(szItem), "%s%L", g_bUnsaved ? "\y" : "\d", id, "CSHOP_EDITOR_SAVE")
	menu_additem(iMenu, szItem, "#save")
	menu_addblank(iMenu, 0)
	
	for(i = 0; i < g_iTotalItems; i++)
	{
		ArrayGetArray(g_aItems, i, eItem)
		copy(szItem, charsmax(szItem), eItem[Id])
		format(szItem, charsmax(szItem), "%s%s", eItem[Disabled] ? "\r" : "", szItem)
		menu_additem(iMenu, szItem)
	}
	
	menu_setprop(iMenu, MPROP_BACKNAME, g_eSettings[CSHOP_PREVPAGE])
	menu_setprop(iMenu, MPROP_NEXTNAME, g_eSettings[CSHOP_NEXTPAGE])
	menu_setprop(iMenu, MPROP_EXITNAME, g_eSettings[CSHOP_EXITMENU])
	menu_setprop(iMenu, MPROP_PERPAGE, g_eSettings[CSHOP_PERPAGE])
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}

public Handler_Editor(id, iMenu, iItem)
{
	if(iItem != MENU_EXIT)
	{
		static szKey[2], iUnused
		menu_item_getinfo(iMenu, iItem, iUnused, szKey, charsmax(szKey), .callback = iUnused)
		
		if(szKey[0] == '#')
		{
			if(g_bUnsaved)
			{
				loadItems(1)
				CC_SendMessage(id, "%L", id, "CSHOP_EDITOR_SAVED")
				g_bUnsaved = false
			}
			else
				CC_SendMessage(id, "%L", id, "CSHOP_EDITOR_CANTSAVE")
		}
		else
		{
			g_iEditItem[id] = iItem - 1
			ArrayGetArray(g_aItems, g_iEditItem[id], g_eEditArray[id])
			Menu_EditItem(id)
		}
	}
		
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public Menu_EditItem(id)
{
	static szTitle[128], szValue[128], szSetting[32], Float:fValue, iValue, iType, iMenu, i
	formatex(szTitle, charsmax(szTitle), "%L^n%L\d", id, "CSHOP_EDITOR_TITLE", id, "CSHOP_EDITOR_CURRENT", g_eEditArray[id][Id])
	iMenu = menu_create(szTitle, "Handler_EditItem")
	
	menu_additem(iMenu, g_eEditArray[id][Disabled] ? formatin("%L: \r%L", id, "CSHOP_EDITOR_STATUS", id, "CSHOP_DISABLED") : formatin("%L: \y%L", id, "CSHOP_EDITOR_STATUS", id, "CSHOP_ENABLED"))
	menu_additem(iMenu, formatin("%L: \d%s", id, "CSHOP_NAME", g_eEditArray[id][Name]))
	menu_additem(iMenu, formatin("%L: \d%i", id, "CSHOP_PRICE", g_eEditArray[id][Price]))
	menu_additem(iMenu, formatin("%L: \d%i", id, "CSHOP_LIMIT", g_eEditArray[id][Limit]))
	menu_additem(iMenu, formatin("%L: \d%s", id, "CSHOP_SOUND", g_eEditArray[id][Sound]))
	menu_additem(iMenu, formatin("%L: \d%.1f", id, "CSHOP_DURATION", g_eEditArray[id][Duration]))
	menu_additem(iMenu, formatin("%L: \d%i", id, "CSHOP_TEAM", g_eEditArray[id][Team]))
	menu_additem(iMenu, formatin("%L: \d%s", id, "CSHOP_FLAG", g_eEditArray[id][Flags]))
	
	for(i = 0; i < g_eEditArray[id][SettingsNum]; i++)
	{
		ArrayGetString(g_eEditArray[id][aSettings], i, szSetting, charsmax(szSetting))
		TrieGetCell(g_eEditArray[id][tTypes], szSetting, iType)
		
		switch(iType)
		{
			case ST_INT:
			{
				TrieGetCell(g_eEditArray[id][tSettings], szSetting, iValue)
				menu_additem(iMenu, formatin("%s: \d%i", szSetting, iValue), szSetting)
			}
			case ST_FLOAT:
			{
				TrieGetCell(g_eEditArray[id][tSettings], szSetting, fValue)
				menu_additem(iMenu, formatin("%s: \d%.1f", szSetting, fValue), szSetting)
			}
			case ST_STRING:
			{
				TrieGetString(g_eEditArray[id][tSettings], szSetting, szValue, charsmax(szValue))
				menu_additem(iMenu, formatin("%s: \d%s", szSetting, szValue), szSetting)
			}
		}
	}
	
	menu_setprop(iMenu, MPROP_BACKNAME, g_eSettings[CSHOP_PREVPAGE])
	menu_setprop(iMenu, MPROP_NEXTNAME, g_eSettings[CSHOP_NEXTPAGE])
	menu_setprop(iMenu, MPROP_EXITNAME, g_eSettings[CSHOP_EXITMENU])
	menu_setprop(iMenu, MPROP_PERPAGE, g_eSettings[CSHOP_PERPAGE])
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}

public Handler_EditItem(id, iMenu, iItem)
{
	switch(iItem)
	{
		case MENU_EXIT:
			goto @DESTROY_MENU
		case EDIT_SOUND:
		{
			CC_SendMessage(id, "%L", id, "CSHOP_EDITOR_SOUND")
			goto @DESTROY_MENU
		}
		case EDIT_STATUS:
		{
			static szName[32]
			get_user_name(id, szName, charsmax(szName))
			g_eEditArray[id][Disabled] = g_eEditArray[id][Disabled] ? false : true
			ArraySetArray(g_aItems, g_iEditItem[id], g_eEditArray[id])
			log_amx("%L", LANG_SERVER, "CSHOP_EDITOR_TOGGLE", szName, g_eEditArray[id][Id])
			g_bUnsaved = true
			menu_destroy(iMenu)
			Menu_EditItem(id)
			return PLUGIN_HANDLED
		}
	}
	
	g_bAllowEdit[id] = true
	g_iEditChoice[id] = iItem
	
	static iUnused
	menu_item_getinfo(iMenu, iItem, iUnused, g_szEditSetting[id], charsmax(g_szEditSetting[]), .callback = iUnused)
	client_cmd(id, "messagemode cshop_edit_item")
	
	@DESTROY_MENU:
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public Cmd_Edit(id)
{
	if(!g_bAllowEdit[id])
		return PLUGIN_HANDLED
	
	static szArgs[128]
	read_args(szArgs, charsmax(szArgs))
	remove_quotes(szArgs)
	
	switch(g_iEditChoice[id])
	{
		case EDIT_NAME: copy(g_eEditArray[id][Name], charsmax(g_eEditArray[][Name]), szArgs)
		case EDIT_PRICE: g_eEditArray[id][Price] = str_to_num(szArgs)
		case EDIT_LIMIT: g_eEditArray[id][Limit] = str_to_num(szArgs)
		case EDIT_DURATION: g_eEditArray[id][Duration] = _:str_to_float(szArgs)
		case EDIT_TEAM: g_eEditArray[id][Team] = str_to_num(szArgs)
		case EDIT_FLAG: copy(g_eEditArray[id][Flags], charsmax(g_eEditArray[][Flags]), szArgs)
		default:
		{
			static iType
			TrieGetCell(g_eEditArray[id][tTypes], g_szEditSetting[id], iType)
			
			switch(iType)
			{
				case ST_INT: TrieSetCell(g_eEditArray[id][tSettings], g_szEditSetting[id], str_to_num(szArgs))
				case ST_FLOAT: TrieSetCell(g_eEditArray[id][tSettings], g_szEditSetting[id], str_to_float(szArgs))
				case ST_STRING: TrieSetString(g_eEditArray[id][tSettings], g_szEditSetting[id], szArgs)
			}
		}
	}
	
	ArraySetArray(g_aItems, g_iEditItem[id], g_eEditArray[id])
	g_bUnsaved = true
	
	static szName[32]
	get_user_name(id, szName, charsmax(szName))
	CC_LogMessage(0, _, "^x04%s &x01> %L", szName, id, "CSHOP_EDITOR_SET", g_eEditArray[id][Id], szArgs)
	
	g_bAllowEdit[id] = false
	Menu_EditItem(id)
	return PLUGIN_HANDLED
}

buyItem(id, iItem, iPrice)
{
	static iReturn
	ExecuteForward(g_fwdSelectItem, iReturn, id, iItem)
	
	if(iReturn)
		return iReturn
		
	static eItem[Items]
	ArrayGetArray(g_aItems, iItem, eItem)
	
	if(g_eSettings[CSHOP_POINTS_ENABLE])
		g_iPoints[id] -= iPrice
	else
		take_user_money(id, iPrice)
		
	CC_SendMessage(id, "%L", id, "CSHOP_ITEM_BOUGHT", eItem[Name], iPrice, g_eSettings[CSHOP_CURRENCY])
	
	switch(g_eSettings[CSHOP_BUYSOUND_TYPE])
	{
		case 0: sound_emit(id, eItem[Sound])
		case 1: sound_speak(id, eItem[Sound])
	}
	
	switch(g_eSettings[CSHOP_LIMIT_TYPE])
	{
		case 0: g_iLimit[id][iItem]++
		case 1: g_iItemTeamLimit[get_user_team(id)][iItem]++
		case 2: g_iItemLimit[iItem]++
	}
	
	g_bHasItem[id][iItem] = true
	
	if(eItem[Duration])
	{
		static iArray[2]
		iArray[0] = id
		iArray[1] = iItem
		set_task(eItem[Duration], "autoRemoveItem", 0, iArray, 2)
	}
	
	return PLUGIN_HANDLED
}

public autoRemoveItem(iArray[2])
{
	static eItem[Items], id, iItem
	id = iArray[0], iItem = iArray[1]
	ArrayGetArray(g_aItems, iItem, eItem)
	remove_item(id, iItem)
	
	if(is_user_alive(id))
	{
		CC_SendMessage(id, "%L", id, "CSHOP_ITEM_EXPIRED", eItem[Duration], eItem[Name])
		
		switch(g_eSettings[CSHOP_EXPIRESOUND_TYPE])
		{
			case 0:	sound_emit(id, g_eSettings[CSHOP_SOUND_EXPIRE])
			case 1:	sound_speak(id, g_eSettings[CSHOP_SOUND_EXPIRE])
		}
	}
}

/*public Disable_Item(id, iMenu, iItem)
	return ITEM_DISABLED*/

get_user_saveinfo(id)
{
	switch(g_eSettings[CSHOP_SAVE_TYPE])
	{
		case 0: get_user_name(id, g_szInfo[id], charsmax(g_szInfo[]))
		case 1: get_user_ip(id, g_szInfo[id], charsmax(g_szInfo[]), 1)
		case 2: get_user_authid(id, g_szInfo[id], charsmax(g_szInfo[]))
	}
}

get_user_limit(id, iItem)
{
	switch(g_eSettings[CSHOP_LIMIT_TYPE])
	{
		case 0: return g_iLimit[id][iItem]
		case 1: return g_iItemTeamLimit[get_user_team(id)][iItem]
		case 2: return g_iItemLimit[iItem]
	}
	
	return 0
}

remove_item(id, iItem)
{
	static iReturn
	g_bHasItem[id][iItem] = false
	ExecuteForward(g_fwdRemoveItem, iReturn, id, iItem)
}
	
sound_speak(id, szSound[])
	client_cmd(id, "spk %s", szSound)
	
sound_emit(id, szSound[])
	emit_sound(id, CHAN_ITEM, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
play_error_sound(id)
	sound_speak(id, g_eSettings[CSHOP_SOUND_ERROR])
	
bool:boolclamp(szString[])
	return bool:clamp(str_to_num(szString), false, true)
	
bool:has_access_flag(id)
	return (g_eSettings[CSHOP_FLAG] == ADMIN_ALL || get_user_flags(id) & g_eSettings[CSHOP_FLAG])
	
bool:has_access_team(id)
	return (!g_eSettings[CSHOP_TEAM] || get_user_team(id) == g_eSettings[CSHOP_TEAM])
	
bool:is_blank(szString[])
	return szString[0] == EOS
	
public plugin_natives()
{
	register_library("CustomShop")
	register_native("cshop_register_item", "_cshop_register_item")
	register_native("cshop_has_item", "_cshop_has_item")
	register_native("cshop_points_enabled", "_cshop_points_enabled")
	register_native("cshop_get_limit", "_cshop_get_limit")
	register_native("cshop_remove_item", "_cshop_remove_item")
	register_native("cshop_error_sound", "_cshop_error_sound")
	register_native("cshop_total_items", "_cshop_total_items")
	register_native("cshop_give_points", "_cshop_give_points")
	register_native("cshop_get_points", "_cshop_get_points")
	register_native("cshop_get_prefix", "_cshop_get_prefix")
	register_native("cshop_open", "_cshop_open")	
	register_native("cshop_set_int", "_cshop_set_int")	
	register_native("cshop_set_float", "_cshop_set_float")	
	register_native("cshop_set_string", "_cshop_set_string")
	register_native("cshop_get_int", "_cshop_get_int")	
	register_native("cshop_get_float", "_cshop_get_float")	
	register_native("cshop_get_string", "_cshop_get_string")
	register_native("cshop_find_item_by_id", "_cshop_find_item_by_id")
	register_native("cshop_get_item_data", "_cshop_get_item_data")
}

public _cshop_register_item(iPlugin, iParams)
{
	static eItem[Items]
	get_string(1, eItem[Id], charsmax(eItem[Id]))
	get_string(2, eItem[Name], charsmax(eItem[Name]))
	
	if(g_eSettings[CSHOP_POINTS_ENABLE])
	{
		static iPoints
		iPoints = get_param(7)
		eItem[Price] = iPoints ? iPoints : mtop(get_param(3))
	}
	else eItem[Price] = get_param(3)
	
	eItem[Limit] = get_param(4)
	get_string(5, eItem[Sound], charsmax(eItem[Sound]))
	eItem[Duration] = _:get_param_f(6)
	eItem[Team] = get_param(8)
	get_string(9, eItem[Flags], charsmax(eItem[Flags]))
	
	eItem[aSettings] = _:ArrayCreate(32)
	eItem[tSettings] = _:TrieCreate()
	eItem[tTypes] = _:TrieCreate()
	ArrayPushArray(g_aItems, eItem)
	g_iTotalItems++
	
	if(!eItem[Sound][0])
		copy(eItem[Sound], charsmax(eItem[Sound]), DEFAULT_SOUND)
		
	precache_sound(eItem[Sound])
	
	static id
	id = g_iTotalItems - 1
	TrieSetCell(g_tItemIds, eItem[Id], id)
	return id
}

public bool:_cshop_has_item(iPlugin, iParams)
	return g_bHasItem[get_param(1)][get_param(2)] ? true : false
	
public bool:_cshop_points_enabled(iPlugin, iParams)
	return g_eSettings[CSHOP_POINTS_ENABLE] ? true : false
	
public _cshop_get_limit(iPlugin, iParams)
	return get_user_limit(get_param(1), get_param(2))
	
public _cshop_remove_item(iPlugin, iParams)
	remove_item(get_param(1), get_param(2))

public _cshop_error_sound(iPlugin, iParams)
	sound_speak(get_param(1), g_eSettings[CSHOP_SOUND_ERROR])
	
public _cshop_total_items(iPlugin, iParams)
	return g_iTotalItems
	
public _cshop_give_points(iPlugin, iParams)
	g_iPoints[get_param(1)] += get_param(2)
	
public _cshop_get_points(iPlugin, iParams)
	return g_iPoints[get_param(1)]
	
public _cshop_get_prefix(iPlugin, iParams)
	set_string(1, CC_PREFIX, get_param(2))
	
public _cshop_open(iPlugin, iParams)
	Menu_Shop(get_param(1))
	
public _cshop_set_int(iPlugin, iParams)
{
	static szSetting[32], eItem[Items], iValue, iItem
	iValue = get_param(3), iItem = get_param(1)
	get_string(2, szSetting, charsmax(szSetting))
	ArrayGetArray(g_aItems, iItem, eItem)
	TrieSetCell(eItem[tSettings], szSetting, iValue)
	TrieSetCell(eItem[tTypes], szSetting, ST_INT)
	eItem[SettingsNum]++
	ArrayPushString(eItem[aSettings], szSetting)
	ArraySetArray(g_aItems, iItem, eItem)
}

public _cshop_set_float(iPlugin, iParams)
{
	static szSetting[32], eItem[Items], Float:fValue, iItem
	fValue = get_param_f(3), iItem = get_param(1)
	get_string(2, szSetting, charsmax(szSetting))
	ArrayGetArray(g_aItems, iItem, eItem)
	TrieSetCell(eItem[tSettings], szSetting, fValue)
	TrieSetCell(eItem[tTypes], szSetting, ST_FLOAT)
	eItem[SettingsNum]++
	ArrayPushString(eItem[aSettings], szSetting)
	ArraySetArray(g_aItems, iItem, eItem)
}

public _cshop_set_string(iPlugin, iParams)
{
	static szSetting[32], szValue[128], eItem[Items], iItem
	iItem = get_param(1)
	get_string(2, szSetting, charsmax(szSetting))
	get_string(3, szValue, charsmax(szValue))
	ArrayGetArray(g_aItems, iItem, eItem)
	TrieSetString(eItem[tSettings], szSetting, szValue)
	TrieSetCell(eItem[tTypes], szSetting, ST_STRING)
	eItem[SettingsNum]++
	ArrayPushString(eItem[aSettings], szSetting)
	ArraySetArray(g_aItems, iItem, eItem)
	
	/*switch(iType)
	{
		case CSHOP_PRECACHE_GENERIC: precache_generic(szValue)
		case CSHOP_PRECACHE_MODEL: precache_model(szValue)
		case CSHOP_PRECACHE_SOUND: precache_sound(szValue)
	}*/
}

public _cshop_get_int(iPlugin, iParams)
{
	static szSetting[32], eItem[Items], iValue, iItem
	iItem = get_param(1)
	get_string(2, szSetting, charsmax(szSetting))
	ArrayGetArray(g_aItems, iItem, eItem)
	TrieGetCell(eItem[tSettings], szSetting, iValue)
	return iValue
}

public Float:_cshop_get_float(iPlugin, iParams)
{
	static szSetting[32], eItem[Items], Float:fValue, iItem
	iItem = get_param(1)
	get_string(2, szSetting, charsmax(szSetting))
	ArrayGetArray(g_aItems, iItem, eItem)
	TrieGetCell(eItem[tSettings], szSetting, fValue)
	return fValue
}

public _cshop_get_string(iPlugin, iParams)
{
	static szSetting[32], szValue[128], eItem[Items], iItem
	iItem = get_param(1)
	get_string(2, szSetting, charsmax(szSetting))
	ArrayGetArray(g_aItems, iItem, eItem)
	TrieGetString(eItem[tSettings], szSetting, szValue, charsmax(szValue))
	set_string(3, szValue, get_param(4))
}

public _cshop_find_item_by_id(iPlugin, iParams)
{
	static szItem[32], id
	get_string(1, szItem, charsmax(szItem))
	
	if(!TrieKeyExists(g_tItemIds, szItem))
		return -1
		
	id = TrieGetCell(g_tItemIds, szItem, id)
	return id
}

public any:_cshop_get_item_data(iPlugin, iParams)
{
	static eItem[Items]
	ArrayGetArray(g_aItems, get_param(1), eItem)
	
	switch(get_param(2))
	{
		case CSHOP_DATA_ID: set_string(3, eItem[Id], get_param(4))
		case CSHOP_DATA_NAME: set_string(3, eItem[Name], get_param(4))
		case CSHOP_DATA_PRICE: return eItem[Price]
		case CSHOP_DATA_LIMIT: return eItem[Limit]
		case CSHOP_DATA_SOUND: set_string(3, eItem[Sound], get_param(4))
		case CSHOP_DATA_DURATION: return eItem[Duration]
		case CSHOP_DATA_TEAM: return eItem[Team]
		case CSHOP_DATA_FLAGS: set_string(3, eItem[Flags], get_param(4))
		default: return -1
	}
	
	return 1
}