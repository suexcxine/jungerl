%%%-------------------------------------------------------------------
%%% File    : panEts.erl
%%% Author  : Mats Cronqvist <etxmacr@cbe2077>
%%% Description : 
%%%
%%% Created : 14 Feb 2002 by Mats Cronqvist <etxmacr@cbe2077>
%%%-------------------------------------------------------------------
-module(panEts).

-export([new/1,new/2]).
-export([kill/1]).
-export([upd/2,upd/3]).
-export([lup/2]).

new(Tab) -> new(Tab, []).
new(Tab, Opts) ->
    kill(Tab),
    Mama = self(),
    Ref = make_ref(),
    E = fun() -> register(list_to_atom(atom_to_list(Tab)++"_tab"),self()), 
		 ets:new(Tab,[named_table,public,ordered_set|Opts]), 
		 Mama ! Ref,
		 receive {quit, P} -> P ! Tab end 
	end,
    spawn(E),
    receive Ref -> ok end,
    Tab.

kill(Tab) ->
    case catch (list_to_atom(atom_to_list(Tab)++"_tab") ! {quit, self()}) of
	{'EXIT', _} -> ok;
	{quit,_} -> receive Tab -> ok end
    end.

upd(Tab, Key) -> upd(Tab, Key, 1).
upd(Tab, Key, Inc) ->
    case catch ets:update_counter(Tab, Key, Inc) of
        {'EXIT', _ } -> ets:insert(Tab, {Key, Inc}), Inc;
        O -> O
    end.

lup(Tab, Key) ->
    case catch ets:lookup(Tab, Key) of
        [{Key,Val}] -> Val;
	{'EXIT',_} -> [];
        O -> O
    end.
