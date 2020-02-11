# some_erlang_libs
    This project contains some libraries for Erlang that may help you in your Erlang application.
    Project's structure doesn't match with Erlang application structure because it isn't a application, it only contain some standalone modules that may help you in your Erlang project.

## Basic libraries (basic_libs)
    Contain some basic modules that don't use multiple processes.
    Many functions in these modules are prototype functions.

### Libraries in basic_libs
    * h_erl: Contain some basic simple functions for Erlang.

## Concurence libraries (con_libs)
    Contains Erlang OTP module that was rewrite into multiple processes.
    These libraries divided into 2 version: without supervisor version and with supervisor version.

### Without Supervisor (without_sup)
    Modules in this version just simply spawn multiple of processes to do a certain job without controlling them and those processes will automatically exit when it's job is done.
    This version runs faster than with_sup version but less relible. You only should use it when you made sure that it won't spawn too many processes.

### With Supervisor (with_sup)
    Modules in this version will spawn a limited number of processes to do a certain job and those processes will be controlled by their spawner.
    This version runs slower than without_sup version but more relible. You can use it most of the time and it's better than without_sup version when you can't make sure the number of processes that will be spawned or you know that number will be huge.

### Libraries in con_libs
    * con_lists: List processing functions.
