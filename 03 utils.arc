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
