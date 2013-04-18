(var mac (make-macro
           (fn (name args . body)
             '(do (var name)
                  (= name (make-macro (fn args . body)))))))

(mac def (name args . body)
  '(do (var name)
       (= name (fn args . body))))

(mac square-brackets args
  '(list . args))

(mac curly-brackets args
  '(hash . args))

(def cadr (x)
  (car (cdr x)))

(mac with (names . body)
  (var names (pair names))
  '((fn ,(map car names) . body)
    ,@(map cadr names)))

(mac let (name val . body)
  '(with (name val) . body))
