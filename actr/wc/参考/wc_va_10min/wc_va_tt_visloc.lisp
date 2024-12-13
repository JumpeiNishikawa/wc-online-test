(clear-all)

(defvar *chain-counter* 0)
(defvar P1word-list nil)
(defvar P1time-list nil)
(defvar P1last-time 0)
(defvar P1sdplist nil)

(defvar P2word-list nil)
(defvar P2time-list nil)
(defvar P2last-time 0)
(defvar P2sdplist nil)

(defvar *p1-used-counter* 0)
(defvar *p1-N-counter* 0)
(defvar *P2-used-counter* 0)
(defvar *P2-N-counter* 0)

(defvar used-mora-list1)
(setf used-mora-list1 nil)
(defvar used-mora-list2)
(setf used-mora-list2 nil)
(defvar used-mora-list3)
(setf used-mora-list3 nil)
(defvar used-mora-list4)
(setf used-mora-list4 nil)

(defvar *debug* nil)

(defvar *param-mp*)

(defvar *kana-list*)
(setf *kana-list* '(a-mora i-mora u-mora e-mora o-mora ja-mora ju-mora jo-mora ka-mora ki-mora ku-mora ke-mora ko-mora kja-mora kju-mora kjo-mora ga-mora gi-mora gu-mora ge-mora go-mora gja-mora gju-mora gjo-mora sa-mora si-mora su-mora se-mora so-mora sja-mora sju-mora sjo-mora za-mora zi-mora zu-mora ze-mora zo-mora zja-mora zju-mora zjo-mora ta-mora ti-mora tu-mora te-mora to-mora tja-mora tju-mora tjo-mora da-mora de-mora do-mora na-mora ni-mora nu-mora ne-mora no-mora nju-mora njo-mora ha-mora hi-mora hu-mora he-mora ho-mora hja-mora hju-mora hjo-mora pa-mora pi-mora pu-mora pe-mora po-mora pju-mora ba-mora bi-mora bu-mora be-mora bo-mora bja-mora bju-mora bjo-mora ma-mora mi-mora mu-mora me-mora mo-mora mja-mora mju-mora mjo-mora ra-mora ri-mora ru-mora re-mora ro-mora rja-mora rju-mora rjo-mora wa-mora N-mora R-mora Q-mora))
;nja-mora pja-mora pjo-mora

(defvar *mora-list*)
(setf *mora-list* '(a i u e o ja ju jo ka ki ku ke ko kja kju kjo ga gi gu ge go gja gju gjo sa si su se so sja sju sjo za zi zu ze zo zja zju zjo ta ti tu te to tja tju tjo da de do na ni nu ne no nju njo ha hi hu he ho hja hju hjo pa pi pu pe po pju ba bi bu be bo bja bju bjo ma mi mu me mo mja mju mjo ra ri ru re ro rja rju rjo wa))
;; N R Q

;(defstruct shiritori)
;
;(defmethod device-move-cursor-to ((device shiritori) loc))
;(defmethod device-handle-click ((device shiritori)))
;(defmethod device-handle-keypress ((device shiritori) key))
;(defmethod cursor-to-vis-loc ((device shiritori)))
;(defmethod build-vis-locs-for ((device shiritori) vis-mod))
;(defmethod vis-loc-to-obj ((device shiritori) vis-loc))
;(defmethod get-mouse-coordinates ((device shiritori))
;  (vector 0 0))

(defmethod device-speak-string ((win rpm-window) text)
  (let ((originator (current-model)))
    (dolist (model (mp-models))
      (unless (eq model (current-model))
        (with-model-eval model

          (unless (chunk-p-fct originator)
            (define-chunks-fct `((,originator isa chunk))))
          (new-word-sound text (mp-time) originator))))))

(defun clear-screen ()
  (clear-exp-window)
  (proc-display))

(defun present-hint (hint)
  (add-text-to-exp-window :text hint :x 125 :y 150) 
  (proc-display))

(defun get-formatted-time ()
  (let ((result nil))
    (multiple-value-bind(second minute hour date month year)
      (get-decoded-time)
      (setf result (format nil "~d-~d-~d ~d:~d:~d" year month date hour minute second)) )
      result ))

(defun clear-log-vars ()
  (setf *chain-counter* 0)

  (setf P1word-list NIL)
  (setf P1time-list NIL)
  (setf P1last-time 0)
  (setf P1sdplist nil)

  (setf P2word-list NIL)
  (setf P2time-list NIL)
  (setf P2last-time 0)
  (setf P2sdplist nil)
  
  (setf used-mora-list1 nil)
  (setf used-mora-list2 nil)
  (setf used-mora-list3 nil)
  (setf used-mora-list4 nil)

  (setf *p1-used-counter* 0)
  (setf *p1-N-counter* 0)
  (setf *P2-used-counter* 0)
  (setf *P2-N-counter* 0)
)

(defun export-log (log-file count-sim)
  (let (
    (str (open (concatenate 'string log-file) :direction :output :if-exists :append :if-does-not-exist :create)))

    (format str "player1,")
    (format str "~A,~A,~A,~A,~A,~A~%" (+ count-sim 1) (mp-time) *chain-counter* (length P1word-list) *p1-used-counter* *P1-N-counter*)
    (format str "~A" "p1-word")
    (dolist (word (reverse P1word-list)) (format str ",~A" word))
    (format str "~%~A" "p1-time")
    (dolist (word (reverse P1time-list)) (format str ",~A" word))
    ;;;;(format str "--,")
    ;;;;(dolist (value (reverse P1sdplist)) (format str "~A" value))
    (format str "~%")

    (format str "player2,")
    (format str "~A,~A,~A,~A,~A,~A~%" (+ count-sim 1) (mp-time) *chain-counter* (length P2word-list) *P2-used-counter* *P2-N-counter*)
    (format str "~A" "p2-word")
    (dolist (word (reverse P2word-list)) (format str ",~A" word))
    (format str "~%~A" "p2-time")
    (dolist (word (reverse P2time-list)) (format str ",~A" word))
    ;;;;(format str "--,")
    ;;;;(dolist (value (reverse P2sdplist)) (format str "~A" value))
    (format str "~%")

    (format str "~A" "P2-mora")
    (dolist (word (reverse used-mora-list1)) (format str ",~A" word))
    (format str "~%")
    ;;;(format str "~A,,,," "P2-mora")
    ;;;(dolist (word (reverse used-mora-list2)) (format str ",~A" word))
    ;;;(format str "~%")
    ;;;(format str "~A,,,," "P2-mora")
    ;;;(dolist (word (reverse used-mora-list3)) (format str ",~A" word))
    ;;;(format str "~%")
    ;;;(format str "~A,,,," "P2-mora")
    ;;;(dolist (word (reverse used-mora-list4)) (format str ",~A" word))
    ;;;(format str "~%")

    (close str)
    ))

(defun set-params (param-mp param-v)
      (sgp-fct `(
        :esc t
        :lf  0.05
        :ans 0.5
        :rt  -5
        :bll 0.5

        :v ,param-v
        :act nil ;,(if param-v t nil)
        :cmdt nil ;,(if param-v t nil)

        :mp ,(if (eq (current-model) 'P2) param-mp nil)
        :md ,(if (eq (current-model) 'P2) -100 0)
        :mas ,(if (eq (current-model) 'P2) 5 nil)
        :imaginal-activation ,(if (eq (current-model) 'P2) 1.0 0) ))

  (setf *param-mp* param-mp) )

(defun update-params (param-mp param-v)
      (sgp-fct `(

        :v t;,param-v
        ;:act ,(if param-v t nil)
        ;:cmdt ,(if param-v t nil)

        :mp ,(if (eq (current-model) 'P2) param-mp nil) ))

  (setf *param-mp* param-mp) )

;(defun test-run (chain-count num-of-sim log-file &optional (run-time 5) (real-time nil) )
;  (let ((d (make-shiritori))
;    (str nil))
;
;    (dotimes (count-sim num-of-sim)
;      ;(reset)
;
;      (dolist (x (mp-models))
;        (with-model-eval x
;          (install-device d)))
;
;      ;(with-model-eval 'player2
;      ;  (setf *base-level* 2)
;      ;  (set-base-levels-fct (mapcar (lambda (x) (list x *base-level*)) *kana-list*) ))
;
;      (clear-log-vars)
;      (setf *debug* real-time)
;
;      (loop while (and (> 2000 (mp-time)) (< *chain-counter* chain-count))
;          do (run run-time :real-time real-time)
;          )
;
;      (export-log str log-file count-sim)
;)))

(defun test-run2 (sim-time num-of-sim log-file param-mp &optional (param-v nil) (real-time nil) (run-time 0.1))
  (let (
    (log-dir (concatenate 'string "./log/" log-file "/")) )
    
    (ensure-directories-exist log-dir)

    (let (
      (start-time (write-to-string (get-universal-time)))
      (log-file-path (concatenate 'string log-dir log-file "-" (write-to-string param-mp) ".csv"))
      (window (with-model p1 (open-exp-window "game" :height 100 :width 200)))
      (num-of-run (ceiling (/ sim-time run-time)))
      (time-stamp (open (concatenate 'string log-dir log-file "-time-stamp.txt") :direction :output :if-exists :append :if-does-not-exist :create)) )

      (dotimes (count-sim num-of-sim)
        (reset)
        (clear-log-vars)

        (dolist (m (mp-models))
          (with-model-eval m
            (update-params param-mp (when param-v (concatenate 'string log-dir "trace-" (write-to-string m) "-" log-file "-mp" (write-to-string param-mp) "-"   start-time ".txt")))

            (install-device window)
            (proc-display) ))

        ;;(> 10000 (mp-time))
        ;(loop while (and (> 100 (mp-time)) (< *chain-counter* chain-count))
        ;    do (progn (dolist (m (mp-models))
        ;        (with-model-eval m (proc-display)))
        ;      (run run-time :real-time real-time))
        ;    )
        ;;;(and (> 100 (mp-time)) (< *chain-counter* chain-count))
        ;;;simulation time limit: 100 = 0.1 * 1000
        (dotimes (x num-of-run)
          (dolist (m (mp-models))
            (with-model-eval m (proc-display)) )
          (run run-time :real-time real-time) )

        ;;;;print progress
        (format t "mp:~A simulation:~A time:~A~%~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))
        (format time-stamp "mp:~A simulation:~A time:~A~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))

        (export-log log-file-path count-sim) )
      (close time-stamp) )))

(defun my-ex (sim-time num-of-sim log-file &optional (param-v nil) (real-time nil) (run-time 0.1))
  (let (
      (mp-list '(1 10 20 30 40 50 60 70 80 90 100))
      ;(mp-list '(30 40 50 60 70 80 90 100))
      )

    (dolist (param-mp mp-list)
      (test-run2 sim-time num-of-sim log-file param-mp param-v real-time run-time) )))




(defun run-train (sim-time num-of-sim log-file param-mp &optional (param-v nil) (real-time nil) (run-time 0.1))
  (let (
    (log-dir (concatenate 'string "./log/" log-file "/")) )
    (ensure-directories-exist log-dir)

    (let (
      (start-time (write-to-string (get-universal-time)))
      (log-file-train (concatenate 'string log-dir log-file "-train-" (write-to-string param-mp) ".csv"))
      (trace-log-train nil)
      (window (with-model p1 (open-exp-window "game" :height 100 :width 200)))
      (num-of-run (ceiling (/ sim-time run-time)))
      (time-stamp (open (concatenate 'string log-dir log-file "-time-stamp.txt") :direction :output :if-exists :append :if-does-not-exist :create)) )

      (dotimes (count-sim num-of-sim)
        ;;;;;;;;train part;;;;;;;;;
        (reset)
        (clear-log-vars)

        (dolist (m (mp-models))
          (with-model-eval m
            (setf trace-log-train (concatenate 'string log-dir "trace-train-" (write-to-string m) "-" log-file "-mp" (write-to-string param-mp) "-"   start-time ".txt"))
            (update-params param-mp (when param-v trace-log-train))

            (install-device window)
            ))
        
        ;;;;;;enable and disable productions for train traials
        (dolist (m (mp-models))
          (with-model-eval m
            (penable image-past-answer-train image-my-answer-train check-myanswer-used-train)
            (pdisable image-past-answer-test image-my-answer-test check-myanswer-used-test) ))
        (with-model P1
          (penable vocalize-myanswer-error-train vocalize-myanswer-train)
          (pdisable vocalize-myanswer-error-test vocalize-myanswer-test))
        (with-model P2 
          (penable attend-kana retrieve-mora get-hint detected-sound-p2-train)
          (pdisable detected-sound-p2-test))


        ;;(> 10000 (mp-time))
        ;(loop while (and (> 100 (mp-time)) (< *chain-counter* chain-count))
        ;    do (progn (dolist (m (mp-models))
        ;        (with-model-eval m (proc-display)))
        ;      (run run-time :real-time real-time))
        ;    )
        ;;;(and (> 100 (mp-time)) (< *chain-counter* chain-count))
        ;;;simulation time limit: 100 = 0.1 * 1000
        (dotimes (x num-of-run)
          (dolist (m (mp-models))
            (with-model-eval m (proc-display)) )
          (run run-time :real-time real-time) )

        ;;;;print progress
        (format t "TRAIN mp:~A simulation:~A time:~A~%~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))
        (format time-stamp "TRAIN mp:~A simulation:~A time:~A~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))

        (export-log log-file-train count-sim) )
      (close time-stamp) )))


;;;;;;;;;;;;;;;;;
;;;train and test
;;;;;;;;;;;;;;;;;

(defun run-train-test (sim-time num-of-sim log-file param-mp &optional (param-v nil) (real-time nil) (run-time 0.1))
  (let (
    (log-dir (concatenate 'string "./log/" log-file "/")) )
    (ensure-directories-exist log-dir)

    (let (
      (start-time (write-to-string (get-universal-time)))
      (log-file-train (concatenate 'string log-dir log-file "-train-" (write-to-string param-mp) ".csv"))
      (log-file-test (concatenate 'string log-dir log-file "-test-" (write-to-string param-mp) ".csv"))
      (trace-log-train nil)
      (trace-log-test nil)
      (window (with-model p1 (open-exp-window "game" :height 100 :width 200)))
      (num-of-run (ceiling (/ sim-time run-time)))
      (time-stamp (open (concatenate 'string log-dir log-file "-time-stamp.txt") :direction :output :if-exists :append :if-does-not-exist :create)) )

      (dotimes (count-sim num-of-sim)
        ;;;;;;;;train part;;;;;;;;;
        (reset)
        (clear-log-vars)

        (dolist (m (mp-models))
          (with-model-eval m
            (setf trace-log-train (concatenate 'string log-dir "trace-train-" (write-to-string m) "-" log-file "-mp" (write-to-string param-mp) "-"   start-time ".txt"))
            (update-params param-mp (when param-v trace-log-train))

            (install-device window)
            ))
        
        ;;;;;;enable and disable productions for train traials
        (dolist (m (mp-models))
          (with-model-eval m
            (penable image-past-answer-train image-my-answer-train check-myanswer-used-train)
            (pdisable image-past-answer-test image-my-answer-test check-myanswer-used-test) ))
        (with-model P1
          (penable vocalize-myanswer-error-train vocalize-myanswer-train)
          (pdisable vocalize-myanswer-error-test vocalize-myanswer-test))
        (with-model P2 
          ;(penable attend-kana retrieve-mora get-hint detected-sound-p2-train)
          (penable attend-kana-and-sound retrieve-mora-and-set-partner-answer get-hint attend-vis-loc)
          (pdisable detected-sound-p2-test))


        ;;(> 10000 (mp-time))
        ;(loop while (and (> 100 (mp-time)) (< *chain-counter* chain-count))
        ;    do (progn (dolist (m (mp-models))
        ;        (with-model-eval m (proc-display)))
        ;      (run run-time :real-time real-time))
        ;    )
        ;;;(and (> 100 (mp-time)) (< *chain-counter* chain-count))
        ;;;simulation time limit: 100 = 0.1 * 1000
        (dotimes (x num-of-run)
          (dolist (m (mp-models))
            (with-model-eval m (proc-display)) )
          (run run-time :real-time real-time) )

        ;;;;print progress
        (format t "TRAIN mp:~A simulation:~A time:~A~%~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))
        (format time-stamp "TRAIN mp:~A simulation:~A time:~A~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))

        (export-log log-file-train count-sim)

        ;;;;;;;;test part;;;;;;;;;
        (clear-log-vars)

        (dolist (m (mp-models))
          (with-model-eval m
            (setf trace-log-test (concatenate 'string log-dir "trace-test-" (write-to-string m) "-" log-file "-mp" (write-to-string param-mp) "-"   start-time ".txt"))
            (update-params param-mp (when param-v trace-log-test)) ))
        ;;;;;;enable and disable productions for train traials
        (dolist (m (mp-models))
          (with-model-eval m
            (remove-all-items-from-rpm-window window)
            (clear-buffer 'goal)
            (penable image-past-answer-test image-my-answer-test check-myanswer-used-test)
            (pdisable image-past-answer-train image-my-answer-train check-myanswer-used-train) ))
        ;blank?
        (run 5)
        (run 5)
        (format t "blank")

        (with-model P1
          (goal-focus answer-p1)
          (install-device window)
          (penable vocalize-myanswer-error-test vocalize-myanswer-test)
          (pdisable vocalize-myanswer-error-train vocalize-myanswer-train) )
        (with-model P2
          (goal-focus answer-p2)
          (install-device window)
          (penable detected-sound-p2-test)
          (pdisable attend-kana-and-sound retrieve-mora-and-set-partner-answer get-hint attend-vis-loc))

        ;;;simulation time limit: 100 = 0.1 * 1000
        (dotimes (x num-of-run)
          (dolist (m (mp-models))
            (with-model-eval m (proc-display)) )
          (run run-time :real-time real-time) )

        ;;;;print progress
        (format t "TEST mp:~A simulation:~A time:~A~%~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))
        (format time-stamp "TEST mp:~A simulation:~A time:~A~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))

        (export-log log-file-test count-sim)
        )
      (close time-stamp) )))


(defun ex-tt (sim-time num-of-sim log-file &optional (param-v nil) (real-time nil) (run-time 0.1))
  (let (
      (mp-list '(1 10 20 30 40 50 60 70 80 90 100))
      ;(mp-list '(30 40 50 60 70 80 90 100))
      )

    (dolist (param-mp mp-list)
      (run-train-test sim-time num-of-sim log-file param-mp param-v real-time run-time) )))


;(load "./wc_va_p1.lisp")
;(load "./wc_va_p2.lisp")
(load "./wc_va_p1_rr.lisp")
;(load "./wc_va_p2_rr.lisp")
(load "./wc_va_p2_same_time.lisp")