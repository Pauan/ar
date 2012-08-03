#lang racket
;; Nu Arc Compiler -- Manifest Destiny
;; http://www.youtube.com/watch?v=qXp3qjeM0e4

;; TODO: look for uses of null? and replace them with empty-stream? as needed
;; TODO: replace uses of #%datum with #%quote

(provide (all-defined-out)
         (all-from-out racket) ; racket/base
         ;(all-from-out racket/path)
         )

;(require (only-in racket syntax-case syntax))

(require ffi/unsafe)
(require racket/unsafe/ops)
;(require racket/path)
;(require racket/port)
;(require racket/system)
;(require racket/tcp)

;=============================================================================
;  Convenient extras; can remove
;=============================================================================
(require racket/pretty)

(define (acompile1 ip op)
  (let/ x (read ip)
    (if (eof-object? x)
        #t
        (let/ scm (ac x)
          (eval scm)
          (pretty-print scm op)
          (newline op)
          (newline op)
          (acompile1 ip op)))))

; compile xx.arc to xx.arc.scm
; useful to examine the Arc compiler output
(define (acompile inname)
  (let/ outname (string-append inname ".scm")
    (when (file-exists? outname)
      (warn "deleting file " outname)
      (delete-file outname))
    (call-with-input-file inname
      (lambda (ip)
        (call-with-output-file outname
          (lambda (op)
            (acompile1 ip op)))))))

(define (prn . args)
  (for-each (lambda (x)
              (display x)
              (display " "))
            args)
  (newline)
  (car args))


;=============================================================================
;  General purpose utilities
;=============================================================================
(define-syntax (with/ stx)
  ;; TODO: map2 is general purpose
  (define (map2 f x)
    (cond ((null? x)
            x)
          ((null? (cdr x))
            (list (f (car x) null)))
          (else
            (cons (f (car x) (cadr x))
                  (map2 f (cddr x))))))

  (define (arc-let->racket-let stx x)
    (datum->syntax stx
      (map2 (lambda (x y)
              (if (pair? x)
                  (list x y)
                  (list (list x) y)))
            (syntax->datum x))))

  (syntax-case stx ()
    [(_ x . body) #`(let-values (#,@(arc-let->racket-let stx #'x)) . body)]))

;(syntax->datum (expand '(with/ () 1 2 3)))
;(syntax->datum (expand '(with/ (x 1 y 2) x y)))
;(syntax->datum (expand '(with/ ((x y) 1 z 2) x y z)))
;(syntax->datum (expand '(let/ x 1 x)))
;(syntax->datum (expand '(let/ (x y) 1 x y)))
;(syntax->datum (expand '(withs (x 1 y 2) x y)))
;(syntax->datum (expand '(withs ((x y) 1 y 2) x y)))
;(syntax->datum (expand '(awith (x 1 y 2) (self x y))))
;(syntax->datum (expand '(awith () (self 1 2))))
;(syntax->datum (expand '(awith (x '(1 2 3 4 5)) (if (null? x) x (cons (car x) (self (cdr x)))))))
;(syntax->datum (expand '(alet x '(1 2 3 4 5) (if (null? x) x (cons (car x) (self (cdr x)))))))

(define-syntax (let/ stx)
  (syntax-case stx ()
    [(_ (x ...) y . body) #'(let-values (((x ...) y)) . body)]
    [(_ x y . body)       #'(let/ (x) y . body)]))

#|(define-syntax (let/ stx)
  (syntax-case stx ()
    [(_ x y . body) #'(with/ (x y) . body)]))|#

#|(define-syntax-rule (let/ x y . body)
  (with/ (x y) . body))|#

(define-syntax (withs stx)
  (syntax-case stx ()
    [(_ ((x ...) y z ...) . body) #'(let-values (((x ...) y)) (withs (z ...) . body))]
    [(_ (x y z ...) . body)       #'(let-values (((x) y)) (withs (z ...) . body))]
    [(_ (x) . body)               #'(withs (x null) . body)]
    [(_ x . body)                 #'(begin . body)]))

(define-syntax (awith stx)
  ;; TODO: pair is general purpose
  (define (pair x)
    (cond ((null? x)
            x)
          ((null? (cdr x))
            (list (list (car x))))
          (else
            (cons (list (car x) (cadr x))
                  (pair (cddr x))))))

  (syntax-case stx ()
    [(_ parms . body) #`(let #,(datum->syntax stx 'self)
                          (#,@(datum->syntax stx (pair (syntax->datum #'parms))))
                          . body)]))

(define-syntax (alet stx)
  (syntax-case stx ()
    [(_ x y . body) #`(let #,(datum->syntax stx 'self) ((x y)) . body)]))

#|(let-syntax (($if (make-rename-transformer #'if)))
  (displayln ($if 1 2 3))
  (define-syntax if
    (lambda (stx)
      (displayln (syntax-local-get-shadower #'if))
      (displayln ((syntax-local-value #'if) stx))
      (syntax-case stx ()
        [(_)             #'(void)]
        [(_ x)           #'x]
        [(_ x y)         #'($if x y (void))]
        [(_ x y z)       #'($if x y z)]
        [(_ a b c d ...) #'($if a b (if c d ...))])))
  (void))|#

(define-syntax (if stx)
  (syntax-case stx ()
    [(_)             #'(void)]
    [(_ x)           #'x]
    [(_ x y)         #'(cond (x y))]
    [(_ x y z)       #'(cond (x y) (else z))]
    [(_ a b c d ...) #'(if a b (if c d ...))]))

;(syntax->datum (expand '(if)))
;(syntax->datum (expand '(if 1)))
;(syntax->datum (expand '(if 1 2)))
;(syntax->datum (expand '(if 1 2 3)))
;(syntax->datum (expand '(if 1 2 3 4)))
;(syntax->datum (expand '(if 1 2 3 4 5)))
;(syntax->datum (expand '(if 1 2 3 4 5 6)))

(define-syntax-rule (consif p a b)
  (if p (cons a b) b))


(define (caris x y)
  (and (pair? x)
       (eq? (car x) y)))

(define (zip . args)
  (apply map list args))

(define (proper-list? x)
  (if (pair? x)  (proper-list? (cdr x))
      (null? x)  #t
                 #f))

;; There's two ways to turn an improper list into a proper one:
;;   (1 2 3 . 4) -> (1 2 3)
;;   (1 2 3 . 4) -> (1 2 3 4)
;; This uses the first way, because it's intended for function argument lists
(define (dotted->proper x)
  (if (pair? x)
      (cons (car x) (dotted->proper (cdr x)))
      null))

(define (dottedmap f xs #:end (end f))
  (alet xs xs
    (if (pair? xs)
        (cons (f (car xs))
              (self (cdr xs)))
        (end xs))))

#|(define (imap f xs)
  (if (pair? xs)
      (cons (f (car xs))
            (imap f (cdr xs)))
      xs))|#

(define (dottedrec f xs)
  (alet xs xs
    (if (pair? xs)
        (cons (f (self (car xs)))
              (self (cdr xs)))
        (f xs))))

;; TODO: better name
(define (arg-list* args)
  (if (null? (cdr args))
      (car args)
      (cons (car args)
            (arg-list* (cdr args)))))

(define (keyword->symbol x)
  (string->symbol (keyword->string x)))

#|(define (keyword-get kw kwa x opt)
  (awith (kw   kw
          kwa  kwa)
    (if (null? kw)
          opt
        (eq? (car kw) x)
          (car kwa)
        (self (cdr kw) (cdr kwa)))))|#

(define (keyword-get kw kwa x opt)
  (awith (kw    kw
          kwa   kwa
          acc1  null
          acc2  null
          res   opt)
    (if (null? kw)
          (values (reverse acc1)
                  (reverse acc2)
                  res)
        (eq? (car kw) x)
          (self (cdr kw)
                (cdr kwa)
                acc1
                acc2
                (car kwa))
        (self (cdr kw)
              (cdr kwa)
              (cons (car kw) acc1)
              (cons (car kwa) acc2)
              res))))

(define (process-keywords kw kwa args)
  (withs (kws   (if (null? kw)
                    kw
                    (zip kw kwa))
          args  (alet x args
                  (if (null? x)
                        x
                      (keyword? (car x))
                        (begin (set! kws (cons (list (car x) (cadr x)) kws))
                               (self (cddr x)))
                      (cons (car x) (self (cdr x))))))
    (if (null? kws)
        (values kws kws args)
        ;; WOW Racket seriously expects the keyword list to be *sorted*?
        (let/ kws (apply zip (sort kws keyword<? #:key car))
          (values (car kws) (cadr kws) args)))))

  #|(awith (x     args
          kws   (if (null? kw)
                    kw
                    (zip kw kwa))
          args  null)
    (if (null? x)
          (if (null? kws)
              (values kws kws (reverse args))
              ;; WOW Racket seriously expects the keyword list to be *sorted*?
              (let/ kws (apply zip (sort kws keyword<? #:key car))
                (values (car kws) (cadr kws) (reverse args))))
        (keyword? (car x))
          (self (cddr x)
                (cons (list (car x) (cadr x)) kws)
                args)
        (self (cdr x) kws (cons (car x) args))))|#

(define (keyword-args? args)
  (alet x args
    (if (null? x)           #f
        (keyword? (car x))  #t
                            (self (cdr x)))))

(define (kw-join kw kwa args)
  ;; TODO: keywords are at the end of the list rather than the front;
  ;;       not a huge deal, but still...
  (append* args (zip kw kwa)))

;; based on Arc's reduce. Can't use foldl because it doesn't work well with
;; multiple types (e.g. +-2)
(define (reduce f xs)
  (if (null? (cdr xs))
      (car xs) ;(f (car xs))
      (reduce f (cons (f (car xs) (cadr xs)) (cddr xs)))))

(define (warn . args)
  (display "warning: " (current-error-port))
  (for ((x args))
    (display x (current-error-port)))
  (newline (current-error-port)))

(define (fraction? x)
  (and (number? x)
       (exact? x)
       (not (integer? x))))


;=============================================================================
;  Arc variables
;=============================================================================
(define arc3-namespace  (make-base-empty-namespace))
(define names           (make-hash))

;; TODO: see if redef and reset are needed
#|(define-syntax-rule (redef name parms . body)
  (reset name (lambda parms . body)))

(define-syntax-rule (reset name val)
  ((var-raw 'name) val))|#


;; creates a function that is exposed to Arc
;; use #:sig to define a custom Arc sig
(define-syntax sdef
  (syntax-rules ()
    ((_ name parms #:sig parms2 . body)
      (sset name parms2 (lambda parms . body)))
    ((_ name parms . body)
      (sset name parms (lambda parms . body)))))

;; like sdef but makes the function mutable from within Arc
;; use #:name to define a different Arc name than the Racket name
(define-syntax mdef
  (syntax-rules ()
    ((_ name parms #:name name2 . body)
      (mset name parms #:name name2 (lambda parms . body)))
    ((_ name parms #:sig parms2 . body)
      (mset name parms2 (lambda parms . body)))
    ((_ name parms . body)
      (mset name parms (lambda parms . body)))))


;; wraps the Racket value in a global variable function before making it
;; accessible to Arc while also optionally setting the sig of the name
(define-syntax sset
  (syntax-rules ()
    ((_ a b)        (let/ v b
                      (nameit 'a v)
                      (set 'a (make-global-var v))))
    ((_ a parms b)  (begin (hash-set! sig 'a 'parms)
                           (sset a b)))))

;; like sset but makes the Racket value mutable from within Arc
;; use #:name to define a different Arc name than the Racket name
(define-syntax mset
  (syntax-rules ()
    ((_ a #:name name b)        (begin (define a b)
                                       (nameit 'name a)
                                       (set 'name (case-lambda
                                                    (()  a)
                                                    ((x) (set! a x))))))
    ((_ a b)                    (mset a #:name a b))
    ((_ a parms #:name name b)  (begin (hash-set! sig 'name 'parms)
                                       (mset a #:name name b)))
    ((_ a parms b)              (begin (hash-set! sig 'a 'parms)
                                       (mset a b)))))


;; creates a parameter in the compiler's namespace, then makes it implicit in
;; Arc's namespace
(define-syntax-rule (pset a b)
  (begin (define a (make-parameter b))
         (set 'a a)))


;; this makes the variable accessible to Arc but doesn't wrap it or do
;; anything else
(define (set a b)
  ;(sref (namespace) b a)
  (namespace-set-variable-value! a b #f arc3-namespace)) ;(coerce (namespace) 'namespace)

(define (nameit name val)
  (when (or (procedure? val)
            (tagged? val))
    (hash-set! names val name)))

(define (make-global-var x)
  (case-lambda
    (()  x)
    ((v) (set! x v))))


;=============================================================================
;  Types
;=============================================================================
(struct tagged (type rep)
  #:constructor-name make-tagged
  ;; TODO: make mutable later, maybe
  ;#:mutable
  #|#:property prop:custom-write
             (lambda (x port mode)
               (display "#(tagged " port)
               (display (type x) port)
               (display " " port)
               (display (rep x) port)
               (display ")" port))|#
  )

(define (iround x)   (inexact->exact (round x)))
(define (wrapnil f)  (lambda args (apply f args) nil))
(define (wraptnil f) (lambda (x)  (tnil (f x))))


;=============================================================================
;  Arc stuff used by the compiler
;=============================================================================
(mset nil  null)
(mset sig  (make-hash))
(mset t    't)

;; TODO: a better argument name than typ
;; TODO: annotate doesn't need to be mutable, but does need to be exposed to
;;       both the compiler and Arc
(mdef annotate (typ rep)
      ;; TODO: does this need to eqv? rather than eq?
  (if (eqv? (type rep) typ)
      rep
      (make-tagged typ rep)))

;; car and cdr probably will be used later, but not right now
(mdef ac-car (x) #:name car
  (if (null? x)
        x
      #|(stream-empty? x)
        x|#
      (pair? x)
        (car x)
      #|(stream? x)
        (stream-first x)|#
      (raise-type-error 'car "cons" x)))

(mdef ac-cdr (x) #:name cdr
  (if (null? x)
        x
      #|(stream-empty? x)
        x|#
      (pair? x)
        (cdr x)
      #|(stream? x)
        (stream-rest x)|#
      (raise-type-error 'cdr "cons" x)))

(mdef close args
  (map close1 args)
  (map (lambda (p) (try-custodian p)) args) ;; free any custodian
  nil)

(mdef close1 (p)
  (if (input-port? p)    (close-input-port p)
      (output-port? p)   (close-output-port p)
      (tcp-listener? p)  (tcp-close p)
                         (err "can't close " p)))

;; TODO: list + table of types for coerce
(mdef coerce (x to (base 10))
       #:sig (x to (o base 10))
  (if (tagged? x)         (err "can't coerce annotated object")
       ;; TODO: does this need to be eqv? rather than eq?
      (eqv? to (type x))  x
      (symbol? x)         (case to
                            ((string)  (symbol->string x))
                            (else      (err "can't coerce" x to)))
      (pair? x)           (case to
                            ((string)  (apply string-append
                                              (map (lambda (y) (coerce y 'string))
                                                   x)))
                            (else      (err "can't coerce" x to)))
      ;(eq? x nil)
      (null? x)           (case to
                            ((string)  "")
                            (else      (err "can't coerce" x to)))
      (char? x)           (case to
                            ((int)     (char->integer x))
                            ((string)  (string x))
                            ((sym)     (string->symbol (string x)))
                            (else      (err "can't coerce" x to)))
      (exact-integer? x)  (case to
                            ((num)     x)
                            ((char)    (integer->char x))
                            ((string)  (number->string x base))
                            (else      (err "can't coerce" x to)))
      (number? x)         (case to
                            ((int)     (iround x))
                            ((char)    (integer->char (iround x)))
                            ((string)  (number->string x base))
                            (else      (err "can't coerce" x to)))
      (string? x)         (case to
                            ((sym)     (string->symbol x))
                            ((cons)    (string->list x))
                            ((num)     (or (string->number x base)
                                           (err "can't coerce" x to)))
                            ((int)     (let/ n (string->number x base)
                                         (if n  (iround n)
                                                (err "can't coerce" x to))))
                            (else      (err "can't coerce" x to)))
                          (err "can't coerce" x to)))

(mdef err (x . rest)
  (apply error x rest))

(mdef ac-eval (expr) #:name eval
  (eval (ac expr) (coerce (namespace) 'namespace)
                  #|(if (namespace? (namespace))
                      (namespace)
                      arc3-namespace)|#
                  ))

;; macroexpand the outer call of a form as much as possible
(mdef macex (e)
  (let/ v (macex1 e)
    (if (eq? v e)
        v
        (macex v))))

;; macroexpand the outer call of a form once
(mdef macex1 (e)
  (if (pair? e)
      (let/ m (macro? (car e))
                   ;; TODO: not sure about this
        (if (and m (not (or (eq? m assign)
                            (eq? m fn)
                            (eq? m ac-if)
                            (eq? m ac-quote)
                            (eq? m ac-quasiquote))))
            (mac-call m (cdr e))
            e))
      e))

;; TODO: not sure what category this should be placed in
;; TODO: should pipe call ((caddddr x) 'wait)?
(mdef pipe (cmd)
         ;; TODO: destructuring
  (withs (x   (process/ports #f #f (current-error-port) cmd)
          in  (car x)
          out (cadr x))
    (list in out)))

(mdef protect (during after)
  (dynamic-wind (lambda () #t) during after))

(mdef rep (x)
  (if (tagged? x)
      (tagged-rep x)
      x))

(mdef scar (p x)
  (if (pair? p)    (unsafe-set-mcar! p x)
      (string? x)  (string-set! p 0 x)
                   (raise-type-error 'scar "cons" p))
  x)

;; Later may want to have multiple indices.
(mdef sref (x val key)
  (if (namespace? x)  (namespace-set-variable-value! key val #f x) ;(global-name key)
                           ;(eq? val nil)
      (hash? x)       (if (false? val)
                          (hash-remove! x key)
                          (hash-set! x key val))
      (string? x)     (string-set! x key val)
      (pair? x)       (scar (list-tail x key) val)
                      (err "can't set reference " x key val))
  val)

(mdef type (x)
        ;; TODO: better ordering for speed
  (if (tagged? x)         (tagged-type x)
      (namespace? x)      'namespace
      (pair? x)           'cons
      ;(stream? x)         'stream ;; TODO: not sure about this
      (symbol? x)         'sym
      ; (type nil) -> sym
      (null? x)           'sym
      (procedure? x)      'fn
      (char? x)           'char
      (string? x)         'string
      (exact-integer? x)  'int
      (number? x)         'num     ; unsure about this
      (hash? x)           'table
      (output-port? x)    'output
      (input-port? x)     'input
      (tcp-listener? x)   'socket
      (exn? x)            'exception
      (thread? x)         'thread
                          ;(err "type: unknown type" x)
                          ;; TODO: not sure about this, but seems okay
                          nil))

;; Racket functions
(sset -        args                    -)
(sset cons     (x y)                   cons) ;; TODO: look for some uses of cons and replace em with ac-cons
(sset instring (str (o name 'string))  open-input-string)
(sset seconds  ()                      current-seconds)

;; Racket parameters
(sset stdout ((o out))  current-output-port)  ; should be a vars
(sset stdin  ((o in))   current-input-port)
(sset stderr ((o err))  current-error-port)


;=============================================================================
;  Initialization and loading
;=============================================================================
(define exec-dir (current-directory))

(define (init (dir (current-directory)))
  (set! exec-dir dir)
  ;; TODO: why does Arc 3.1 do this?
  (putenv "TZ" ":GMT")
  ;; TODO: why is this in Arc 3.1?
  ;(print-hash-table #t)
  (current-readtable arc3-readtable)
  ;(%load-all dir)
  )

#|(mdef %load-all (dir)
  (aload (build-path dir "02 arc.arc")))

(define (repl)
  (aload (build-path exec-dir "03 repl.arc")))|#

(define (aload filename)
  ;; This is so that it's possible to retrieve the column/line of an input port
  (parameterize ((port-count-lines-enabled #t))
    (call-with-input-file filename aload1)))

(define (aload1 p)
  (let/ x (read p)
    (if (eof-object? x)
        #t ;; TODO: should probably be (void)
        (begin (ac-eval x)
               (aload1 p)))))


;=============================================================================
;  The compiler
;=============================================================================
(define local-env  (make-parameter null)) ;; list of lexically bound variables
(define nocompile  (gensym)) ;; if in the car the expression won't be compiled
(define fail       (gensym))

;; compile an Arc expression into a Racket expression; both are s-expressions
(define (ac x)
  (if (symbol? x)
        (if (ssyntax x)
            (ac (ssexpand x))
            (ac-symbol x))
      (pair? x)
        (if (caris x nocompile)
            (cdr x)
            (ac-call (car x) (cdr x)))
      (null? x)
        ;; this causes it to return null
        (list '#%datum)
        ;null
      (string? x)
        (ac-string x)
      x))

(define (ac-all x)
  (dottedmap ac x #:end idfn))

(define (idfn x) x)


;=============================================================================
;  Namespaces
;=============================================================================
(define (empty-namespace)
  (parameterize ((current-namespace (make-base-empty-namespace)))
    (namespace-init)
    (current-namespace)))

(define (namespace-init)
  (namespace-require '(rename   '#%kernel  #%begin        begin))
  (namespace-require '(rename   '#%kernel  #%if           if))
  (namespace-require '(rename racket/base  #%lambda       lambda))
  (namespace-require '(rename racket/base  #%let*-values  let*-values))
  (namespace-require '(rename   '#%kernel  #%quote        quote))
  (namespace-require '(rename   '#%kernel  #%set          set!))
  ;(namespace-require '(rename   '#%kernel  #%var  case-lambda))
  (namespace-require '(only   racket/base  #%top #%app #%datum))
  ;(namespace-require '(only   racket/base  displayln))
  )

(parameterize ((current-namespace arc3-namespace))
  (namespace-init)
  )

(define namespace (make-parameter arc3-namespace))
;(pset namespace arc3-namespace)


;=============================================================================
;  Variables
;=============================================================================
(define cached-global-ref  (gensym))
(define replace-var        (make-parameter null))
(define unique             (gensym))

(define (var-raw a (def nil))
  (ref (namespace) a def))

(define (var a (def nil))
  (let/ v (var-raw a fail)
    (if (eq? v fail)
        def
        (v))))

(mdef %symbol-global (x)
  ;`(,(global-ref x))
  `(,x))

(define (ac-symbol x)
  (let/ r (assq x (replace-var))
    (if r (cadr r)
          (if (lex? x)
              x
              (%symbol-global x)))))

#|
                                ;; TODO
(define (global-ref name (space (namespace)))
  (let/ hash (ref space cached-global-ref
               (lambda ()
                 (sref space (make-hash) cached-global-ref)))
    (hash-ref! hash name
      (lambda ()
        (parameterize ((current-namespace (coerce space 'namespace))
                       ;(compile-allow-set!-undefined #t)
                       )
          (eval `(#%var (() (,name))))
          #|(eval `(#%var (()           (,name))
                        ((,unique) (#%set ,name ,unique))))|#
          )))))|#

(define (lex? v) ;; is v lexically bound?
  (memq v (local-env)))


;=============================================================================
;  Normal strings and atstrings
;=============================================================================
(define atstrings #f)

(define (ac-string s)
  (if atstrings
      (if (atpos s 0)
          (ac (cons 'string (map (lambda (x)
                                   (if (string? x)
                                       (unescape-ats x)
                                       x))
                                 (codestring s))))
          (unescape-ats s))
      ;; This is for normal strings
      (string-copy s))) ; avoid immutable strings

;; All of this is for atstrings, not needed for normal strings at all
(define (codestring s)
  (let/ i (atpos s 0)
    (if i  (cons (substring s 0 i)
                 (withs (rest (substring s (+ i 1))
                         in   (open-input-string rest)
                         expr (read in)
                              ;; TODO: function for this...?
                         i2   (let/ (x y z) (port-next-location in) z))
                   (close-input-port in)
                   (cons expr (codestring (substring rest (- i2 1))))))
           (list s))))

; First unescaped @ in s, if any.  Escape by doubling.
(define (atpos s i)
         ;; TODO: shouldn't this use = ?
  (if (eqv? i (string-length s))
        #f
      (eqv? (string-ref s i) #\@)
        (if (and (< (+ i 1) (string-length s))
                 (not (eqv? (string-ref s (+ i 1)) #\@)))
            i
            (atpos s (+ i 2)))
      (atpos s (+ i 1))))

(define (unescape-ats s)
  (list->string (alet cs (string->list s)
                  (if (null? cs)
                        cs
                      (and (eqv? (car cs) #\@)
                           (not (null? (cdr cs)))
                           (eqv? (cadr cs) #\@))
                        (self (cdr cs))
                      (cons (car cs) (self (cdr cs)))))))


;=============================================================================
;  Predicates
;=============================================================================
;; convert Racket booleans to Arc booleans
(define (tnil x) (if x t nil))

;; definition of falseness for Arc's if
(define (false? x)
  (or (eq? x nil)
      (eq? x #f)))

(define (true? x)
  (not (false? x)))

(define (isa x y)
  (eq? (type x) y))


;=============================================================================
;  call / ref
;=============================================================================
(define direct-calls #f)
(define inline-calls #f)

(define (ac-call f args)
  (withs (f  (if (ssyntax f)
                 (ssexpand f)
                 f)
          c  (and (pair? f)
                  (macro? (car f)))
          m  (macro? f))
    ;(when (and c (not (caris f 'fn))) (prn c f))
          ; the next three clauses could be removed without changing semantics
          ; ... except that they work for macros (so prob should do this for
          ; every elt of s, not just the car)
                         ;; TODO: this is only very slightly better than
                         ;;       hardcoding the symbol: figure out a better
                         ;;       way
    (if (and c (eq? c (var 'compose)))
          (ac (de-compose (cdr f) args))
        (and c (eq? c (var 'complement)))
          (ac (list 'no (cons (cadr f) args)))
        (and c (eq? c (var 'andf)))
          (ac (de-andf f args))
        m
          (ac (mac-call m args))
        ;; inserts the actual value for things in functional position, so
        ;; (+ 1 2) compiles into (#<fn:+> 1 2)
        ;;
        ;; this is much faster than direct-calls but it's even more strict:
        ;; if you redefine any global, even functions, those changes aren't
        ;; retroactive: they affect new code, but not old code
        (and inline-calls
             (symbol? f)
             (not (lex? f))
             ;; TODO: bound
             (not (eq? (var f fail) fail)))
          (let/ f (var f)
            (if (procedure? f)
                `(     ,f ,@(ac-all args))
                `(,ref ,f ,@(ac-all args))))
        ;; (foo bar) where foo is a global variable bound to a procedure.
        ;; this breaks if you redefine foo to be a non-fn (like a hash table)
        ;; but as long as you don't redefine anything, it's faster
        (and direct-calls
             (symbol? f)
             (not (lex? f))
             (procedure? (var f)))
          `(,(ac f) ,@(ac-all args))
        (let/ f (ac f)
              ;; optimization for (#<fn> ...) and ((fn ...) ...)
          (if (or (procedure? f)
                  (caris f '#%lambda)
                  ;; needed because #%call doesn't accept keyword args
                  (keyword-args? args))
              `(       ,f ,@(ac-all args))
              `(#%call ,f ,@(ac-all args)))))))

;; the next two are optimizations, except work for macros.
(define (de-compose fns args)
        ;; TODO: is this needed anywhere in Arc or can I remove it...?
  (if ;(null? fns)       `((fn vals (car vals)) ,@args)
      (null? (cdr fns)) (cons (car fns) args)
                        (list (car fns) (de-compose (cdr fns) args))))

(define (de-andf f args)
  (let/ gs (map (lambda (x) (gensym)) args)
    `((fn ,gs
        (and ,@(map (lambda (f) `(,f ,@gs))
                    (cdr f))))
      ,@args)))

;; returns #f or the macro
(define (macro? f)
  (if (and (symbol? f)
           (not (lex? f)))
        (macro? (var f))
      (isa f 'mac)
        f
      #f))

(define (mac-call m args)
  (let/ (kw kwa args) (process-keywords nil nil args)
    (parameterize ((local-env (local-env)))
      ;; TODO: use (keyword-apply #%call ...) ?
      (keyword-apply (rep m) kw kwa args))))

#|(define #%keyword-call
  (make-keyword-procedure
    (lambda (kw kwa x . args)
      (if (procedure? x)
          (keyword-apply x kw kwa args)
          (error "calling non-fn with keyword arguments" x kw kwa args)))))

(set '#%keyword-call #%keyword-call)|#

;; call a function or perform an array ref, hash ref, etc.
(define #%call ;(x . args)
  ;; uses case-lambda for ridiculous speed: now using call for *all* function
  ;; calls is just as fast as using the funcall functions, and unlike
  ;; funcall, this hardcodes up to 6 arguments rather than only 4
  ;;
  ;; I could go higher but it'd be kinda pointless and would just make the
  ;; definition of call even bigger than it already is
  (case-lambda
    ((x)              (if (procedure? x)
                          (x)
                          (ref x)))
    ((x a)            (if (procedure? x)
                          (x a)
                          (ref x a)))
    ((x a b)          (if (procedure? x)
                          (x a b)
                          (ref x a b)))
    ((x a b c)        (if (procedure? x)
                          (x a b c)
                          (ref x a b c)))
    ((x a b c d)      (if (procedure? x)
                          (x a b c d)
                          (ref x a b c d)))
    ((x a b c d e)    (if (procedure? x)
                          (x a b c d e)
                          (ref x a b c d e)))
    ((x a b c d e f)  (if (procedure? x)
                          (x a b c d e f)
                          (ref x a b c d e f)))
    ((x . args)       ;(prn "warning: called with 7+ arguments:" x args)
                      (if (procedure? x)
                          (apply x args)
                          (apply ref x args)))))

(set '#%call #%call)

;; Non-fn constants in functional position are valuable real estate, so
;; should figure out the best way to exploit it.  What could (1 foo) or
;; ('a foo) mean?  Maybe it should mean currying.
;;
;; For now the way to make the default val of a hash table be other than
;; nil is to supply the val when doing the lookup.  Later may also let
;; defaults be supplied as an arg to table.  To implement this, need: an
;; eq table within scheme mapping tables to defaults, and to adapt the
;; code in arc.arc that reads and writes tables to read and write their
;; default vals with them.  To make compatible with existing written tables,
;; just use an atom or 3-elt list to keep the default.
;;
;; experiment: means e.g. [1] is a constant fn
;;       ((or (number? fn) (symbol? fn)) fn)
;; another possibility: constant in functional pos means it gets
;; passed to the first arg, i.e. ('kids item) means (item 'kids).
(mset ref (x k (o d))
  (case-lambda
    ((x k)    (if (namespace? x)  (namespace-variable-value k #f (lambda () nil) x) ;(global-name k)
                  (hash? x)       (hash-ref x k nil)
                  (string? x)     (string-ref x k)
                  (pair? x)       (list-ref x k)
                                  (err "function call on inappropriate object" x k)))
    ((x k d)  (if (namespace? x)  (namespace-variable-value k #f ;(global-name k)
                                    (if (procedure? d) d (lambda () d))
                                    x)
                  (hash? x)       (hash-ref x k d)
                                  (err "function call on inappropriate object" x k d)))
    (args     (apply err "function call on inappropriate object" args))))


;=============================================================================
;  Binaries
;=============================================================================
;; (pairwise pred '(a b c d)) =>
;;   (and (pred a b) (pred b c) (pred c d))
;; pred returns t/nil, as does pairwise
(define (pairwise pred lst)
  (if (null? (cdr lst))
        t
      ;; TODO: maybe the binary functions should return #t and #f rather
      ;;       than t and nil
      (true? (pred (car lst) (cadr lst)))
        (pairwise pred (cdr lst))
      nil))

;; TODO: should pairwise take an init parameter or not...?
(define (make-pairwise f)
  (case-lambda
    ((x y) (f x y))
    (args  (pairwise f args))
    ((x)   t)
    (()    t)))

(define (make-reduce f init)
  (case-lambda
    ((x y) (f x y))
    (args  (reduce f args))
    ((x)   x)
    (()    init)))

;; generic comparison
(define (make-comparer a b c)
  (lambda (x y)
                ;; TODO: better ordering for speed
    (tnil (if (number? x)  (a x y)
              (string? x)  (b x y)
              (char? x)    (c x y)
              (symbol? x)  (b (symbol->string x)
                              (symbol->string y))
                           (a x y)))))

;; generic +: strings, lists, numbers.
;; return val has same type as first argument.
(define (+-2 x y)
      ;; TODO: better ordering for speed
  (if (number? x)  (+ x y)
      (string? x)  (string-append x (coerce y 'string))
      (list? x)    (append x y)
      ;; TODO: check the behavior of Arc 3.1 for (+ "foo" #\a) and (+ #\a "foo")
      (char? x)    (string-append (string x) (coerce y 'string))
                   (+ x y)
                   ;(err "can't + " x " with " y)
                   ))

(define <-2 (make-comparer < string<? char<?))
(define >-2 (make-comparer > string>? char>?))

;; not quite right, because behavior of underlying eqv unspecified
;; in many cases according to r5rs
;; do we really want is to ret t for distinct strings?
(define (is-2 a b)
  (tnil (or (eqv? a b)
            (and (string? a) (string? b) (string=? a b))
            ;; TODO: why is this here in Arc 3.1?
            ;(and (false? a) (false? b))
            )))


;=============================================================================
;  I/O
;=============================================================================
(define explicit-flush #f)

(define (print f x port)
      ;; TODO: should probably use (no x) or whatever
  (if (null? x)       (display "nil" port)
      ;; TODO: maybe use isa for pair? and procedure?
      (pair? x)       (print-w/list f x port)
      (keyword? x)    (begin (display ":" port)
                             (display (keyword->string x) port))
      (procedure? x)  (print-w/name x "#<fn" ":" ">" port)
      (isa x 'mac)    (print-w/name x "#<mac" ":" ">" port)
      (tagged? x)     (begin (display "#(tagged " port)
                             (print f (type x) port)
                             (display " " port)
                             (print f (rep x)  port)
                             (display ")" port))
      (fraction? x)   (f (exact->inexact x) port)
                      (f x port))
  nil)

(define (name x)
  (or (hash-ref names x #f)
      (and (not (tagged? x))
           (object-name x))
      nil))

(define (print-w/list f x port)
  (display "(" port)
  (alet x x
    (if (pair? x)
        (begin (print f (car x) port)
               (unless (null? (cdr x))
               (display " " port)
               (self (cdr x))))
        (begin (display ". " port)
               (print f x port))))
  (display ")" port))

(define (print-w/name x l m r port)
  (let/ x (name x)
    (display l port)
    (when (true? x)
      (display m port)
      (display x port))
    (display r port)))

(define (make-read f)
  (lambda ((in (current-input-port)) (eof nil))
    (let/ x (f in)
      (if (eof-object? x) eof x))))

(define (make-write f)
  (lambda (c (out (current-output-port)))
    (f c out)
    c))

(define (make-print f)
  (lambda (x (out (current-output-port)))
    (print f x out)
    (unless explicit-flush (flush-output out))
    nil))

; make sure only one thread at a time executes anything
; inside an atomic-invoke. atomic-invoke is allowed to
; nest within a thread; the thread-cell keeps track of
; whether this thread already holds the lock.
(define the-sema (make-semaphore 1))

(define sema-cell (make-thread-cell #f))

; there are two ways to close a TCP output port.
; (close o) waits for output to drain, then closes UNIX descriptor.
; (force-close o) discards buffered output, then closes UNIX desc.
; web servers need the latter to get rid of connections to
; clients that are not reading data.
; mzscheme close-output-port doesn't work (just raises an error)
; if there is buffered output for a non-responsive socket.
; must use custodian-shutdown-all instead.
(define custodians (make-hash))

(define (associate-custodian c i o)
  (hash-set! custodians i c)
  (hash-set! custodians o c))

; if a port has a custodian, use it to close the port forcefully.
; also get rid of the reference to the custodian.
; sadly doing this to the input port also kills the output port.
(define (try-custodian p)
  (let/ c (hash-ref custodians p #f)
    (if c  (begin (custodian-shutdown-all c)
                  (hash-remove! custodians p)
                  #t)
           #f)))


;=============================================================================
;  square-brackets / curly-brackets
;=============================================================================
(define (read-square-brackets ch port src line col pos)
  `(square-brackets ,@(read/recursive port #\[ #f)))

(define (read-curly-brackets ch port src line col pos)
  `(curly-brackets ,@(read/recursive port #\{ #f)))

#|
;; http://docs.racket-lang.org/guide/symbols.html
(define keyword-delimiters (list #\( #\) #\[ #\] #\{ #\}
                                 #\" #\, #\' #\` #\; #\| #\\))

(define (char-in-keyword? c)
  (not (or (char-whitespace? c)
           (memv c keyword-delimiters))))

(define (read-keyword ch port src line col pos)
  (prn
  (string->keyword
    (list->string
      (awith ()
        (let/ c (peek-char port)
          (if (eqv? c #\\)
                (begin (read-char port)
                       (cons (read-char port) (self)))
              (char-in-keyword? c)
                (cons (read-char port) (self))
              null)))))))|#

(define (read-keyword ch port src line col pos)
  (read/recursive (input-port-append #t (open-input-string "#:") port) #f #f))

(define arc3-readtable
  (make-readtable #f #\[ 'terminating-macro read-square-brackets
                     #\{ 'terminating-macro read-curly-brackets
                     #\: 'non-terminating-macro read-keyword))

(sset square-brackets body
  (annotate 'mac (lambda body `(fn (_) ,body))))


;=============================================================================
;  assign
;=============================================================================
(define (ac-assign x)
  (let/ x (pairfn assign1 x)
    (if (null? (cdr x))
        (car x)
        (cons '#%begin x))))

(define (pairfn f x)
  (if (null? x)
      x
               ;; TODO: why does Arc 3.1 call macex here?
      (cons (f (car x) (cadr x))
                ;; this is so the assign form returns the value
            (if (and (null? (cddr x))
                     (lex? (car x)))
                (list (ac (car x)))
                (pairfn f (cddr x))))))

(define (assign1 a b1)
  (if (symbol? a)
      (if (lex? a)  `(#%set ,a ,(ac b1))
                    ;`(,(ac '%assign-global) ,(namespace) (#%datum . ,a) ,(ac b1))
                    `(#%set-global ,(namespace) (#%datum . ,a) ,(ac b1))
                    )
      (err "first arg to assign must be a symbol" a)))

(define (assign-global-new space name val)
  (sref space (make-global-var val) name))

(define (assign-global-raw space name val)
  (let/ v (ref space name fail)
    (if (eq? v fail)
        (assign-global-new space name val)
        (v val)))
  val)

(define (assign-global space name val)
  (nameit name val)
  (assign-global-raw space name val))

(set '#%set-global assign-global)

(mset assign args
  (annotate 'mac (lambda args
                   (cons nocompile (ac-assign args)))))


;=============================================================================
;  if
;=============================================================================
; (if)           -> nil
; (if x)         -> x
; (if t a ...)   -> a
; (if nil a b)   -> b
; (if nil a b c) -> (if b c)
(define (ac-ifn args)
      ;; TODO: maybe simplify this a little, like by using ac-cdr
  (if (null? args)
        (ac 'nil)
      (null? (cdr args))
        (ac (car args))
             ;; TODO: fix this if I expose true? to Arc
      `(#%if (,true? ,(ac (car args)))
             ,(ac (cadr args))
             ,(ac-ifn (cddr args)))))

(mset ac-if args #:name if
  (annotate 'mac (lambda args
                   (cons nocompile (ac-ifn args)))))


;=============================================================================
;  fn
;=============================================================================
(define fn-gensym-args  (make-parameter #f))
(define fn-keyword      (make-parameter #f))
(define fn-parms        (make-parameter null))
(define fn-body         (make-parameter null))
(define fn-let*         (make-parameter null))

(define (cons-to x y)
  (x (cons y (x))))

(define (append-to x y)
  (x (append y (x))))

(define (nilify x)
  (if (null? x)
      (list 'nil)
      x))

(define (ac-fn parms body)
  (parameterize ((fn-keyword #f))
    (let/ x (cons '#%lambda
                  (parameterize ((fn-body    (nilify body))
                                 (local-env  (local-env))
                                 (fn-let*    null)
                                 (fn-parms   parms))
                    (withs (x  (fn-args parms)
                            k  (fn-keyword)
                            x  (if k (append k x) x))
                      (cons x (if (null? (fn-let*))
                                  (ac-all (fn-body))
                                  (list (list* '#%let*-values
                                               (fn-let*)
                                               (ac-all (fn-body)))))))))
      (if (fn-keyword)
          ;; TODO: how big is the performance hit of using make-keyword-procedure?
          (list make-keyword-procedure x)
          x))))

(define (fn-gensym x)
  (if (fn-gensym-args)
      (let/ u (gensym)
                                     ;; TODO: test this, should it be (list 'quote u) ?
        (cons-to replace-var (list x (cons '#%datum u)))
        u)
      x))

(define (fn-args x)
  (fn-args1 x (not (proper-list? x))))

#|
> ((fn (:foo :bar . x) (list foo bar x)) :foo 1 :qux 10)
(1 nil (:qux 10))

> ((fn (:foo :bar . x) (list foo bar x)) :foo 1 :qux 10 :bar 20)
(1 20 (:qux 10))


> ((fn (:foo (o :bar 5) . x) (list foo bar x)) :foo 1 :qux 10)
(1 5 (:qux 10))

> ((fn (:foo (o :bar 5) . x) (list foo bar x)) :foo 1 :qux 10 :bar 20)
(1 20 (:qux 10))


> (apply (fn x x) :qux 20 '(:bar 10))
(:bar 10 :qux 20)
|#

(define fn-args1
  (with/ (kw   (gensym)
          kwa  (gensym))
    (define (fn-keyword-arg x rest? k s . d)
      (cons-to fn-let*
        (list (list kw kwa s)
              (list* keyword-get kw kwa
                     (list '#%quote k)
                     d)))
      (fn-args1 (cdr x) rest?))
    (lambda (x rest?)
      (if (null? x)                     ;; end of the argument list
            x
          (symbol? x)                   ;; dotted rest args
            (let/ x (fn-gensym x)
              (fn-keyword (list kw kwa))
              (fn-let* (append (fn-let*)
                               (list (list (list x)
                                           (list kw-join kw kwa x)))))
              ;(cons-to fn-let* )
              (cons-to local-env x)
              x)
          (let/ c (car x)
            (if (and (fn-gensym-args)
                     (caris c 'quote))        ;; anaphoric arg
                  (begin (cons-to local-env (cadar x))
                         (prn (cadar x))
                         (cons (cadar x) (fn-args1 (cdr x) rest?)))
                (keyword? c)                  ;; keyword arg
                  (let/ s (keyword->symbol c)
                    (cons-to local-env s)
                    (if rest?
                        (fn-keyword-arg x rest? c s (ac 'nil))
                        (list* c (list s (ac 'nil))
                                 (fn-args1 (cdr x) rest?))))
                (caris c 'o)                  ;; optional arg
                  (withs (a  (cadr c)
                          d  (cddr c)
                          n  (if (keyword? a)
                                 (keyword->symbol a)
                                 (fn-gensym a)))
                    (cons-to local-env n)
                    (if (and (keyword? a) rest?)
                        (apply fn-keyword-arg x rest? a n (ac-all (nilify d)))
                        (consif (keyword? a)
                          a
                          (cons (cons n (ac-all (nilify d)))
                                (fn-args1 (cdr x) rest?)))))
                (pair? c)                     ;; destructuring args
                  (let/ u (gensym)
                    (append-to fn-let* (fn-destructuring u c))
                    (cons u (fn-args1 (cdr x) rest?)))
                (let/ n (fn-gensym c)         ;; normal args
                  (cons-to local-env n)
                  (cons n (fn-args1 (cdr x) rest?)))))))))


;; u is a local variable which refers to the current place within the object
;; that is being destructuring
;;
;; x is the destructuring argument list
;; TODO: use Arc's car and cdr so destructuring works on lists that are too
;;       small
(define (fn-destructuring u x)
  (if (null? x)                     ;; end of the argument list
        x
      (symbol? x)                   ;; dotted rest args
        (let/ x (fn-gensym x)
          (cons-to local-env x)
          (list (list (list x) u)))
      (caris (car x) 'o)            ;; optional args
        ;; TODO: code duplication with fn-args
        (withs (c  (car x)
                n  (fn-gensym (cadr c))
                d  (if (pair? (cddr c))
                       (caddr c)
                       'nil))
          (cons-to local-env n)
                                  ;; TODO: code duplication
          (cons (list (list n) (ac `(if ,(cons nocompile u)
                                         (car ,(cons nocompile u))
                                        ,d)))
                (fn-destructuring-next u x)))
      (pair? (car x))               ;; destructuring args
        (let/ v (gensym)
          (cons (list (list v) (ac `(car ,(cons nocompile u))))
                (append (fn-destructuring v (car x))
                        (fn-destructuring-next u x))))
      (let/ n (fn-gensym (car x))   ;; normal args
        (cons-to local-env n)
        (cons (list (list n) (ac `(car ,(cons nocompile u))))
              (fn-destructuring-next u x)))))

(define (fn-destructuring-next u x)
  (if (null? (cdr x))
      null
      (cons (list (list u) (ac `(cdr ,(cons nocompile u))))
            (fn-destructuring u (cdr x)))))

(mset fn (parms . body)
  (annotate 'mac (lambda (parms . body)
                   (cons nocompile (ac-fn parms body)))))


;=============================================================================
;  quasiquote
;=============================================================================
; qq-expand takes an Arc list containing a quasiquotation expression
; (the x in `x), and returns an Arc list containing Arc code.  The Arc
; code, when evaled by Arc, will construct an Arc list, the
; expansion of the quasiquotation expression.
;
; This implementation is a modification of Alan Bawden's quasiquotation
; expansion algorithm from "Quasiquotation in Lisp"
; http://repository.readscheme.org/ftp/papers/pepm99/bawden.pdf
;
; You can redefine qq-expand in Arc if you want to implement a
; different expansion algorithm.
(define (qq-expand x)
        ;; TODO: don't hardcode the symbol unquote
  (if (caris x 'unquote)
        (cadr x)
      ;; TODO: don't hardcode the symbol unquote-splicing
      (caris x 'unquote-splicing)
        (err ",@ cannot be used immediately after `")
      ;; TODO: don't hardcode the symbol quasiquote
      (caris x 'quasiquote)
        (qq-expand (qq-expand (cadr x)))
      (pair? x)
        (qq-expand-pair x)
      (list ac-quote x)))

(define (qq-expand-pair x)
  (if (pair? x)
      (let/ c (car x)
            ;; TODO: don't hardcode the symbol unquote
        (if (and (eq? c 'unquote)
                 (null? (cddr x)))
              (cadr x)
            ;; TODO: don't hardcode the symbol unquote-splicing
            (and (eq? c 'unquote-splicing)
                 (null? (cddr x)))
              (err "cannot use ,@ after .")
            ;; TODO: don't hardcode the symbol unquote
            (caris c 'unquote)
              (list cons (cadr c)
                         (qq-expand-pair (cdr x)))
            ;; TODO: don't hardcode the symbol unquote-splicing
            (caris c 'unquote-splicing)
              (if (null? (cdr x))
                  (cadr c)
                  (list append (cadr c)
                               (qq-expand-pair (cdr x))))
            ;; TODO: don't hardcode the symbol quasiquote
            (caris c 'quasiquote)
              (list cons (qq-expand-pair (qq-expand (cadr c)))
                         (qq-expand-pair (cdr x)))
            (list cons (qq-expand-pair c)
                       (qq-expand-pair (cdr x)))))
          ;; TODO: maybe remove this
      (if (null? x)
          x
          (list ac-quote x))))

(mset ac-quasiquote (x) #:name quasiquote
  (annotate 'mac (lambda (x)
                   (qq-expand x))))


;=============================================================================
;  quote
;=============================================================================
(define (sym->nil x)
  (if (eq? x 'nil)
      nil
      x))

#|(define (nil->null x)
  (if (eq? x 'nil)
      null
      x))|#

(mset ac-quote (x) #:name quote
  (annotate 'mac (let/ u (gensym)
                   (make-keyword-procedure
                     (lambda (kw kwa [x u])
                       (let/ x (dottedrec sym->nil (if (eq? x u)
                                                       (car kw)
                                                       x)) ; #:end nil->null
                         (list (lambda () x))))))))


;=============================================================================
;  ssyntax
;=============================================================================
(define (ssyntax x)
  (and (symbol? x)
       ;(not (or (eq? x '+) (eq? x '++) (eq? x '_)))
       (let/ name (symbol->string x)
         (has-ssyntax-char? name (- (string-length name) 1)))))

;; TODO: why does this count backwards...? efficiency, maybe?
(define (has-ssyntax-char? string i)
  (and (>= i 0)
       (or (let/ c (string-ref string i)
             (or (eqv? c #\:) (eqv? c #\~)
                 (eqv? c #\&)
                 ;(eqv? c #\_)
                 (eqv? c #\.)  (eqv? c #\!)))
           (has-ssyntax-char? string (- i 1)))))

(define (read-from-string str)
  (withs (port  (open-input-string str)
          val   (read port))
    (close-input-port port)
    val))

; Though graphically the right choice, can't use _ for currying
; because then _!foo becomes a function.  Maybe use <>.  For now
; leave this off and see how often it would have been useful.

; Might want to make ~ have less precedence than &, because
; ~foo&bar prob should mean (andf (complement foo) bar), not
; (complement (andf foo bar)).

;; TODO: better definition of ssexpand
(define (ssexpand sym)
  ((if (or (insym? #\: sym) (insym? #\~ sym))  expand-compose
       (or (insym? #\. sym) (insym? #\! sym))  expand-sexpr
       (insym? #\& sym)                        expand-and
                                               (err "unknown ssyntax" sym))
   sym))

#|(define (expand-keyword sym)
  (if (symbol? sym)
      (let/ x (symbol->chars sym)
        (if (caris x #\:)
            (string->keyword (list->string (cdr x)))
            sym))
      sym))|#

(define (expand-compose sym)
  (let/ elts (map (lambda (tok)
                    (if (eqv? (car tok) #\~)
                        (if (null? (cdr tok))
                            ;; TODO: don't hardcode the symbol 'no ?
                            'no
                            ;; TODO: don't hardcode the symbol 'complement ?
                            `(complement ,(chars->value (cdr tok))))
                        (chars->value tok)))
                  (tokens (lambda (c) (eqv? c #\:))
                          (symbol->chars sym)
                          null
                          null
                          #f))
    (if (null? (cdr elts))
        (car elts)
        ;; TODO: don't hardcode the symbol 'compose ?
        (cons 'compose elts))))

(define (expand-sexpr sym)
  (build-sexpr (reverse (tokens (lambda (c) (or (eqv? c #\.) (eqv? c #\!)))
                                (symbol->chars sym)
                                null
                                null
                                #t))
               sym))

(define (expand-and sym)
  (let/ elts (map chars->value
                  (tokens (lambda (c) (eqv? c #\&))
                          (symbol->chars sym)
                          null
                          null
                          #f))
    (if (null? (cdr elts))
        (car elts)
        ;; TODO: don't hardcode the symbol 'andf ?
        (cons 'andf elts))))

(define (build-sexpr toks orig)
  (if (null? toks)
        ;; TODO: don't hardcode the symbol 'get ?
        'get
      (null? (cdr toks))
        (chars->value (car toks))
      (list (build-sexpr (cddr toks) orig)
            (if (eqv? (cadr toks) #\!)
                ;; TODO: don't hardcode the symbol 'quote ?
                (list 'quote (chars->value (car toks)))
                (if (or (eqv? (car toks) #\.) (eqv? (car toks) #\!))
                    (err "bad ssyntax" orig)
                    (chars->value (car toks)))))))

(define (insym? char sym)    (member char (symbol->chars sym)))
(define (symbol->chars x)    (string->list (symbol->string x)))
(define (chars->value chars) (read-from-string (list->string chars)))

(define (tokens test source token acc keepsep?)
  (if (null? source)
        (reverse (if (pair? token)
                     (cons (reverse token) acc)
                     acc))
      (test (car source))
        (tokens test
                (cdr source)
                null
                (let/ rec (if (null? token)
                              acc
                              (cons (reverse token) acc))
                  (if keepsep?
                      (cons (car source) rec)
                      rec))
                keepsep?)
      (tokens test
              (cdr source)
              (cons (car source) token)
              acc
              keepsep?)))


;=============================================================================
;  Extra stuff
;=============================================================================
#|(define namespace  (make-parameter arc3-namespace))
(set 'namespace  namespace)|#

#|(mset dref (x (o k))
  (case-lambda
    ((n)    (let/ x (ref (namespace) n fail)
              (if (eq? x fail)
                  nil
                  (begin (namespace-undefine-variable! n (coerce (namespace) 'namespace))
                         x))))
    ((x k)  (err "can't delete reference" x k))))|#

#|(sset % args
  (annotate 'mac (lambda args
                   (cons nocompile
                         (if (null? (cdr args))
                             (car args)
                             (cons '#%begin args))))))

(let/ space (current-namespace)
  (sset % args
    (annotate 'mac (lambda (x)
                     (list nocompile eval (cons '#%datum x) space)))))|#

(define nu-namespace (current-namespace))

(sset % args
  (annotate 'mac (lambda args
                   (list (eval `(lambda () ,@args) nu-namespace)))))

(sdef %port-next-location (s f)
  (call-with-values (lambda () (port-next-location s)) f)
  #|(let/ (l c p) (port-next-location s)
    (f l c p))|#
  )


;=============================================================================
;  Compiler stuff used by Arc
;=============================================================================
(define uniq-counter (make-parameter 1))


;=============================================================================
;  Arc functions not used by the compiler
;=============================================================================
;; Racket functions
(sset *                            args                       *)
(sset /                            args                       /)
(sset acos                         (n)                        acos)
(sset asin                         (n)                        asin)
(sset atan                         (n (o m))                  atan)
(sset break-thread                 (x)                        break-thread)
(sset ccc                          (f (o prompt))             call-with-current-continuation)
(sset cos                          (n)                        cos)
(sset current-gc-milliseconds      ()                         current-gc-milliseconds)
(sset current-process-milliseconds (x)                        current-process-milliseconds)
(sset current-thread               ()                         current-thread)
(sset expt                         (n to)                     expt)
(sset infile                       (path (o #:mode 'binary))  open-input-file) ;; TODO: Arc exposes the mzscheme version of open-input-file, but Nu exposes the Racket version, which uses keywords rather than optional args. Does any Arc code depend on infile accepting more than 1 argument?
;; use as a general fn for looking inside things
(sset inside                       (out)                      get-output-string)
(sset kill-thread                  (x)                        kill-thread)
(sset log                          (n)                        log) ;; logarithm
(sset memory                       ((o custodian))            current-memory-use)
(sset mod                          (n m)                      modulo)
(sset msec                         ()                         current-milliseconds)
(sset new-thread                   (thunk)                    thread)
(sset newstring                    (n (o c #\nul))            make-string)
(sset outstring                    ((o name 'string))         open-output-string)
(sset quit                         ((o n 0))                  exit)
(sset rand                         ((o n) (o gen))            random) ;: TODO: need to use a better seed (Arc 3.1???)
(sset sin                          (n)                        sin)
(sset sqrt                         (n)                        sqrt)
(sset tan                          (n)                        tan)

;; allow Arc to give up root privileges after it calls open-socket.
;; thanks, Eli!
(sset setuid (i) (get-ffi-obj 'setuid #f (_fun _int -> _int)))

;; binaries
(sset +  args (make-reduce    +-2 0))
(sset >  args (make-pairwise  >-2))
(sset <  args (make-pairwise  <-2))
(sset is args (make-pairwise is-2))

;; wrapnil
(sset rmfile (path)      (wrapnil delete-file))
(sset sleep  ((o sec 0)) (wrapnil sleep))
;; Will system "execute" a half-finished string if thread killed in the
;; middle of generating it?
(sset system (command)   (wrapnil system))

;; wraptnil
(sset dead        (x) (wraptnil thread-dead?))
(sset dir-exists  (x) (wraptnil directory-exists?))
(sset exact       (x) (wraptnil exact-integer?)) ;; TODO: bad name
(sset file-exists (x) (wraptnil file-exists?))
(sset ssyntax     (x) (wraptnil ssyntax))

;; make-read
(sset readc ((o in (stdin))) (make-read read-char))
(sset readb ((o in (stdin))) (make-read read-byte))
(sset peekc ((o in (stdin))) (make-read peek-char))

;; make-write
(sset writec (c (o out (stdout))) (make-write write-char))
(sset writeb (c (o out (stdout))) (make-write write-byte))

;; make-print
(sset write  (x (o out (stdout))) (make-print write))
(sset disp   (x (o out (stdout))) (make-print display))

;; functions
#|(sdef apply (f . args)
  (apply #%call f (arg-list* args)))|#

;; TODO: how slow is this compared to the above definition...?
(sset apply (f . args)
  (make-keyword-procedure
    (lambda (kw kwa f . args)
      (let/ (kw kwa args) (process-keywords kw kwa (arg-list* args))
        (if (procedure? f)
            (keyword-apply f kw kwa args)
            (keyword-apply ref kw kwa f args))))))

;; TODO: make this better
(sdef atomic-invoke (f)
  (if (thread-cell-ref sema-cell)
      ;; TODO: why are these #%call...?
      (#%call f)
      (begin (thread-cell-set! sema-cell #t)
             (protect (lambda ()
                        (call-with-semaphore
                          the-sema
                          (lambda () (#%call f))))
                      (lambda ()
                        (thread-cell-set! sema-cell #f))))))

(sdef bound (x)
  (tnil (not (eq? (var-raw x fail) fail))))

(sdef call-w/stdin (port thunk)
  (parameterize ((current-input-port port)) (thunk)))

(sdef call-w/stdout (port thunk)
  (parameterize ((current-output-port port)) (thunk)))

(sdef call-w/stderr (port thunk)
  (parameterize ((current-error-port port)) (thunk)))

(sdef client-ip (port)
  (let/ (x y) (tcp-addresses port) y))

(sdef declare (key val)
  (let/ flag (true? val)
    (case key
      ((atstrings)      (set! atstrings      flag))
      ((direct-calls)   (set! direct-calls   flag))
      ((inline-calls)   (set! inline-calls   flag))
      ((explicit-flush) (set! explicit-flush flag))
      (else             (warn "invalid declare mode " key)))
    val))

(sset details (e) exn-message)
               ;; TODO: why does this use disp-to-string...?
  ;(lambda (e) (disp-to-string (exn-message e)))

;; TODO: better dir
(sdef dir (name)
  (map path->string (directory-list name)))

; Added because Mzscheme buffers output.  Not a permanent part of Arc.
; Only need to use when declare explicit-flush optimization.
(sdef flushout ()
  (flush-output)
  t)

(sdef force-close args
       ;; TODO: force-close1
  (map (lambda (p)
         (when (not (try-custodian p))
           (close p)))
       args)
  nil)

(sdef len (x)
  (if (string? x)  (string-length x)
      (hash? x)    (hash-count x)
                   (length x)))

(sdef maptable (fn table)
  (hash-for-each table fn) ; arg is (fn (key value) ...)
  table)

;; TODO: mkdir with make-directory*
; Would def mkdir in terms of make-directory and call that instead
; of system in ensure-dir, but make-directory is too weak: it doesn't
; create intermediate directories like mkdir -p.

(sdef mvfile (old new (flag t))
       #:sig (old new (o flag t))
  (rename-file-or-directory old new (true? flag))
  nil)

; If an err occurs in an on-err expr, no val is returned and code
; after it doesn't get executed.  Not quite what I had in mind.
(sdef on-err (errfn f)
  (with-handlers ((exn:fail? errfn)) (f))
  ;; TODO: why does Arc 3.1 implement it like this?
  #|((call-with-current-continuation
     (lambda (k)
       (lambda ()
         (with-handlers ((exn:fail? (lambda (e)
                                      (k (lambda () (errfn e))))))
                        (f))))))|#
  )

(sdef open-socket (num)
  (tcp-listen num 50 #t))

                 ;; TODO check this
(sdef outfile (f (mode 'truncate))
        #:sig (f (o mode 'truncate))
  (open-output-file f #:mode 'text #:exists mode))

(sdef pipe-from (cmd)
         ;; TODO: destructuring
  (withs (x   (pipe cmd)
          in  (car x)
          out (cadr x))
    ;; Racket docs say I need to close all 3 ports explicitly,
    ;; but the err port doesn't need to be closed, because it's
    ;; redirected to stderr
    (close out)
    in))

(sdef scdr (p x)
  (if (pair? p)    (unsafe-set-mcdr! p x)
      (string? x)  (err "can't set cdr of a string" x)
                   (raise-type-error 'scdr "cons" p))
  x)

; the 2050 means http requests currently capped at 2 meg
; http://list.cs.brown.edu/pipermail/plt-scheme/2005-August/009414.html
(sdef socket-accept (s)
  (with/ (oc  (current-custodian)
          nc  (make-custodian))
    (current-custodian nc)
    (call-with-values
      (lambda () (tcp-accept s))
      (lambda (in out)
        (let/ in1 (make-limited-input-port in 100000 #t)
          (current-custodian oc)
          (associate-custodian nc in1 out)
          (list in1
                out
                (let/ (us them) (tcp-addresses out) them)))))))

; sread = scheme read. eventually replace by writing read
(sdef sread (p eof)
  (let/ expr (read p)
    (if (eof-object? expr)
        eof
        (dottedmap sym->nil expr))))

(sdef ssexpand (x)
  (if (symbol? x) (ssexpand x) x))

; Racket provides eq? eqv? and equal? hash tables
; we need equal? for strings
(sdef table ((init nil))
      #:sig ((o init))
  (let/ h (make-hash)
    (when (true? init)
      (init h))
    h))

(sdef timedate ((sec (current-seconds)))
         #:sig ((o sec (seconds)))
  (let/ d (seconds->date sec)
    (list (date-second d)
          (date-minute d)
          (date-hour d)
          (date-day d)
          (date-month d)
          (date-year d))))

(sdef trunc (x)
  (inexact->exact (truncate x)))

(sdef uniq ((name 'g) (num nil))
     #:sig ((o name 'g) (o num))
  (let/ num (if (false? num)
                (let/ num (uniq-counter)
                  (uniq-counter (+ (uniq-counter) 1))
                  num)
                num)
    (string->uninterned-symbol
      (string-append (coerce name 'string)
                     (coerce num  'string)))))
