%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc
%%% <pre>
%%%     Concurence lists module without supervisor.
%%%     This module run slower than without supervisor module but more reliable.
%%%
%%%     Every function in this module will return atom timeout if Timeout occurs. It also will
%%% throw exception error {proc_died, Pid, Reason} if there's any process that died.
%%%
%%%     NOTE: You only should only use this module when have to do a very-too-long list of very 
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
-export([all/2, all/4,
         any/2, any/4,
         dropmap/2, dropmap/4,
         filter/2, filter/4,
         filtermap/2, filtermap/4,
         flatmap/2, flatmap/4,
         foreach/2, foreach/4,
         keymap/3, keymap/5,
         map/2, map/4,
         partition/2, partition/4]).

%%%================================================================================================
%%% EXPORT INTERNAL FUNCTIONS
%%%================================================================================================
-export([all_recv/2,
         any_recv/2,
         dropmap_recv/5,
         filter_recv/5,
         filtermap_recv/5,
         foreach_recv/2,
         keymap_recv/5,
         map_recv/5,
         partition_recv/5,
         get_max_workers/0,
         spawn_worker/6, sender/3, fun_worker/3,
         keymap_spawner/7, keymap_worker/4,
         sort_result_worker/3]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2. MACROS AND RECORDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%================================================================================================
%%% MACROS
%%%================================================================================================
-define(TIMEOUT, 10000).
-define(CPU_PROCESS, erlang:system_info(logical_processors)).
-define(PROCESS_LIMIT, erlang:system_info(process_limit)).
-define(PROCESS_COUNT, erlang:system_info(process_count)).
-define(PROCESS_AVAIL, ?PROCESS_LIMIT - ?PROCESS_COUNT - 5).
-define(MAX_WORKER, con_lists:get_max_workers()).

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
%%% @equiv con_lists:all(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
all(Fun, List) ->
    all(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec all(Fun, List, MaxWorkers, Timeout) -> boolean() | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele::Term) -> boolean())
%%%     List = [Term]
%%%     Term = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Returns true if Fun(Ele) returns true for all elements Ele in List, returns false if 
%%% Fun(Ele) returns false for at least one element Ele in List.
%%% === Example ===
%%% ```
%%%     con_lists:all(fun(X) -> X rem 2 == 0 end, [1, 2, 3, 4, 5, 6], 1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
all(Fun, List, MaxWorkers, Timeout) ->
    Length = erlang:length(List),
    Self = erlang:self(),
    fun_main_proc(Fun, List, MaxWorkers, Timeout, Self, Length, all_recv, [Self, Length]).

%%%------------------------------------------------------------------------------------------------
%%% @spec any(Fun, List) -> boolean() | timeout
%%% @equiv con_lists:any(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
any(Fun, List) ->
    any(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec any(Fun, List, MaxWorkers, Timeout) -> boolean() | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele::Term) -> boolean())
%%%     List = [Term]
%%%     Term = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Returns true if Fun(Ele) returns true for at least one element Ele in List, returns false 
%%% if Fun(Ele) returns false for all elements Ele in List.
%%% === Example ===
%%% ```
%%%     con_lists:any(fun(X) -> X rem 2 == 0 end, [1, 2, 3, 4, 5, 6], 1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
any(Fun, List, MaxWorkers, Timeout) ->
    Length = erlang:length(List),
    Self = erlang:self(),
    fun_main_proc(Fun, List, MaxWorkers, Timeout, Self, Length, any_recv, [Self, Length]).

%%%------------------------------------------------------------------------------------------------
%%% @spec dropmap(Fun, List) -> List1 | timeout
%%% @equiv con_lists:dropmap(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
dropmap(Fun, List) ->
    dropmap(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec dropmap(Fun, List, MaxWorkers, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele::Term) -> boolean() | {false, Value})
%%%     List = [Ele]
%%%     List1 = [Ele | Value]
%%%     Ele = Value = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Calls Fun(Ele) on succssive elements Ele of List1. Fun/1 must return either a boolean or a 
%%% tuple {false, Value}. The function returns the list of elements for which Fun returns a new 
%%% value, where a value of false is synonymous with {false, Ele}.
%%%     This function basically oposite of filtermap/2 and filtermap/4.
%%% === Example ===
%%% ```
%%%     con_lists:dropmap(fun(X) -> case X rem 2 of 0 -> true; _ -> {false, X*3} end end,
%%%                       [1, 2, 3, 4, 5], 1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
dropmap(Fun, List, MaxWorkers, Timeout) ->
    L = erlang:length(List),
    S = erlang:self(),
    fun_main_proc(Fun, List, MaxWorkers, Timeout, S, L, dropmap_recv, [S, L, L div 2, [], []]).

%%%------------------------------------------------------------------------------------------------
%%% @spec filter(Fun, List) -> List1 | timeout
%%% @equiv con_lists:filter(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
filter(Fun, List) ->
    filter(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec filter(Fun, List, MaxWorkers, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele :: Term) -> boolean())
%%%     List = List1 = [Term]
%%%     Term = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Returns List1 is a list of all elements Elem in List for which Fun(Ele) returns true.
%%% === Example ===
%%% ```
%%%     con_lists:filter(fun(X) -> X rem 2 == 0 end, [1, 2, 3, 4, 5], 1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
filter(Fun, List, MaxWorkers, Timeout) ->
    L = erlang:length(List),
    S = erlang:self(),
    fun_main_proc(Fun, List, MaxWorkers, Timeout, S, L, filter_recv, [S, L, L div 2, [], []]).

%%%------------------------------------------------------------------------------------------------
%%% @spec filtermap(Fun, List) -> List1 | timeout
%%% @equiv con_lists:filtermap(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
filtermap(Fun, List) ->
    filtermap(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec filtermap(Fun, List, MaxWorkers, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele) -> boolean() | {true, Value})
%%%     List = [Ele]
%%%     List1 = [Ele | Value]
%%%     Ele = Value = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Calls Fun(Ele) on succssive elements Ele of List1. Fun/1 must return either a boolean or a 
%%% tuple {true, Value}. The function returns the list of elements for which Fun returns a new 
%%% value, where a value of true is synonymous with {true, Ele}.
%%% === Example ===
%%% ```
%%%     con_lists:filtermap(fun(X) -> case X rem 2 of 0 -> {true, X div 2}; _ -> false end end,
%%%                         [1, 2, 3, 4, 5], 1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
filtermap(Fun, List, MaxWorkers, Timeout) ->
    L = erlang:length(List),
    S = erlang:self(),
    fun_main_proc(Fun, List, MaxWorkers, Timeout, S, L, filtermap_recv, [S, L, L div 2, [], []]).

%%%------------------------------------------------------------------------------------------------
%%% @spec flatmap(Fun, List) -> List1 | timeout
%%% @equiv con_lists:flatmap(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
flatmap(Fun, List) ->
    flatmap(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec flatmap(Fun, List, MaxWorkers, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((A) -> B)
%%%     List = [A]
%%%     List1 = [B]
%%%     A = B = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Takes a function from As to Bs, and a list of As and produces a list of Bs by applying the 
%%% function to every element in the list. This function is used to obtain the return values. The 
%%% evaluation order depends on the implementation.
%%% === Example ===
%%% ```
%%%     con_lists:flatmap(fun(X) -> [X, [X]] end, [n, e, i, h], 1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
flatmap(Fun, List, MaxWorkers, Timeout) ->
    lists:append(con_lists:map(Fun, List, MaxWorkers, Timeout)).

%%%------------------------------------------------------------------------------------------------
%%% @spec foreach(Fun, List) -> ok | timeout
%%% @equiv con_lists:foreach(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
foreach(Fun, List) ->
    foreach(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec foreach(Fun, List, MaxWorkers, Timeout) -> ok | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele :: T) -> term())
%%%     List = [T]
%%%     T = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Calls Fun(Ele) for each element Ele in List. This function is used for its side effects and
%%% the evaluation order may not be the same as the order of the elements in the list.
%%% === Example ===
%%% ```
%%%     con_lists:foreach(fun(X) -> io:format("~p ", [X]) end, [165, 137, 140, 215], 1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
foreach(Fun, List, MaxWorkers, Timeout) ->
    Length = erlang:length(List),
    Self = erlang:self(),
    fun_main_proc(Fun, List, MaxWorkers, Timeout, Self, Length, foreach_recv, [Self, Length]).

%%%------------------------------------------------------------------------------------------------
%%% @spec keymap(Fun, N, TupleList) -> TupleList1 | timeout
%%% @equiv con_lists:keymap(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
keymap(Fun, N, List) ->
    keymap(Fun, N, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec keymap(Fun, N, TupleList, MaxWorkers, Timeout) -> TupleList1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Term :: term()) -> Term1 :: term())
%%%     N = interger() >= 1
%%%      1..tuple_size(Tuple)
%%%     TupleList = TupleList1 = [Tuple]
%%%     Tuple = tuple()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Returns a list of tuples where, for each tuple in TupleList, the Nth element Term of the
%%% tuple has been replaced with the result of calling Fun(Term).
%%% === Example ===
%%% ```
%%%     con_lists:keymap(fun(X) -> X div 2 end, 2, [{a, 329}, {b, 276}, {c, 323}, {d, 430}],
%%%                      1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
keymap(Fun, N, List, MaxWorkers, Timeout) ->
    erlang:process_flag(trap_exit, true),
    Length = erlang:length(List),
    MPid = erlang:self(),
    NumWorkers = case MaxWorkers > Length of
                     true ->
                         Length;
                     false ->
                         MaxWorkers
                 end,
    RPid = erlang:spawn_link(?MODULE, keymap_recv, [MPid, Length, Length div 2, [], []]),
    SPid = erlang:spawn_link(?MODULE, sender, [MPid, List, 0]),
    SpPid = erlang:spawn_link(?MODULE, keymap_spawner, [MPid, SPid, RPid, Fun, N, NumWorkers, []]),
    receive
        {result, Result} ->
            RPid ! {MPid, exit, nornal},
            SPid ! {MPid, exit, normal},
            SpPid ! {MPid, exit, normal},
            Result;
        {'EXIT', Pid, Reason} when Reason /= normal ->
            RPid ! {MPid, exit, nornal},
            SPid ! {MPid, exit, normal},
            SpPid ! {MPid, exit, normal},
            erlang:error({proc_died, Pid, Reason})
    after
        Timeout ->
            RPid ! {MPid, exit, normal},
            SPid ! {MPid, exit, normal},
            SpPid ! {MPid, exit, normal},
            timeout
    end.

%%%------------------------------------------------------------------------------------------------
%%% @spec map(Fun, List) -> List1 | timeout
%%% @equiv con_lists:map(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
map(Fun, List) ->
    map(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec map(Fun, List, MaxWorkers, Timeout) -> List1 | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((A) -> B)
%%%     List = [A]
%%%     List1 = [B]
%%%     A = B = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Takes a function from As to Bs, and a list of As and produces a list of Bs by applying the 
%%% function to every element in the list. This function is used to obtain the return values. The 
%%% evaluation order depends on the implementation. Or returns atom timeout if Timeout occurs.
%%%     This function will throw exception error {proc_died, Pid, Reason} if there's any process
%%% that died.
%%% === Example ===
%%% ```
%%%     con_lists:map(fun(X) -> X*2 end, [1, 2, 3, 4, 5], 1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
map(Fun, List, MaxWorkers, Timeout) ->
    L = erlang:length(List),
    S = erlang:self(),
    fun_main_proc(Fun, List, MaxWorkers, Timeout, S, L, map_recv, [S, L, L div 2, [], []]).

%%%------------------------------------------------------------------------------------------------
%%% @spec partition(Fun, List) -> {Satisfying, NotSatisfying} | timeout
%%% @equiv con_lists:partition(Fun, List, con_lists:get_max_workers(), 10000)
%%% @end
%%%------------------------------------------------------------------------------------------------
partition(Fun, List) ->
    partition(Fun, List, ?MAX_WORKER, ?TIMEOUT).

%%%------------------------------------------------------------------------------------------------
%%% @spec partition(Fun, List, MaxWorkers, Timeout) -> {Satisfying, NotSatisfying} | timeout
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Fun = fun((Ele :: T) -> boolean())
%%%     List = Satisfying = NotSatisfying = [T]
%%%     T = term()
%%%     MaxWorkers = integer()
%%%     Timeout = integer() | infinity
%%% === Description ===
%%%     Partitions List into twolists, where the first list contains all elements for which
%%% Fun(Ele) returns true, and the second list contains all elements for which Fun(Ele) returns
%%% false.
%%% === Example ===
%%% ```
%%%     con_lists:partition(fun(X) -> X rem 2 == 0 end, [454, 431, 272, 359, 280, 457, 430, 479],
%%%                         1000, 10000).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
partition(Fun, List, M, T) ->
    L = erlang:length(List),
    S = erlang:self(),
    fun_main_proc(Fun, List, M, T, S, L, partition_recv, [S, L, L div 2, {[], []}, {[], []}]).

%%%------------------------------------------------------------------------------------------------
%%% @spec get_max_workers() -> integer()
%%% @doc
%%% <pre>
%%% === Description ===
%%%     Get recommended maximum number of workers.
%%% === Example ===
%%% ```
%%%     con_lists:get_max_workers()
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
get_max_workers() ->
    case ?PROCESS_AVAIL > ?CPU_PROCESS*2 of
        true ->
            ?CPU_PROCESS*2;
        false ->
            ?PROCESS_AVAIL
    end.

%%%================================================================================================
%%% CODE FOR EXPORTED INTERNAL FUNCTIONS
%%%================================================================================================
%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions all/2 and all/4.
%%%------------------------------------------------------------------------------------------------
all_recv(Pid, Counter) ->
    receive
        {_Index, true, _Item} ->
            case Counter > 1 of
                true ->
                    all_recv(Pid, Counter - 1);
                false ->
                    Pid ! {result, true},
                    exit(normal)
            end;
        {_Index, false, _Item} ->
            Pid ! {result, false},
            exit(normal);
        {Pid, exit, Reason} ->
            exit(Reason);
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions any/2 and any/4.
%%%------------------------------------------------------------------------------------------------
any_recv(Pid, Counter) ->
    receive
        {_Index, false, _Item} ->
            case Counter > 1 of
                true ->
                    any_recv(Pid, Counter - 1);
                false ->
                    Pid ! {result, false},
                    exit(normal)
            end;
        {_Index, true, _Item} ->
            Pid ! {result, true},
            exit(normal);
        {Pid, exit, Reason} ->
            exit(Reason);
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions dropwhile/2 and dropwhile/4.
%%%------------------------------------------------------------------------------------------------
dropmap_recv(Pid, Counter, Threshold, Low, High) ->
    receive
        {_Index, true, _Item} ->
            case Counter > 1 of
                true ->
                    dropmap_recv(Pid, Counter - 1, Threshold, Low, High);
                false ->
                    Pid ! {result, sort_result(Low, High)},
                    exit(normal)
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
                            exit(normal);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Item} | High])},
                            exit(normal)
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
                            exit(normal);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Value} | High])},
                            exit(normal)
                    end
            end;
        {Pid, exit, Reason} ->
            exit(Reason);
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions filter/2 and filter/4.
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
                            exit(normal);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Item} | High])},
                            exit(normal)
                    end
            end;
        {_Index, false, _Item} ->
            case Counter > 1 of
                true ->
                    filter_recv(Pid, Counter - 1, Threshold, Low, High);
                false ->
                    Pid ! {result, sort_result(Low, High)},
                    exit(normal)
            end;
        {Pid, exit, Reason} ->
            exit(Reason);
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions filtermap/2 and filtermap/4.
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
                            exit(normal);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Item} | High])},
                            exit(normal)
                    end
            end;
        {_Index, false, _Item} ->
            case Counter > 1 of
                true ->
                    filtermap_recv(Pid, Counter - 1, Threshold, Low, High);
                false ->
                    Pid ! {result, sort_result(Low, High)},
                    exit(normal)
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
                            exit(normal);
                        false ->
                            Pid ! {result, sort_result(Low, [{Index, Value} | High])},
                            exit(normal)
                    end
            end;
        {Pid, exit, Reason} ->
            exit(Reason);
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions foreach/2 and foreach/4.
%%%------------------------------------------------------------------------------------------------
foreach_recv(Pid, Counter) ->
    receive
        {Pid, exit, Reason} ->
            exit(Reason);
        {_Index, _Result, _Item} ->
            case Counter > 1 of
                true ->
                    foreach_recv(Pid, Counter - 1);
                false ->
                    Pid ! {result, ok},
                    exit(normal)
            end;
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions keymap/2 and keymap/4
%%%------------------------------------------------------------------------------------------------
keymap_recv(Pid, Counter, Threshold, Low, High) ->
    receive
        {Pid, exit, Reason} ->
            exit(Reason);
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
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions map/2 and map/4
%%%------------------------------------------------------------------------------------------------
map_recv(Pid, Counter, Threshold, Low, High) ->
    receive
        {Pid, exit, Reason} ->
            exit(Reason);
        {Index, Value, _Item} ->
            case Counter > 1 of
                true ->
                    case Index < Threshold of
                        true ->
                            map_recv(Pid, Counter - 1, Threshold, [{Index, Value} | Low], High);
                        false ->
                            map_recv(Pid, Counter - 1, Threshold, Low, [{Index, Value} | High])
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
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Receiver for functions partition/2 and partition/4
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
                            exit(normal);
                        false ->
                            TSorted = sort_result(TLow, [{Index, Item} | THigh]),
                            FSorted = sort_result(FLow, FHigh),
                            Pid ! {result, {TSorted, FSorted}},
                            exit(normal)
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
                            exit(normal);
                        false ->
                            TSorted = sort_result(TLow, THigh),
                            FSorted = sort_result(FLow, [{Index, Item} | FHigh]),
                            Pid ! {result, {TSorted, FSorted}},
                            exit(normal)
                    end
            end;
        {Pid, exit, Reason} ->
            exit(Reason);
        Error ->
            erlang:error({badmatch, Error})
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Spawn new workers.
%%%------------------------------------------------------------------------------------------------
spawn_worker(MainPid, SenderPid, RecvPid, Fun, WorkerCounter, WorkerList) ->
    erlang:process_flag(trap_exit, true),
    Worker = erlang:spawn_link(?MODULE, fun_worker, [SenderPid, RecvPid, Fun]),
    case WorkerCounter > 0 of
        true ->
            spawn_worker(MainPid, SenderPid, RecvPid, Fun, WorkerCounter - 1,
                         [Worker | WorkerList]);
        false ->
            ok
    end,
    receive
        {MainPid, exit, Reason} ->
            send_msg({exit, Reason}, WorkerList),
            exit(Reason);
        {'EXIT', Pid, normal} ->
            NewWorkerList = lists:delete(Pid, WorkerList),
            spawn_worker(MainPid, SenderPid, RecvPid, Fun, WorkerCounter, NewWorkerList);
        {'EXIT', Pid, _Reason} ->
            NewWorker = erlang:spawn_link(?MODULE, fun_worker, [SenderPid, RecvPid, Fun]),
            NewWorkerList = [NewWorker | lists:delete(Pid, WorkerList)],
            spawn_worker(MainPid, SenderPid, RecvPid, Fun, WorkerCounter, NewWorkerList)
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Spawn new workers for keymap/3 and keymap/5.
%%%------------------------------------------------------------------------------------------------
keymap_spawner(MainPid, SenderPid, RecvPid, Fun, N, WorkerCounter, WorkerList) ->
    erlang:process_flag(trap_exit, true),
    Worker = erlang:spawn_link(?MODULE, keymap_worker, [SenderPid, RecvPid, Fun, N]),
    case WorkerCounter > 0 of
        true ->
            keymap_spawner(MainPid, SenderPid, RecvPid, Fun, N, WorkerCounter - 1,
                           [Worker | WorkerList]);
        false ->
            ok
    end,
    receive
        {MainPid, exit, Reason} ->
            send_msg({exit, Reason}, WorkerList),
            exit(Reason);
        {'EXIT', Pid, normal} ->
            NewWorkerList = lists:delete(Pid, WorkerList),
            keymap_spawner(MainPid, SenderPid, RecvPid, Fun, N, WorkerCounter, NewWorkerList);
        {'EXIT', Pid, _Reason} ->
            NewWorker = erlang:spawn_link(?MODULE, keymap_worker, [SenderPid, RecvPid, Fun, N]),
            NewWorkerList = [NewWorker | lists:delete(Pid, WorkerList)],
            keymap_spawner(MainPid, SenderPid, RecvPid, Fun, N, WorkerCounter, NewWorkerList)
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Worker execute function.
%%%------------------------------------------------------------------------------------------------
fun_worker(SenderPid, RecvPid, Fun) ->
    SenderPid ! {self(), ask_arg},
    receive
        {exit, Reason} ->
            exit(Reason);
        {Index, Arg} ->
            RecvPid ! {Index, Fun(Arg), Arg},
            fun_worker(SenderPid, RecvPid, Fun);
        _Msg ->
            fun_worker(SenderPid, RecvPid, Fun)
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Worker execute function for keymap/3 and keymap/5.
%%%------------------------------------------------------------------------------------------------
keymap_worker(SenderPid, RecvPid, Fun, N) ->
    SenderPid ! {erlang:self(), ask_arg},
    receive
        {exit, Reason} ->
            exit(Reason);
        {Index, Arg} ->
            RecvPid ! {Index, erlang:setelement(N, Arg, Fun(erlang:element(N, Arg)))};
        _Msg ->
            keymap_worker(SenderPid, RecvPid, Fun, N)
    end.

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Send arguments to workers.
%%%------------------------------------------------------------------------------------------------
sender(Pid, [H | T], Index) ->
    receive
        {WorkerPid, ask_arg} ->
            WorkerPid ! {Index, H},
            sender(Pid, T, Index + 1);
        {Pid, exit, Reason} ->
            exit(Reason)
    end;
sender(_Pid, [], Index) when Index >= 1 ->
    receive
        {WorkerPid, ask_arg} ->
            WorkerPid ! {exit, normal},
            sender(_Pid, [], Index - 1)
    end;
sender(_Pid, [], Index) when Index < 1 ->
    exit(normal).

%%%------------------------------------------------------------------------------------------------
%%% @private
%%% Worker sort result list.
%%%------------------------------------------------------------------------------------------------
sort_result_worker(Pid, Position, List) ->
    Pid ! {Position, [Value || {_, Value} <- lists:keysort(1, List)]},
    exit(normal).

%%%================================================================================================
%%% CODE FOR INTERNAL FUNCTIONS
%%%================================================================================================
%%%------------------------------------------------------------------------------------------------
%%% Main process for functions that do list of functions.
%%%------------------------------------------------------------------------------------------------
fun_main_proc(Fun, List, MaxWorkrs, Timeout, MainPid, Length, RecvFun, RecvArgs) ->
    erlang:process_flag(trap_exit, true),
    NumWorkrs = case MaxWorkrs > Length of
                     true ->
                         Length;
                     false ->
                         MaxWorkrs
                 end,
    RPid = erlang:spawn_link(?MODULE, RecvFun, RecvArgs),
    SPid = erlang:spawn_link(?MODULE, sender, [MainPid, List, 0]),
    SpPid = erlang:spawn_link(?MODULE, spawn_worker, [MainPid, SPid, RPid, Fun, NumWorkrs, []]),
    receive
        {result, Result} ->
            RPid ! {MainPid, exit, nornal},
            SPid ! {MainPid, exit, normal},
            SpPid ! {MainPid, exit, normal},
            Result;
        {'EXIT', Pid, Reason} when Reason /= normal ->
            RPid ! {MainPid, exit, nornal},
            SPid ! {MainPid, exit, normal},
            SpPid ! {MainPid, exit, normal},
            erlang:error({proc_died, Pid, Reason})
    after
        Timeout ->
            RPid ! {MainPid, exit, normal},
            SPid ! {MainPid, exit, normal},
            SpPid ! {MainPid, exit, normal},
            timeout
    end.

%%%------------------------------------------------------------------------------------------------
%%% Send a message to list of pid().
%%%------------------------------------------------------------------------------------------------
send_msg(_Msg, []) ->
    ok;
send_msg(Msg, [H | T]) ->
    H ! Msg,
    send_msg(Msg, T).

%%%------------------------------------------------------------------------------------------------
%%% Sort return list into original order
%%%------------------------------------------------------------------------------------------------
sort_result(Low, High) ->
    erlang:process_flag(trap_exit, true),
    Self = self(),
    LowPid = erlang:spawn_link(?MODULE, sort_result_worker, [Self, low, Low]),
    HighPid = erlang:spawn_link(?MODULE, sort_result_worker, [Self, high, High]),
    sort_result_recv(Self, {LowPid, Low}, {HighPid, High}, {low, high}).

%%%------------------------------------------------------------------------------------------------
%%% Receiver for function sort_result/3.
%%%------------------------------------------------------------------------------------------------
sort_result_recv(Self, {LPid, LList} = Low, {HPid, HList} = High, {LPart, HPart})
  when LPart == low; HPart == high ->
    receive
        {low, Sorted} ->
            sort_result_recv(Self, Low, High, {Sorted, HPart});
        {high, Sorted} ->
            sort_result_recv(Self, Low, High, {LPart, Sorted});
        {'EXIT', _ExitPid, normal} ->
            sort_result_recv(Self, Low, High, {LPart, HPart});
        {'EXIT', LPid, Reason} when Reason /= normal ->
            NewLPid = erlang:spawn_link(?MODULE, sort_result_worker, [Self, low, LList]),
            sort_result_recv(Self, {NewLPid, LList}, {HPid, HList}, {LPart, HPart});
        {'EXIT', HPid, Reason} when Reason /= normal ->
            NewHPid = erlang:spawn_link(?MODULE, sort_result_worker, [Self, high, HList]),
            sort_result_recv(Self, {LPid, LList}, {NewHPid, HList}, {LPart, HPart});
        Error ->
            erlang:error({badmatch, Error})
    end;
sort_result_recv(_Self, _Low, _High, {LowPart, HighPart}) ->
    LowPart ++ HighPart.