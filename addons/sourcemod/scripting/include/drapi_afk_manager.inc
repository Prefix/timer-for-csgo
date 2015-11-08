/*<DR.API AFK MANAGER NATIVES> (c) by <De Battista Clint (http://doyou.watch)*/
/*                                                                           */
/*             <DR.API AFK MANAGER NATIVES> is licensed under a              */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//************************DR.API AFK MANAGER NATIVES*************************//
//***************************************************************************//
//***************************************************************************//
#if defined _drapi_afk_manager_included_
  #endinput
#endif
#define _drapi_afk_manager_included_
 
//Call when the player is moving to spectator.
//@param 	client:			client index.
forward void AFK_OnMoveToSpec(int client);

public SharedPlugin __pl_drapi_afk_manager = 
{

	name = "drapi_afk_manager",
	file = "drapi_afk_manager.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_drapi_afk_manager_SetNTVOptional() 
{

}
#endif