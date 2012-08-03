(mac redef (name parms . body)
  `(let orig ,name
     (= ,name (fn ,parms ,@body))))

(mac remac (name parms . body)
  `(let orig (rep ,name)
     (= ,name (annotate 'mac (fn ,parms ,@body)))))

(mac extend (name parms test . body)
  (w/uniq (args a b)
    `(withs (orig  ,name
             ,a    (fn ,parms ,test)
             ,b    (fn ,(cons 'it parms) ,@body))
       (= ,name (fn ,args
                  (aif (apply ,a ,args)
                       (apply ,b it ,args)
                       (apply orig ,args)))))))

#|(mac extend (name parms test . body)
  (w/uniq args
    `(redef ,name ,args
       (aif (apply ,(fn ,parms ,test) ,args)
            (apply ,(fn ,parms ,@body) ,args)
            (apply orig ,args)))))|#


(= ref-types* (obj))

(extend ref (x . args) (orig ref-types* type.x)
  (apply it x args))

(mac defcall (type parms . body)
  `(= (ref-types* ',type) (fn ,parms ,@body)))


(def eachfn (f xs)
  (each x xs f.x))


(def hash args
  (listtab pair.args))


(mac catcherr body
  (w/uniq c
    `(on-err (fn (,c) (details ,c))
             (fn ()   ,@body nil))))


(def assoc-ref (xs key)
  (if (atom xs)
        nil
      (and (acons (car xs)) (is (caar xs) key))
        xs
      (assoc-ref (cdr xs) key)))

(def partition (f xs)
  ;; awith
  ((afn (x l r)
         ;; TODO: should use cons? rather than no
     (if (no x)
           (list l r)
         (f car.x)
           (self cdr.x (cons car.x l) r)
         (self cdr.x l (cons car.x r))))
   xs nil nil))


(mac collect body
  `(accum yield ,@body))


(def debug args
  ;(apply prn (intersperse " " args))
  nil)


(mac %no (x)
  (cons %.nocompile x))


(def var (x)
  ((%.namespace) x))

(extend sref (x v k) (is x var)
  (sref (%.namespace) v k))


(mac %require args
  `(% (parameterize ((current-namespace nu-namespace))
        (namespace-require ,@(map (fn (x) `',x) args)))))

(mac require-rename args
  `((% namespace-require) ,@(map (fn ((x y))
                                   `'(rename racket/base ,y ,x))
                                 pair.args)))

(= list* %.list*)


(def zip (x)
  (apply map list x))


(mac rwith (name parms . body)
  (let p pair.parms
    `((rfn ,name ,(map car p)
        ,@body)
      ,@(map cadr p))))

(mac awith (parms . body)
  `(rwith self ,parms ,@body))

(mac alet (x y . body)
  `(awith (,x ,y) ,@body))

(mac awhenlet (x y . body)
  (w/uniq u
    `(alet ,u ,y
       (whenlet ,x ,u ,@body))))


(mac zap2 (f x y . rest)
  ;; TODO: w/setforms
  `(= ,y (,f ,x ,y ,@rest)))


(mac maplet (var expr . body)
  `(map (fn (,var) ,@body) ,expr))


(def splitlast (x)
  ;(split x (- (len x) 1))
  ;; TODO: ew
  (if cdr.x
      (awith (x    x
              acc  nil)
        (if cdr.x
            (self cdr.x (cons car.x acc))
            (list rev.acc car.x)))
      (list x)))


(def dispfile (val file)
  (w/outfile o file (disp val o)))


(mac w/pipe-from (var expr . body)
  `(let ,var (pipe-from ,expr)
     (after (do ,@body)
            (close ,var))))

;; from Akkartik (http://arclanguage.org/item?id=14622)
(mac w/pipe-to (dest . body)
  `(fromstring (tostring ,@body)
               (system ,dest)))

;; TODO: improve this, such as adding eof...?
(def readlines (x)
  (drain readline.x))


(mac awhile args
  `(whilet it ,@args))


#|(mac w/stderr (var . body)
  `(parameterize (%.current-error-port ,var) ,@body))|#

(mac w/stderr (x . body)
  `(call-w/stderr ,x (fn () ,@body)))

(mac quiet body
  (w/uniq gv
    ;; TODO: figure out a way to do this without outstring
    `(w/outstring ,gv
       (w/stdout ,gv
         (w/stderr ,gv
           ,@body)))))


(def exec args
  (tostring:system:apply string args))


(def num (x (o base 10))
  (coerce x 'num base))


(def uniq? (x)
  (when %.symbol?.x
    (if %.symbol-interned?.x nil t)))


#|
; TODO should probably be in strings.arc or utils.arc
(def rtokens (str test)
  (awith (s    (coerce str 'cons)
          acc  (list nil))
    (if (no s)
          (map string:rev acc)
        (caris s test)
          (self cdr.s (cons nil acc))
        (self cdr.s (cons (cons car.s car.acc) cdr.acc)))))

; (posmatch "foo" "fobarfo")
(def posmatch (pat in)
  (with (orig  (coerce pat 'cons)
         in    (coerce in 'cons))
    (awith (pat   orig
            in    in
            jump  in
            i     0)
      (if (no pat)
            i
          (no in)
            nil
          (or (and (is   car.pat car.in)
                   (self cdr.pat cdr.in jump i))
              (self orig cdr.jump cdr.jump (+ i 1)))))))|#


;; Pattern matching
#|
(casefn
  (0) 1
  (1) 1
  (x) (foo (- x 1)))

(casefn
  (0) 1
  (1) 1
  (x (list y z)) (foo (- x 1)))

(case-lambda
  ((g1)
    (if (is g1 0) 1
        (is g1 1) 1
        (err)))
  ((g1 g2)
    (if (acons g2)
        (with (x      g1
               (y z)  g2)
          (foo (- x 1)))
        (err))))

(defcase foo
  (0)              1
  (1)              1
  (x)              (foo (- 1 x))
  (x (list a b c)) (+ a b c))


(case-lambda
  ((g1)
    (if (is g1 0) 1
        (is g1 1) 1
        (with (x g1)
          (foo (- 1 x)))))
  ((g1 g2)
    (if (acons g2)
        (with (x       g1
               (a b c) g2)
          (+ a b c))
        (err))))


(defcase fact
  (0) 1
  (x) (* x (fact (- x 1))))

(case-lambda
  ((g1)
    (if (is g1 0) 1
        (with (x g1)
          (* x (fact (- 1 x)))))))


(define iso
  X X           -> true
  [X|XS] [Y|YS] -> (and (iso X Y) (iso XS YS))
  X Y           -> false)

(defcase iso
  (x x)               t
  ([x . xs] [y . ys]) (and (iso x y) (iso xs ys))
  (x y)               nil)
|#
#|
(require-rename case-lambda #%case-lambda)

;; TODO: dislike how you pass in a variable and it uses `it`
(mac casefn-parm-if (x test . body)
  (w/uniq (l r)
    `(maplet (,l ,r) ,x
       (list (maplet it ,l
               (if ,test
                   (do ,@body)
                   it))
             ,r))))

(def casefn-square-brackets->list (x)
  (casefn-parm-if x (caris it 'square-brackets)
                    `(list ,@cdr.it)))

(def casefn-list->cons (x)
  (casefn-parm-if x (caris it 'list)
                    (alet x cdr.it
                      (if no.x
                          x
                          `(cons ,car.x ,(self cdr.x))))))

(def casefn-wildcard->uniq (x)
  (casefn-parm-if x (is it '_)
                    (uniq)))

(def casefn-multiple->is (x)
  (let tab (obj)
    (casefn-parm-if x (do1 tab.it
                           (= tab.it t))
                      `(is ,(uniq) ,it))))

(def casefn-literal->is (x)
  (casefn-parm-if x (no:in type.it 'cons 'sym)
                    `(is ,(uniq) ,it)))


(def make-casefn-if-cons (x u w)
  (if (caris x 'cons)
        (list (list 'acons u)
                     ;; TODO: relies upon the Arc implementation of destructuring;
                     ;;       should check and see if it would be better to implement
                     ;;       destructuring in here instead;
                     ;;       or maybe I should expose the destructuring primitives
                     ;;       to Arc code instead? It should offer the capacity to
                     ;;       both extend destructuring and also configure it
                     ;;       (strict vs loose destructuring, for instance)
              (list* (alet x x
                       (if acons.x
                           (let (_ x y . rest) x
                             (if rest
                                 (list* self.x self.y self.rest)
                                 (cons self.x self.y)))
                           x))
                     u w))
      (caris x 'is)
        (let (_ v x) x
          (list `(is ,u ,x) (if uniq?.v
                                w
                                (list* v u w))))
      (err "unknown match" x)))

(def make-casefn-if1 (parms body uniqs)
  (awith (x  parms
          u  uniqs
          w  nil)
    (if (no x)
        (list (if w `(with ,w ,body)
                    body))
        (let c car.x
          (if acons.c
              (let (result w) (make-casefn-if-cons c car.u w)
                (cons result (self cdr.x cdr.u w)))
              (self cdr.x cdr.u (list* c car.u w)))))))

(def make-casefn-if (x u)
  (with (err?  t
         x     (casefn-literal->is
               (casefn-multiple->is
               (casefn-wildcard->uniq
               (casefn-list->cons
               (casefn-square-brackets->list x))))))
    `(if ,@(mappend (fn ((p b))
                      (let x (make-casefn-if1 p b u)
                        (when (is len.x 1)
                          (= err? nil))
                        x))
                    x)
        ,@(when err?
            (list `(err "could not match input against patterns"))))))

(def make-casefn (x)
  (let tab (obj)
    (awhenlet (p b . rest) x
      (push (list p b) (tab:and acons.p len.p))
      (self rest))
    (maplet (k v) tablist.tab
      (let u (n-of k (uniq))
        (list u (make-casefn-if rev.v u))))))

(mac casefn body
  `(%no:#%case-lambda ,@(maplet (k v) make-casefn.body
                          (%.append-to %.local-env k)
                          (list k %.ac.v))))

(mac defcase (name . body)
  `(safeset ,name (casefn ,@body)))

(mac match (x . body)
  `(apply (casefn ,@body) ,x))

(mac match1 (x . body)
  `((casefn ,@(mappend (fn ((x y)) (list (list x) y)) pair.body)) ,x))|#
