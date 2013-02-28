%% @author Mochi Media <dev@mochimedia.com>
%% @copyright greeting Mochi Media <dev@mochimedia.com>

%% @doc Callbacks for the greeting application.

-module(greeting_app).
-author("Mochi Media <dev@mochimedia.com>").

-behaviour(application).
-export([start/2,stop/1]).


%% @spec start(_Type, _StartArgs) -> ServerRet
%% @doc application start callback for greeting.
start(_Type, _StartArgs) ->
    greeting_deps:ensure(),

%%  erlydb:start(
%%     mysql,[{hostname, "localhost"},
%%        {username, "root"},
%%        {password, "123456"},
%%        {database, "t1"},
%%        {logfun, fun (Module, Line, Level, FormatFun) -> ok end}]),
    mysql_connect(50,"localhost", "root", "123456","t1"),
%% mysql:fetch(erlydb_mysql,<<"set names utf8;">>),

    greeting_sup:start_link().

%% @spec stop(_State) -> ServerRet
%% @doc application stop callback for greeting.
stop(_State) ->
    ok.

mysql_connect(PoolSize, Hostname, User, Password, Database) ->
  erlydb:start(
      mysql, [{hostname, Hostname},
          {username, User},
          {password, Password},
          {database, Database},
          {logfun, fun (Module, Line, Level, FormatFun) -> ok end}, {"encoding", utf8}]),
%%    ok.
   lists:foreach(
       fun(L) ->
               mysql:connect(erlydb_mysql, Hostname, undefined, User, Password, Database, utf8 , true),
               %%mysql:fetch(erlydb_mysql,<<"set names utf8;">>),
               L
       end, lists:seq(1, PoolSize - 1)).
