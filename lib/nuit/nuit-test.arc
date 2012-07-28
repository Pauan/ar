(import nuit-parse)

;; TODO: generic utility
(mac assert (x y)
  (w/uniq (u v)
    `(let ,u (on-err (fn (,u)
                       (string "error: " (details ,u)))
                     (fn () ,x))
       (let ,v (on-err (fn (,u)
                         (string "error: " (details ,u)))
                       (fn () ,y))
         (unless (iso ,u ,v)
           (prn)
           (pr "failed assertion\n  expected:  ")
           (write ,u)
           (pr "\n  but got:   ")
           (write ,v)
           (prn))))))


(assert (err "invalid escape $
  \\$foobar  (line 1, column 2)
   ^")
  (nuit-parse "\\$foobar"))

(assert (err "invalid indentation
   foobar  (line 1, column 1)
  ^")
  (nuit-parse " foobar"))

(assert (err "invalid character \t
  \tfoobar  (line 1, column 1)
  ^")
  (nuit-parse "\tfoobar"))

(assert (err "invalid indentation
   @foobar  (line 1, column 1)
  ^")
  (nuit-parse " @foobar"))

(assert (err "invalid indentation
   yes  (line 4, column 1)
  ^")
  (nuit-parse "
@foobar
  @quxnou
 yes
"))

(assert (err "invalid indentation
   questionable  (line 4, column 1)
  ^")
  (nuit-parse "
` foo bar qux
    yes maybe no
 questionable"))

(assert (err "invalid indentation
   quxcorge  (line 3, column 1)
  ^")
  (nuit-parse "
# foobar
 quxcorge
 nou yes
 maybe sometimes
yestoo
"))

(assert (err "invalid escape b
  \" foo\\bar  (line 2, column 7)
        ^")
  (nuit-parse "
\" foo\\bar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "missing (
  \" foo\\uAB01ar  (line 2, column 8)
         ^")
  (nuit-parse "
\" foo\\uAB01ar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "missing space or )
  \" foo\\u(AB01 FA1  (line 2, column 17)
                  ^")
  (nuit-parse "
\" foo\\u(AB01 FA1
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "invalid hexadecimal U
  \" foo\\u(AB01 FA1U  (line 2, column 17)
                  ^")
  (nuit-parse "
\" foo\\u(AB01 FA1U
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "invalid hexadecimal U
  \" foo\\u(AB01 U)ar  (line 2, column 14)
               ^")
  (nuit-parse "
\" foo\\u(AB01 U)ar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "invalid character \u0000
  foo\u0000bar  (line 1, column 4)
     ^")
  (nuit-parse "foo\u0000bar"))

(assert (err "invalid character \u0000
  \u0000foobar  (line 1, column 1)
  ^")
  (nuit-parse "\u0000foobar"))

(assert (err "invalid character \uFEFF
  f\uFEFFoobar  (line 1, column 2)
   ^")
  (nuit-parse "f\uFEFFoobar"))



(assert '("foobar")
  (nuit-parse "\uFEFFfoobar"))

(assert '(("foo" ("bar" "10")
            ("qux" "nou"))
          ("yes"))
  (nuit-parse "
@foo @bar 10
  @qux nou
@yes"))

(assert '(("foo" ("bar" "10")
            ("qux" "nou"))
          ("yes"))
  (nuit-parse "
@foo @bar 10
     @qux nou
@yes"))

(assert '(("foo" ("bar" "10"
                   ("qux" "nou")))
          ("yes"))
  (nuit-parse "
@foo @bar 10
      @qux nou
@yes"))

(assert '(("foo")
          ("yes"))
  (nuit-parse "
@foo #@bar 10
      @qux nou
@yes"))

(assert '(("foo" "")
          ("yes"))
  (nuit-parse "
@foo `
@yes"))

(assert '(("foo")
          ("yes"))
  (nuit-parse "
@foo
@yes"))

(assert '(("foo" "bar" "qux" "corge"))
  (nuit-parse "@foo bar\n  qux\n   \n  corge"))

(assert '(("foo" "bar" "qux" "corge"))
  (nuit-parse "@foo bar\n  qux\n  \n  corge"))

(assert '(("foo" "bar" "qux" "corge"))
  (nuit-parse "@foo bar\n  qux\n \n  corge"))

(assert '(("foo" "bar" "qux" "corge"))
  (nuit-parse "@foo bar\n  qux\n\n  corge"))

(assert '("foobar")
  (nuit-parse "       \nfoobar"))

(assert '("foobar" "quxcorge")
  (nuit-parse "\nfoobar  \nquxcorge"))

(assert '("foobar")
  (nuit-parse "foobar"))

(assert '("\"foobar")
  (nuit-parse "\\\"foobar"))

(assert '(("foo" "bar" ("testing") "qux \"\"\" yes" "corge 123" "nou@ yes")
          ("another" "one" "inb4 this#" "next thread"
            ("nested\\" "lists are cool"
              ("yes" "indeed")
              ("no" "maybe"))
            ("oh yes" "oh my")
            ("oh yes" "oh my")))
  (nuit-parse "
@foo bar
  @testing
  qux \"\"\" yes

  corge 123
  nou@ yes

@another one
  inb4 this#

  next thread
  @nested\\
    lists are cool

    @yes indeed
    @no maybe
  @ oh yes

   oh my
  @ oh yes
   oh my
"))

(assert '(() ("foobar" "qux"))
  (nuit-parse "
@
@
 foobar
 qux"))

(assert '("foo bar qux\nyes maybe no\nquestionable")
  (nuit-parse "
` foo bar qux
  yes maybe no
  questionable"))

(assert '(("foobar" "foo bar qux\n  yes maybe no\n  questionable"))
  (nuit-parse "
@foobar
  ` foo bar qux
      yes maybe no
      questionable"))

(assert '("foo bar qux\n  yes maybe no\n  questionable")
  (nuit-parse "
` foo bar qux
    yes maybe no
    questionable"))

(assert '("yestoo")
  (nuit-parse "
# foobar
  quxcorge
  nou yes
  maybe sometimes
yestoo
"))

(assert '("yestoo")
  (nuit-parse "
#foobar
 quxcorge
 nou yes
 maybe sometimes
yestoo
"))

(assert '()
  (nuit-parse "
# foobar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert '(("another" "one" "inb4 this#" "next thread"
            ("oh yes")
            ("oh yes" "oh my")))
  (nuit-parse "
#@foo bar
  @testing
  qux \"\"\" yes
  corge 123
  nou@ yes
@another one
  inb4 this#
  next thread
  #@nested\\
    lists are cool
    @yes indeed
    @no maybe
  @ oh yes
   #oh my
  @ oh yes
   oh my
"))

(assert '("foobar\n\nquxcorge\n\nnou yes\n\nmaybe sometimes")
  (nuit-parse "
` foobar

  quxcorge

  nou yes

  maybe sometimes
"))

(assert '("foobar\n\nquxcorge\n\nnou yes\n\nmaybe sometimes")
  (nuit-parse "
\" foobar

  quxcorge

  nou yes

  maybe sometimes
"))

(assert '("foobar\n\n\nquxcorge\n\nnou yes\n\n\nmaybe sometimes")
  (nuit-parse "
\" foobar


  quxcorge

  nou yes


  maybe sometimes
"))

(assert '("foobar\n\n\n\nquxcorge\n\nnou yes\n\n\n\nmaybe sometimes")
  (nuit-parse "
\" foobar



  quxcorge

  nou yes



  maybe sometimes
"))

(assert '("foobar quxcorge nou yes maybe sometimes")
  (nuit-parse "
\" foobar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert '("foobar\nquxcorge\nnou yes\nmaybe sometimes")
  (nuit-parse "
\" foobar\\
  quxcorge\\
  nou yes\\
  maybe sometimes\\
"))

(assert '("foobar\nquxcorge\nnou yes\nmaybe sometimes" "mooooooooooo")
  (nuit-parse "
\" foobar\\
  quxcorge\\
  nou yes\\
  maybe sometimes
mooooooooooo
"))

(assert '("foobar\nquxcorge\nnou yes\nmaybe sometimes" "mooooooooooo")
  (nuit-parse "
\" foobar\\
  quxcorge\\
  nou yes\\
  maybe sometimes\\
mooooooooooo
"))

(assert '("foo\\bar qux €corge nou yes maybe sometimes")
  (nuit-parse "
\" foo\\\\bar
  qux\\u(20 20AC)corge
  nou yes
  maybe sometimes
"))

(assert '("foobar\nquxcorge\nnou yes\nmaybe sometimes")
  (nuit-parse "\n\" foobar\\  \n  quxcorge\\\n  nou yes\\\n  maybe sometimes\n"))
