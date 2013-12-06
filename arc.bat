::  @echo off

::  Blatantly stolen and modified from https://gist.github.com/rocketnia/576688
 
::  Lines beginning with "rem", like this one, are comments.
 
::  The "@echo off" line above stops the following commands,
::  including these comments, from being displayed to the terminal
::  window. For a more transparent view of what this batch file is
::  doing, you can take out that line.
 
::  The @ at the beginning of "@echo off" causes that command to be
::  invisible too.
 
 
::  Now we'll keep track of ".", which is the current working
::  directory, and return to that directory later on using "popd".
::  This is mostly useful if we're running this batch file as part of
::  a longer terminal session, so that when we exit Arc and return to
::  the command prompt we're in the same directory we left.
 
pushd .

::  http://stackoverflow.com/questions/3827567/how-to-get-the-path-of-the-batch-script-in-windows
::  Actually executes Arc
for %i in (Racket.exe) do @echo. %~$PATH:i
echo "%~dp0arc"
racket "%~dp0arc"

::  The "pause" command displays a "press any key" message. If Racket
::  exits with an error, this command keeps the batch script running
::  long enough for you to read the error message. (Double-clicking a
::  batch file opens a window that closes once the script is
::  complete.)
 
pause
 
 
::  Finally, as planned, we restore the working directory we started
::  with.
 
popd