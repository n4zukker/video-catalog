#
# sed script to extract unit tests from the comments in a file.
#
# This script pulls out all lines after a comment of
# "Examples:" until the next uncommented line.
#
# Empty lines are removed.
# Leading spaces are removed from lines ending with ":"
# and also lines that start with "Arg:" or "ArgFile:".
# Lines consisting of hyphens are also removed.
#
# Examples:
# Arg: --silent
# Input: -
#   # ...
#   # some leading text
#   # ...
#   #
#   # Examples:
#   # Input:
#   #   test input line 1
#   #   test input line 2
#   # Arg: a b c
#   #
# Output: -
#   >Input:
#   >   test input line 1
#   >   test input line 2
#   >Arg: a b c
# ---
#
/^#[[:space:]]*Examples:/,/\(^[^#]\)\|\(^$\)/ {
  # Delete the first and last lines.  The leading one with Examples and the trailing non-comment one.
  /^#[[:space:]]*Examples:/d
  /^[^#]/d

  # Remove the leading comment mark from the lines
  s/#//

  # Trim leading spaces from the start of our keyword lines
  s/^[[:space:]]*\(Command:\)/\1/
  s/^[[:space:]]*\(Arg:\)/\1/
  s/^[[:space:]]*\(ArgFile:\)/\1/
  s/^[[:space:]]*\(Input:\)/\1/
  s/^[[:space:]]*\(Output:\)/\1/

  # Delete any lines with just four or more hyphens, or lines that are empty
  /^[[:space:]]*\(----*\)$/d
  /^[[:space:]]*$/d

  # print out the result.
  # This file should be run with the -n, --quiet or --silent option.
  p
}
