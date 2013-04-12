Differences between Arc/Nu and Arc 3.1
======================================

Bug Fixes
---------

* ``coerce`` and ``annotate`` use Arc's ``is`` rather than Racket's ``eqv?``

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

* The following Arc macros are defined::

    % assign curly-brackets fn get-setter if import quasiquote quote reimport square-brackets var w/exclude w/include w/prefix w/rename

* The following Arc functions are defined::

    call-w/stderr sym->box sym->filename

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

    > (mac foo (x)
        `(,(sym->box 'let) a 5
           (,(sym->box '+) ,x a)))

    > (macex1 '(foo 10))
    (#<box:let> a 5 (#<box:+> 10 a))

    > (foo 10)
    15

  This enables you to write hygienic macros in Arc

* A new ``'inline-calls`` declare mode, which is even faster than
  ``'direct-calls``::

    > (declare 'inline-calls t)

    > (%.ac '(+ 1 2))
    (#<fn:+> 1 2)

  Basically, it takes the value of the symbol at compile-time and splices it
  into the expression. This is much faster than direct-calls because it
  doesn't need to do a global lookup at runtime.

  The downside is that if you redefine any global variable, even functions,
  those changes aren't retroactive: they'll affect new code but not old
  code
