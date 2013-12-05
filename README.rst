How to install
==============

::

  git clone --recursive https://github.com/arclanguage/arc-nu.git arc-nu

You'll also need `Racket <http://racket-lang.org/>`_. If you're on *nix you can probably get it with your distribution's package manager, like ``apt-get`` or ``yum`` or whatever. If you're on Windows or Mac OS X, get Racket `here <http://racket-lang.org/download/>`_.


How to run
==========

If you're on Windows, double click on the ``arc.bat`` file.

----

If you're on *nix or OS X, use ``./arc`` while in the Arc/Nu directory.

You can also use ``./arc foo`` to load the Arc file ``foo.arc``.

This also means that the ``arc`` executable is suitable for writing shell scripts::

    #! /usr/bin/env arc
    (prn "foo")

Use ``./arc -h`` to see all the available options.


Why?
====

So, why would you want to use it over Arc 3.1 or Anarki?

* It's faster! Arc/Nu strives to be *at least* as fast as Arc 3.1, and in some
  cases is significantly faster. For instance, ``(+ 1 2)`` was 75.21% faster
  in Arc/Nu than in Arc 3.1, last time I checked.

* In addition to supporting Arc 3.1, the Arc/Nu compiler can also support other languages. All languages supported by Arc/Nu can communicate with each other and use libraries defined in other languages.

* Includes an ``import`` macro which makes it significantly easier to load files::

    ; Arc 3.1
    (load "/path/to/foo.arc")

    ; Arc/Nu
    (import foo)

* The REPL is implemented **substantially** better:

  * ``Ctrl+D`` exits the REPL

  * ``Ctrl+C`` aborts the current computation but doesn't exit the REPL::

        > ((afn () (self)))
        ^Cuser break
        >

  * Readline support is built-in, which means:

    * Pressing ``Tab`` will autocomplete the names of global variables::

          > f
          filechars    find         flat         for          fromdisk
          file-exists  findsubseq   flushout     force-close  fromstring
          fill-table   firstn       fn           forlen

    * Pressing ``Up`` will recall the entire expression rather than only the
      last line::

          > (+ 1
               2
               3)
          6
          > (+ 1
               2
               3)

* You can use the ``arc`` executable to write shell scripts::

      #! /usr/bin/env arc
      (prn "foo")

  This is like ``arc.sh`` in Anarki but implemented in Racket rather than as a
  bash script, so it should be cleaner and more portable.

  In addition, it supports common Unix idioms such as::

      $ arc < foo.arc
      $ echo "(+ 1 2)"       | arc
      $ echo "(prn (+ 1 2))" | arc

  This idea is courtesy of `this thread <http://arclanguage.org/item?id=10344>`_

* Like Anarki, Arc/Nu provides a form that lets you bypass the compiler and drop
  directly into Racket. In Anarki this form is ``$`` and in Arc/Nu it's ``%``::

      > (% (let loop ((a 3))
             (if (= a 0)
                 #f
                 (begin (displayln a)
                        (loop (- a 1))))))
      3
      2
      1
      #f

  This also lets you call Arc/Nu and Racket functions that aren't exposed
  to Arc::

      > (%.->name +)
      +

      > (%.string? "foo")
      #t

* ``[a b c]`` is expanded into ``(square-brackets (a b c))`` which is then
  implemented as a macro::

      (mac square-brackets (body)
        `(fn (_) ,body))

  Likewise, ``{a b c}`` is expanded into ``(curly-brackets (a b c))``

  This makes it easy to change the meaning of ``[...]`` and ``{...}`` from
  within Arc

* The Arc/Nu compiler is written in Racket, rather than mzscheme

* Arc/Nu cleans up a lot of stuff in Arc 3.1 and fixes bugs (Anarki also fixes
  some bugs in Arc 3.1, but it generally doesn't clean things up)

* Arc/Nu has reorganized Arc 3.1 significantly, hopefully this makes it easier
  to understand and hack

* All special forms (``assign``, ``fn``, ``if``, ``quasiquote``, and ``quote``) are
  implemented as ordinary Arc macros

* For more details on the differences between Arc/Nu and Arc 3.1, see `this
  page <doc/Differences.rst>`_
