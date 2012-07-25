#|(def io-err (s . rest)
  (%port-next-location s (fn (l c p)
    (err:string rest " (at " l ":" (+ c 1) ")"))))|#

(mac in-unicode-range? (x . body)
  (w/uniq u
    `(when ,x
       (let ,u (coerce ,x 'int)
         (or ,@(mappend (fn (x)
                          (if acons.x
                            (collect:let (l r) x
                              (for i (coerce string.l 'int 16)
                                     (coerce string.r 'int 16)
                                (yield `(is ,u ,i))))
                            (list `(is ,u ,(coerce string.x 'int 16)))))
                        body))))))

(def nuit-always-illegal? (c)
  (in-unicode-range? c
    (0 8)
    (B C)
    (E 1F)
    7F
    (80 84)
    (86 9F)
    ;; TODO this causes it to take a long time to start-up
    ;(D800 DFFF)
    (FFFE FFFF)))

(def nuit-illegal-at-start? (c)
  (in-unicode-range? c
    ;(9 A)
    9
    ;D
    20
    85
    A0
    1680
    180E
    (2000 200A)
    (2028 2029)
    202F
    205F
    3000))


#|(def nuit-parse-@1 (first second rest)
  (if empty.first
      (if empty.second
          rest
          (cons second rest))
      (if empty.second
          (cons first rest)
          (list* first second rest))))

(def nuit-parse-@ (s limit)
  (withs (first   (nuit-string-whitespace s)
          second  (do (while (is peekc.s #\space)
                        (readc s))
                      (nuit-string-newline s))
          new     nuit-parse-whitespace.s
          ;rest    (nuit-parse2 s (cons new limits))
                  ;(nuit-parse1 s nuit-parse-whitespace.s limit)
                  ;(nuit-parse2 s nuit-parse-whitespace.s)

                    ;(nuit-parse1 s limit)
                    #|(do (nuit-strip-newline s)
                      (nuit-parse1 s nuit-parse-whitespace.s))|#
                  #|(do (prn "@" new " " limit)
                      nil)|# ;(nuit-parse2 s limit)
                  ;(nuit-parse2 s new)
                  )
    (if (< new limit)
          (list (nuit-parse-@1 first second nil))
        (is new limit)
          (cons (nuit-parse-@1 first second nil)
                (nuit-parse2 s new new))
        (list:nuit-parse-@1 first second
          (nuit-parse2 s new new)))
    #|(if (< new limit)
          #|(do (prn new " " limit)
          (cons
                ))|#
          (list:nuit-parse-@1 first second nil)
          ;(nuit-parse2 s new)
        (is new limit)
          (cons (nuit-parse-@1 first second nil)
                (nuit-parse2 s new limit))
        (list:nuit-parse-@1 first second
          (nuit-parse2 s new limit)))|#
))

(def nuit-parse-# (s limit)
  (if (is peekc.s #\|)
      (awith ()
        (case peekc.s
          #\# (do (readc s)
                  (if (is peekc.s #\|)
                      (self)
                      ;(nuit-parse-# s limit)
                      (self)))
          #\| (do (readc s)
                  (if (is peek.c #\#)
                      (do (readc s)
                          nil)
                      (self)))
          nil nil
              (self)))
      (while (no:in peekc.s #\newline #\return nil)
        (readc s))))


(def nuit-string-whitespace (s)
  (collect:while (no:in peekc.s nil #\newline #\return #\space)
    (yield readc.s)))


(def nuit-parse2 (s new limit)
  (let c peekc.s
    #|#\newline  (do (readc s)
                   #|(let new nuit-parse-whitespace.s
                     (while (and indents (< new car.indents))
                       (zap cdr indents)))|#
                   (self 0))
    #\return   (do (readc s)
                   (when (is peekc.s #\newline)
                     (readc s))
                   #|(let new nuit-parse-whitespace.s
                     (while (and indents (< new car.indents))
                       (zap cdr indents)))|#
                   (self 0))|#
    ;#\space
               #|(withs (new  nuit-parse-whitespace.s
                       c    peekc.s)
                 ;(prn new " " limit)
                 #|(if (< new limit)
                       nil
                     ;(in c #\@ #\# #\" #\| #\> #\\)
                     (self new)
                     ;(io-err s "illegal character at start of line " c)
                     )|#
                 )|#

      ;(and (> old-limit 0))
    (if (nuit-illegal-at-start? c)
          (io-err s "illegal character at start of line " c)
        (< new limit)
          nil
        (case c
          #\@        (do (readc s)
                         (join (nuit-parse-@ s limit)
                               (nuit-parse1 s limit)))
          #\#        (do (readc s)
                         (nuit-parse-# s limit)
                         (nuit-parse1 s limit))
          #\"        (do (readc s)
                         (cons (nuit-parse-quote s limit)
                               (nuit-parse1 s limit)))
          #\|        (do (readc s)
                         (cons (nuit-parse-bar s limit)
                               (nuit-parse1 s limit)))
          #\>        (do (readc s)
                         (cons (nuit-parse-> s limit)
                               (nuit-parse1 s limit)))
          #\\        (do (readc s)
                         (if (in peekc.s #\@ #\# #\" #\| #\> #\\)
                             (cons (nuit-string-newline s)
                                   (nuit-parse1 s limit))
                             (io-err s "invalid escape sequence \\" peekc.s)))
          nil        nil
                     (cons (nuit-string-newline s)
                           (nuit-parse1 s limit))))))

(def nuit-parse1 (s limit)
  (nuit-parse2 s nuit-parse-whitespace.s limit)
  ;(prn limit " " peekc.s)
  #|(let new nuit-parse-whitespace.s
    ;(prn new " " limit " " peekc.s)
    #|(while (and limits (<= new car.limits))
      (prn new " " limits)
      (zap cdr limits))|#
    (if (< new limit)
        (do #|(while (and limits (< new car.limits))
              (zap cdr limits))|#
            ;(prn new " " limits)
            ;(zap cdr limits)
            nil)
        (nuit-parse2 s new))
    ;(zap cdr limits)
    #|(if (< new car.limits) ;(< new cadr.limits)
        (do ;(prn new " " limits)
            ;(zap cdr limits)
            nil)
        (do ;(zap cdr limits)
            (nuit-parse2 s (cons new limits)))
        )|#
    )|#
)|#


(= nuit-fail (uniq))

(def split-whitespace (str)
  (awith (x    str
          acc  nil)
    (if (no x)
          (list (and acc (string rev.acc)) nil)
        (is car.x #\space)
          (list (and acc (string rev.acc))
                (do (while (is car.x #\space)
                      (zap cdr x))
                    (and x (string x))))
        (self cdr.x (cons car.x acc)))))

#|(mac block-indent (rest new . body)
  (w/uniq u
    `(let ,u ,new
       (collect:while (and ,rest (>= (caar ,rest) ,u))
         ,@body
         (zap cdr ,rest)))))|#

(def nuit-first-value (reify)
  (alet x nil
    (or x (self:reify:fn (parse next x)
            (if cdr.x
                x
                (do (next) nil))))))

(def block-indent (err reify new (o end) (o f))
  (let oend nil
    (collect:while:reify:fn (parse next x)
      (when x ;(= x (next))
        ;(prn x " " new " " oend)
        (if #|(no cdr.x)
              (do (yield #\newline)
                  (yield #\newline)
                  ;(= oend #\newline)
                  (next)
                  ; TODO code duplication
                  (let x (next)
                    (when (>= car.x new)
                      (yield (newstring (- car.x new) #\space))
                      (if f (yield (f cdr.x))
                            (yield cdr.x))))
                  t)|#
            (>= car.x new)
              (do ;(prn car.x " " new)
                  (if oend (do (yield oend)
                               (= oend nil))
                           (yield end))
                  (yield (newstring (- car.x new) #\space))
                  (if f (yield (f err new cdr.x))
                        (yield cdr.x))
                  #|(when f
                    (f yield x))|#
                  ;(next x new)
                  (next)
                  t)
            (no cdr.x)
              ;(= oend #\newline)
              (do (= oend #\newline)
                  ;(yield #\newline)
                  (yield #\newline)
                  (next)
                  t)
              ;(= x (next))
              ))))
  #|(collect:while (fn (x)      (>= car.x new))
                 (fn (next x) (f yield x)
                              (next x)))|#
  )

(mac find-indent (s i)
  (w/uniq u
    `(let ,u (+ ,i 1)
       (while (is (car ,s) #\space)
         (++ ,u)
         (zap cdr ,s))
       ,u)))

#|(def block-string (self i s rest end)
  (let new (find-indent s i)
    (iflet body (block-indent rest new
                  (let x car.rest
                    (yield end)
                    (yield (newstring (- car.x new) #\space))
                    (yield cdr.x)))
      (cons (string s body)
            (self rest))
      (string s))))|#

(def hexadecimal? (c)
  (in c #\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9
        #\a #\b #\c #\d #\e #\f
        #\A #\B #\C #\D #\E #\F))

(def nuit-parse-unicode (err self rest i)
  (if (is car.rest #\()
      (do (++ i)
          (zap cdr rest)
          (join (awith ()
                  (let x (collect:while (hexadecimal? car.rest)
                           (yield car.rest)
                           (++ i)
                           (zap cdr rest))
                    (let x (when x
                             (coerce (coerce string.x 'int 16) 'char))
                      (if (is car.rest #\space)
                            (do (++ i)
                                (zap cdr rest)
                                (cons x (self)))
                          (is car.rest #\))
                            (do (++ i)
                                (zap cdr rest)
                                (list x))
                          (no rest)
                            (err (string "missing ending )") (+ i 1))
                          (err (string "illegal Unicode escape " car.rest) (+ i 1))))))
                (self rest i)))
          #|(if (hexadecimal? car.rest)
              nil
              (err (string "illegal Unicode escape " car.rest) (+ i 1)))|#
      (self rest i)
      (err (string "illegal Unicode escape " car.rest) (+ i 1))))

;"\\(([0-9a-fA-F]+ ?)+\\)"

(def transform-quote (err i s)
  (awith (s  s
          i  i)
    (whenlet (c . rest) s
      (if (is c #\\)
          (if (is car.rest #\\)
                (cons car.rest
                      (self cdr.rest (+ i 2)))
              (is car.rest #\u)
                (nuit-parse-unicode err self cdr.rest (+ i 1))
              (no rest)
                (list #\newline)
              (err (string "illegal escape " car.rest) (+ i 1)))
          (cons c (self rest (+ i 1)))))))

(def block-string (err reify i s end (o f))
  (let new (find-indent s i)
    (let s (if f (f err new s)
                 s)
      (string s
        (block-indent err reify new end f)))))

(= parsers (obj #\` (fn (err reify i s)
                      (block-string err reify i s #\newline))
                #|#\> (fn (err reify i s)
                      (block-string err reify i s #\space))|#
                #\" (fn (err reify i s)
                      (block-string err reify i s #\space transform-quote))
                #\# (fn (err reify i s)
                      (block-indent err reify (find-indent s i))
                      ;(reify (fn (parse next x) (prn x) (parse:next)))
                      nuit-fail)
                #\\ (fn (err reify i s)
                      (if (parsers car.s)
                          string.s
                          ;(nuit-parse-single-string i s rest stack)
                          (err (string "invalid escape sequence \\" car.s) 1)))
                #\@ (fn (err reify i s)
                      (let (first second) split-whitespace.s
                        ;(prn "@" first " " second)
                        (withs (new   (car:nuit-first-value reify)
                                body  (when (> new i)
                                        (collect:while:reify:fn (parse next x)
                                          (when x
                                            (if (no cdr.x)
                                                  (do (next) t)
                                                (is car.x new)
                                                  (let x (parse (next) new)
                                                    (if (is x nuit-fail)
                                                        t
                                                        (yield x)))))))
                                        #|(drain:reify:fn (parse next x)
                                          (when (and x (is car.x new))
                                            (parse (next) new)))|#
                                        #|(while (fn (x) (is car.x new))
                                          (fn (next x) (next x)))|#
                                      )
                          (if first
                              (if second
                                  (list* first second body)
                                  (cons first body))
                              (if second
                                  (cons second body)
                                  body))))
                        #|(withs (new   caar.rest
                                body  (collect:while (and rest (> caar.rest i))
                                        (yield:self rest new)
                                        (zap cdr rest))
                                xs    (if first
                                        (if second
                                            (list* first second body)
                                            (cons first body))
                                        (if second
                                            (cons second body)
                                            body)))
                          ;(prn "@" xs)
                          ;(cons xs (self rest stack))
                          (if (or body xs)
                              (cons xs self.rest)
                              xs)
                          )|#
                    )))


(def nuit-parse-whitespace (line s)
  (let indent 0
    (while (is peekc.s #\space)
      (++ indent)
      (readc s))
    (if (and (> indent 0)
             (in peekc.s #\newline #\return))
      (formatted-err "illegal whitespace" (newstring indent #\space) line indent))
    indent))

(def nuit-string-newline (line s)
  (let acc nil
    (while (no:in peekc.s nil #\newline #\return)
      (let c readc.s
        (if (nuit-always-illegal? c)
            (err (string "illegal character" c))
            (push c acc))))
    (if (is car.acc #\space)
        (formatted-err "illegal whitespace" rev.acc line len.acc)
        (rev acc))))

(def nuit-strip-newline (s)
  (case peekc.s
    #\newline (readc s)
    #\return  (do (readc s)
                  (when (is peekc.s #\newline)
                    (readc s)))))

(def nuit-chunk (s)
  (let line 0
    (collect:while peekc.s
      (++ line)
      (withs (new  (nuit-parse-whitespace line s)
              str  (nuit-string-newline line s))
        (nuit-strip-newline s)
        (yield:cons new str)))))

#|(def nuit-parse-single-string (i s rest stack)
  ;(list string.s)
  string.s
  #|(cons
        (self rest i))|#
  #|(prn caar.rest " " stack)
  (if (or no.rest (some [is caar.rest _] stack))

      (err "illegal indentation"))|#
  )|#

(def formatted-err (message str lines column)
  (err:string message "\n  " str
    "  (line " lines ", column " column ")\n "
    (newstring column #\space) "^"))

(def f-err (message lines i c s (o offset 0))
  (formatted-err message
    (string (newstring i #\space) (cons c s))
    lines
    (if (is i 0)
        (+ 1 offset)
        (+ i offset))))

(def nuit-parse1 (l)
  (with (lines  0
         next   nil
         parse  nil
         reify  nil
         stack  nil)
    (def next ()
      (++ lines)
      (let x car.l
        (zap cdr l)
        x))
    (def parse (x (o new))
      (when new
        (push new stack))
      (whenlet (i c . s) x
        ;(prn i " " c " " s)
        (aif (no c)
               (parse (next) new)
             (no:some [is i _] stack); (isnt i stack)
               #|(if (is i 0)
                   nil
                   )|#
               (f-err "illegal indentation" lines i c s)
             (nuit-illegal-at-start? c)
               (f-err (string "illegal character at start of line " c)
                      lines i c s)
             (parsers c)
               (it (fn (message (o offset 0))
                     (f-err message lines i c s offset))
                   reify i s)
             (string:cons c s))))
    (def reify (body)
      (body parse next car.l))
    (collect:while l
      (= stack (list 0))
      (let x (parse:next)
        (unless (is x nuit-fail)
          (yield x))))))

(def nuit-parse (s)
  (let s (if (isa s 'string)
             (instring s)
             s)
    ;(nuit-strip-newline s)
    ;(nuit-parse1 s 0)
    (nuit-parse1 nuit-chunk.s)))



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


(assert (err "invalid escape sequence \\$
  \\$foobar  (line 1, column 2)
   ^")
  (nuit-parse "\\$foobar"))

(assert (err "illegal indentation
   foobar  (line 1, column 1)
  ^")
  (nuit-parse " foobar"))

(assert (err "illegal character at start of line \t
  \tfoobar  (line 1, column 1)
  ^")
  (nuit-parse "\tfoobar"))

(assert (err "illegal whitespace
           (line 1, column 7)
        ^")
  (nuit-parse "       \nfoobar"))

(assert (err "illegal whitespace
  foobar    (line 2, column 8)
         ^")
  (nuit-parse "\nfoobar  \nquxcorge"))

(assert (err "illegal indentation
   @foobar  (line 1, column 1)
  ^")
  (nuit-parse " @foobar"))

(assert (err "illegal indentation
   yes  (line 4, column 1)
  ^")
  (nuit-parse "
@foobar
  @quxnou
 yes
"))

(assert (err "illegal indentation
   questionable  (line 4, column 1)
  ^")
  (nuit-parse "
` foo bar qux
    yes maybe no
 questionable"))

(assert (err "illegal indentation
   quxcorge  (line 3, column 1)
  ^")
  (nuit-parse "
# foobar
 quxcorge
 nou yes
 maybe sometimes
yestoo
"))

(assert (err "illegal escape b
  \" foo\\bar  (line 2, column 7)
        ^")
  (nuit-parse "
\" foo\\bar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "illegal Unicode escape A
  \" foo\\uAB01ar  (line 2, column 8)
         ^")
  (nuit-parse "
\" foo\\uAB01ar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "missing ending )
  \" foo\\u(AB01 FA1  (line 2, column 17)
                  ^")
  (nuit-parse "
\" foo\\u(AB01 FA1
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "illegal Unicode escape U
  \" foo\\u(AB01 U)ar  (line 2, column 14)
               ^")
  (nuit-parse "
\" foo\\u(AB01 U)ar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "illegal whitespace
  \" foobar\\    (line 2, column 11)
            ^")
  (nuit-parse "\n\" foobar\\  \n  quxcorge\\\n  nou yes\\\n  maybe sometimes\n"))


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
  maybe sometimes
"))

(assert '("foo\\bar qux €corge nou yes maybe sometimes")
  (nuit-parse "
\" foo\\\\bar
  qux\\u(20 20AC)corge
  nou yes
  maybe sometimes
"))
