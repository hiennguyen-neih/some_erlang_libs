%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc
%%% <pre>
%%%     Concurence lists module without supervisor.
%%%     This module run faster than with supervisor module but less reliable.
%%%
%%%     Every function in this module will returns atom timeout if Timeout occurs.
%%%
%%%     NOTE: You only should only use this module when have to do a not-too-long list of very 
%%% complex functions.
%%% </pre>
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(con_lists).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1. EXPORT_FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%================================================================================================
%%% EXPORT INTERFACE FUNCTIONS
%%%================================================================================================
-export([all/2, all/3,
         any/2, any/3,
         dropmap/2, dropmap/3,
         filter/2, filter/3,
         filtermap/2, filtermap/3,
         flatmap/2, flatmap/3,
         foreach/2, foreach/3,
         keymap/3, keymap/4,
         map/2, map/3,
         partition/2, partition/3]).

%%%================================================================================================
%%% EXPORT INTERNAL FUNCTIONS
%%%================================================================================================
-export([all_recv/2,
         any_recv/2,
         dropmap_recv/5,
         map_recv/5,
         filter_recv/5,
         filtermap_recv/5,
         foreach_recv/2,
         keymap_recv/5, keymap_spawner/5, keymap_worker/5,
         partition_recv/5,
         spawn_worker/4, fun_worker/4,
         sort_result_worker/3]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2. MACROS AND RECORDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%================================================================================================
%%% MACROS
%%%================================================================================================
-define(TIMEOUT, 10000).

%%%================================================================================================
%%% RECORDS
%%%================================================================================================

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 3. CODE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%================================================================================================
%%% CODE FOR EXPORTED INTERFACE FUNCTIONS
%%%================================================================================================
%%%------------------------------------------------------------------------------------------------
%%% @spec all(Fun, List) -> boolean() | timeout
%%% @equiv con_lists:all(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
all(Fun, List) ->
    all(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec all(Fun, List, Timeout) -> boolean() | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele::Term) -> boolean())
%%%     List = [Term]
%%%     Term = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Returns true if Fun(Ele) returns true for all elements Ele in List, returns false if 
%%% Fun(Ele) returns false for at least one element Ele in List.
%%% === Example ===
%%% ```
%%%     con_lists:all(fun(X) -> X rem 2 == 0 end, [1, 2, 3, 4, 5], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
all(Fun, List, Timeout) ->
    fun_main_proc(Fun, List, Timeout, all_recv, [erlang:self(), erlang:length(List)]).

%%%------------------------------------------------------------------------------------------------
%%% @spec any(Fun, List) -> boolean() | timeout
%%% @equiv con_lists:any(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
any(Fun, List) ->
    any(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec any(Fun, List, Timeout) -> boolean() | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele::Term) -> boolean())
%%%     List = [Term]
%%%     Term = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Returns true if Fun(Ele) returns true for at least one element Ele in List, returns false 
%%% if Fun(Ele) returns false for all elements Ele in List.
%%% === Example ===
%%% ```
%%%     con_lists:any(fun(X) -> X rem 2 == 0 end, [1, 2, 3, 4, 5], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
any(Fun, List, Timeout) ->
    fun_main_proc(Fun, List, Timeout, any_recv, [erlang:self(), erlang:length(List)]).

%%%------------------------------------------------------------------------------------------------
%%% @spec dropmap(Fun, List) -> List1 | timeout
%%% @equiv con_lists:dropmap(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
dropmap(Fun, List) ->
    dropmap(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec dropmap(Fun, List, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele::Term) -> boolean() | {false, Value})
%%%     List = [Ele]
%%%     List1 = [Ele | Value]
%%%     Ele = Value = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Calls Fun(Ele) on succssive elements Ele of List1. Fun/1 must return either a boolean or a 
%%% tuple {false, Value}. The function returns the list of elements for which Fun returns a new 
%%% value, where a value of false is synonymous with {false, Ele}.
%%%     This function basically oposite of filtermap/2 and filtermap/3.
%%% === Example ===
%%% ```
%%%     con_lists:dropmap(fun(X) -> case X rem 2 of 0 -> true; _ -> {false, X*3} end end,
%%%                       [1, 2, 3, 4, 5], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
dropmap(Fun, List, Timeout) ->
    Length = erlang:length(),
    fun_main_proc(Fun, List, Timeout, dropmap_recv, [erlang:self(), Length, Length div 2, [], []]).

%%%------------------------------------------------------------------------------------------------
%%% @spec filter(Fun, List) -> List1 | timeout
%%% @equiv con_lists:filter(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
filter(Fun, List) ->
    filter(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec filter(Fun, List, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele :: Term) -> boolean())
%%%     List = List1 = [Term]
%%%     Term = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Returns List1 is a list of all elements Elem in List for which Fun(Ele) returns true.
%%% === Example ===
%%% ```
%%%     con_lists:filter(fun(X) -> X rem 2 == 0 end, [1, 2, 3, 4, 5], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
filter(Fun, List, Timeout) ->
    Length = erlang:length(List),
    fun_main_proc(Fun, List, Timeout, filter_recv, [erlang:self(), Length, Length div 2, [], []]).

%%%------------------------------------------------------------------------------------------------
%%% @spec filtermap(Fun, List) -> List1 | timeout
%%% @equiv con_lists:filtermap(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
filtermap(Fun, List) ->
    filtermap(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec filtermap(Fun, List, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele) -> boolean() | {true, Value})
%%%     List = [Ele]
%%%     List1 = [Ele | Value]
%%%     Ele = Value = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Calls Fun(Ele) on succssive elements Ele of List1. Fun/1 must return either a boolean or a 
%%% tuple {true, Value}. The function returns the list of elements for which Fun returns a new 
%%% value, where a value of true is synonymous with {true, Ele}.
%%% === Example ===
%%% ```
%%%     con_lists:filtermap(fun(X) -> case X rem 2 of 0 -> {true, X div 2}; _ -> false end end,
%%%                         [1, 2, 3, 4, 5], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
filtermap(Fun, List, Timeout) ->
    Len = erlang:length(List),
    fun_main_proc(Fun, List, Timeout, filtermap_recv, [erlang:self(), Len, Len div 2, [], []]).

%%%------------------------------------------------------------------------------------------------
%%% @spec flatmap(Fun, List) -> List1 | timeout
%%% @equiv con_lists:flatmap(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
flatmap(Fun, List) ->
    flatmap(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec flatmap(Fun, List, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((A) -> B)
%%%     List = [A]
%%%     List1 = [B]
%%%     A = B = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Takes a function from As to Bs, and a list of As and produces a list of Bs by applying the 
%%% function to every element in the list. This function is used to obtain the return values. The 
%%% evaluation order depends on the implementation.
%%% === Example ===
%%% ```
%%%     con_lists:flatmap(fun(X) -> [X, [X]] end, [n, e, i, h], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
flatmap(Fun, List, Timeout) ->
    lists:append(con_lists:map(Fun, List, Timeout)).

%%%------------------------------------------------------------------------------------------------
%%% @spec foreach(Fun, List) -> ok | timeout
%%% @equiv con_lists:foreach(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
foreach(Fun, List) ->
    foreach(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec foreach(Fun, List, Timeout) -> ok | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele :: T) -> term())
%%%     List = [T]
%%%     T = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Calls Fun(Ele) for each element Ele in List. This function is used for its side effects and
%%% the evaluation order may not be the same as the order of the elements in the list.
%%% === Example ===
%%% ```
%%%     con_lists:foreach(fun(X) -> io:format("~p ", [X]) end, [165, 137, 140, 215], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
foreach(Fun, List, Timeout) ->
    Length = erlang:length(List),
    fun_main_proc(Fun, List, Timeout, foreach_recv, [erlang:self(), Length]).

%%%------------------------------------------------------------------------------------------------
%%% @spec keymap(Fun, N, TupleList) -> TupleList1 | timeout
%%% @equiv con_lists:keymap(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
keymap(Fun, N, List) ->
    keymap(Fun, N, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec keymap(Fun, N, TupleList, Timeout) -> TupleList1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Term :: term()) -> Term1 :: term())
%%%     N = interger() >= 1
%%%      1..tuple_size(Tuple)
%%%     TupleList = TupleList1 = [Tuple]
%%%     Tuple = tuple()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Returns a list of tuples where, for each tuple in TupleList, the Nth element Term of the
%%% tuple has been replaced with the result of calling Fun(Term).
%%% === Example ===
%%% ```
%%%     con_lists:keymap(fun(X) -> X div 2 end, 2, [{a, 329}, {b, 276}, {c, 323}, {d, 430}], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
keymap(Fun, N, List, Timeout) ->
    Len = erlang:length(List),
    RecvPid = erlang:spawn(?MODULE, keymap_recv, [erlang:self(), Len, Len div 2, [], []]),
    SpawnerPid = erlang:spawn(?MODULE, keymap_spawner, [RecvPid, Fun, N, List, 0]),
    receive
        {result, Result} ->
            SpawnerPid ! got_result,
            Result
    after
        Timeout ->
            RecvPid ! timeout,
            SpawnerPid ! timeout,
            timeout
    end.

%%%------------------------------------------------------------------------------------------------
%%% @spec map(Fun, List) -> List1 | timeout
%%% @equiv con_lists:map(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
map(Fun, List) ->
    map(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec map(Fun, List, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((A) -> B)
%%%     List = [A]
%%%     List1 = [B]
%%%     A = B = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Takes a function from As to Bs, and a list of As and produces a list of Bs by applying the 
%%% function to every element in the list. This function is used to obtain the return values. The 
%%% evaluation order depends on the implementation.
%%% === Example ===
%%% ```
%%%     con_lists:map(fun(X) -> X*2 end, [1, 2, 3, 4, 5], 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
map(Fun, List, Timeout) ->
    fun_main_proc(Fun, List, Timeout, map_recv, [erlang:self(), erlang:length(List)]).

%%%------------------------------------------------------------------------------------------------
%%% @spec partition(Fun, List) -> {Satisfying, NotSatisfying} | timeout
%%% @equiv con_lists:partition(Fun, List, 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
partition(Fun, List) ->
    partition(Fun, List, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec partition(Fun, List, Timeout) -> {Satisfying, NotSatisfying} | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele :: T) -> boolean())
%%%     List = Satisfying = NotSatisfying = [T]
%%%     T = term()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Partitions List into twolists, where the first list contains all elements for which
%%% Fun(Ele) returns true, and the second list contains all elements for which Fun(Ele) returns
%%% false.
%%% === Example ===
%%% ```
%%%     con_lists:partition(fun(X) -> X rem 2 == 0 end, [454, 431, 272, 359, 280, 457, 430, 479],
%%%                         10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
partition(Fun, List, Timeout) ->
    L = erlang:length(List),
    fun_main_proc(Fun, List, Timeout, partition_recv, [self(), L, L div 2, {[], []}, {[], []}]).

%%%================================================================================================
%%% CODE FOR EXPORTED INTERNAL FUNCTIONS
%%%================================================================================================
%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions all/2 and all/3.
%%%------------------------------------------------------------------------------------------------
all_recv(Pid, Counter) ->
    receive
        {_Index, true, _Item} ->
            case Counter > 1 of
                true ->
                    all_recv(Pid, Counter - 1);
                false ->
                    Pid ! {result, true},
                    exit(done)
            end;
        {_Index, false, _Item} ->
            Pid ! {result, false},
            exit(done);
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions any/2 and any/3.
%%%------------------------------------------------------------------------------------------------
any_recv(Pid, Counter) ->
    receive
        {_Index, false, _Item} ->
            case Counter > 1 of
                true ->
                    any_recv(Pid, Counter - 1);
                false ->
                    Pid ! {result, false},
                    exit(done)
            end;
        {_Index, true, _Item} ->
            Pid ! {result, true},
            exit(done);
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions dropwhile/2 and dropwhile/3.
%%%------------------------------------------------------------------------------------------------
dropmap_recv(Pid, Counter, Threshold, Low, High) ->
    receive
        {_Index, true, _Item} ->
            case Counter > 1 of
                true ->
                    dropmap_recv(Pid, Counter - 1, Threshold, Low, High);
                false ->
                    Pid ! {result, sort_result(Low, High)},
                    exit(done)
            end;
        {Index, false, Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            dropmap_recv(Pid, Counter - 1, Threshold, [{Index, Item} | Low], High);
                        false ->
                            dropmap_recv(Pid, Counter - 1, Threshold, Low, [{Index, Item} | High])
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            Pid ! {result, sort_result([{Index, Item} | Low], High)},
                            exit(done);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Item} | High])},
                            exit(done)
                    end
            end;
        {Index, {false, Value}, _Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            dropmap_recv(Pid, Counter - 1, Threshold, [{Index, Value} | Low], High);
                        false ->
                            dropmap_recv(Pid, Counter - 1, Threshold, Low, [{Index, Value} | High])
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            Pid ! {result, sort_result([{Index, Value} | Low], High)},
                            exit(done);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Value} | High])},
                            exit(done)
                    end
            end;
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions filter/2 and filter/3.
%%%------------------------------------------------------------------------------------------------
filter_recv(Pid, Counter, Threshold, Low, High) ->
    receive
        {Index, true, Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            filter_recv(Pid, Counter - 1, Threshold, [{Index, Item} | Low], High);
                        false ->
                            filter_recv(Pid, Counter - 1, Threshold, Low, [{Index, Item} | High])
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            Pid ! {result, sort_result([{Index, Item} | Low], High)},
                            exit(done);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Item} | High])},
                            exit(done)
                    end
            end;
        {_Index, false, _Item} ->
            case Counter > 1 of
                true ->
                    filter_recv(Pid, Counter - 1, Threshold, Low, High);
                false ->
                    Pid ! {result, sort_result(Low, High)},
                    exit(done)
            end;
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions filtermap/2 and filtermap/3.
%%%------------------------------------------------------------------------------------------------
filtermap_recv(Pid, Counter, Threshold, Low, High) ->
    receive
        {Index, true, Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            filtermap_recv(Pid, Counter - 1, Threshold, [{Index, Item} | Low], High);
                        false ->
                            filtermap_recv(Pid, Counter - 1, Threshold, Low, [{Index, Item} | High])
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            Pid ! {result, sort_result([{Index, Item} | Low], High)},
                            exit(done);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Item} | High])},
                            exit(done)
                    end
            end;
        {_Index, false, _Item} ->
            case Counter > 1 of
                true ->
                    filtermap_recv(Pid, Counter - 1, Threshold, Low, High);
                false ->
                    Pid ! {result, sort_result(Low, High)},
                    exit(done)
            end;
        {Index, {true, Value}, _Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            filtermap_recv(Pid, Counter - 1, Threshold, [{Index, Value} | Low], High);
                        false ->
                            filtermap_recv(Pid, Counter - 1, Threshold, Low, [{Index, Value} | High])
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            Pid ! {result, sort_result([{Index, Value} | Low], High)},
                            exit(done);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Value} | High])},
                            exit(done)
                    end
            end;
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions foreach/2 and foreach/3.
%%%------------------------------------------------------------------------------------------------
foreach_recv(Pid, Counter) ->
    receive
        {_Index, _Result, _Item} ->
            case Counter > 1 of
                true ->
                    foreach_recv(Pid, Counter - 1);
                false ->
                    Pid ! {result, ok},
                    exit(done)
            end;
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions keymap/2 and keymap/3.
%%%------------------------------------------------------------------------------------------------
keymap_recv(Pid, Counter, Threshold, Low, High) ->
    receive
        {Index, Value} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            keymap_recv(Pid, Counter - 1, Threshold, [{Index, Value} | Low], High);
                        false ->
                            keymap_recv(Pid, Counter - 1, Threshold, Low, [{Index, Value} | High])
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            Pid ! {result, sort_result([{Index, Value} | Low], High)},
                            exit(normal);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Value} | High])},
                            exit(normal)
                    end
            end;
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions map/2 and map/3.
%%%------------------------------------------------------------------------------------------------
map_recv(Pid, Counter, Threshold, Low, High) ->
    receive
        {Index, Result, _Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            map_recv(Pid, Counter - 1, Threshold, [{Index, Result} | Low], High);
                        false ->
                            map_recv(Pid, Counter - 1, Threshold, Low, [{Index, Result} | High])
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            Pid ! {result, sort_result([{Index, Result} | Low], High)},
                            exit(done);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Result} | High])},
                            exit(done)
                    end
            end;
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions partition/2 and partition/3.
%%%------------------------------------------------------------------------------------------------
partition_recv(Pid, Counter, Threshold, {TLow, THigh} = TPart, {FLow, FHigh} = FPart) ->
    receive
        {Index, true, Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            partition_recv(Pid, Counter - 1, Threshold,
                                           {[{Index, Item} | TLow], THigh}, FPart);
                        false ->
                            partition_recv(Pid, Counter - 1, Threshold,
                                           {TLow, [{Index, Item} | THigh]}, FPart)
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            TSorted = sort_result([{Index, Item} | TLow], THigh),
                            FSorted = sort_result(FLow, FHigh),
                            Pid ! {result, {TSorted, FSorted}},
                            exit(done);
                        false ->
                            TSorted = sort_result(TLow, [{Index, Item} | THigh]),
                            FSorted = sort_result(FLow, FHigh),
                            Pid ! {result, {TSorted, FSorted}},
                            exit(done)
                    end
            end;
        {Index, false, Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            partition_recv(Pid, Counter - 1, Threshold, TPart,
                                           {[{Index, Item} | FLow], FHigh});
                        false ->
                            partition_recv(Pid, Counter - 1, Threshold, TPart,
                                           {FLow, [{Index, Item} | FHigh]})
                    end;
                false ->
                    case Index < Threshold of
                        true ->
                            TSorted = sort_result(TLow, THigh),
                            FSorted = sort_result([{Index, Item} | FLow], FHigh),
                            Pid ! {result, {TSorted, FSorted}},
                            exit(done);
                        false ->
                            TSorted = sort_result(TLow, THigh),
                            FSorted = sort_result(FLow, [{Index, Item} | FHigh]),
                            Pid ! {result, {TSorted, FSorted}},
                            exit(done)
                    end
            end;
        timeout ->
            exit(timeout);
        Error ->
            throw({error, {badmatch, Error}})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Spawn new workers.
%%%------------------------------------------------------------------------------------------------
spawn_worker(_Pid, _Fun, [], _Counter) ->
    exit(spawned_last_pid);
spawn_worker(Pid, Fun, [H | T], Counter) ->
    spawn(?MODULE, fun_worker, [Pid, Fun, H, Counter]),
    spawn_worker(Pid, Fun, T, Counter + 1),
    receive
        got_result ->
            exit(got_result);
        timeout ->
            exit(timeout);
        _Msg ->
            spawn_worker(Pid, Fun, [H | T], Counter)
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Spawn new workers for keymap/3 and keymap/4.
%%%------------------------------------------------------------------------------------------------
keymap_spawner(_Pid, _Fun, _N, [], _Counter) ->
    exit(spawned_last_pid);
keymap_spawner(Pid, Fun, N, [H | T], Counter) ->
    spawn(?MODULE, keymap_worker, [Pid, Fun, N, H, Counter]),
    keymap_spawner(Pid, Fun, N, T, Counter + 1),
    receive
        got_result ->
            exit(got_result);
        timeout ->
            exit(timeout);
        _Msg ->
            keymap_spawner(Pid, Fun, N, [H | T], Counter)
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Worker execute function.
%%%------------------------------------------------------------------------------------------------
fun_worker(Pid, Fun, Arg, Index) ->
    Pid ! {Index, Fun(Arg), Arg},
    exit(done).

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Worker execute function for keymap/3 and keymap/4.
%%%------------------------------------------------------------------------------------------------
keymap_worker(Pid, Fun, N, Arg, Index) ->
    Pid ! {Index, erlang:setelement(N, Arg, Fun(erlang:element(N, Arg)))},
    exit(done).

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Worker sort result list into original order.
%%%------------------------------------------------------------------------------------------------
sort_result_worker(Pid, Position, List) ->
    Pid ! {Position, [Value || {_, Value} <- lists:keysort(1, List)]},
    exit(done).

%%%================================================================================================
%%% CODE FOR INTERNAL FUNCTIONS
%%%================================================================================================
%%%------------------------------------------------------------------------------------------------
%%% Main process for functions that do list of functions.
%%%------------------------------------------------------------------------------------------------
fun_main_proc(Fun, List, Timeout, RecvFun, RecvArgs) ->
    RecvPid = erlang:spawn(?MODULE, RecvFun, RecvArgs),
    SpawnerPid = erlang:spawn(?MODULE, spawn_worker, [RecvPid, Fun, List, 0]),
    receive
        {result, Result} ->
            SpawnerPid ! got_result,
            Result
    after
        Timeout ->
            RecvPid ! timeout,
            SpawnerPid ! timeout,
            timeout
    end.

%%%------------------------------------------------------------------------------------------------
%%% Sort return list into original order.
%%%------------------------------------------------------------------------------------------------
sort_result(Low, High) ->
    erlang:spawn(?MODULE, sort_result_worker, [self(), low, Low]),
    erlang:spawn(?MODULE, sort_result_worker, [self(), high, High]),
    sort_result_recv(low, high).

%%%------------------------------------------------------------------------------------------------
%%% Receiver for function sort_result/3.
%%%------------------------------------------------------------------------------------------------
sort_result_recv(LowPart, HighPart) when LowPart == low; HighPart == high ->
    receive
        {low, Sorted} ->
            sort_result_recv(Sorted, HighPart);
        {high, Sorted} ->
            sort_result_recv(LowPart, Sorted);
        _Msg ->
            sort_result_recv(LowPart, HighPart)
    end;
sort_result_recv(LowPart, HighPart) ->
    LowPart ++ HighPart.