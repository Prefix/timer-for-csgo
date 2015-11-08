/*   <DR.API HP BAR NATIVES> (c) by <De Battista Clint (http://doyou.watch)  */
/*                                                                           */
/*               <DR.API HP BAR NATIVES> is licensed under a                 */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API HP BAR NATIVES***************************//
//***************************************************************************//
//***************************************************************************//

#if defined _drapi_hpbar_included_
  #endinput
#endif
#define _drapi_hpbar_included_
 
//Clear the HPBAR icon.
//@param 	client:			client index.
native void ClearHPBar(int client);

//Create the HPBAR icon.
//@param 	client:			client index.
//@param 	team:			team index.
//@param 	hp:				set the bar %.
//@param 	real_hp:		client health.
native void SetHPBar(int client, int team, int hp, int real_hp);

public SharedPlugin __pl_drapi_hpbar = 
{

	name = "drapi_hpbar",
	file = "drapi_hpbar.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_drapi_hpbar_SetNTVOptional() 
{

	MarkNativeAsOptional("ClearHPBar");
	MarkNativeAsOptional("SetHPBar");
}
#endif