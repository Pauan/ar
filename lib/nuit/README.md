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

The syntax is extremely simple. Here's an example:

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

The above is intended to describe a playlist of music files. It is equivalent to the following JSON:

    [["playlist", "5 Stars",
       "05 - Memories of Green",
       "51 - Time Circuits",
       "55 - Undersea Palace"],
     ["playlist", "4 Stars",
       "47 - Battle with Magus",
       "53 - Sara's (Schala's) Theme",
       "64 - To Far Away Times"]
     ["playlist", "3 Stars",
       "11 - Secret of the Forest",
       "36 - The Brink of Time"]]

How does it work? There are special characters that can only appear at the start of a line. They are called sigils:

  * The `@` sigil creates a list:

      * Anything between the `@` and the first whitespace character[1] is the first element of the list.

      * Anything between the whitespace character[1] and the end of the line[2] is the second element of the list.

      * Every line that's indented further than the `@` is added to the list.

  * The `#` sigil creates a comment. Anything that is indented greater than the `#` is completely ignored by the parser.

  * The `\`` sigil creates a multi-line string that contains everything that is indented greater than `\``:

        ` foobar
          quxcorge
          nou

        "foobar\nquxcorge\nnou"

  * The `"` sigil is exactly like `\`` except it converts newlines[2] to a single space:

        " foobar
          quxcorge
          nou

        "foobar quxcorge nou"

    In addition, within the string, `\` has the following meaning:

      * `\\` inserts a literal `\`
      * `\u` starts a Unicode code point escape[3]

  * The `\` sigil creates a new string which contains the next sigil and continues until the end of the line[2]:

        \@foobar -> "@foobar"
        \#foobar -> "#foobar"
        \`foobar -> "`foobar"
        \"foobar -> "\"foobar"
        \\foobar -> "\\foobar"

If a line does not start with any of the above sigils it is treated as a string that continues until the end of the line[2].

That's it! The only thing left to describe is some Unicode implementation details.


Unicode
=======

The following Unicode code points are not legal at the start of a string:

    U+0009 through U+000A
    U+000D
    U+0020
    U+0085
    U+00A0
    U+1680
    U+180E
    U+2000 through U+200A
    U+2028 through U+2029
    U+202F
    U+205F
    U+3000

If you wish to put them at the start of a string you must use a `\`` or `"` sigil.

When serializing to a string, it is required to convert all of the above code points (excluding `U+0020` and `U+000A`) into a Unicode code point escape[3].

This is because the above are *whitespace* characters which are usually invisible. Encoding them as Unicode code points makes them visible and removes any ambiguity.

---

The following Unicode code points are *always* illegal, even within a `"` sigil:

    U+0000 through U+0008
    U+000B through U+000C
    U+000E through U+001F
    U+007F
    U+0080 through U+0084
    U+0086 through U+009F
    U+D800 through U+DFFF
    U+FFFE through U+FFFF

To represent them, you must use a Unicode code point escape[3] within a `"` sigil.

---

All other Unicode characters may be used freely.

---

* [1]: Whitespace is defined as the Unicode code point `U+0020` (space) and end of line[2].

* [2]: End of line is defined as either EOF, `U+000A` (newline), `U+000D` (carriage return), or the combination of `U+000D` and `U+000A`. Parsers must convert all end of lines (excluding EOF) within strings to `U+000A`

* [3]: A Unicode code point escape starts with `\u(`, contains one or more strings (which must contain only the hexidecimal characters 0123456789abcdefABCDEF) separated by whitespace[1], and ends with `)`.

Each string is the hexadecimal value of a Unicode code point. As an example, the string `fob` is the same as `"\u(66)\u(6F)\(62)"` which is the same as `"\u(66 6F 62)"`

This is necessary to include illegal characters (listed above). It is also useful in the situation where you don't have an easy way to insert a Unicode character directly, but you do know its code point, e.g. you can represent the string `foo€bar` as `"foo\u(20AC)bar"`


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
