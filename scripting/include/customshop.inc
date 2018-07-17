#if defined _customshop_included
    #endinput
#endif

#include <cshop_settings>

#define _customshop_included

/**
 * Used in cshop_item_selected() to prevent buying an item
 */
#define DONT_BUY PLUGIN_HANDLED

/**
 * Used in cshop_item_selected() to allow buying an item
 */
#define BUY_ITEM PLUGIN_CONTINUE

/**
 * Used in cshop_menu_opened() to prevent opening the shop
 */
#define SHOP_CLOSE PLUGIN_HANDLED

/**
 * Used in cshop_menu_opened() to allow opening the shop
 */
#define SHOP_OPEN PLUGIN_CONTINUE

/**
 * Typically used for registering an item variable, nothing fancy
 */
#define additem new

/**
 * Data types for cshop_get_item_data()
 */
enum _:CshopData
{
	CSHOP_DATA_ID = 0,
	CSHOP_DATA_NAME,
	CSHOP_DATA_PRICE,
	CSHOP_DATA_LIMIT,
	CSHOP_DATA_SOUND,
	CSHOP_DATA_DURATION,
	CSHOP_DATA_TEAM,
	CSHOP_DATA_FLAGS
}

/** 
 * Registers a new item.
 * 
 * @param id	 		Item short name (id).
 * @param name	 		Item name.
 * @param price 		Item price.
 * @param limit			Item limit.
 * @param sound 		Sound when buying the item.
 * @param duration		If you want the item to be removed after X seconds, instead of right away.
 * @param points		If you want to change the price with points.
 * @param team	 		If you want it to be available for a specific team only.
 * @param flag	 		If you want only players with a specific flag to be able to buy the item.
 * @return				Item ID.
 */
native cshop_register_item(id[], name[], price, limit = 0, sound[] = DEFAULT_SOUND, Float:duration = 0.0, points = 0, team = 0, flag[] = "")
#define cshopRegisterItem cshop_register_item

/** 
 * Checks whether a player has an item or not.
 * 
 * @param id 			Player's index.
 * @param item			Item ID.
 * @return				True if he has, false if he hasn't.
 */
native bool:cshop_has_item(id, item)
#define cshopHasItem cshop_has_item

/** 
 * Checks whether the points system is enabled.
 * 
 * @return				True if it is, false if it isn't.
 */
native bool:cshop_points_enabled()
#define cshopPointsEnabled cshop_points_enabled

/** 
 * Checks player's item limit.
 * 
 * @param id 			Player's index.
 * @param item			Item ID.
 * @return				Player's item limit.
 */
native cshop_get_limit(id, item)
#define cshopGetLimit cshop_get_limit

/** 
 * Removes a player's item.
 * 
 * @param id 			Player's index.
 * @param item			Item ID.
 * @noreturn
 */
native cshop_remove_item(id, item)
#define cshopRemoveItem cshop_remove_item

/** 
 * Called right before an item is purchased.
 *
 * @param id 			Player's index.
 * @param item			Item ID.
 * @noreturn
 */
forward cshop_item_selected(id, item)
#define cshopItemBought cshop_item_selected

/** 
 * Called when an item is removed.
 *
 * @param id 			Player's index.
 * @param item			Item ID.
 * @noreturn
 */
forward cshop_item_removed(id, item)
#define cshopItemRemoved cshop_item_removed

/** 
 * Called right before the menu is opened.
 *
 * @param id 			Player's index.
 * @noreturn
 */
forward cshop_menu_opened(id, item)

/** 
 * Plays the error sound on a player.
 * 
 * @param id 			Player's index.
 * @noreturn
 */
native cshop_error_sound(id)
#define cshopErrorSound cshop_error_sound

/** 
 * Gets the total number of loaded items.
 * 
 * @return				Total number of loaded items.
 */
native cshop_total_items()
#define cshopTotalItems cshop_total_items

/** 
 * Give/take points to/from a player.
 *
 * @param id 			Player's index.
 * @param points		Amount of points.
 * @noreturn
 */
native cshop_give_points(id, points)
#define cshopGivePoints cshop_give_points

/** 
 * Return player points.
 *
 * @param id 			Player's index.
 * @return 				Player's points.
 */
native cshop_get_points(id)
#define cshopGetPoints cshop_get_points

/** 
 * Gets the plugin prefix.
 *
 * @param prefix 		Buffer.
 * @param len 			Max buffer length.
 * @noreturn
 */
native cshop_get_prefix(prefix[], len)

/** 
 * Tries to open the shop menu.
 *
 * @param id 			Player's id.
 * @noreturn
 */
native cshop_open(id)

/** 
 * Registers an integer setting for a specific item.
 *
 * @param item 			Item id.
 * @param setting 		Setting's name.
 * @param value 		Setting's default value.
 * @noreturn
 */
native cshop_set_int(item, setting[], value)

/** 
 * Registers a float setting for a specific item.
 *
 * @param item 			Item id.
 * @param setting 		Setting's name.
 * @param value 		Setting's default value.
 * @noreturn
 */
native cshop_set_float(item, setting[], Float:value)

/** 
 * Registers a string setting for a specific item.
 *
 * @param item 			Item id.
 * @param setting 		Setting's name.
 * @param value 		Setting's default value.
 * @noreturn
 */
native cshop_set_string(item, setting[], value[])

/** 
 * Returns an integer value from a specific item's setting.
 *
 * @param item 			Item id.
 * @param setting 		Setting's name.
 * @return				Setting's value.
 */
native cshop_get_int(item, setting[])

/** 
 * Returns a float value from a specific item's setting.
 *
 * @param item 			Item id.
 * @param setting 		Setting's name.
 * @return				Setting's value.
 */
native Float:cshop_get_float(item, setting[])

/** 
 * Returns a string value from a specific item's setting.
 *
 * @param item 			Item id.
 * @param setting 		Setting's name.
 * @param value 		Buffer for the value.
 * @param len 			Buffer length.
 * @noreturn
 */
native cshop_get_string(item, setting[], value[], len)

/** 
 * Returns item's unique id.
 *
 * @param id 			Item id (string).
 * @return 				Item id (integer).
 */
native cshop_find_item_by_id(id[])
 
/** 
 * Returns item data.
 *
 * @param item 			Item id.
 * @param type 			Data type.
 * @param buffer 		Buffer to store string data in.
 * @param buffer 		Buffer length.
 * @return 				Integer or float type data. -1 on failure.
 */
native any:cshop_get_item_data(item, any:type, buffer[] = "", len = 0)
#define cshop_get_name(%1,%2,%3) cshop_get_item_data(%1, CSHOP_DATA_NAME, %2, %3)

/** 
 * Called before a menu price is set.
 *
 * @param id 			Player's index.
 * @param ite, 			Item's id.
 * @param price 		Item's price.
 * @noreturn
 */
forward cshop_set_price(id, item, price)