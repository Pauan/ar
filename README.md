Lite Nu is Nu stripped down to the bare minimum:

  * "01 ac.rkt" is the Nu compiler for Arc
  * "arc.arc" is copied unmodified from Arc 3.1
  * "repl.arc" implements a REPL
  * "arc" is an executable that will load the above three files in order

Okay, so it's basically just Arc 3.1 (it even copies arc.arc from Arc 3.1!).
Why would you want to use it over Arc 3.1 or Anarki, then?

  * It's faster! Nu strives to be *at least* as fast as Arc 3.1, and in some
    cases is significantly faster. For instance, `(+ 1 2)` is 44.12% faster in
    Nu than in Arc 3.1

  * Nu lets you define custom calling behavior for anything you like by
    extending the `ref` function. This is like `defcall` in Anarki

  * Nu reflects some of the compiler functions into Arc, so they can be called
    and hacked from within Arc

  * Like Anarki, Nu provides a form that lets you bypass the compiler and drop
    directly into Racket. In Anarki this form is `$` and in Nu it's `%`:

        > (% (let loop ((a 3))
               (if (= a 0)
                   #f
                   (begin (displayln a)
                          (loop (- a 1))))))
        3
        2
        1
        #f

    This also lets you call Nu compiler/Racket functions that aren't exposed
    to Arc:

        > (%.global-name 'foo)
        _foo

        > (%.string? "foo")
        #t

  * The Nu compiler is written in Racket, rather than mzscheme

  * Nu makes it possible to add in awesome things like namespaces, aliases,
    and implicit parameters as a library without hacking the compiler

  * Nu cleans up a lot of stuff in Arc 3.1 and fixes bugs (Anarki also fixes
    some bugs in Arc 3.1, but it generally doesn't clean things up)

  * You can use the "arc" executable to write shell scripts:

        #! /path/to/arc
        (prn "foo")

    This is like "arc.sh" in Anarki but implemented in Racket rather than as a
    bash script

  * Nu has reorganized Arc 3.1 significantly, hopefully this makes it easier
    to understand and hack

  * All special forms (`assign`, `fn`, `if`, `quasiquote`, and `quote`) are
    implemented as ordinary Arc macros