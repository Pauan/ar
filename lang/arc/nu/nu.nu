(const mac (make-macro
             (fn (name args . body)
               '(const-rec name (make-macro (fn args . body))))))

(mac def (name args . body)
  '(const-rec name (fn args . body)))

(def cadr (x) (car (cdr x)))
(def cddr (x) (cdr (cdr x)))

(mac map (var x . body)
  '(map-fn (fn (var) . body) x))

(mac each (var x . body)
  '(each-fn (fn (var) . body) x))

(mac mappair (var x . body)
  '(flatten (map var (pair x) . body)))

(mac with-raw (names . body)
  '((fn ,(map-fn car names) . body)
    ,@(map-fn cadr names)))

(mac with (names . body)
  '(with-raw ,(pair names) . body))

(mac let (name val . body)
  '(with (name val) . body))

(mac withs (names . body)
  (if names
      '(let ,(car names) ,(cadr names)
         (withs ,(cddr names) . body))
      '(do . body)))

(mac push (x xs)
  '(= xs (cons x xs)))

(def listify (x)
  (if (cons? x)
      x
      (list x)))

(mac quasiquote (x)
  ((% bypass) (list (sym "quasiquote") x)))

(mac w/uniq (x . body)
  '(with-raw ,(map x (listify x) (list x '(uniq))) . body))

(mac w/sym (x . body)
  '(with-raw ,(map x (listify x) (list x '(sym ,(str x)))) . body))

(mac %ac (x)
  (list (% ac) ((% bypass) (list (sym "quote") x))))

(mac when (x . body)
  '(if x (do . body)))

(mac awhen (x . body)
  (w/sym it
    '(let it x (when it . body))))

(def not (x) (if x nil t))

(mac unless (x . body)
  '(when (not x) . body))

(mac iflet (var x yes (o no))
  (w/uniq u
    '(let u x
       (if u (let var u yes) no))))

(mac collect body
  (w/sym yield
    (w/uniq (u v)
      '(let u nil
         (let yield (fn (v) (push v u))
           ,@body
           (rev u))))))

(mac rwith (name names . body)
  (let names (pair names)
    '(let name nil
       (= name (fn ,(map-fn car names) . body))
       (name ,@(map-fn cadr names)))))

(mac awith (names . body)
  (w/sym self
    '(rwith self names . body)))

(mac alet (var val . body)
  '(awith (var val) . body))

(mac aloop (x y . body)
  (w/uniq u
    '(alet u y
       (if (cons? u)
           (let x u . body)
           u))))

(mac while (test . body)
  (w/uniq u
    '(rwith u ()
       (when test ,@body (u)))))

(mac case (x . body)
  (w/uniq u
    '(let u x
       ,(alet x body
          (if (cons? (cdr x))
              (let (x val . rest) x
                '(if (is u x)
                     val
                     ,(self rest)))
              (car x))))))

(mac w/ (x y . body)
  (w/uniq u
    '(let u nil
       (dynamic-wind (fn () (= u x)
                            (= x y))
                     (fn () . body)
                     (fn () (= x u))))))

; TODO multi-arg version
(def isnt (x y)
  (not (is x y)))

(mac and args
  (if args
      (if (cdr args)
          '(if ,(car args) (and ,@(cdr args)))
          (car args))
      t))

(mac or args
  ; TODO is this and necessary?
  (and args
       (w/uniq g
         '(let g ,(car args)
            (if g g (or ,@(cdr args)))))))

(def split (xs n)
  ; TODO some sort of aloop variant
  (awith (xs xs
          n  n
          r  nil)
    (if (and (cons? xs)
             (> n 0))
        (self (cdr xs) (- n 1) (cons (car xs) r))
        (list (rev r) xs))))

(def tuple (xs n)
  (when xs
    (let (left right) (split xs n)
      (cons left (tuple right n)))))

(mac defs args
  (let args (tuple args 3)
    '(const-rec ,@(flatten (map (name args body) args
                             (list name '(fn args body)))))))
#|
'(do ,@(map (n) args '(var n))
         ,@(map (n args body) args '(= n (fn args body)))
         ,@(map (n) args '(const n n)))
|#

; TODO better name than until
(mac until (var x . body)
  (w/uniq (r y self)
    '(rwith self (r  nil
                  y  x)
       (if (let var y . body)
           (list (rev r) y)
           (self (cons (car y) r) (cdr y))))))

(def orf fns
  (fn args
    (aloop (x . rest) fns
      (or (apply x args) (self rest)))))

(mac w/complex (x . body)
  (w/uniq (u v)
    '(if (cons? x)
         (w/uniq u
           (with (v  x
                  x  u)
             '(let u v ,,@body)))
         (do . body))))

(mac in (x y . choices)
  (if choices
      (w/complex x
        '(or (is x y) ,@(map y choices '(is x y))))
      '(is x y)))

(def any-fn (f x)
  (when (cons? x)
    (if (f (car x))
        t
        (any-fn f (cdr x)))))

(mac any (var x . body)
  '(any-fn (fn (var) . body) x))

(def ->input (x)
  (if (str? x)
      ((% open-input-string) x)
      x))

(def dotted? (x)
  (when x
    (if (cons? x)
        (dotted? (cdr x))
        t)))

(def dotted->list (x)
  (when x
    (if (cons? x)
        (cons (car x) (dotted->list (cdr x)))
        (list x))))

(mac square-brackets (args)
  (if (dotted? args)
      '(list* ,@(dotted->list args))
      '(list . args)))

(mac curly-brackets (args)
  '(dict ,@(mappair (x y) args (list (str x) y))))

(parameter-var stdin (% current-input-port))

#|(prn ((% ac) '(case 1
       1 2
       2 3
         4)))|#
