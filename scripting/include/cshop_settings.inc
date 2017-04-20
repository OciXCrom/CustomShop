#if defined _cshop_settings_included
    #endinput
#endif

#include <cstrike>

#define _cshop_settings_included
#define DEFAULT_SOUND "items/gunpickup2.wav"
#define FLAG_ADMIN ADMIN_BAN
#define LANG_TYPE LANG_SERVER
#define MAX_ITEMS 100

/*
	* Change the lines below if you want to use a native for your money currency, e.g. Ammo Packs, BaseBuilder Credits, JBPacks, etc.
	* Example (%1 = id | %2 = amount):
		native zp_get_user_ammo_packs(id)
		native zp_set_user_ammo_packs(id, amount)
		#define get_user_money(%1) zp_get_user_ammo_packs(%1)
		#define set_user_money(%1,%2) zp_set_user_ammo_packs(%1, %2)
*/
#define get_user_money(%1) cs_get_user_money(%1)
#define set_user_money(%1,%2) cs_set_user_money(%1, %2)

/* Don't touch this line unless you know what you're doing */
#define take_user_money(%1,%2) set_user_money(%1, get_user_money(%1) - %2)