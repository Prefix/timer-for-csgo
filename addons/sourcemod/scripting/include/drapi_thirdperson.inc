/*<DR.API THIRDPERSON NATIVES> (c) by <De Battista Clint (http://doyou.watch)*/
/*                                                                           */
/*            <DR.API THIRDPERSON NATIVES> is licensed under a               */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//************************DR.API THIRDPERSON NATIVES*************************//
//***************************************************************************//
//***************************************************************************//

#if defined _drapi_thirdperson_included_
  #endinput
#endif
#define _drapi_thirdperson_included_
 
//Check if player is in thirdperson.
//@param 	client:			client index.
//@return	True/False:		True if the player is in thirdperson, and false if is in firstperson.
native bool IsPlayerInTP(client);

//Toggle player person mode.
//@param 	client:			client index.
native TogglePlayerTP(client);

//Set player thirdperson.
//@param 	client:			client index.
native SetPlayerThird(client);

//Set player firstperson.
//@param 	client:			client index.
native SetPlayerFirst(client);

public SharedPlugin:__pl_drapi_thirdperson = {

	name = "drapi_thirdperson",
	file = "drapi_thirdperson.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_drapi_thirdperson_SetNTVOptional() {

	MarkNativeAsOptional("IsPlayerInTP");
	MarkNativeAsOptional("TogglePlayerTP");
	MarkNativeAsOptional("SetPlayerThird");
	MarkNativeAsOptional("SetPlayerFirst");
}
#endif