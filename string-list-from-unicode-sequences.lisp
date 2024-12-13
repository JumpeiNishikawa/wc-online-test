(defun string-list-from-unicode-sequences (seq)
  (loop 
    with start1 = 0
    with start2 = (search "\u" seq :start2 (+ 1 start1))
    repeat (count #\u seq) ;seqの中の\uの数だけくりかえす
    collect (format nil "~C" (name-char (subseq seq start1 start2)))
    do 
    (format t "~A~%" (count #\u seq))
    (format t "~A~%" start1)
    (format t "~A~%" start2)
    (format t "~A~%" (subseq seq start1 start2))
    (setq start1 start2)   
    (setq start2 (if start1 (search "\u" seq :start2 (+ start1 1)))) )
)

(format nil "~{~a~}~%" (string-list-from-unicode-sequences "\u308B\u305F\u3042"))

