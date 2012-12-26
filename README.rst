How to install
==============

::

  git clone --recursive https://github.com/Pauan/ar.git arc-nu


How to run
==========

Just call ``./arc`` and you'll get a REPL.

You can also use ``./arc foo`` to load the Arc file "foo.arc".

This also means that the ``arc`` executable is suitable for writing shell scripts::

    #! /path/to/arc
    (prn "foo")

Use ``./arc -h`` to see all the available options.


What is it?
===========

Arc/Nu is Arc 3.1 but *bettar*. It includes some bug fixes and additional libraries and applications that I've found useful.

* ``01 nu.rkt`` is the Arc/Nu compiler
* ``02 arc.arc`` is copied unmodified from Arc 3.1
* ``03 utils.arc`` contains generic utilities
* ``04 parameters.arc`` implements implicit parameters
* ``05 paths.arc`` contains functions for inspecting and manipulating paths
* ``06 import.arc`` implements an ``import`` macro for loading files
* ``07 repl.arc`` implements a REPL
* ``arc`` is an executable that will load the above files in order

* ``lib/`` contains other useful libraries
* ``app/`` contains applications I've written using Arc/Nu

Okay, so it's basically Arc 3.1 (it even copies arc.arc from Arc 3.1!).
Why would you want to use it over Arc 3.1 or Anarki, then?

* It's faster! Arc/Nu strives to be *at least* as fast as Arc 3.1, and in some
  cases is significantly faster. For instance, ``(+ 1 2)`` was 132.48% faster
  in Arc/Nu than in Arc 3.1, last time I checked. You can view the latest timing
  tests `here <timing>`

* Arc/Nu makes it possible to add in awesome things like namespaces, aliases,
  and implicit parameters as a library without hacking the compiler.

  As an example, Arc/Nu implements ``defcall`` as a library by extending the
  ``ref`` function in ``lib/01 utils.arc`` and implements implicit parameters
  in ``lib/02 parameters.arc``

* Racket's keyword arguments are fully supported::

      > (def foo (:bar (o :qux 5))
          (list bar qux))

      > (foo :bar 10)
      (10 5)

      > (foo :qux 20)
      (nil 20)

      > (foo :qux 2 :bar 1)
      (1 2)

  Not only are keywords supported, but they're arguably supported better
  than in Racket::

      > (mac tester (:test)
          `(do (prn ,test)
               (+ 1 2)))

      > (tester)
      nil
      3

      > (tester :test "hello!")
      hello!
      3

  Yeah, that's right, you can use keyword arguments with macros too. And it
  works exactly the same as it does with functions: no mucking around with
  ``syntax-case``. But wait, that's not all!

  ::

      > (def proxy args
          (prn args)
          (apply foo args))

      > (proxy :bar 10)
      (:bar 10)
      (10 5)

      > (apply foo :bar 10 nil)
      (10 5)

      > (apply foo '(:bar 10))
      (10 5)

  Functions receive the keyword arguments in their rest arg and ``apply``
  works too. This means you don't need to muck around with
  ``make-keyword-procedure`` or ``keyword-apply`` at all. Much cleaner.

* The REPL is implemented **substantially** better:

    * ``Ctrl+D`` exits the REPL

    * ``Ctrl+C`` aborts the current computation but doesn't exit the REPL::

          > ((afn () (self)))
          ^Cuser break
          >

    * Readline support is built-in, which means:

      * Pressing ``Tab`` will autocomplete the names of global variables::

            > f
            filechars    file-exists  fill-table   find         firstn       flat         flushout     fn           for          force-close  forlen       fromdisk     fromstring

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

      #! /path/to/arc
      (prn "foo")

  This is like ``arc.sh`` in Anarki but implemented in Racket rather than as a
  bash script, so it should be cleaner and more portable.

  In addition, it supports common Unix idioms such as::

      $ /path/to/arc < foo.arc
      $ echo "(+ 1 2)" | /path/to/arc

  This idea is courtesy of `this thread <http://arclanguage.org/item?id=10344>`

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

  This also lets you call Arc/Nu compiler/Racket functions that aren't exposed
  to Arc::

      > (%.make-global-var 5)
      #<fn>

      > (%.string? "foo")
      #t

* ``[a b c]`` is expanded into ``(square-brackets a b c)`` which is then
  implemented as a macro::

      (mac square-brackets body
        `(fn (_) ,body))

  Likewise, ``{a b c}`` is expanded into ``(curly-brackets a b c)``

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
  page <../../blob/arc%2Fnu/notes/differences.md>`
