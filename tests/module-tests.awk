#
# AWK script to run a series of tests with input and expected output.
#
# Usage:
#   awk
#    -v commandFile=...
#    -v inputFile=...
#    -v outputFile=...
#    -v testScript=...
#    -f "<this file>"
#
# Where the variables are:
#   commandFile -- file to hold Command: content found in stdin
#   inputFile   -- file to hold Input: content
#   outputFile  -- file to hold Output: content
#   testScript  -- name of an executable script to run for each test.
#
# The test script will be run as:
#
#   <testScript> <commandFile> <inputFile> <outputFile> ...args...
#
# and the test script will be run for each Input: section that is found in stdin.
#
# See below for what is expected from stdin.
#
BEGIN {
  # Initialize our global variables.
  # iTest: the number of tests seen so far for the current command.
  # rc: the max return code seen from running the test script. (So we can report if any run errored)
  # file: name of the file we are currently splitting the stdin lines into.
  # cArgs: count of command line argument literals we will pass in
  # cArgFiles: cound of command line arguments we compute from files
  # trimLeading: boolean indicating if leading white space should be stripped away (0 = yes)

  # We also have these two arrays:
  # args[]: Command line arguments, including filenames to pass onwards
  # argFiles[]: Map of filename -> command to compute the argument for a particular filename

  iTest=0
  rc=0
  file=""
  cArgs=0
  cArgFiles=0
  trimLeading=1

  systemTrace = ""
  # systemTrace = "set -x ; "

  for (i = 0; i < length(PROCINFO["argv"]); i++) {
    if ( PROCINFO["argv"][i] == "-f" || PROCINFO["argv"][i] == "--file" ) {
      cmd = "dirname '" PROCINFO["argv"][i+1] "'"
      cmd | getline source_dir
      close(cmd)
    }
  }
}

$1 == "Command:" {
  # A line that starts with "Command:" indicates that the next lines should go into commandFile

  # A new Command: means that we are finished and ready to run the previous test (if any)
  runTest()
  iTest = 0

  # Close the current file handle
  closeFile()

  # Switch file so that now we write lines to the command file
  # and zero out its contents so that any prior command text is removed.
  file = commandFile
  printf "" >file

  # Clear out any arguments passed to previous commands.
  resetArgs()

  trimLeading = 1
  if ( $NF == "-" ) {
    trimLeading = 0
    NF = NF - 1
  }

  next
}

$1 == "Arg:" {
  # An argument line starts with "Arg:" and then can optionally have arguments on it.
  #
  #  Arg: --arg foo '"Foo"'
  #  Input:
  # 
  # means that when the test is run "--arg", "foo" and '"Foo"' are passed as command line arguments.
  # If there are lines that follow, the *contents* of those lines are also passed as a trailing argument.
  # Suppose we have
  #
  #  Arg: --argjson foo 
  #    "Hello World"
  #  Input:
  #
  # Then the test will be passed three command line arguments.  "--argjson", "foo" and '"Hello World"'.

  # Close the current file handle.
  closeFile()

  # Create an empty file to write subsequent lines, if any, into.
  "mktemp" | getline tempFile
  close("mktemp")

  # When we get around to running our test, we will want to include the contents of the temporary file
  # if anything was written.  If the temp file is empty then nothing will go on the command line.
  #
  # We store a shell expression that handles this in the argFiles array.
  #
  # The expression looks like:
  #
  #   test -s 'tempFile' && echo '"$( cat 'tempFile' )"'
  #
  # "test -s" checks for a non-empty file.  If there is anything in tempFile then we echo a "cat" of the contents.
  # If tempFile is empty then nothing gets echoed.  We use lots of quoting to avoid premature command line expansion.
  #
  cArgFiles = cArgFiles + 1
  argFiles[tempFile] = "test -s '" tempFile "' && echo " wrapQuotes( "\"" "$( cat " wrapQuotes( wrapQuotes(tempFile, "\"'\""), "'" ) ")" "\"", "'" )
  file = tempFile

  trimLeading = 1
  if ( $NF == "-" ) {
    trimLeading = 0
    NF = NF - 1
  }

  # Add any arguments that were passed on this "Arg:" line.
  for (i = 2 ; i <= NF ; ++i ) {
    cArgs = cArgs + 1
    args[cArgs] = $i
  }

  # And add our tempfile to the end of our arguments array.
  cArgs = cArgs + 1
  args[cArgs] = tempFile

  next
}

$1 == "ArgFile:" {
  # ArgFile lines are the same as the above except that if there is any text below, that text is passed as a filename
  # instead of its contents.
  #
  #  ArgFile: --slurpfile foo 
  #    "Hello World"
  #  Input:
  #
  # will add three extra arguments to the command:  "--slurpfile", "foo" and a filename such as "/tmp/tmp.1234".
  # "Hello World" (with a leading space) will be in "/tmp/tmp.1234".
  #
  # The filename will always be in the command line, even if it is an empty file.

  # Close the current file handle.
  closeFile()

  # Create an empty file to write subsequent lines, if any, into.
  cArgFiles = cArgFiles + 1
  "mktemp" | getline tempFile
  close("mktemp")

  # In this case, we will just echo the name of the file instead of doing a complicated check and cat like we
  # had to above, when we compute what to add to the argument line for the test.
  argFiles[tempFile] = "echo '" tempFile "'"
  file = tempFile

  trimLeading = 1
  if ( $NF == "-" ) {
    trimLeading = 0
    NF = NF - 1
  }

  # Add any arguments that were passed on this "ArgFile:" line.
  for (i = 2 ; i <= NF ; ++i ) {
    cArgs = cArgs + 1
    args[cArgs] = $i
  }

  # And add our tempfile to the end of our arguments array.
  cArgs = cArgs + 1
  args[cArgs] = tempFile

  next
}

$1 == "Input:" {
  # A line that starts with "Input:" means gather input for a new test.

  # Run any previous test we were working on.
  runTest()

  # Close the current file handle and switch over to writing into an empty input file.
  closeFile()
  file = inputFile
  printf "" >file

  trimLeading = 1
  if ( $NF == "-" ) {
    trimLeading = 0
    NF = NF - 1
  }

  iTest = iTest + 1
  next
}

$1 == "Output:" {
  # A line that starts with "Output:" means gather the expected output results of a test.

  # Close the current file handle and switch over to writing into an empty output file.
  closeFile()
  file = outputFile
  printf "" >file

  trimLeading = 1
  if ( $NF == "-" ) {
    trimLeading = 0
    NF = NF - 1
  }

  next
}

$1 == "empty" {
  # A line that starts with "empty" means that we should write an empty line into the current file.

  if ( file != "" ) {
    print "" >> file
  }
  next
}

{
  # This is the default case where a line didn't match any of the above patterns.
  # Note that for each pattern above, we include a "next" statement.  That causes awk
  # to stop its pattern matching for the current line and lines that match above don't
  # end up being also processed here.

  # We simply write the contents to the current file
  if ( file != "" ) {
    print $0 >> file
  }
}

END {
  # When reach the end of all the lines, we run the last test. 
  runTest()
  resetArgs()
}

# Function to run the test with the accumulated command, input and output.
function runTest () {
  if ( iTest > 0 ) {
    closeFile()

    # Compute any extra arguments we need to pass along.
    # system() just takes a single string as input.  We need to quote things
    # so that the shell breaks the args out properly. 
    extraArgs = ""
    for (i = 1 ; i <= cArgs ; ++i ) {
      a = args[i]
      if (a in argFiles) {
        # If this argument is a file, run the system command to get the proper text
        cmd = systemTrace argFiles[a]
        a = ""
        cmd | getline a
        close(cmd)
      } else {
        # Otherwise just quote it as a string literal.
        a = wrapQuotes(a, "'")
      }
      extraArgs = extraArgs " " a
    }

    # Make our full command line and execute it.  Remember if the test result is non-zero
    cmd = wrapQuotes(testScript, "'") " " wrapQuotes(commandFile, "'") " " wrapQuotes(inputFile, "'") " " wrapQuotes(outputFile, "'") extraArgs
    rc = rc + system(systemTrace cmd)
  }
}

# Clear out our collection of extra command line arguments and files.
function resetArgs () {
  for (x in args) {
    delete args[x]
  }

  if (cArgFiles > 0) {
    fileList = ""
    for (x in argFiles) {
      fileList=fileList "'" x "' "
      delete argFiles[x]
    }
    system(systemTrace "rm " fileList)
  }

  cArgs=0
  cArgFiles = 0
}

function closeFile () {
  if ( file != "" ) {
    close(file)
    if (trimLeading == 0) {
      system(systemTrace wrapQuotes(source_dir "/shift-left.sh", "'") " " wrapQuotes(file))
    }
  }
}

function wrapQuotes (s, quote) {
  return quote s quote
}