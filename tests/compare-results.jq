# jq script which returns nothing if we got what we expected.
# $got and $expected should be passed as command line arguments.
# This should also be run with the "--null-input" because it
# doesn't read any input from stdin. 
#
# Examples:
#
#   ------
#   Input:
#     empty
#   Arg: --null-input
#   ArgFile: --slurpfile got
#     "A"
#   ArgFile: --slurpfile expected
#     "A"
#   Output:
#   ------
#
#   ------
#   Input:
#     empty
#   Arg: --null-input
#   ArgFile: --slurpfile got
#     "A" { "key1": "val1", "key2": "val"2 }
#
#   ArgFile: --slurpfile expected
#     "A" { "key2": "val2", "key1": "val1" }
#   Output:
#   ------

if $got == $expected then
  empty
else
  "" | halt_error
end
