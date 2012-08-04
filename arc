#! /usr/bin/env racket
#lang racket/base

(require racket/cmdline)
(require racket/path)
(require profile)

(define all   (make-parameter #f))
(define debug (make-parameter #f))
(define repl  (make-parameter #f))

(define arguments
  (command-line
    #:program "Nu Arc"
    #:once-each
    [("-a" "--all")   "Execute every file rather than only the first"
                      (all #t)]
    [("-d" "--debug") "Turns debug mode on, causing extra messages to appear"
                      (debug #t)]
    [("-i" "--repl")  "Always execute the repl"
                      (repl #t)]
    #:args args
    args))

(if (all)
    (current-command-line-arguments (make-vector 0))
    (current-command-line-arguments (list->vector arguments)))

(define exec-dir (path-only (normalize-path (find-system-path 'run-file))))

#|(parameterize ((current-directory exec-dir))
  (namespace-require '(file "01 nu.rkt")))

(init (path->string exec-dir))

(aload (build-path exec-dir "02 arc.arc"))

(unless (null? arguments)
  (if (all)
      (map aload arguments)
      (aload (car arguments))))

(when (or (repl) (null? arguments))
  (aload (build-path exec-dir "03 repl.arc")))|#

;; TODO should evaluate in this namespace, not a new namespace
(parameterize ((current-namespace (make-base-empty-namespace)))
  ;; TODO should be in 01 nu.rkt ...?
  (define-syntax-rule (nu-eval x)
    (eval '(ac-eval 'x)))

  ;(profile-thunk (lambda ()
  (parameterize ((current-directory exec-dir))
    (namespace-require '(file "01 nu.rkt")))

  (eval `(init ,(path->string exec-dir)))

  (let ((load   (eval 'aload))
        (files  (map (lambda (x) (path->string (build-path exec-dir x)))
                     ;; These files have Arc/Nu's dir prefixed to them
                     ;; and are automatically loaded when Arc/Nu
                     ;; starts up.
                     (list "02 arc.arc"
                           "03 utils.arc"
                           "04 parameters.arc"
                           "05 paths.arc"
                           "06 import.arc"
                           "lib/strings.arc"
                           "lib/re.arc"))))
    (for ((x files))
      (load x))

    (let ((cache (nu-eval import-cache)))
      (for ((x files))
        (hash-set! cache x (nu-eval t))))

    (when (debug)
      (nu-eval (= debug? t)))

    (let ((load (nu-eval import1)))
      (unless (null? arguments)
        (if (all)
            (map load arguments)
            (load (car arguments)))))

    (when (or (repl) (null? arguments))
      (load (build-path exec-dir "07 repl.arc"))))
  ;))

  ;; This is to prevent () from being printed when the REPL exits
  (void))
