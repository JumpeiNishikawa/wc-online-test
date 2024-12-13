;活性値の中間ファイルを読み込み，参照数などを操作する
;/Users/nishikawa/Desktop/wc_va_10min/log/7x-test/7x-test-activatoin-p1-0-0.lisp

(defun create-output-path (file-path)
    (let (
        (path-temp file-path)
        (result) )
        (setq result (subseq path-temp 0 (- (length path-temp) 5)))
        (setq result (concatenate 'string result "-manipulated.lisp")) ))

(defun manipulate-references (file-path chunk-list)
    (let (
        (file (open file-path :direction :input))
        (output-path (create-output-path file-path))
        (rc-max 0)
        (output) )

        (loop for x = (read file nil)
            while x
            do
                (if (and (eq (car x) 'sdp) (member (second x) chunk-list))
                    (if (< rc-max (sixth x))
                        (setq rc-max (sixth x)) )
                    ))
        (close file)
        (format t "maxRC is ~A~%" rc-max)

        (setq file (open file-path :direction :input))
        (setq output (open output-path :direction :output :if-exists :append :if-does-not-exist :create))
        (loop for x = (read file nil)
            while x
            do
                (if (member (second x) chunk-list)
                    (progn
                        (fill x rc-max :start 5 :end 6)
                        ;(format t "~A~%" x)
                        (write-line (write-to-string x) output) )
                    ;(format output "~A~%~%" x)
                    (write-line (write-to-string x) output)
                    ))
        (close file)
        (close output)
        (format t "word chunk referense count were manipulated, file: ~A~%" output-path)
        output-path))

