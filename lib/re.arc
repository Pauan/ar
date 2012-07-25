(def regexp (pattern)
  (if (isa pattern 'string)
      %.pregexp.pattern
      pattern))

(mac w/re-matcher (vars match (o after))
  (w/uniq u
    (let (p in) vars
      `(with (,p   (regexp ,p)
              ,in  (if (isa ,in 'string)
                       (instring ,in)
                       ,in)
              it   %.regexp-try-match)
         (whenlet ,u ,match
           (maplet it ,u
                      ;; TODO: figure out how to get rid of this `if`
             ,(let x `(if %.bytes?.it
                          %.bytes->string/utf-8.it
                          it)
                (if after
                    `(let it ,after ,x)
                    x))))))))

(def re-match (pattern (o in (stdin)))
  (w/re-matcher (pattern in)
    (it pattern in))
  #|(let result ((if (isa in 'string)
                   %.regexp-match
                   %.regexp-try-match)
               regexp.pattern in)
    (prn result)
    (when result
           ;; TODO: figure out how to get rid of this `if`
      (map [if %.bytes?._
               %.bytes->string/utf-8._
               _]
           result)
      ;result
      ))|#
)

(def re-match* (pattern (o in (stdin)) (o :group 0))
  (w/re-matcher (pattern in)
    (drain (it pattern in) #f)
    (it group))
  #|(with (pattern  regexp.pattern
         func     %.regexp-try-match
         in       (if (isa in 'string)
                      (instring in)
                      in))
    (let g1 (drain (prn:func pattern in) #f)
      (maplet x g1
        (= x (x group))
        (if %.bytes?.x
            %.bytes->string/utf-8.x
            x))))|#
)

(def re-match1 (pattern (o in (stdin)))
  (cadr:re-match pattern in))

; This isn't anchored at the beginning of the input unless you use
; "^" yourself.
(def re-looking-at (pattern (o in stdin))
  ;; TODO: different ssyntax priorities
  (%.tnil (%.regexp-match-peek regexp.pattern in)))


(def re-replace (pattern in replace)
  (%.regexp-replace regexp.pattern in replace))

;; TODO: what should this be called...?
(def re-replace* (pattern in replace)
  (%.regexp-replace* regexp.pattern in replace))

(mac re-multi-replace (x . args)
  ((afn (((from to (o g)) . rest))
     (list (if g %.regexp-replace*
                 %.regexp-replace)
           (regexp:string from)
           (if rest self.rest x)
           to))
   rev.args))


(def re-split (x y)
  (%.regexp-split regexp.x y))
