(const mac (make-macro
             (fn (name args . body)
               '(const-rec name (make-macro (fn args . body))))))

(mac def (name args . body)
  '(const-rec name (fn args . body)))

(def cadr (x) (car (cdr x)))

(mac map (var x . body)
  '(map-fn (fn (var) . body) x))

(mac each (var x . body)
  '(each-fn (fn (var) . body) x))

(mac with-raw (names . body)
  '((fn ,(map-fn car names) . body)
    ,@(map-fn cadr names)))

(mac with (names . body)
  '(with-raw ,(pair names) . body))

(mac let (name val . body)
  '(with (name val) . body))

(mac push (x xs)
  '(= xs (cons x xs)))

(def listify (x)
  (if (cons? x)
      x
      (list x)))

(mac w/uniq (x . body)
  '(with-raw ,(map x (listify x) (list x '(uniq))) . body))

(mac w/sym (x . body)
  '(with-raw ,(map x (listify x) (list x '(sym ,(str x)))) . body))

(mac %ac (x)
  (list (% ac) ((% bypass) (list (sym "quote") x))))

(mac when (x . body)
  '(if x (do . body)))

(mac iflet (var x yes (o no))
  (w/uniq u
    '(let u x
       (if u (let var u yes) no))))

(mac rwith (name names . body)
  (let names (pair names)
    '(let name nil
       (= name (fn ,(map-fn car names) . body))
       (name ,@(map-fn cadr names)))))

(mac alet (var val . body)
  (w/sym self
    '(rwith self (var val) . body)))

(mac awhenlet (x y . body)
  (w/uniq u
    '(alet u y
       (when u
         (let x u . body)))))

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

#|(mac square-brackets (args)
  (if (dotted? args)
      '(list* ,@(dotted->list args))
      '(list . args)))

(mac curly-brackets (args)
  '(hash . args))|#

(prn ((% ac) '(case 1
       1 2
       2 3
         4)))
