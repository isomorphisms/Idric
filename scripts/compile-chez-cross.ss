#!chezscheme

(import (chezscheme))

(define (fail message)
  (display "compile-chez-cross: " (current-error-port))
  (display message (current-error-port))
  (newline (current-error-port))
  (exit 2))

(let ([args (cdr (command-line))])
  (unless (= (length args) 3)
    (fail "expected XPATCH INPUT OUTPUT"))
  (let ([xpatch (list-ref args 0)]
        [input (list-ref args 1)]
        [output (list-ref args 2)])
    (load xpatch)
    (parameterize ([optimize-level 3]
                   [compile-file-message #f])
      (compile-program input output))))
