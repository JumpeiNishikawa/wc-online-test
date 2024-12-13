#+:packaged-actr (in-package :act-r)
#+(and :clean-actr (not :packaged-actr) :ALLEGRO-IDE) (in-package :cg-user)
#-(or (not :clean-actr) :packaged-actr :ALLEGRO-IDE) (in-package :cl-user)

(defvar *critical-params* '(:MD :RT :LE :MS :MP :PAS :MAS :ANS :BLC :LF 
                            :BLL :ESC :ER :OL :IU :UL :ALPHA :UT :NU 
                            :EGS :EPL :TT :DAT :PPM))

(defvar *default-chunk-types*
    (let ((dummy-name (gensym)))
      (prog2
        (define-meta-process-fct dummy-name)
        (with-meta-process-eval dummy-name
          (define-model dummy)
          (setf *critical-params*
            (mapcar (lambda (x) (list x (car (no-output (sgp-fct (list x)))))) *critical-params*))
          (all-chunk-type-names))
        (delete-meta-process-fct dummy-name))))


(defun my-save-chunks (file-name chunks &optional (zero-ref t))
  (let (
    (cmdt (car (no-output (sgp :cmdt)))) )
  
  (unwind-protect
      (progn
          ;;;set output file
          (sgp-fct (list :cmdt file-name))
          
          ;;;write out model name and time
          (multiple-value-bind (sec min hour date month year) (get-decoded-time)
            (command-output ";;; Saved version of model ~s at run time ~f on ~d/~d/~d ~d:~2,'0d:~2,'0d"
                            (current-model) (mp-time) year month date hour min sec))
          

          ;;;write out  general parameters (sgp)
          (command-output "~%(sgp ")
          
          (dolist (param *critical-params*)
            (unless (equalp (second param) (car (no-output (sgp-fct (list (first param))))))
              (command-output "~s ~s" (first param) (car (no-output (sgp-fct (list (first param))))))))
          
          (command-output ")")

          ;;; Write out the current seed in a comment if continuing exactly is desired
          
          (command-output "~%;;; (sgp :seed ~s)~%" (no-output (car (sgp :seed))))

          ;;; If declarative options are enabled write out the necessary parameters
          
          (let ((esc (no-output (car (sgp :esc))))
                (mp (no-output (car (sgp :mp))))
                (bll (no-output (car (sgp :bll))))
                (ol (no-output (car (sgp :ol))))
                (params nil))
            
            (when (and esc (or mp bll))
              
              (when mp (push :similarities params))
              
              (cond ((null bll)
                     ;;; no extra params needed
                     )
                    ((null ol)
                     ;;; need creation and list
                     (push :reference-list params)
                     (push :creation-time params))
                    ((numberp ol)
                     (push :reference-list params)
                     (push :reference-count params)
                     (push :creation-time params))
                    (t ;;; :ol is t
                     (push :reference-count params)
                     (push :creation-time params)))
              
              (dolist (c chunks)
                (command-output "(sdp ~a" c)
                (dolist (param params)
                  (let ((val (caar (no-output (sdp-fct (list c param))))))
                    (case param
                      (:similarities 
                       (command-output "  ~s (~{~s~})" param val))
                      (:creation-time
                       (command-output "  ~s ~f" param (if zero-ref (- val (mp-time)) val)))
                      (:reference-count
                       (command-output "  ~s ~d" param val))
                      (:reference-list
                       (command-output "  ~s (~{~F~^ ~})" param (if zero-ref (mapcar (lambda (x) (- x (mp-time))) val) val))))))
                (command-output ")")
                (command-output ""))))
          
          (command-output "")
          (command-output "")
          (command-output "(format t \"previous trial activation saved, file: ~A~%\")" file-name)

          (sgp-fct (list :cmdt cmdt))
          ))))