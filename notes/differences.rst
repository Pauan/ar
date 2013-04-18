Differences between Arc/Nu and Arc 3.1
======================================

Bug Fixes
---------

* ``coerce`` and ``annotate`` use Arc's ``is`` rather than Racket's ``eqv?``

* atstrings and ssyntax use Arc's ``sread`` rather than Racket's ``read``

* The following macro works differently in Arc/Nu (use ``%`` instead)::

    > (mac $ (x) `(cdr `(0 . ,,x)))
    > ($ (let a 5 a))
    5

* Lexical variables take precedence over macros::

    > (mac foo (x) `(+ ,x 2))
    > (foo 0)
    2
    > (let foo [+ _ 5] (foo 0))
    5

* Global variables are represented with their Arc names::

    > x
    error: x: undefined;
     cannot reference undefined identifier

* Function rest args are ``nil``-terminated::

    > (cdr ((fn args args) 1))
    nil

* ``uniq`` is implemented using actual Racket gensyms

* The queue bug `has been fixed <http://arclanguage.org/item?id=13616>`_


New Features
------------

* Arc special forms are implemented as macros::

    assign fn if quasiquote quote

* New macros:

  * ``{...}`` expands to ``(curly-brackets ...)``

  * ``[...]`` expands to ``(square-brackets ...)``

  * ``%`` lets you use Racket stuff from within Arc::

      (%.string? "yes")

      (% (let self ((x 0))
           (if (< x 5)
               (self (+ x 1))
               (displayln x))))

    You can also use it to access the compiler::

      (%.ac '(+ 1 2))

      (%.->box '+)

  * ``w/include``, ``w/exclude``, ``w/rename``, and ``w/prefix`` provide great control over variables::

      ; Only the variable foo is accessible outside the w/include
      (w/include (foo)
        (= foo 1)
        (= bar 2)
        (= qux 3))

      ; The variable foo is not accessible outside the w/exclude
      (w/exclude (foo)
        (= foo 1)
        (= bar 2)
        (= qux 3))

      ; The variable foo is renamed to foo2; bar and qux are not renamed
      (w/rename (foo foo2)
        (= foo 1)
        (= bar 2)
        (= qux 3))

      ; foo, bar, and qux are renamed to my-foo, my-bar, and my-qux
      (w/prefix my-
        (= foo 1)
        (= bar 2)
        (= qux 3))

  * ``w/lang`` lets you use a different language in the same file::

      (w/lang arc/nu
        (var foo 1))

  * ``import``, ``export``, and ``reimport`` provide a more concise way to load files. They also work with ``w/include``, ``w/exclude``, ``w/rename``, ``w/prefix``, and ``w/lang``::

      ; Loads the foo library defined in arc/3.1
      (import foo)

      ; Loads the foo library defined in arc/nu
      (w/lang arc/nu
        (import foo))

      ; Loads the qux library, but without the foo and bar variables
      (w/exclude (foo bar)
        (import qux))

      ; Loads the foo library and also exports it
      (export foo)

      ; Reloads the foo library even if it's already been loaded
      (reimport foo)

* Fractions print as decimals::

    > 1/3
    0.3333333333333333

* Functions print as ``#<fn:...>`` and macros print as ``#<mac:...>``. In
  addition, macros have names::

    > do
    #<mac:do>

* ``[a b c]`` is expanded into ``(square-brackets a b c)`` which is then
  implemented as a macro::

    (mac square-brackets body
      `(fn (_) ,body))

  Likewise, ``{a b c}`` is expanded into ``(curly-brackets a b c)``

  This makes it easy to change the meaning of ``[...]`` and ``{...}`` from
  within Arc

* Anything not understood by the compiler is considered to be a literal.
  Thus, Racket values can be used freely::

    > (if #f 5 10)
    10

    > #(foo bar qux)
    #(foo bar qux)

  In addition, function and macro values can be included by macros::

    > (mac foo (x)
        `(,let a 5
           (,+ ,x a)))

    > (macex1 '(foo 10))
    (#<mac:let> a 5 (#<fn:+> 10 a))

    > (foo 10)
    15

  This includes boxes::

    > (mac box (x)
        (%.->box x))

    > (mac foo (x)
        `(,(box let) a 5
           (,(box +) ,x a)))

    > (macex1 '(foo 10))
    (#<mac:let> a 5 (#<fn:+> 10 a))

    > (foo 10)
    15

  This enables you to write hygienic macros in Arc
