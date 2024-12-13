(defun select-first-word ()
    (with-open-file (in "./wordlist/words.txt" :direction :input)
        (let* (
            (words (loop for line = (read-line in nil)
                    while line
                    collect line)) 
            (fst-word (nth (random (length words)) words)))

            (if (string= (char fst-word (- (length fst-word) 1)) "ん")
                (select-first-word)
                fst-word) )))