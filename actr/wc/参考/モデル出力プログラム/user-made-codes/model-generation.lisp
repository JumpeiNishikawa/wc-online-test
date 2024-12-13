(in-package :cl-user)
(ql:quickload :cl-emb)
(defpackage the-game.model-generation
  (:use :cl :cl-emb)
  (:export make-the-game-model output *model-num*))
(in-package :the-game.model-generation)

(delete-package :cl-emb-intern)
(setf *function-package* (find-package :the-game.model-generation))

(deftype what-to-remember-type () '(member :as-is :cumulative))
(deftype search-method-type () '(member :complete :outcome-weight-large :outcome-weight-small))
(deftype how-to-use-cases-type () '(member :case-base :imitation))

(defclass the-game-model ()
  ((what-to-remember :reader what-to-remember :initarg :what-to-remember :type what-to-remember-type)
   (search-method :reader search-method :initarg :search-method :type search-method-type)
   (how-to-use-cases :reader how-to-use-cases :initarg :how-to-use-cases :type how-to-use-cases-type)))

(defun make-the-game-model (what-to-remember search-method how-to-use-cases)
  (check-type what-to-remember what-to-remember-type)
  (check-type search-method search-method-type)
  (check-type how-to-use-cases how-to-use-cases-type)
  (make-instance 'the-game-model :what-to-remember what-to-remember :search-method search-method :how-to-use-cases how-to-use-cases))

(defvar *model-num* "")

(defmethod model-name ((model the-game-model))
  (format nil "~a+~a+~a-~a" (what-to-remember model) (search-method model) (how-to-use-cases model) *model-num*))

(defmethod mismatch-penalty ((model the-game-model))
  (case (search-method model)
    (:complete nil)
    ((:outcome-weight-large :outcome-weight-small) 10.0)))

(defmethod maximum-difference ((model the-game-model))
  (case (search-method model)
    (:outcome-weight-large "(sgp :md -100)")
    (otherwise "")))

(defmethod do-not-harvest-imaginal ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "")
    (:cumulative "(sgp :do-not-harvest imaginal)")))

(defmethod learned-info ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "(chunk-type learned-info m-1st m-2nd m-3rd m-4th m-5th o-1st o-2nd o-3rd o-4th o-5th mresult)")
    (:cumulative "(chunk-type learned-info m-1st m-2nd m-3rd m-4th o-1st o-2nd o-3rd o-4th mresult)")))

(defmethod similarities ((model the-game-model))
  (case (search-method model)
    (:complete "")
    (:outcome-weight-large "(set-similarities (win lose -100) (win draw -50) (lose draw -50))")
    (:outcome-weight-small "(set-similarities (win lose -1) (win draw -0.5) (lose draw -0.5))")))

(defmethod retrieve-win ((model the-game-model))
  (case (how-to-use-cases model)
    (:case-base "mresult win")
    (:imitation "")))

(defmethod 2nd-start ((model the-game-model))
  (concatenate 'string
    (case (what-to-remember model)
      (:as-is "(p 2nd-start
     =goal>
       isa game-state
       state start
     - m-1st nil
       m-2nd nil
       m-1st =m1
       o-1st =o1
    ==>
     =goal>
       state retrieving
     +retrieval>
       isa learned-info
       m-1st =m1
       o-1st =o1
       ")
      (:cumulative "(p 2nd-start
     =goal>
       isa game-state
       state start
     - m-1st nil
       m-2nd nil
       o-1st =o
     =imaginal>
       isa learned-info
       m-1st =m
    ==>
     =goal>
       state retrieving
     =imaginal>
       o-1st =o
     +retrieval>
       isa learned-info
       m-1st =m
       o-1st =o
       "))
    (retrieve-win model) ")"))

(defmethod 3rd-start ((model the-game-model))
  (concatenate 'string
    (case (what-to-remember model)
      (:as-is "(p 3rd-start
     =goal>
       isa game-state
       state start
     - m-2nd nil
       m-3rd nil
       m-1st =m1
       m-2nd =m2
       o-1st =o1
       o-2nd =o2
    ==>
     =goal>
       state retrieving
     +retrieval>
       isa learned-info
       m-1st =m1
       m-2nd =m2
       o-1st =o1
       o-2nd =o2
       ")
      (:cumulative "(p 3rd-opponent-add-before
     =goal>
       isa game-state
       state start
     - m-2nd nil
       m-3rd nil
       o-2nd =act
     =imaginal>
       isa learned-info
       o-1st =last
    ==>
     =goal>
       state opponent-adding
     +retrieval>
       isa addition-fact
       addend1 =last
       addend2 =act)
  (p 3rd-opponent-add-after
     =goal>
       isa game-state
       state opponent-adding
     - m-2nd nil
       m-3rd nil
     =imaginal>
       isa learned-info
       m-2nd =m
     =retrieval>
       isa addition-fact
       sum =o
    ==>
     =goal>
       state retrieving
     =imaginal>
       o-2nd =o
     +retrieval>
       isa learned-info
       m-2nd =m
       o-2nd =o
       "))
    (retrieve-win model) ")"))

(defmethod 4th-start ((model the-game-model))
  (concatenate 'string
    (case (what-to-remember model)
      (:as-is "(p 4th-start
     =goal>
       isa game-state
       state start
     - m-3rd nil
       m-4th nil
       m-1st =m1
       m-2nd =m2
       m-3rd =m3
       o-1st =o1
       o-2nd =o2
       o-3rd =o3
    ==>
     =goal>
       state retrieving
     +retrieval>
       isa learned-info
       m-1st =m1
       m-2nd =m2
       m-3rd =m3
       o-1st =o1
       o-2nd =o2
       o-3rd =o3
       ")
      (:cumulative "(p 4th-opponent-add-before
     =goal>
       isa game-state
       state start
     - m-3rd nil
       m-4th nil
       o-3rd =act
     =imaginal>
       isa learned-info
       o-2nd =last
    ==>
     =goal>
       state opponent-adding
     +retrieval>
       isa addition-fact
       addend1 =last
       addend2 =act)
  (p 4th-opponent-add-after
     =goal>
       isa game-state
       state opponent-adding
     - m-3rd nil
       m-4th nil
     =imaginal>
       isa learned-info
       m-3rd =m
     =retrieval>
       isa addition-fact
       sum =o
    ==>
     =goal>
       state retrieving
     =imaginal>
       o-3rd =o
     +retrieval>
       isa learned-info
       m-3rd =m
       o-3rd =o
       "))
    (retrieve-win model) ")"))

(defmethod 5th-start ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "(p 5th-start
     =goal>
       isa game-state
       state start
     - m-4th nil
       m-5th nil
    ==>
     =goal>
       state random)")
    (:cumulative "(p 5th-opponent-add-before
     =goal>
       isa game-state
       state start
     - m-4th nil
       m-5th nil
       o-4th =act
     =imaginal>
       isa learned-info
       o-3rd =last
    ==>
     =goal>
       state opponent-adding
     +retrieval>
       isa addition-fact
       addend1 =last
       addend2 =act)
  (p 5th-opponent-add-after
     =goal>
       isa game-state
       state opponent-adding
     - m-4th nil
       m-5th nil
     =imaginal>
     =retrieval>
       isa addition-fact
       sum =o
    ==>
     =goal>
       state random
     =imaginal>
       o-4th =o)")))

(defmethod imitation-remember-game-1st ((model the-game-model))
  (case (how-to-use-cases model)
    (:case-base "")
    (:imitation "(p imitation-remember-game-1st
     =goal>
       isa game-state
       state retrieving
       m-1st nil
     =retrieval>
       isa learned-info
       mresult lose
       o-1st =act
    ==>
     =goal>
       state confirming
       want =act
     @retrieval>)")))

(defmethod case-base-remember-game-2nd ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "(p case-base-remember-game-2nd
     =goal>
       isa game-state
       state retrieving
     - m-1st nil
       m-2nd nil
     =retrieval>
       isa learned-info
       mresult win
       m-2nd =act
    ==>
     =goal>
       state confirming
       want =act
     @retrieval>)")
    (:cumulative "(p case-base-remember-game-2nd
     =goal>
       isa game-state
       state retrieving
     - m-1st nil
       m-2nd nil
     =imaginal>
       isa learned-info
       m-1st =last
     =retrieval>
       isa learned-info
       mresult win
       m-2nd =sum
    ==>
     =goal>
       state subtracting
     @retrieval>
     +retrieval>
       isa addition-fact
       addend1 =last
       sum =sum)")))

(defmethod imitation-remember-game-2nd ((model the-game-model))
  (case (how-to-use-cases model)
    (:case-base "")
    (:imitation
     (case (what-to-remember model)
       (:as-is "(p imitation-remember-game-2nd
     =goal>
       isa game-state
       state retrieving
     - m-1st nil
       m-2nd nil
     =retrieval>
       isa learned-info
       mresult lose
       o-2nd =act
    ==>
     =goal>
       state confirming
       want =act
     @retrieval>)")
       (:cumulative "(p imitation-remember-game-2nd
     =goal>
       isa game-state
       state retrieving
     - m-1st nil
       m-2nd nil
     =imaginal>
       isa learned-info
       m-1st =last
     =retrieval>
       isa learned-info
       mresult lose
       o-2nd =sum
    ==>
     =goal>
       state subtracting
     @retrieval>
     +retrieval>
       isa addition-fact
       addend1 =last
       sum =sum)")))))

(defmethod case-base-remember-game-3rd ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "(p case-base-remember-game-3rd
     =goal>
       isa game-state
       state retrieving
     - m-2nd nil
       m-3rd nil
     =retrieval>
       isa learned-info
       mresult win
       m-3rd =act
    ==>
     =goal>
       state confirming
       want =act
     @retrieval>)")
    (:cumulative "(p case-base-remember-game-3rd
     =goal>
       isa game-state
       state retrieving
     - m-2nd nil
       m-3rd nil
     =imaginal>
       isa learned-info
       m-2nd =last
     =retrieval>
       isa learned-info
       mresult win
       m-3rd =sum
    ==>
     =goal>
       state subtracting
     @retrieval>
     +retrieval>
       isa addition-fact
       addend1 =last
       sum =sum)")))

(defmethod imitation-remember-game-3rd ((model the-game-model))
  (case (how-to-use-cases model)
    (:case-base "")
    (:imitation
     (case (what-to-remember model)
       (:as-is "(p imitation-remember-game-3rd
     =goal>
       isa game-state
       state retrieving
     - m-2nd nil
       m-3rd nil
     =retrieval>
       isa learned-info
       mresult lose
       o-3rd =act
    ==>
     =goal>
       state confirming
       want =act
     @retrieval>)")
       (:cumulative "(p imitation-remember-game-3rd
     =goal>
       isa game-state
       state retrieving
     - m-2nd nil
       m-3rd nil
     =imaginal>
       isa learned-info
       m-2nd =last
     =retrieval>
       isa learned-info
       mresult lose
       o-3rd =sum
    ==>
     =goal>
       state subtracting
     @retrieval>
     +retrieval>
       isa addition-fact
       addend1 =last
       sum =sum)")))))

(defmethod case-base-remember-game-4th ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "(p case-base-remember-game-4th
     =goal>
       isa game-state
       state retrieving
     - m-3rd nil
       m-4th nil
     =retrieval>
       isa learned-info
       mresult win
       m-4th =act
    ==>
     =goal>
       state confirming
       want =act
     @retrieval>)")
    (:cumulative "(p case-base-remember-game-4th
     =goal>
       isa game-state
       state retrieving
     - m-3rd nil
       m-4th nil
     =imaginal>
       isa learned-info
       m-3rd =last
     =retrieval>
       isa learned-info
       mresult win
       m-4th =sum
    ==>
     =goal>
       state subtracting
     @retrieval>
     +retrieval>
       isa addition-fact
       addend1 =last
       sum =sum)")))

(defmethod imitation-remember-game-4th ((model the-game-model))
  (case (how-to-use-cases model)
    (:case-base "")
    (:imitation
     (case (what-to-remember model)
       (:as-is "(p imitation-remember-game-4th
     =goal>
       isa game-state
       state retrieving
     - m-3rd nil
       m-4th nil
     =retrieval>
       isa learned-info
       mresult lose
       o-4th =act
    ==>
     =goal>
       state confirming
       want =act
     @retrieval>)")
       (:cumulative "(p imitation-remember-game-4th
     =goal>
       isa game-state
       state retrieving
     - m-3rd nil
       m-4th nil
     =imaginal>
       isa learned-info
       m-3rd =last
     =retrieval>
       isa learned-info
       mresult lose
       o-4th =sum
    ==>
     =goal>
       state subtracting
     @retrieval>
     +retrieval>
       isa addition-fact
       addend1 =last
       sum =sum)")))))

(defmethod remember-lost-game ((model the-game-model))
  (case (how-to-use-cases model)
    (:case-base "(p remember-lost-game
     =goal>
       isa game-state
       state retrieving
     =retrieval>
       isa learned-info
       mresult lose
    ==>
     =goal>
       state random
     @retrieval>)")
    (:imitation "")))

(defmethod subtract-after ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "")
    (:cumulative "(p subtract-after
     =goal>
       isa game-state
       state subtracting
     =retrieval>
       isa addition-fact
       addend2 =act
    ==>
     =goal>
       state confirming
       want =act)")))

(defmethod submit-or-memorize ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "submitting")
    (:cumulative "memorizing")))

(defmethod memorizing-productions ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "")
    (:cumulative "(p 1st-memorize
     =goal>
       isa game-state
       state memorizing
       m-1st nil
       want =act
    ==>
     =goal>
       state submitting
     +imaginal>
       isa learned-info
       m-1st =act)
  
  (p 2nd-model-add-before
     =goal>
       isa game-state
       state memorizing
     - m-1st nil
       m-2nd nil
       want =act
     =imaginal>
       isa learned-info
       m-1st =last
    ==>
     =goal>
       state model-adding
     +retrieval>
       isa addition-fact
       addend1 =last
       addend2 =act)
  
  (p 2nd-model-add-after
     =goal>
       isa game-state
       state model-adding
     - m-1st nil
       m-2nd nil
     =imaginal>
       isa learned-info
     =retrieval>
       isa addition-fact
       sum =sum
    ==>
     =goal>
       state submitting
     =imaginal>
       m-2nd =sum)
  
  (p 3rd-model-add-before
     =goal>
       isa game-state
       state memorizing
     - m-2nd nil
       m-3rd nil
       want =act
     =imaginal>
       isa learned-info
       m-2nd =last
    ==>
     =goal>
       state model-adding
     +retrieval>
       isa addition-fact
       addend1 =last
       addend2 =act)
  
  (p 3rd-model-add-after
     =goal>
       isa game-state
       state model-adding
     - m-2nd nil
       m-3rd nil
     =imaginal>
       isa learned-info
     =retrieval>
       isa addition-fact
       sum =sum
    ==>
     =goal>
       state submitting
     =imaginal>
       m-3rd =sum)
  
  (p 4th-model-add-before
     =goal>
       isa game-state
       state memorizing
     - m-3rd nil
       m-4th nil
       want =act
     =imaginal>
       isa learned-info
       m-3rd =last
    ==>
     =goal>
       state model-adding
     +retrieval>
       isa addition-fact
       addend1 =last
       addend2 =act)
  
  (p 4th-model-add-after
     =goal>
       isa game-state
       state model-adding
     - m-3rd nil
       m-4th nil
     =imaginal>
       isa learned-info
     =retrieval>
       isa addition-fact
       sum =sum
    ==>
     =goal>
       state submitting
     =imaginal>
       m-4th =sum)
  
  (p 5th-memorize
     =goal>
       isa game-state
       state memorizing
     - m-4th nil
       m-5th nil
    ==>
     =goal>
       state submitting)")))

(defmethod imagine-result ((model the-game-model))
  (case (what-to-remember model)
    (:as-is "(p imagine-result
     =goal>
       isa game-result
       state result
       m-1st =m1
       m-2nd =m2
       m-3rd =m3
       m-4th =m4
       m-5th =m5
       o-1st =o1
       o-2nd =o2
       o-3rd =o3
       o-4th =o4
       o-5th =o5
       mresult =res
     ?imaginal>
       state free
    ==>
     =goal>
       state clearing
     +imaginal>
       isa learned-info
       m-1st =m1
       m-2nd =m2
       m-3rd =m3
       m-4th =m4
       m-5th =m5
       o-1st =o1
       o-2nd =o2
       o-3rd =o3
       o-4th =o4
       o-5th =o5
       mresult =res)")
    (:cumulative "(p imagine-result
     =goal>
       isa game-result
       state result
       mresult =res
     =imaginal>
       isa learned-info
    ==>
     =goal>
       state clearing
     =imaginal>
       mresult =res)")))

(defvar *model*)

(defmethod output ((model the-game-model))
  (let ((*model* model))
    (execute-emb #p"user-made-codes/model-template.lisp")))
