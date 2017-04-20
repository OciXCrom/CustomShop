#if defined _customshop_included
    #endinput
#endif

#include <cshop_settings>

#define _customshop_included
#define DONT_BUY PLUGIN_HANDLED
#define BUY_ITEM PLUGIN_CONTINUE
#define SHOP_CLOSE PLUGIN_HANDLED
#define SHOP_OPEN PLUGIN_CONTINUE
#define additem new

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
native cshopRegisterItem(id[], name[], price, limit = 0, sound[] = DEFAULT_SOUND, Float:duration = 0.0, points = 0, team = 0, flag[] = "")
#define cshop_register_item cshopRegisterItem

/** 
 * Checks whether a player has an item or not.
 * 
 * @param id 			Player's index.
 * @param item			Item ID.
 * @return				True if he has, false if he hasn't.
 */
native bool:cshopHasItem(id, item)
#define cshop_has_item cshopHasItem

/** 
 * Checks whether the points system is enabled.
 * 
 * @return				True if it is, false if it isn't.
 */
native bool:cshopPointsEnabled()
#define cshop_points_enabled cshopPointsEnabled

/** 
 * Checks player's item limit.
 * 
 * @param id 			Player's index.
 * @param item			Item ID.
 * @return				Player's item limit.
 */
native cshopGetLimit(id, item)
#define cshop_get_limit cshopGetLimit

/** 
 * Removes a player's item.
 * 
 * @param id 			Player's index.
 * @param item			Item ID.
 * @noreturn
 */
native cshopRemoveItem(id, item)
#define cshop_remove_item cshopRemoveItem

/** 
 * Called right before an item is purchased.
 *
 * @param id 			Player's index.
 * @param item			Item ID.
 * @noreturn
 */
forward cshopItemBought(id, item)
#define cshop_item_selected cshopItemBought

/** 
 * Called when an item is removed.
 *
 * @param id 			Player's index.
 * @param item			Item ID.
 * @noreturn
 */
forward cshopItemRemoved(id, item)
#define cshop_item_removed cshopItemRemoved

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
native cshopErrorSound(id)
#define cshop_error_sound cshopErrorSound

/** 
 * Gets the total number of loaded items.
 * 
 * @return				Total number of loaded items.
 */
native cshopTotalItems()
#define cshop_total_items cshopTotalItems

/** 
 * Give/take points to/from a player.
 *
 * @param id 			Player's index.
 * @param points		Amount of points.
 * @noreturn
 */
native cshopGivePoints(id, points)
#define cshop_give_points cshopGivePoints

/** 
 * Return player points.
 *
 * @param id 			Player's index.
 * @return 				Player's points.
 */
native cshopGetPoints(id, points)
#define cshop_get_points cshopGetPoints

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
native cshop_open(prefix[], len)

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
 * Returns item name.
 *
 * @param item 			Item id.
 * @param name 			Buffer to store name in.
 * @param len 			Buffer length.
 * @noreturn
 */
native cshop_get_name(item, name[], len)