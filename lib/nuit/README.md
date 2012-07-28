Nuit (pronounced "knew it" or "new eat") is a very simple format for describing structured text. It is short for "Nu Indented Text"

Nuit attempts to combine the ease-of-use and conciseness of YAML with the simplicity of S-expressions.

Goals
=====

 1. The ability to create strings without delimiters or escaping
 2. Capable of expressing arbitrary acyclic tree structures
 3. Extremely concise and easy for humans to read and write
 4. Simple enough to be easily understood by a computer

Nuit is general-purpose. It is intended to completely replace INI and XML configuration files.

Nuit is *not* intended to have lots of features. For that, I recommend using YAML.


Data types
==========

Nuit has only lists and strings. Lists can be nested within lists which allows for arbitrary tree structures.


Syntax
======

There are special characters that can only appear at the start of a line. They are called sigils:

  * The `@` sigil creates a list:

    1. If there's any non-whitespace[1] immediately after the `@` it is added to the list as a string:

            Nuit  @foo
            JSON  ["foo"]

    2. After the first string (if any), if there's any whitespace[1] followed by non-whitespace[1], it is treated as a new line and added to the list:

            Nuit  @foo bar
            JSON  ["foo", "bar"]

            Nuit  @ foo bar
            JSON  ["foo bar"]

            Nuit  @foo @bar qux
            JSON  ["foo", ["bar", "qux"]]

    3. The line starting with `@` is the "first line". Look at the second line and see if it has a greater indent than the first line. If not, then it is not added to the list:

            Nuit  @foo bar qux
                  yes
            JSON  ["foo", "bar qux"]

    4. If the second line *does* have a greater indent than the first line then it is added to the list:

            Nuit  @foo bar qux
                    yes
            JSON  ["foo", "bar qux", "yes"]

    5. Every line after the second line that has the *same indent* as the second line is added to the list:

            Nuit  @foo bar qux
                    yes
                    @maybe
                    someday
                      not included
            JSON  ["foo", "bar qux", "yes", ["maybe"], "someday"]

    6. The above rules are recursive, which allows lists to nest within lists:

            Nuit  @foo @bar qux
                         corge nou
                    yes
                    @maybe
                      @
                      someday
            JSON  ["foo", ["bar", "qux", "corge nou"] "yes" ["maybe", [], "someday"]]

  * The `#` and \` and `"` sigils use the following indent rules:

     1. Find the number of characters between the start of the line (including indentation) and the first non-whitespace[1] character after the sigil. Let's call that number `index`.

     2. If there aren't any non-whitespace[1] characters after the sigil, then `index` is the indentation + the sigil + `1`

     3. Everything between `index` and the end of the line[2] is included in the sigil:

             Nuit  ` foobar
             JSON  "foobar"

     4. Every following line that has an indent that is greater than or equal to `index` is included in the sigil:

             Nuit  `    foobar
                         quxcorge
                        nou
                      not included
             JSON  "foobar\n quxcorge\nnou"

     5. Empty lines are also included, regardless of their indentation:

             Nuit  ` foobar
                      quxcorge

                     nou

                     yes
             JSON  "foobar\n quxcorge\n\nnou\n\nyes"

    In addition, the following rules apply to the individual sigils:

      * `#` completely ignores everything that is included by the above indent rules.

      * \` creates a string which contains everything that is included by the above indent rules.

      * `"` is exactly like \` except:

          * 1 empty line is converted to a space[1]:

                Nuit  " foobar
                        quxcorge
                        nou
                JSON  "foobar quxcorge nou"

          * 2+ empty lines are left unchanged:

                Nuit  " foobar

                        quxcorge

                        nou
                JSON  "foobar\n\nquxcorge\n\nnou"

          * Within the string, `\` has the following meaning:

              * `\` at the end of the line[2] inserts a literal newline, except at the end of the string, in which case it does nothing:

                    Nuit  " foobar\
                            quxcorge\
                            nou\
                    JSON  "foobar\nquxcorge\nnou"

              * `\\` inserts a literal `\`:

                    Nuit  " foo\\bar
                    JSON  "foo\\bar"

              * `\u` starts a Unicode code point escape[3]:

                    Nuit  " foo\u(20 20AC)bar
                    JSON  "foo\u20\20ACbar"

  * The `\` sigil creates a string which contains the next sigil and continues until the end of the line[2]:

        Nuit  \@foobar
        JSON  "@foobar"

        Nuit  \#foobar
        JSON  "#foobar"

        Nuit  \`foobar
        JSON  "`foobar"

        Nuit  \"foobar
        JSON  "\"foobar"

        Nuit  \\foobar
        JSON  "\\foobar"

If a line does not start with any of the above sigils it is treated as a string that continues until the end of the line[2].

Whitespace[1] is *completely* ignored at the end of the line[2], even within strings.

Except within strings, empty lines are *completely* ignored. They don't even count for indentation.

It is invalid for a non-empty line to be indented if it is not within a list, comment, or string.

There is an implicit list that contains the entire Nuit text. Which means this:

    @playlist 5 Stars
      05 - Memories of Green
      51 - Time Circuits
      55 - Undersea Palace

    @playlist 4 Stars
      47 - Battle with Magus
      53 - Sara's (Schala's) Theme
      64 - To Far Away Times

    @playlist 3 Stars
      11 - Secret of the Forest
      36 - The Brink of Time

Is the same as this JSON:

    [
      ["playlist", "5 Stars",
        "05 - Memories of Green",
        "51 - Time Circuits",
        "55 - Undersea Palace"],
      ["playlist", "4 Stars",
        "47 - Battle with Magus",
        "53 - Sara's (Schala's) Theme",
        "64 - To Far Away Times"],
      ["playlist", "3 Stars",
        "11 - Secret of the Forest",
        "36 - The Brink of Time"]
    ]

That's it! The only thing left to describe is some Unicode details.


Unicode
=======

All parsers and serializers are required to support Unicode. This specification deals only with Unicode code points: the encoding used is an implementation detail.

It is *very highly* recommended to support at least UTF-8, but any Unicode encoding is acceptable (UTF-7, UTF-16, UTF-32, Punycode, etc.)

---

The following Unicode code points are *always* invalid:

    # whitespace
    U+0009
    U+000B
    U+000C
    U+0085
    U+00A0
    U+1680
    U+180E
    U+2000 - U+200A
    U+2028
    U+2029
    U+202F
    U+205F
    U+3000

    # non-printing
    U+0000 - U+0008
    U+000E - U+001F
    U+007F
    U+0080 - U+0084
    U+0086 - U+009F
    U+FDD0 - U+FDEF
    U+FFFE
    U+FFFF
    U+1FFFE
    U+1FFFF
    U+10FFFE
    U+10FFFF

To represent them, you must use a Unicode code point escape[3]

---

The Unicode byte order mark `U+FEFF` is invalid everywhere except as the first character in the stream. It is used for encoding and is an implementation detail. Thus, it has no effect on indentation, is not included in the string, etc.

---

The following Unicode code points are *only* valid when using UTF-16 encoding:

    U+D800 - U+DFFF

They are **always** invalid within Unicode code point escapes[3] even in UTF-16 encoding

---

All other Unicode characters may be used freely.

---

  * [1]: Whitespace is defined as the Unicode code point `U+0020` (space).

  * [2]: End of line is defined as either `EOF`, `U+000A` (newline), `U+000D` (carriage return), or the combination of `U+000D` and `U+000A`. Parsers must convert all end of lines (but not `EOF`) within strings to `U+000A`

  * [3]: A Unicode code point escape starts with `\u(`, contains one or more strings (which must contain only the hexidecimal characters `0123456789abcdefABCDEF`) separated by whitespace[1], and ends with `)`

    Each string is the hexadecimal value of a Unicode code point. As an example, the string `"fob` is the same as `"\u(66)\u(6F)\(62)` which is the same as `"\u(66 6F 62)`. Because they are *code points* and not bytes, `\u(1D11E)` represents the Unicode character `𝄞`

    Unicode code point escapes are necessary to include invalid characters (listed above). They are also useful in the situation where you don't have an easy way to insert a Unicode character directly, but you do know its code point, e.g. you can represent the string `foo€bar` as `"foo\u(20AC)bar`


Comparison
==========

It is only natural to want to compare text formats to see which one is the "best". Unfortunately, there is no "best" format because it depends on what your needs are. So, instead, I will present what I believe to be the advantages and disadvantages of other text formats compared to Nuit.

JSON
----

In Nuit, the sender emits generic lists and strings. It's up to the receiver to parse those lists and strings in any way it wants: as a number, or a hash table, or a binary search tree, etc. This same flexibility is found in XML.

JSON, however, provides native support for unordered dictionaries, numbers, booleans, and null. This means that the *sender* can decide how the data should be structured, and the receiver has to go out of its way to change that structure.

In practice this isn't a big deal because JSON was originally designed to communicate between a server and JavaScript. Thus, using JavaScript's native notation for objects, arrays, numbers, booleans, and null, was a practical decision.

---

JSON does not have any support for comments. Nuit, however, supports both single and multi-line comments. It is also much more concise than JSON, which makes it easier to read and write. These two things combined make Nuit much better for configuration files.

As shown below, Nuit is actually shorter than JSON, even after taking into account the extra overhead from CR+LF line endings. This is because JSON requires `"` around every string while Nuit doesn't.

YAML
----

The next obvious comparison would be with YAML. Like JSON, YAML supports unordered dictionaries, numbers, booleans, and null. In fact, YAML is a strict superset of JSON, which means all JSON is valid YAML. Unlike JSON, YAML also supports a much cleaner syntax and a much wider variety of types, including sets and ordered dictionaries.

When it comes to raw features, YAML is clearly *drastically* better than XML, JSON, and Nuit. The primary downside of YAML is that, *precisely because* it has so many amazing features, it's also much more complicated than JSON and Nuit.

My recommendation is to use Nuit if it's good enough for your needs (because of its simplicity), but if Nuit starts to get too restrictive, switch to YAML.

XML
---

Ah, yes, XML... the only real compliment I can give is that it works passably when writing a document that has lots of text in it, such as a web page. Unfortunately, XML is terrible for *everything else*.

Just don't use XML. If you have to communicate with some other code that *already uses* XML, then you have no choice... but if you have even the slightest choice in the matter, use a better format like YAML or Nuit.

Don't use XML even if your favorite language has an XML parser and doesn't have a Nuit parser: it's easier and faster to just write your own Nuit parser rather than deal with XML.


Size comparison
===============

Let's look at a size comparison between the various text formats. It is assumed that UTF-8 is used in serialization and that the line endings are CR+LF (this is a common situation when transmitting over HTTP). The results are listed from smallest-to-largest:

Inline YAML (650 bytes):

    [[playlist,{5 Stars:[[05 - Memories of Green,{album:Chrono Trigger,author:Yasunori Mitsuda}],[51 - Time Circuits,{album:Chrono Trigger,author:Yasunori Mitsuda}],[55 - Undersea Palace,{album:Chrono Trigger,author:Yasunori Mitsuda}]]}],[playlist,{4 Stars:[[47 - Battle with Magus,{album:Chrono Trigger,author:Yasunori Mitsuda}],[53 - Sara's (Schala's) Theme,{album:Chrono Trigger,author:Yasunori Mitsuda}],[64 - To Far Away Times,{album:Chrono Trigger,author:Yasunori Mitsuda}]]}],[playlist,{3 Stars:[[11 - Secret of the Forest,{album:Chrono Trigger,author:Yasunori Mitsuda}],[36 - The Brink of Time,{album:Chrono Trigger,author:Yasunori Mitsuda}]]}]]

Nuit (731 bytes):

    @playlist 5 Stars
     @file 05 - Memories of Green
      @album Chrono Trigger
      @author Yasunori Mitsuda
     @file 51 - Time Circuits
      @album Chrono Trigger
      @author Yasunori Mitsuda
     @file 55 - Undersea Palace
      @album Chrono Trigger
      @author Yasunori Mitsuda
    @playlist 4 Stars
     @file 47 - Battle with Magus
      @album Chrono Trigger
      @author Yasunori Mitsuda
     @file 53 - Sara's (Schala's) Theme
      @album Chrono Trigger
      @author Yasunori Mitsuda
     @file 64 - To Far Away Times
      @album Chrono Trigger
      @author Yasunori Mitsuda
    @playlist 3 Stars
     @file 11 - Secret of the Forest
      @album Chrono Trigger
      @author Yasunori Mitsuda
     @file 36 - The Brink of Time
      @album Chrono Trigger
      @author Yasunori Mitsuda

JSON (742 bytes):

    [["playlist",{"5 Stars":[["05 - Memories of Green",{"album":"Chrono Trigger","author":"Yasunori Mitsuda"}],["51 - Time Circuits",{"album":"Chrono Trigger","author":"Yasunori Mitsuda"}],["55 - Undersea Palace",{"album":"Chrono Trigger","author":"Yasunori Mitsuda"}]]}],["playlist",{"4 Stars":[["47 - Battle with Magus",{"album":"Chrono Trigger","author":"Yasunori Mitsuda"}],["53 - Sara's (Schala's) Theme",{"album":"Chrono Trigger","author":"Yasunori Mitsuda"}],["64 - To Far Away Times",{"album":"Chrono Trigger","author":"Yasunori Mitsuda"}]]}],["playlist",{"3 Stars":[["11 - Secret of the Forest",{"album":"Chrono Trigger","author":"Yasunori Mitsuda"}],["36 - The Brink of Time",{"album":"Chrono Trigger","author":"Yasunori Mitsuda"}]]}]]

Indented YAML (778 bytes):

    - playlist
      5 Stars:
       - 05 - Memories of Green
         album: Chrono Trigger
         author: Yasunori Mitsuda
       - 51 - Time Circuits
         album: Chrono Trigger
         author: Yasunori Mitsuda
       - 55 - Undersea Palace
         album: Chrono Trigger
         author: Yasunori Mitsuda
    - playlist
      4 Stars:
       - 47 - Battle with Magus
         album: Chrono Trigger
         author: Yasunori Mitsuda
       - 53 - Sara's (Schala's) Theme
         album: Chrono Trigger
         author: Yasunori Mitsuda
       - 64 - To Far Away Times
         album: Chrono Trigger
         author: Yasunori Mitsuda
    - playlist
      3 Stars:
       - 11 - Secret of the Forest
         album: Chrono Trigger
         author: Yasunori Mitsuda
       - 36 - The Brink of Time
         album: Chrono Trigger
         author: Yasunori Mitsuda

XML (807 bytes):

    <playlists><playlist name="5 Stars"><file album="Chrono Trigger" author="Yasunori Mitsuda">05 - Memories of Green</file><file album="Chrono Trigger" author="Yasunori Mitsuda">51 - Time Circuits</file><file album="Chrono Trigger" author="Yasunori Mitsuda">55 - Undersea Palace</file></playlist><playlist name="4 Stars"><file album="Chrono Trigger" author="Yasunori Mitsuda">47 - Battle with Magus</file><file album="Chrono Trigger" author="Yasunori Mitsuda">53 - Sara's (Schala's) Theme</file><file album="Chrono Trigger" author="Yasunori Mitsuda">64 - To Far Away Times</file></playlist><playlist name="3 Stars"><file album="Chrono Trigger" author="Yasunori Mitsuda">11 - Secret of the Forest</file><file album="Chrono Trigger" author="Yasunori Mitsuda">36 - The Brink of Time</file></playlist></playlists>

---

If you're after the smallest format, inline YAML wins by a *very* huge margin. Nuit and JSON are quite close to eachother. Indented YAML and XML are the worst of the bunch, by a fairly significant margin.

If you use LF or CR rather than CR+LF then Nuit is 704 bytes and Indented YAML is 748 bytes.
