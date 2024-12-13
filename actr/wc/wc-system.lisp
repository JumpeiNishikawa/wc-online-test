;;;Lisp part
(load "./actr/wc/wordlist/mora.lisp")             ;(defvar *mora-list*)
;(load "./wc/wordlist/mora_sim.lisp")         ;(defvar *mora-sim-list*)

;;;exp setting;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;(load "./wc/wordlist/mora_sim1.lisp")         ;(defvar *mora-sim-list1*)
;(load "./wc/wordlist/mora_sim2.lisp")         ;(defvar *mora-sim-list2*)
(load "./actr/wc/wordlist/mora_sim_for_exp.lisp")            ;(defvar *mora-sim-list1*)
(load "./actr/wc/wordlist/mora_sim_plusminus_for_exp.lisp")  ;(defvar *mora-sim-list2*)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;(load "./wc/wordlist/wc-base-levels.lisp")   ;(defvar *word-base-levels*)
;;(load "./wc/wordlist/base-levels-wm-fromFami-exp-revese.lisp") ;(defvar *word-mora-base-levels*)
;
;;(load "./wordlist/word.lisp")               ;(defvar *word-list*)
;(load "./wc/wordlist/word-wo-tl.lisp")       ;(defvar *word-list-wo-tl*)
;;(load "./wordlist/word-mora.lisp")          ;(defvar *wm-list*)
;;(load "./wordlist/word-mora-00.lisp")       ;(defvar *wm-list*) ;Head and tail are enough
;(load "./wc/wordlist/word-mora-wo-tl.lisp")  ;(defvar *wm-list-wo-tl*) ;This is also 00 type
;;;wo-tl means "without long tail".
;;;e. g.，コンピューター:
;;;(ko0pju1ta ISA word word-concept ko0pju1ta word-sound "こんぴゅーた") 
;
;;(defvar *chunk-list*)
;;(setf *chunk-list* (concatenate 'list *mora-list* *word-list* *wm-list*))
;;(defvar *chunk-name-list*)
;;(setf *chunk-name-list* (mapcar #'car *chunk-list*))
;(defvar *chunk-list-wo-tl*)
;(setf *chunk-list-wo-tl* (concatenate 'list *mora-list* *word-list-wo-tl* *wm-list-wo-tl*))
;(defvar *chunk-name-list-wo-tl*)
;(setf *chunk-name-list-wo-tl* (mapcar #'car *chunk-list-wo-tl*))

;(load "./wc/wordlist/word-tl2v-random2000.lisp")      ;(defvar *word-list-tl2v*)
;(load "./wc/wordlist/word-mora-tl2v-random2000.lisp") ;(defvar *wm-list-tl2v*) ;This is also 00 type
(load "./actr/wc/wordlist/word-tl2v-nansense-mora-freq-2000.lisp")
(load "./actr/wc/wordlist/word-mora-tl2v-nansense-mora-freq-2000.lisp")
;;tl2v means "tail long to vowel".
;;e. g.，コンピューター:
;;(ko0pju1taa ISA word word-concept ko0pju1taa word-sound "こんぴゅーたあ")

;;;exp setting;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;「しりにゃ」のかわりに「とばや」
(load "./actr/wc/wordlist/word-without-sirinja.lisp") 
(load "./actr/wc/wordlist/word-mora-without-sirinja.lisp")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defvar *chunk-list-tl2v*)
(setf *chunk-list-tl2v* (concatenate 'list *mora-list* *word-list-tl2v* *wm-list-tl2v*))
(defvar *chunk-name-list-tl2v*)
(setf *chunk-name-list-tl2v* (mapcar #'car *chunk-list-tl2v*))

(defvar *monitor-installed* nil)
(defvar *window* nil)
(defvar *dbg* nil)

(defvar *lowest-item-y* 0)
(defvar *item-margin* 50)

(defvar *user-answer* "はじめ")

(defun relay-speech-output (model string)
  (dolist (m (mp-models))
    (unless (eq model m) 
      (with-model-eval m 
        (unless (chunk-p-fct model)
          (define-chunks-fct (list model)))
        (new-word-sound string (mp-time) model) )))

    (when *dbg*
      ;(add-text-to-exp-window *window* (concatenate 'string (string (current-model)) ": " string) :x 60 :y (+ *lowest-item-y* *item-margin*) :font-size 30)
      (add-text-to-exp-window *window* string :x 60 :y (+ *lowest-item-y* *item-margin*) :font-size 30)
      (setf *user-answer* string)
      (add-button-to-exp-window *window* :text "これ！" :x 20 :y (+ *lowest-item-y* *item-margin*) :width 36 :height 36 :action (list 'choose *user-answer*) :color 'lightgray)
      (setf *lowest-item-y* (+ *lowest-item-y* *item-margin*))
      (with-output-to-string (out)
        (sb-ext:run-program "/usr/bin/say" (list string) :output out) )))

(defun choose (word)
  (add-text-to-exp-window *window* (concatenate 'string  "これ： " word) :x 30 :y (+ *lowest-item-y* *item-margin*) :font-size 30)
  (setf *lowest-item-y* (+ *lowest-item-y* *item-margin*)))

;(defun speech-output-for-system (model string)
;  (let ((word (format nil "~{~a~}" (string-list-from-unicode-sequences string)))) ;formatでリストから文字列に, (る た あ) -> るたあ
;    (declare (ignore model))
;    (format t "now working this!: ~A~%" word)
;    (add-text-to-exp-window *window* word)) )
(defun speech-output-for-system (model string)
    (declare (ignore model))
    (format t "now working this!: ~A~%" string)
    (add-text-to-exp-window *window* string)) 

(defun add-speech-monitor ()
  (unless *monitor-installed*
    ;(add-act-r-command "wc-response" 'relay-speech-output "WC task model response")
    (add-act-r-command "wc-response" 'speech-output-for-system "WC task model response")
    (monitor-act-r-command "output-speech" "wc-response")
    (setf *monitor-installed* t)))

(defun remove-speech-monitor ()
  (remove-act-r-command-monitor "output-speech" "wc-response")
  (remove-act-r-command "wc-response")
  (setf *monitor-installed* nil))

;e.g., \u308B\u305F\u3042 -> (る た あ)
(defun string-list-from-unicode-sequences (seq)
  (format t "(search "u" seq)~A~%" (search "\u" seq))
  (if (search "\u" seq) ;渡された文字列がユニコードか
    (loop ;if true, ひらがなのリストを返す
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
    seq ;if false, 受け取ったものそのまま返す 
    ))

(defun select-first-word ()
    (with-open-file (in "./actr/wc/wordlist/words_from_lyricaloid7.txt" :direction :input)
        (let* (
            (words (loop for line = (read-line in nil)
                    while line
                    collect line)) 
            (fst-word (nth (random (length words)) words)))

            (if (string= (char fst-word (- (length fst-word) 1)) "ん")
                (select-first-word)
                fst-word) )))

;refer to dispatcher.lisp
;(defun present-1st-word (first-word)
;  (let* ((hiragana-list (string-list-from-unicode-sequences first-word))
;         (word (format nil "~{~a~}" hiragana-list)))
;    (format t "calling string-list-from-unicode-sequences~%")
;    (format t "(search ? seq) ~A~%" (search "?" word))
;    (format t "recieve ~A from node~%" hiragana-list)
;    (format t "recieve ~A from node~%" word)
;    (format t "(name-char word) ~A~%" (name-char word))
;    (clear-exp-window)
;    (dolist (m (mp-models))
;      (with-model-eval m (new-word-sound word)))
;    (run 100 t) ))
(defun present-1st-word (first-word)
    (format t "calling string-list-from-unicode-sequences~%")
    (format t "(search ? seq) ~A~%" (search "?" first-word))
    ;(format t "recieve ~A from node~%" hiragana-list)
    (format t "recieve ~A from node~%" first-word)
    (format t "(name-char word) ~A~%" (name-char first-word))

    (clear-exp-window)
    (dolist (m (mp-models))
      (with-model-eval m (new-word-sound first-word)))
    (run 100 t) )

(defun add-1st-word-command ()
  (add-command "game-start" 'present-1st-word "present-1st-word" t nil nil :lisp))
(defun remove-1st-word-command ()
  (remove-command "game-start"))

(defun modify-P-value (model value) ;;今あるモデルのPを指定値に変えるだけ，将来的にはモデルを新しく作る
  (with-model-fct model (sgp :mp value)))

(defun run-trial-w-moniter (first-word)
  (add-speech-monitor)
  (run-trial first-word)
  (remove-speech-monitor)
)

(defun run-trial (first-word)
  (clear-exp-window)
  (setf *lowest-item-y* (+ 0 *item-margin*))
  (dolist (m (mp-models))
    (with-model-eval m (new-word-sound first-word)))
    
  (add-text-to-exp-window *window* (concatenate 'string "もんだい！「" first-word "」") :x 20 :y (+ *lowest-item-y* *item-margin*) :font-size 30)
  (setf *lowest-item-y* (+ *lowest-item-y* *item-margin*))
  ;(new-tone-sound 500 -0.1)
  (run 5 *dbg*)
)

(defun run-trial-dbg ()
    (reset)
    (let (
        (first-word (select-first-word)))
    (format t "~A" first-word)
    (setf *dbg* t)
    (setf *window*
	    (open-exp-window "Shiritori" 
        :visible *dbg* 
		    :width 640
			  :height 480
        :x 0
        :y 0))
    (dolist (m (mp-models))
        (with-model-eval m (install-device *window*)))

    (add-speech-monitor)
    (run-trial first-word)
    (remove-speech-monitor) ;;;これここにあるとrun-trialだけで繰り返しできない
    ))

(defun init()
  (setf *window*
	  (open-exp-window "Shiritori" 
      :visible t
		  :width 640
			:height 480
      :x 0
      :y 0))
    (dolist (m (mp-models))
        (with-model-eval m (install-device *window*)))
  
  (add-speech-monitor)
  (add-1st-word-command)
)

(defun send-my-socket-event1 (param)
  (let ((win (determine-exp-window (agi-component) *window*)))
        (send-update-to-handlers win (json:encode-json-to-string param)) ))
        ;;(send-update-to-handlers win (json:encode-json-to-string '((this . 0) (is . 1) (my . 2) (event . 3)))) ))
;;下のようなメッセージが送られる
;;{
;;  method: 'evaluate',
;;  params: [ 'vv', null, '{":THIS":0,":IS":1,":MY":2,":EVENT":3}' ],
;;  id: 4
;;}

(defun send-my-socket-event2 ()
  (let (
    (win (determine-exp-window (agi-component) *window*)) ;win -> ;#<VISIBLE-VIRTUAL-WINDOW {700522D363}>
    (params (json:encode-json-to-string '((this . 0) (is . 1) (my . 2) (event . 3)))))
    (format t "~A~%" win)

    (dolist (name (bt:with-recursive-lock-held ((window-lock win)) (display-handlers win)));; name -> "node-js-vv-relay"
      (format t "~A~%" name)
      (let* (
        (c (gethash name (dispatcher-command-table *dispatcher*)))
        (handler (dispatch-command-evaluator c)))
          (format t "~A~%" (handler-socket handler))
          (format (usocket:socket-stream (handler-socket handler)) "{\"method\": \"my_event\", \"params\": ~a, \"id\": ~d}~c" params 0 (code-char 4))
          (force-output (usocket:socket-stream (handler-socket handler))) ))))
;;{
;;  "method": "my_event", 
;;  "params": {"THIS":0,"IS":1,"MY":2,"EVENT":3}, 
;;  "id": 0
;;}

(defun retrieval-fail (model)
  (send-my-socket-event1 (list "retrieval-fail" model)))


;;;model part
;;細川くんのを参考にして自動化する
(clear-all)

;2024/05/31 同じ類似度テーブルを比較する実験
(load "./actr/wc/models/productions.lisp")
;wc1 -> mp 10, sim table 1
(load "./actr/wc/models/exp-model1.lisp")
;;wc2 -> mp 30, sim table 1
;(load "./actr/wc/models/exp-model2.lisp")
;wc3 -> mp 10, sim table 2
(load "./actr/wc/models/exp-model3.lisp")
;;wc4 -> mp 30, sim table 2
;(load "./actr/wc/models/exp-model4.lisp")

(init)

(format t "===model file loaded===")