#lang racket
(require "pollenboots/utils.rkt")
(require racket/file)

(define flag-file (build-path *project-root* ".xref-changed"))

(define any-updated #f)

(define (write-if-changed path entries)
  (define tmp (make-temporary-file))
  (call-with-output-file tmp
    (lambda (o)
      (for ([entry entries])
        (write entry o)
        (newline o)))
    #:exists 'replace)
  (define changed?
    (or (not (file-exists? path))
        (not (equal? (file->bytes tmp) (file->bytes path)))))
  (when changed?
    (rename-file-or-directory tmp path #t)
    (set! any-updated #t)
    (printf "~a updated\n" (path->string path))))

(write-if-changed *glossary-root-file* (read-entries 'glossary))
(write-if-changed *xref-root-file*     (read-entries 'xref))

(when any-updated
  (close-output-port (open-output-file flag-file #:exists 'replace)))
