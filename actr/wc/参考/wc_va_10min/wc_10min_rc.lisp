(clear-all)

(defvar *param-mp*)
(defun set-params (param-mp param-v)
      (sgp-fct `(
        :esc t
        :lf  0.05
        :ans .5
        :rt  -5
        :bll 0.5

        :ol t

        :v ,param-v
        :act nil;,(if param-v t nil)
        :cmdt nil;,(if param-v t nil)

        :mp ,(if (eq (current-model) 'P2) param-mp nil)
        :md ,(if (eq (current-model) 'P2) -100 0)
        :mas ,(if (eq (current-model) 'P2) 5 nil)
        :imaginal-activation ,(if (eq (current-model) 'P2) 1.0 0) ))

  (setf *param-mp* param-mp) )

;;;my-save-chunks()
(load "./pre-my-save-chunks.lisp")
;;;(load "~/actr7/extras/save-model/save-chunks-and-productions.lisp")
(load "./manipulate-reference-count.lisp")

;(actr-load "./wordlist/mora_kana.lisp")
;(actr-load "./wordlist/mora_rensou_test.lisp")
;(actr-load "./wordlist/word_mora_test.lisp")
(load "./wordlist/mora-kana.lisp")
(load "./wordlist/mora-rensou-test.lisp")
(load "./wordlist/word-mora-test.lisp")

(load "./wc_va_p1_rr.lisp")
(load "./wc_va_p2_visloc.lisp")

(defvar *chunks-list*)
(setf *chunks-list* (concatenate 'list *mora-kana* *mora-rensou* *word-mora*))
(defvar *chunk-name-list*)
(setf *chunk-name-list* (mapcar #'car *chunks-list*))

(defvar *mora-chunk-name-list*)
(setf *mora-chunk-name-list* (mapcar #'car *mora-kana*))
(defvar *word-chunk-name-list*)
(setf *word-chunk-name-list* (mapcar #'car *mora-rensou*))

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

(defvar *kana-list*)
(setf *kana-list* '(a-mora i-mora u-mora e-mora o-mora ja-mora ju-mora jo-mora ka-mora ki-mora ku-mora ke-mora ko-mora kja-mora kju-mora kjo-mora ga-mora gi-mora gu-mora ge-mora go-mora gja-mora gju-mora gjo-mora sa-mora si-mora su-mora se-mora so-mora sja-mora sju-mora sjo-mora za-mora zi-mora zu-mora ze-mora zo-mora zja-mora zju-mora zjo-mora ta-mora ti-mora tu-mora te-mora to-mora tja-mora tju-mora tjo-mora da-mora de-mora do-mora na-mora ni-mora nu-mora ne-mora no-mora nju-mora njo-mora ha-mora hi-mora hu-mora he-mora ho-mora hja-mora hju-mora hjo-mora pa-mora pi-mora pu-mora pe-mora po-mora pju-mora ba-mora bi-mora bu-mora be-mora bo-mora bja-mora bju-mora bjo-mora ma-mora mi-mora mu-mora me-mora mo-mora mja-mora mju-mora mjo-mora ra-mora ri-mora ru-mora re-mora ro-mora rja-mora rju-mora rjo-mora wa-mora N-mora R-mora Q-mora))
;nja-mora pja-mora pjo-mora

(defvar *mora-list*)
(setf *mora-list* '(a i u e o ja ju jo ka ki ku ke ko kja kju kjo ga gi gu ge go gja gju gjo sa si su se so sja sju sjo za zi zu ze zo zja zju zjo ta ti tu te to tja tju tjo da de do na ni nu ne no nju njo ha hi hu he ho hja hju hjo pa pi pu pe po pju ba bi bu be bo bja bju bjo ma mi mu me mo mja mju mjo ra ri ru re ro rja rju rjo wa))
;; N R Q

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




(defun update-params (param-mp param-v)
      (sgp-fct `(

        :v ,param-v
        :act ,(if param-v t nil)
        :cmdt ,(if param-v t nil)

        :mp ,(if (eq (current-model) 'P2) param-mp nil) ))

  (setf *param-mp* param-mp) )


(defun run-n-times (sim-time num-of-sim trial-count log-file-name param-mp &optional (param-v nil) (real-time nil) (run-time 0.1))
  (let (
    (log-dir (concatenate 'string "./log/" log-file-name "/")) )
    (ensure-directories-exist log-dir)

    (let (
      (start-time (write-to-string (get-universal-time)))
      (log-file (concatenate 'string log-dir log-file-name  "-" (write-to-string trial-count) "-" (write-to-string param-mp) ".csv"))
      (trace-log nil)
      (window (with-model p1 (open-exp-window "game" :height 100 :width 200)))
      (num-of-run (ceiling (/ sim-time run-time)))
      (time-stamp (open (concatenate 'string log-dir log-file-name "-" (write-to-string trial-count) "-time-stamp.txt") :direction :output :if-exists :append :if-does-not-exist :create)) 
      (pre-act-file-p1)
      (pre-act-file-p2))

      (dotimes (count-sim num-of-sim)
        (reset)
        (clear-log-vars)
        (let (
          (act-file-p1 (concatenate 'string log-dir log-file-name "-activatoin-p1-" (write-to-string trial-count) "-" (write-to-string count-sim) ".lisp"))
          (act-file-p2 (concatenate 'string log-dir log-file-name "-activatoin-p2-" (write-to-string trial-count) "-" (write-to-string count-sim) ".lisp"))
          )

        (with-model p1 (add-dm-fct *chunks-list*))
        (with-model p2 (add-dm-fct *chunks-list*))
        (with-model p2 (load "./wordlist/mora_sim.lisp"))

        ;;;;import activations
        (format t "previous trial activation loaded, file: ~A~%" pre-act-file-p1)
        (unless (null pre-act-file-p1)
          ;(format t "activation load")
          (with-model p1 (load pre-act-file-p1))
          (with-model p2 (load pre-act-file-p2)) )

        (dolist (m (mp-models))
          (with-model-eval m
            (setf trace-log (concatenate 'string log-dir "trace-" (write-to-string m) "-" log-file "-mp" (write-to-string param-mp) "-"   start-time ".txt"))
            (update-params param-mp (when param-v trace-log)) ))
        ;;;;;;enable and disable productions for train traials
        (dolist (m (mp-models))
          (with-model-eval m
            (remove-all-items-from-rpm-window window)
            (clear-buffer 'goal)
            (penable image-past-answer-test image-my-answer-test check-myanswer-used-test)
            (pdisable image-past-answer-train image-my-answer-train check-myanswer-used-train) ))
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
          ;;;RUN;;;;;;;
          (run run-time :real-time real-time) )

        ;;;;print progress
        (format t "TEST mp:~A simulation:~A time:~A~%~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))
        (format time-stamp "TEST mp:~A simulation:~A time:~A~%" (write-to-string param-mp) (write-to-string count-sim) (get-formatted-time))

        ;;;export log and activation
        (export-log log-file count-sim)
        
        (with-model p1 (my-save-chunks act-file-p1 *chunk-name-list*) )
        (with-model p2 (my-save-chunks act-file-p2 *chunk-name-list*) )
        ;(with-model p1 (save-chunks-and-productions act-file-p1) )
        ;(with-model p2 (save-chunks-and-productions act-file-p1) )
        ;(format t "pre:~A now:~A~%" pre-act-file-p1 act-file-p1)
        ;(setf pre-act-file-p1 act-file-p1)
        ;(setf pre-act-file-p2 act-file-p2) 
        (setf pre-act-file-p1 (manipulate-references act-file-p1 *word-chunk-name-list*))
        (setf pre-act-file-p2 (manipulate-references act-file-p2 *word-chunk-name-list*))  )
        
         )
      (close time-stamp) )))

(defun n-trial (sim-time num-of-run num-of-trial log-file &optional (param-mp 10))
  (dotimes (trial-count num-of-trial)
    (run-n-times sim-time num-of-run trial-count log-file param-mp) ))