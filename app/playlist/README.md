How to run
==========

This is a program for generating .xspf playlists from [Nuit text](https://github.com/Pauan/ar/tree/arc/nu/lib/nuit).

It is assumed that all your playlist files will be kept in a single folder.

For the sake of this README, I'll assume that folder is called "nuit".

Here is the basic usage of the program. First, you navigate to the folder
which contains all your music, then you run the program with the path to the
"nuit" folder as the first argument:

    cd path/to/music
    playlist path/to/nuit

If you give a second argument to the playlist program, it will store the
.xspf files there instead of in the current directory:

    playlist path/to/nuit path/to/xspf

This will cause the program to scan through the "nuit" folder and use
the Nuit playlists defined within to generate .xspf equivalents.
It will then store those .xspf playlists in the "xspf" folder.

To quickly create a playlist, simply create a new file in the "nuit"
folder and add some lines which specify the music files to include. That's
it! Now just run the program as specified above.


The Nuit playlist format
========================

The simplest playlist is simply a bunch of strings, one on each line:

    Moonstone
    Orchestral Balthasar Theme
    Ruined World (Eternal Derelict)
    Green Amnesia
    Far Away Memories
    Rotted Garden

Strings are used to specify the filenames of music. Thus, each line in the
above playlist specifies a single music file. Each string only needs to
specify *part* of the filename: the string `foo` will match the file `foo`, or
the file `foobar.mp3`, or the file `/path/to/05 - foo.mp3`, etc.

The playlist format is fairly strict about the strings:

 * If a string matches two or more files, an error will be printed: you will
   need to make the string more specific.

 * If a file is matched by two or more strings, an error will be printed: you
   will need to change the strings to match different files.

 * If a string does not match any file, an error will be printed.

---

It is possible to specify more complicated things by using a list, which
starts with `@` and is followed by a name and a string. Let's look at the
`@title` list:

    @title Chrono Trigger

    Moonstone
    Orchestral Balthasar Theme
    Ruined World (Eternal Derelict)
    Green Amnesia
    Far Away Memories
    Rotted Garden

Here we've specified that the title of the playlist is `Chrono Trigger`. By
default, the playlist program uses the playlist's filename as the title, but
you can use `@title` to override it.

---

Another list is `@folder`:

    @title Chrono Trigger

    @folder Chrono Trigger
      Moonstone
      Orchestral Balthasar Theme
      Ruined World (Eternal Derelict)
      Green Amnesia
      Far Away Memories
      Rotted Garden

The above playlist is just like the previous one except that the files must be
inside the `Chrono Trigger` folder. This is useful if you have a string which
matches two or more files, but the files are in different folders: you can use
`@folder` to specify which file to match.

---

Another list is `@playlist`:

    @title Chrono Trigger

    @folder Chrono Trigger
      @playlist 5 Stars
        Moonstone
        Orchestral Balthasar Theme
      @playlist 4 Stars
        Ruined World (Eternal Derelict)
      @playlist 3 Stars
        Green Amnesia
        Far Away Memories
      @playlist 2 Stars
        Rotted Garden

The above is just like the previous playlist except that *in addition* to
adding the files to the current playlist, the files `Moonstone`
and `Orchestral Balthasar Theme` are added to the playlist `5 Stars`, the
file `Ruined World (Eternal Derelict)` is added to the playlist `4 Stars`,
etc.

Because of the rule that files may not be matched by multiple strings, this is
one way to add a file to multiple different playlists. I use this to give a
rating to my files: as shown above, the files would be put into different
"X Stars" playlists depending on their rating. But there isn't any set
semantic: you can use `@playlist` to place files into any playlist.

---

The last list is `@include`:

    @title Chrono Trigger

    @include Chrono Cross

    @folder Chrono Trigger
      @playlist 5 Stars
        Moonstone
        Orchestral Balthasar Theme
      @playlist 4 Stars
        Ruined World (Eternal Derelict)
      @playlist 3 Stars
        Green Amnesia
        Far Away Memories
      @playlist 2 Stars
        Rotted Garden

`@include` will take all the files in another playlist and will put them into
the current playlist. This is the second way to include a file in multiple
different playlists.


Examples
========

I have included a few of my own playlists in the "examples" subdirectory.

These demonstrate how to write playlists, and also clearly show how much
shorter/easier to read/write the Nuit format is, compared to raw .xspf

This makes managing playlists a much more pleasant experience.
