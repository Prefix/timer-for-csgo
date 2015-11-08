/*<DR.API ZOMBIE RIOT NATIVES> (c) by <De Battista Clint (http://doyou.watch)*/
/*                                                                           */
/*             <DR.API ZOMBIE RIOT NATIVES> is licensed under a              */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//************************DR.API ZOMBIE RIOT NATIVES*************************//
//***************************************************************************//
//***************************************************************************//

#if defined _drapi_zombie_riot_included
 #endinput
#endif
#define _drapi_zombie_riot_included

#include <topmenus>


//Check if player is a zombie.
//@param 	client:			client index.
//@return	True/False:		True if the player is a zombie, and false if human.
native bool ZRiot_IsClientZombie(int client);

//Turns a human into a zombie.
//@param 	client:			client index.
native int ZRiot_Zombie(int client);

//Turns a zombie into a human (will not work for bots)
//@param 	client:			client index.
native int ZRiot_Human(int client);

//Get the current day.
native int ZRiot_GetDay();

//Get the max day (days.txt).
native int ZRiot_GetDayMax();

//Get the menu zombie riot.
native TopMenu ZRiot_GetMenu();

//Get the menu zombie riot when is ready.
forward void ZRiot_OnMenuReady(Handle topmenu);


public SharedPlugin __pl_drapi_zombie_riot =
{
	name = "drapi_zombie_riot",
	file = "drapi_zombie_riot.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_drapi_zombie_riot_SetNTVOptional()
{
	MarkNativeAsOptional("ZRiot_IsClientZombie");
	MarkNativeAsOptional("ZRiot_Zombie");
	MarkNativeAsOptional("ZRiot_Human");
	MarkNativeAsOptional("ZRiot_GetDay");
	MarkNativeAsOptional("ZRiot_GetDayMax");
	MarkNativeAsOptional("ZRiot_GetMenu");
}
#endif
