(def regexp (pattern)
  (if (isa pattern 'string)
      %.pregexp.pattern
      pattern))

(def re-match (pattern (o in (stdin)))
  (let result ((if (isa in 'string)
                   %.regexp-match
                   %.regexp-try-match)
               regexp.pattern in)
    (when result
           ;; TODO: figure out how to get rid of this `if`
      (map [if %.bytes?._
               %.bytes->string/utf-8._
               _]
           result)
      ;result
      )))

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
