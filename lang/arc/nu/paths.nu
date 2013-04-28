;;(load:string %.exec-dir "lib/utils.arc")
;;(load:string %.exec-dir "lib/parameters.arc")

(% (require racket/path))

(parameter-var cwd
  ((% make-derived-parameter) (% current-directory)
    (fn (v)
      (let v (str v)
        (if (is v "")
            ((% current-directory))
            ((% expand-user-path) v))))
    (fn (v) ((% path->string) v))))

;; TODO: inefficient
(parameter-var script-args
  ((% make-derived-parameter) (% current-command-line-arguments)
    (% list->vector)
    (% vector->list)))

(var script-src (car script-args))
(zap cdr script-args)

(def ->dir (x)
  (let x (str x)
        ;; TODO empty
    (if (or (is x "") (is (last x) #\/))
        x
        (str x "/"))))

(def hidden-file? (x)
  (is ((str x) 0) #\.))

(def expandpath (x)
  (let x (str x)
    (if (is x "") ; TODO empty
        x
        ((% path->string) ((% expand-user-path) x)))))

(def path args
  ((% path->string)
    (apply (% build-path)
      (awith (x    args
              acc  nil)
        (if (not x)
            (rev acc)
            (let c (expandpath (car x))
              (if (is c "") ; TODO empty
                    (self (cdr x) acc)
                  (is (c 0) #\/)
                    (self (cdr x) (cons c nil))
                  (self (cdr x) (cons c acc)))))))))

(def dirall ((o x ".") (o f idfn))
  (w/ cwd x
    (alet d nil
      (flatten (map x (dir (or d ".")) ; TODO
                 (let x (path d x)
                   (when (f x)
                         ;; dirname ?
                     (if (dir? x)
                         (self x)
                         (list x)))))))))

(def extension (x)
  (let x ((% filename-extension) (str x))
    (and x (str x))))
#|

(def no-extension (x)
  (cut x 0 (-:+ (len extension.x) 1)))

#|(= exec-dir %.exec-dir)

(def exec-path args
  (apply path exec-dir args))|#


(def make-path->string (converter)
  (fn (x)
    (zap string x)
    (unless empty.x
      (aand converter.x %.path->string.it))))

(var dirname  (make-path->string:compose %.path-only           expandpath))
(var basename (make-path->string:compose %.file-name-from-path expandpath))

(def abspath args
  (let x (expandpath:apply string args)
    (if empty.x
          cwd
        ;; TODO: is this necessary? fix it if not
        file-exists.x
          (%.path->string %.normalize-path.x)
        x))) ;path->complete-path

(def absdir args
  (dirname:apply abspath args))
|#
