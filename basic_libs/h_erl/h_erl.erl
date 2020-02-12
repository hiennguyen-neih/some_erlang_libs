%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc
%%% <pre>
%%%     This module contain some basic simple functions for erlang.
%%%
%%%     NOTE: This module only contains some prototype functions.
%%% </pre>
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(h_erl).
% -compile(export_all).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1. EXPORT_FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export([is_string/1,
         string_to_list/1,
         to_list/1,
         type_of/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2. MACROS AND RECORDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%================================================================================================
%%% MACROS
%%%================================================================================================

%%%================================================================================================
%%% RECORDS
%%%================================================================================================

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 3. CODE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%================================================================================================
%%% CODE FOR EXPORTED FUNCTIONS
%%%================================================================================================
%%%------------------------------------------------------------------------------------------------
%%% @spec is_string(Term) -> boolean()
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Term = term()
%%% === Description ===
%%%     Returns true if Term is a valid string, otherwise false.
%%%     NOTE: This function DOESN'T work on unicode chardata.
%%% === Example ===
%%% ```
%%%     h_erl:is_string(<<"neih"/utf8>>).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
is_string([]) ->
    true;
is_string([H | T] = Term) ->
    case type_of_hd(H) of
        integer ->
            io_lib:printable_list(Term);
        list ->
            case io_lib:printable_list(H) of
                true ->
                    is_string(T);
                false ->
                    false
            end;
        binary ->
            case io_lib:printable_list(erlang:binary_to_list(H)) of
                true ->
                    is_string(T);
                false ->
                    false
            end;
        _ ->
            false
    end;
is_string(Term) when is_binary(Term) ->
    io_lib:printable_list(erlang:binary_to_list(Term));
is_string(_Term) ->
    false.

%%% Not yet finish.
% send_msg(Msg, Pids) when is_list(Pids) ->
%     lists:foreach(fun(X) ->
%                       if
%                           is_pid(X) ->
%                               X ! Msg;
%                           is_port(X) ->
%                               X ! Msg;
%                           true ->
%                               ok
%                       end end, Pids);
% send_msg(Msg, Pids) when is_tuple(Pids) ->
%     Msg.

%%%------------------------------------------------------------------------------------------------
%%% @spec string_to_list(String) -> List | {error, wrong_data_type}
%%% @doc
%%% <pre>
%%% === Type ===
%%%     String = tring()
%%%     List = list()
%%% === Description ===
%%%     Returns a list corresponding to String or return {error, wrong_data_type} if String is not 
%%% a string().
%%% === Example ===
%%% ```
%%%     h_erl:string_to_list(<<"neih"/utf8>>).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
string_to_list(Str) ->
    case is_string(Str) of
        true ->
            case is_list(Str) of
                true ->
                    Str;
                false ->
                    erlang:binary_to_list(Str)
            end;
        false ->
            {error, wrong_data_type}
    end.

%%%------------------------------------------------------------------------------------------------
%%% @spec to_list(Term) -> List | {wrong_data_type, Type}
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Term = term()
%%%     List = list()
%%%     Type = type()
%%%            Type of Term
%%%     type() = integer | float | boolean | atom | string | list | array | tuple | binary | 
%%%              bitstring | pid | port | map | function | reference | unknown
%%% === Description ===
%%%     Returns a list corresponding to Term or return {error, Type} if Term is not supported type.
%%% === Example ===
%%% ```
%%%     h_erl:to_list(301).
%%%     h_erl:to_list(neih).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
to_list(Term) ->
    Type = type_of(Term),
    io:format("~p~n", [Type]),
    case type_of(Term) of
        integer ->
            erlang:integer_to_list(Term);
        float ->
            erlang:float_to_list(Term);
        atom ->
            erlang:atom_to_list(Term);
        string ->
            string_to_list(Term);
        binary ->
            erlang:binary_to_list(Term);
        bitstring ->
            erlang:bitstring_to_list(Term);
        tuple ->
            erlang:tuple_to_list(Term);
        pid ->
            erlang:pid_to_list(Term);
        port ->
            erlang:port_to_list(Term);
        function ->
            erlang:fun_to_list(Term);
        reference ->
            erlang:ref_to_list(Term);
        Type ->
            {wrong_data_type, Type}
    end.

%%%------------------------------------------------------------------------------------------------
%%% @spec type_of(Term) -> Type
%%% @doc
%%% <pre>
%%% === Type ===
%%%     Term = term()
%%%     Type = type()
%%%     type() = integer | float | boolean | atom | string | list | array | tuple | binary | 
%%%              bitstring | pid | port | map | function | reference | unknown
%%% === Description ===
%%%     Returns type of Term if it was a known type, otherwise unknown. This function just simply 
%%% do some patern matching to check data type.
%%%     NOTE: This function only can check type at run-time NOT compile-time.
%%% === Example ===
%%% ```
%%%     h_erl:type_of(301).
%%%     h_erl:type_of(true).
%%% '''
%%% </pre>
%%% @end
%%%------------------------------------------------------------------------------------------------
type_of(Term) when is_integer(Term) ->
    integer;
type_of(Term) when is_float(Term) ->
    float;
type_of(Term) when is_boolean(Term) ->
    boolean;
type_of(Term) when is_atom(Term) ->
    atom;
type_of(Term) when is_list(Term) ->
    case is_string(Term) of
        true ->
            string;
        false ->
            list
    end;
type_of(Term) when is_tuple(Term) ->
    case array:is_array(Term) of
        true ->
            array;
        false ->
            tuple
    end;
type_of(Term) when is_binary(Term) ->
    case is_string(Term) of
        true ->
            string;
        false ->
            binary
    end;
type_of(Term) when is_bitstring(Term) ->
    bitstring;
type_of(Term) when is_pid(Term) ->
    pid;
type_of(Term) when is_port(Term) ->
    port;
type_of(Term) when is_map(Term) ->
    map;
type_of(Term) when is_function(Term) ->
    function;
type_of(Term) when is_reference(Term) ->
    reference;
type_of(_Term) ->
    unknown.

%%%================================================================================================
%%% CODE FOR INTERNAL FUNCTIONS
%%%================================================================================================
%%% Only used to check type of head of list and only check if it was integer,
%%% list or binary.
type_of_hd(H) when is_integer(H) ->
    integer;
type_of_hd(H) when is_list(H) ->
    list;
type_of_hd(H) when is_binary(H) ->
    binary;
type_of_hd(_H) ->
    unknown.