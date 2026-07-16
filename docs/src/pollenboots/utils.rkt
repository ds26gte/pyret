#lang racket

(require txexpr)
(require pollen/core)
(require pollen/setup)

(provide (all-defined-out))

(define (sluggify* terms)
  ; (printf "### sluggify* ~s\n" terms)
  (string-join (map sluggify terms) "-"))

(define (sluggify term)
  ; (printf "### sluggify ~s\n" term)
  (let ([s ""])
    (cond [(string? term) (set! s term)]
          [(list? term)
           (if (null? term) (set! s "-")
               (set! s (sluggify* (rest term))))]
          [else (set! s "unnamed")])
    (string-replace s " " "-")))

(define (change-tag tx from to)
  (define-values (tx1 _)
    (splitf-txexpr tx
      (lambda (tx) (and (txexpr? tx) (eq? (get-tag tx) from)))
      (lambda (tx) (txexpr to (get-attrs tx) (get-elements tx)))))
  tx1)

; (define (tag=? tx tag)
;   (and (txexpr? tx) (equal? (get-tag tx) tag)))

(define (extract-tags tx tags)
  ; (printf "doing extract-tags ~s ~s\n" tx tags)
  (define-values (_ txs)
    (splitf-txexpr tx
      (lambda (tx) (and (txexpr? tx)
                   (member (get-tag tx) tags)))))
  txs)

(define (remove-tag tx tag)
  (define-values (tx1 _)
    (splitf-txexpr tx
      (lambda (tx) (and (txexpr? tx) (eq? (get-tag tx) tag)))))
  tx1)

(define *distinguishing-part-of-containing-directory*
  (let ([md (getenv "MAKE_DIR")])
    (cond [md (set! md (regexp-replace "/$" md ""))
              (path->string (file-name-from-path md))]
          [else "pyret-docs-pb"])))

(define (from-project-root pname)
  (regexp-replace (format ".*~a/" *distinguishing-part-of-containing-directory*)
                  pname ""))

(define (to-project-root pname)
  ; (printf "### to-project-root ~s\n" pname)
  (let ([x ""])
    (let loop ([i (- (string-length pname) 1)])
      (unless (< i 0)
        (when (char=? (string-ref pname i) #\/)
          (set! x (string-append x "../")))
        (loop (- i 1))))
    x))

(define (point-to-project-root pname)
  (when (symbol? pname)
    (set! pname (symbol->string pname)))
  (let ([up-dir ""])
    (for ([c pname])
      (when (char=? c #\/) (set! up-dir (string-append up-dir "../"))))
    up-dir))

(define (prefix-dir up-dir pname)
  (when (symbol? pname)
    (set! pname (symbol->string pname)))
  (if (not pname) pname
      (format "~a~a" up-dir pname)))

(define (h-tag-at-depth n)
  (string->symbol (format "h~a" n)))

(define (make-gloss item-alpha [item-sluggified #f] [item-typeset #f])
  (unless item-sluggified
    (set! item-sluggified (sluggify item-alpha)))
  (unless item-typeset
    (set! item-typeset item-alpha))
  `(span ()
         (a ([name ,item-sluggified]))
         (gloss-1 ,item-alpha ,item-sluggified ,item-typeset)))

(define (ref-gloss item-alpha [item #f] #:mod [mod #f])
  (unless mod (set! mod "nodoc"))
  (unless item (set! item item-alpha))
  ; (printf "### ref-gloss ~s ~s\n" item-alpha item)
  `(ref-gloss-1 () ,item-alpha ,mod ,item))

(define (ref-mod-gloss mod item)
  (ref-gloss item #:mod mod))

(define xref ref-mod-gloss)

; (define (in-link item)
;   (printf "### in-link ~s\n" item)
;   `(xxref-1 () ,item))

;true globals

(define *project-root* (current-project-root))

(define *globals-file*        (build-path *project-root* "globals.rkt"))
(define *glossary-root-file* (build-path *project-root* "_glossary.rkt"))
(define *xref-root-file*     (build-path *project-root* "_xref.rkt"))

(define (read-root-file path)
  (if (file-exists? path)
      (call-with-input-file path
        (lambda (i)
          (let loop ([acc '()])
            (let ([x (read i)])
              (if (eof-object? x) (reverse acc)
                  (loop (cons x acc)))))))
      '()))

(define (read-globals)
  `((glossary ,@(read-root-file *glossary-root-file*))
    (xref     ,@(read-root-file *xref-root-file*))))

(define (calc-here-path-from-project-root)

  (define here-path-source (select-from-metas 'here-path (current-metas)))
  (define here-path-html (regexp-replace "\\.poly.pm$" here-path-source ".html"))
  (define here-path-from-project-root (from-project-root here-path-html))

  here-path-from-project-root)

(define (read-entries item)
  (define prefix-rx (regexp (string-append "^\\._" (symbol->string item) "_")))
  (define sidecar-files
    (filter file-exists?
      (find-files (lambda (f)
                    (or (directory-exists? f)
                        (regexp-match? prefix-rx (path->string (file-name-from-path f)))))
                  *project-root*)))
  (define res '())
  (for ([sidecar-file sidecar-files])
    (call-with-input-file sidecar-file
      (lambda (i)
        (let loop ()
          (let ([x (read i)])
            (unless (eof-object? x)
              (set! res (cons x res))
              (loop)))))))
  (if (eq? item 'glossary)
      (sort res (lambda (a b) (string-ci<? (second a) (second b))))
      (reverse res)))

(define (doc-title doc)
  ; (printf "doc is now ~s\n" doc)
  ; (printf "title = ~s\n" (select 'title doc))
  ; (printf "h1 = ~s\n" (select 'h1 doc))
  (or (select 'title doc)
      (select 'h1 doc)
      (let ([div1 (select 'div doc)])
        ; (printf "div1 = ~s\n" div1)
        (and div1 (txexpr? div1) (attr-ref div1 'id)))
      "Untitled"))

;counter

(define (make-counter)
  (let ([counter 0])
    (lambda ()
      (set! counter (+ counter 1))
      counter)))
