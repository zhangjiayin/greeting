-module(greeting_views).
-compile(export_all).
-import(greeting_shortcuts, [render_ok/3, render_ok/4, get_cookie_value/3]).
-include_lib("amqp_client/include/amqp_client.hrl").
urls() -> [
      {"^/?$", default},
      {"^new/?$", new},
      {"^hello/?$", hello},
      {"^hello/(.+?)/?$", hello}
    ].

% Return username input if present, otherwise return username cookie if
% present, otherwise return "Anonymous"
get_username(Req, InputData) ->
    proplists:get_value("username", InputData,
        get_cookie_value(Req, "username", "Anonymous")).

make_cookie(Username) ->
    mochiweb_cookies:cookie("username", Username, [{path, "/"}]).

handle_hello(Req, InputData) ->
    Username = get_username(Req, InputData),
    Cookie = make_cookie(Username),
    render_ok(Req, [Cookie], greeting_dtl, [{username, Username}]).

default('GET', Req) ->
    Data = get_my_post("1"),
    render_ok(Req, [], default_dtl, [{blogs,Data}]).

new('GET', Req) ->
   Blog =  proplists:get_value("blog", Req:parse_qs(),get_cookie_value(Req, "blog", "Anonymous")),
   CreatedAt = calendar:datetime_to_gregorian_seconds(calendar:now_to_universal_time( now()))-719528*24*3600,
   %%  mysql:prepare(add_new_blog, <<"INSERT INTO `t1`.`t1` (`id`, `uid`, `data`, `created_at`, `updated_at`) VALUES (NULL, ?, ?, ?, ?)">>),
   %%  mysql:execute(erlydb_mysql, add_new_blog, [<<"1">>,Blog, CreatedAt, CreatedAt]),
   User = 1,
   send_post(User,Blog,CreatedAt),
   Data = get_my_post(User),
   render_ok(Req, [], default_dtl, [{blogs,Data}]);
new('POST', Req) ->
    User = 1,
    Blog =  proplists:get_value("blog", Req:parse_post(),get_cookie_value(Req, "blog", "Anonymous")),
    CreatedAt = calendar:datetime_to_gregorian_seconds(calendar:now_to_universal_time( now()))-719528*24*3600,
    send_post(User, Blog,CreatedAt),
    %%mysql:prepare(add_new_blog, <<"INSERT INTO `t1`.`t1` (`id`, `uid`, `data`, `created_at`, `updated_at`) VALUES (NULL, ?, ?, ?, ?)">>),
    %%mysql:execute(erlydb_mysql, add_new_blog, [<<"1">>,Blog, CreatedAt, CreatedAt]),
    Data = get_my_post(User),
    render_ok(Req, [], default_dtl, [{blogs,Data}]).

send_post(User, Blog, CreatedAt) ->
    send_post_to_queue(User,Blog,CreatedAt).
send_post_to_mysql(User,Blog,CreatedAt)->
    mysql:fetch(erlydb_mysql, <<"set names utf8">>),
    mysql:prepare(add_new_blog, <<"INSERT INTO `t1`.`t1` (`id`, `uid`, `data`, `created_at`, `updated_at`) VALUES (NULL, ?, ?, ?, ?)">>),
    mysql:execute(erlydb_mysql, add_new_blog, [User,Blog,CreatedAt, CreatedAt]).

send_post_to_queue(User, Blog, CreatedAt) ->
    Term = term_to_binary({[user,User],[blog,Blog], [createdAt, CreatedAt]}),
    {ok, Connection} = amqp_connection:start(#amqp_params_network{host = "localhost"}),
    {ok, Channel} = amqp_connection:open_channel(Connection),
    amqp_channel:call(Channel, #'queue.declare'{queue = <<"hello">>}),
    amqp_channel:cast(Channel, #'basic.publish'{ exchange = <<"">>, routing_key = <<"hello">>}, #amqp_msg{payload = Term}),
    ok = amqp_channel:close(Channel),
    ok = amqp_connection:close(Connection),
    ok.

get_my_post(Id) ->
    mysql:prepare(get_my_post,<<"select * from t1 where `uid` = ? ORDER BY `id` desc limit 20" >>),
    Blogs = mysql:execute(erlydb_mysql, get_my_post, [Id]),
    {data,{mysql_result,_,Data,_,_}} = Blogs,
    Data.

hello('GET', Req) ->
    handle_hello(Req, Req:parse_qs());
hello('POST', Req) ->
    handle_hello(Req, Req:parse_post()).

hello('GET', Req, Username) ->
    Cookie = make_cookie(Username),
    render_ok(Req, [Cookie], greeting_dtl, [{username, Username}]);
hello('POST', Req, _) ->
  hello('POST', Req).
