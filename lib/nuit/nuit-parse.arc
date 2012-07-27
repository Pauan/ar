(import re)

(= nuit-whitespace   (string "\u9\uB\uC\u85\uA0\u1680\u180E\u2000-\u200A"
                             "\u2028\u2029\u202F\u205F\u3000")
   nuit-nonprinting  (string "\u0-\u8\uE-\u1F\u7F\u80-\u84\u86-\u9F\uFDD0-\uFDEF"
                             "\uFEFF\uFFFE\uFFFF\U1FFFE\U1FFFF\U10FFFE\U10FFFF")
   nuit-end-of-line  "(?:\uD\uA|[\uD\uA]|$)"
   nuit-invalid      (string nuit-whitespace nuit-nonprinting)
   nuit-fail         (uniq))

(= nuit-parsers
  (obj #\@ (fn (while parse next indent rest)
             (withs ((_ x i y)  (re-match "^([^ ]*)( *)(.*)$" rest)
                     s          (car:parse (fn ()) (+ (len:string x i) 1) y)
                                         #|(while:fn (next i str)
                                           (if (is str "")
                                                 (next)
                                               (is i limit)
                                                 (parse next i str)))|#
                     limit      nil
                     line       nil
                     rest       (while:fn (next i str)
                                  (prn i " " indent " " str)
                                  (if (is str "")
                                        (next)
                                      (>= i indent)
                                        (do (or= limit i)
                                            (if (is i limit)
                                                (parse next i str)
                                                (do (= line (list i str))
                                                    nil)))
                                      (do (= line (list i str))
                                          nil)
                                          #|(let x
                                            (cons x (next)))|#
                                          #|(if (is x nuit-fail)
                                              ;x
                                              (next)
                                              (cons x (next)))|#
                                          )))
                                                    ;;(f-err "invalid indentation" i)
               ;(prn "foo " s)
               (cons (if (is x "")
                         (if (is y "")
                             rest
                             (cons s rest))
                         (if (is y "")
                             (cons x rest)
                             (list* x s rest)))
                     (if line (apply parse next line)
                              (next)))))
       #\# (fn (while parse next i rest)
             (let line nil
               (let limit (len:re-match1 "^ *" rest)
                 (while:fn (next i str)
                   (if (or (is str "")
                           (>= i limit))
                       (next)
                       (= line (list i str)))))
               (if line (apply parse next line)
                        (next))))
       #\` (fn (while parse next i rest)
             (cons (nuit-string while i rest #\newline) (next)))
       #\" (fn (while parse next i rest)
             (cons (nuit-string while i rest #\space nuit-string-escape) (next)))
       #\\ (fn (while parse next i rest)
             (if (nuit-parsers rest.0)
                 (cons rest (next))
                 (f-err (string "invalid escape " rest.0) (+ i 1))))))

(def nuit-string-escape (sep i str)
  (let str (string:awith (x  (coerce str 'cons)
                          i  (+ i 1))
             (whenlet (x . rest) x
               (if (is x #\\)
                   (case car.rest
                     #\\ (cons car.rest (self cdr.rest (+ i 2)))
                     #\u (nuit-parse-unicode self cdr.rest (+ i 2))
                     nil (do (= sep nil)
                             (list #\newline))
                         (f-err (string "invalid escape " car.rest) (+ i 1)))
                   (cons x (self rest (+ i 1))))))
    (list sep str)))

(def nuit-parse-unicode (rest x i)
  (if (is car.x #\()
      (let s (instring:string cdr.x)
        (alet i i
          (let (_ h e) (re-match "([0-9a-fA-F]*)(.?)" s)
            (case e
              " " (cons (coerce (coerce h 'int 16) 'char)
                        (self (+ i len.h 1)))
              ")" (cons (coerce (coerce h 'int 16) 'char)
                        (rest (coerce allchars.s 'cons)
                              (+ i len.h 1)))
              ""  (f-err "missing ending )" (+ i len.h 1))
                  (f-err (string "invalid hexadecimal " e) (+ i len.h 1))))))
      (f-err "missing starting (" i)))

(def nuit-string (while i rest sep (o f))
  (withs ((_ limit rest)  (re-match "^( *)(.*)$" rest)
          limit           (+ i len.limit))
    (string:let (s? str) (if f (f sep limit rest)
                               (list sep rest))
      (let x (while:fn (next i str)
               (if (is str "")
                     (do (= s? #\newline)
                         (list #\newline (next)))
                     #|(do ;(= n? nil)
                         (list:string #\newline (next)))|#
                   (>= i limit)
                          ;(re-replace (string "^ {0," limit "}") line "")
                     (let (n? str) (if f (f sep i str)
                                         (list sep str))
                       (do1 (list* s?
                                   (newstring (max 0 (- i limit)) #\space)
                                   str
                                   (next))
                            (= s? n?)))))
        (cons str x)))))

#|(def nuit-parse1 (s)
  (let lines 0
    (alet limit 0
      (when peekc.s
        (++ lines)
        (withs (line  (cadr:re-match (string "^([^\r\n]*)" nuit-end-of-line) s)
                line  (re-replace " +$" line "")
                ls    (instring line))
          (let indent (len:re-match1 "^ *" ls)
            (if (and (<= indent limit)
                     (no peekc.ls))
                  (self limit)
                (is indent limit)
                  (withs (start  (re-match1 (string "^[^" nuit-invalid "]") ls)
                          rest   (re-match1 (string "^[^" nuit-invalid "]*") ls))
                    (aif peekc.ls
                         (f-err (string "invalid character " it)
                                line lines (+ indent (len:string start rest) 1))
                         (aif (nuit-parsers rest.0)
                              (cons (it self rest (list line lines (+ indent 1)))
                                    (self limit))
                              (cons (string start rest) self.limit))))
                (f-err "invalid indentation" line lines indent))))))))|#

(def nuit-indent (line)
  (let (_ i rest invalid)
       (re-match (string "^( *)([^" nuit-invalid "]*)(.?)") line)
    (let i len.i
      (if (is invalid "")
          (list i rest)
          (f-err (string "invalid character " invalid) (+ i len.rest 1))))))

(withs (lines   nil
        line    nil
        stream  nil

        next    (fn ()
                  (++ lines)
                  (let x (cadr:re-match (string "^([^\r\n]*)" nuit-end-of-line) stream)
                    (re-replace " +$" x "")))

        while   (fn (f)
                  ;(= line (next))
                  (awith ()
                    (when peekc.stream
                      (= line (next))
                      (apply f self (nuit-indent line))))
                  #|(let x (fn (n)
                           (apply f n (nuit-indent line))
                             #|(let x
                               (if (is x nuit-fail)
                                   (self n)
                                   x))|#
                           )
                    (x (afn ()
                         (when peekc.stream
                           (= line (next))
                           (x self)))))|#
                )

        parse   (afn (next i str)
                  (aif (and (no empty.str)
                            (nuit-parsers str.0))
                       (let x (it while self next (+ i 1) (cut str 1))
                         x
                         #|(if (is x nuit-fail)
                             ;(when peekc.stream
                               ;(= line (next)))
                             (apply self (nuit-indent line))
                             x)|#
                         )
                       (cons str (next)))))

  (def f-err (message column)
    (err:string message "\n  " line
      "  (line " lines ", column " column ")\n"
      " " (newstring column #\space) "^"))

  #|(def parse (i str)
    (aif (and (no empty.str)
              (nuit-parsers str.0))
         (do (= line (next))
             (it while parse (+ i 1) (cut str 1)))
         str))|#

  (def nuit-parse (s)
    (= stream (if (isa s 'string)
                  (instring s)
                  s))
    ;; Byte Order Mark may appear at the start of the stream but is ignored
    (re-match "^\uFEFF" stream)
    ;; Initialization
    (= lines 0)
    ;(= line (next))
    #|(w/nuit-current-lines 0
      (w/nuit-current-line (next)))|#
    ;(= line (next))
    (awith ()
      (when peekc.stream
        (= line (next))
        (let (i str) (nuit-indent line)
          (if (is str "")
                (self)
              (is i 0)
                  #|(if (is x nuit-fail)
                      x)|#
                      ;(next)
                      ;(apply self next (nuit-indent line))
                (parse self i str)
                #|(let x
                  (cons x (next)))|#
              (f-err "invalid indentation" i)))))
    #|(while:fn (next i str)
      )|#
    ))
