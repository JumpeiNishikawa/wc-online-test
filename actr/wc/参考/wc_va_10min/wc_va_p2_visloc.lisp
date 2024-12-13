;;; SET :recently-retrieved nil AT retrieve-myanswer-by-head-char
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PLAYER2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-model P2
  (set-params nil nil)
  ;(sgp
  ;    :esc t
  ;    :lf  0.05
  ;    :ans 0.5
  ;    :rt  -5
  ;    :bll 0.5
;
  ;    :mas 5
  ;    :imaginal-activation 1.0
;
  ;    :v nil
  ;    :cmdt nil
  ;    )
    (chunk-type word-inf word sound)
    (chunk-type word-mora wm-word mora pos-head pos-tail)
    (chunk-type kana mean string)
    (chunk-type answer-word a-word a-head a-tail state past-tail past-answer)
    (chunk-type past past-string past-word traial)
    ;;;traial is train or test

    (chunk-type hint mora)

    ;(actr-load "./wordlist/mora_kana.lisp")
    ;(actr-load "./wordlist/mora_rensou_test.lisp")
    ;(actr-load "./wordlist/word_mora_test.lisp")
    ;(load "./wordlist/mora_sim.lisp")
    (add-dm
      (answer-p2 ISA answer-word state start-p2) )

    (goal-focus answer-p2)

    (set-audloc-default
      - location self
      - location internal
      :attended nil)

;(P find-kana-hint
;    =goal>
;      ISA answer-word
;      state start-p2
;    ?visual-location>
;      buffer unrequested
;    ==>
;    +visual-location>
;      :attended    nil
;    =goal>
;      state       find-location
;)
;
;(P find-kana-fail
;  =goal>
;    ISA answer-word
;    state find-location
;  ?visual-location>
;    buffer failure
;  ==>
;  =goal>
;    ISA answer-word
;    state start-p2
;)
(P attend-vis-loc
    =goal>
    ISA answer-word
    state       start-p2;find-location
    ?visual-location>
      buffer empty
==>
    =goal>
    +visual-location>
      ISA visual-location

  !output! (attend-visloc)
)

(P attend-kana-and-sound
    =goal>
    ISA answer-word
    state       start-p2;find-location
    =visual-location>
    ?visual>
      state       free
    =aural-location>
    ?aural>
      state   free
==>
    +visual>
      cmd         move-attention
      screen-pos  =visual-location
    +aural>
      event =aural-location

    =goal>
      state       attend

    !eval! (sgp :mp nil)
    !output! (detected-sound)
    !output! (=aural-location)
  ;!eval! (format t "model:~A mp:~A~%" (current-model) (sgp :mp))
)

(P retrieve-mora-and-set-partner-answer
    =goal>
        ISA answer-word
        state       attend
    =aural>
      ISA sound
      content =word
    =visual>
        value       =kana
    ?retrieval>
        state       free
    ==>
    =goal>
        ISA answer-word
        state       get-hint
        a-word =word
    +retrieval>
        isa kana
        string =kana
        - mean nil
    !output! (retrieve =kana)
    !output! (partner answer is =word)
)

(P retrieve-mora-fail
   =goal>
   ISA answer-word
    state       get-hint
   =visual>
   ?retrieval>
      state       failure
==>
   =goal>
      ISA answer-word
      state       attend
)

(P get-hint
  =goal>
  ISA answer-word
    state get-hint
  =retrieval>
    string =kana
    mean =mora
  ?imaginal>
    state free
  ==>
    =goal>
      state       repeat-another-player-answer
   +imaginal>
      isa         hint
      mora      =mora
  !output! (got hint =mora)
  !eval! (sgp-fct `(:mp ,*param-mp*))
  ;!eval! (format t "model:~A mp:~A~%" (current-model) (sgp :mp))
  )

;  (p detected-sound-p2-train
;    =goal>
;      ISA answer-word
;      state got
;    =aural-location>
;    ?aural>
;      state   free
;    ==>
;    =goal>
;      ISA answer-word
;      state set-goal-another-player-answer-sound
;    +aural>
;      event =aural-location
;
;    !output! (detected-sound)
;    !output! (=aural-location)
;  )
;
  (p detected-sound-p2-test
   =goal>
      ISA answer-word
      state start-p2
    =aural-location>
    ?aural>
      state   free
    ==>
    =goal>
      ISA answer-word
      state set-goal-another-player-answer-sound
    +aural>
      event =aural-location

    !output! (detected-sound)
    !output! (=aural-location)
  )

;  (P detected-sound-p2-failure
;    =goal>
;      ISA answer-word
;      state set-goal-another-player-answer-sound
;    =aural-location>
;    ?aural>
;      buffer failure
;    ==>
;    =goal>
;      ISA answer-word
;      state got
;  )

      (P set-goal-answers-meaning
        =goal>
          ISA answer-word
          state set-goal-answers-meaning
          a-word =word
        =retrieval>
          ISA word-inf
          word =mean
          sound =sound
        ==>
        =goal>
          ISA answer-word
          state retrieve-answer-word-tail
          a-word =mean

        !output! (=mean is meaning)
          )


    (P if-error
      =goal>
        ISA answer-word
        state retrieve-answers-meaning
        a-word "ERROR"
        a-head =head
      ==>
      =goal>
        ISA answer-word
        state retrieve-myanswer-by-head-char

      !output! (ERROR now head =head)
        )

    (P vocalize-myanswer
      =goal>
        ISA answer-word
        state vocalize-myanswer
        a-word =myanswer
      ?vocal>
        state free
      ==>
      =goal>
        ISA answer-word
        a-word nil
        state start-p2
      +vocal>
        cmd speak
        string =myanswer
      -aural>

      !output! (answer =myanswer)


      !eval! (push =myanswer P2word-list)
      !eval! (push (- (mp-time) P2last-time) P2time-list)
      !eval! (setf P2last-time (mp-time))

      !eval! (dolist (kana *kana-list*) (push (format nil "{~A:~A}" kana (caar (sdp-fct (list kana :activation)))) P2sdplist))
      !eval! (push "," P2sdplist)
      ; eval! (dolist (kana *error-list*) (push (format nil "{~A:~A}" kana (caar (sdp-fct (list kana :activation)))) P2sdplist))
      !eval! (push "," P2sdplist)
      )

    (P set-goal-another-player-answer-sound
      =goal>
        ISA answer-word
        a-word nil
        state set-goal-another-player-answer-sound
      =aural>
        isa sound
        content =word
      ==>
      =goal>
        ISA answer-word
        state repeat-another-player-answer ;;retrieve-answers-meaning
        a-word =word

      !output! (another player answer is =word)
    )

    (P repeat-another-player-answer
      =goal>
        ISA answer-word
        a-word =answer
        state repeat-another-player-answer
      ?vocal>
        state free
      ==>
      =goal>
        ISA answer-word
        state retrieve-answers-meaning
      +vocal>
        cmd subvocalize
        string =answer

      !output! (repeat =answer)
    )

    (P retrieve-answers-meaning
      =goal>
        ISA answer-word
        state retrieve-answers-meaning
        a-word =sound
      ?retrieval>
        state free
      ==>
      =goal>
        ISA answer-word
        state image-past-answer
      +retrieval>
        ISA word-inf
        sound =sound
    )

    (P retrieve-answers-meaning-fail
      =goal>
        ISA answer-word
        state image-past-answer
                                        ;a-word =word
      ?retrieval>
        buffer failure
      ==>
      =goal>
        ISA answer-word
        state retrieve-answers-meaning
        ;state image-past-answer
        ;+retrieval>
        ;ISA text-inf
        ;text =word
    )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;image another player answer
    (P image-past-answer-train
      =goal>
        ISA answer-word
        state image-past-answer
        a-word =word
      =retrieval>
        sound =sound
      ?imaginal>
        state free
      ==>
      =goal>
        ISA answer-word
        state set-goal-answers-meaning
      =retrieval>
      +imaginal>
        past-word =word
        past-string =sound
        traial train

      !output! (past-word =word =sound)
    )

    (P image-past-answer-test
      =goal>
        ISA answer-word
        state image-past-answer
        a-word =word
      =retrieval>
        sound =sound
      ?imaginal>
        state free
      ==>
      =goal>
        ISA answer-word
        state set-goal-answers-meaning
      =retrieval>
      +imaginal>
        past-word =word
        past-string =sound
        traial test

      !output! (past-word =word =sound)
    )

    (P image-past-answer-fail
      =goal>
        ISA answer-word
        state set-goal-answers-meaning
        a-word =word
        =retrieval>
        sound =sound
      ?imaginal>
        buffer failure
      ==>
      =goal>
        ISA answer-word
        state image-past-answer
        ;state set-goal-answers-meaning
        ;=retrieval>
        ;+imaginal>
        ;past-word =word
        ;past-string =text

      !output! (past-word =word =sound fail)
    )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;only player1 have to retreave answers head char for tutoring
;
;player1 set-goal-answers-meaning -> retrieve-partnaer-answer-head
;player2 set-goal-answers-meaning -> retrieve-answer-word-tail
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    (P set-goal-answers-meaning
;     =goal>
;     ISA answer-word
;     state set-goal-answers-meaning
;     a-word =word
;     =retrieval>
;     ISA text-inf
;     text =text
;     ==>
;     =goal>
;     ISA answer-word
;     state retrieve-answer-word-tail
;     a-word =retrieval
;
;     output! (=retrieval is meaning)
;     )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    (P retrieve-answer-word-tail
      =goal>
        state retrieve-answer-word-tail
        a-word =answer
        ?retrieval>
        state free
      ==>
      =goal>
        state set-goal-answer-word-tail
      +retrieval>
        ISA word-mora
        wm-word =answer
        pos-tail 0
    )
    ;;retrieve-answer-word-tail and -fail is equal "then" . it is ok?
    (P retrieve-answer-word-tail-fail
      =goal>
        state set-goal-answer-word-tail
        a-word =answer
      ?retrieval>
        buffer failure
      ==>
      =goal>
        ISA answer-word
        state retrieve-answer-word-tail
        ;state set-goal-answer-word-tail
        ;+retrieval>
        ;ISA word-tail
        ;meaning =answer
        ;- tail-char nil
    )

    (P set-goal-answer-word-tail
      =goal>
        ISA answer-word
        state set-goal-answer-word-tail
        a-word =answer
      =retrieval>
        ISA word-mora
        wm-word =answer
        mora =tail
        pos-tail 0
      ==>
      =goal>
        ISA answer-word
        a-tail =tail
        state retrieve-tail-char-sound
      !output! (=tail is tail char)
      !eval! (when (equal (current-model) 'p2) (push (concatenate 'string "1:" (string =tail)) used-mora-list1))
    )

    (P retrieve-tail-char-sound
      =goal>
        ISA answer-word
        state retrieve-tail-char-sound
        a-word =answer
        a-tail =tail
      ?retrieval>
        state free
      ==>
      =goal>
        ISA answer-word
        state set-goal-tail-char-sound
      +retrieval>
        mean =tail
    )

    (P retrieve-tail-char-sound-fail
     =goal>
     ISA answer-word
     state set-goal-tail-char-sound
     ;a-word =answer
     ;a-tail =tail
     ?retrieval>
     buffer failure
     ==>
     =goal>
     ISA answer-word
     state retrieve-tail-char-sound
     ;state set-goal-tail-char-sound
     ;+retrieval> =tail
     )

    (P set-goal-tail-char-sound
     =goal>
     ISA answer-word
     state set-goal-tail-char-sound
     a-word =answer
     =retrieval>
     ISA kana
     string =kana
     ==>
     =goal>
     ISA answer-word
     a-tail =kana
     state vocalize-tail-char

     !output! (=kana is tail sound)
     )

    (P vocalize-tail-char
     =goal>
     ISA answer-word
     a-tail =tail
     ;;- a-tail "n"
     state vocalize-tail-char
     ?vocal>
     state free
     ==>
     =goal>
     state retrieve-myanswer-head-char
     +vocal>
     cmd subvocalize
     string =tail

     !output! (vocalize =tail)
     !eval! (when (equal (current-model) 'p2) (push (concatenate 'string "2:" (string =tail)) used-mora-list1))
     !eval! (when (equal (current-model) 'p2) (push (concatenate 'string "3:" (string =tail)) used-mora-list1))
                                        ;eval! (push =word word-list)
                                        ;eval! (push (- (mp-time) last-time) time-list)
     )

                                        ;  (P vocalize-tail-char-fail
                                        ;       =goal>
                                        ;         ISA answer-word
                                        ;         a-tail =tail
                                        ;         - a-tail "n"
                                        ;         state vocalize-tail-char
                                        ;       ?vocal>
                                        ;         state free
                                        ;     ==>
                                        ;  )

    (P retrieve-myanswer-head-char
     =goal>
     ISA answer-word
     a-tail =tail
     state retrieve-myanswer-head-char
     ?retrieval>
     state free
     ==>
     =goal>
     ISA answer-word
     state set-head-char-for-myanswer
     +retrieval>
     string =tail
     )

    (P retrieve-myanswer-head-char-fail
     =goal>
     ISA answer-word
     ;a-tail =tail
     state set-head-char-for-myanswer
     ?retrieval>
     buffer failure
     ==>
     =goal>
     ISA answer-word
     state retrieve-myanswer-head-char
     ;state set-head-char-for-myanswer
     ;+retrieval>
     ;string =tail
     )

    (P set-head-char-for-myanswer
     =goal>
     ISA answer-word
     a-tail =a-tail
     state set-head-char-for-myanswer
     =retrieval>
     string =tail
     ==>
     =goal>
     ISA answer-word
     state retrieve-head-char-kana
     a-head =tail
     !output! (=tail is head-sound)
     )

;;;next retrieve myanswer by head char

    (P retrieve-head-char-kana
     =goal>
     ISA answer-word
     state retrieve-head-char-kana
     a-head =head
     ?retrieval>
     state free
     ==>
     =goal>
     ISA answer-word
     state set-head-char-sound
     +retrieval>
     string =head
     )

    (P retrieve-head-char-kana-fail
     =goal>
     ISA answer-word
     state set-head-char-sound
                                        ;a-head =head
     ?retrieval>
     buffer failure
     ==>
     =goal>
     ISA answer-word
     state retrieve-head-char-kana
     ;state set-head-char-sound
     ;+retrieval>
     ;string =head
     )

    (P set-head-char-sound
     =goal>
     ISA answer-word
     state set-head-char-sound
     a-head =a-text
     =retrieval>
     mean =mean
     string =text
     ==>
     =goal>
     ISA answer-word
     state retrieve-myanswer-by-head-char
     a-head =mean

     !output! (=mean is head-char)
     )

    (P retrieve-myanswer-by-head-char
      =goal>
        ISA answer-word
        state retrieve-myanswer-by-head-char
        a-head =head
      ?retrieval>
        state free
      ==>
      =goal>
        ISA answer-word
        state set-goal-myanswer-meaning
      +retrieval>
        mora =head
        pos-head 0
        :recently-retrieved nil

      !output! (head char is =head)
    )

    (P retrieve-myanswer-by-head-char-fail
     =goal>
     ISA answer-word
     state set-goal-myanswer-meaning
     a-head =head
     ?retrieval>
     buffer failure
     ==>
     =goal>
     ISA answer-word
     state retrieve-myanswer-by-head-char
     ;state set-goal-myanswer-meaning
     ;+retrieval>
     ;head-char =head
     )

    (P set-goal-myanswer-meaning
      =goal>
        ISA answer-word
        state set-goal-myanswer-meaning
        a-head =a-head ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      =retrieval>
        mora =head
        wm-word =meaning
        pos-head 0
      ==>
      =goal>
        ISA answer-word
        state retrieve-myanswer-tail
        a-word =meaning

      !output! (myanswer is =meaning)
      !eval! (when (equal (current-model) 'P2) (push (concatenate 'string "4:" (string =head)) used-mora-list1))
    )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;check my answer has "n"
    (P retrieve-myanswer-tail
      =goal>
        ISA answer-word
        state retrieve-myanswer-tail
        a-word =answer
      ?retrieval>
      state free
      ==>
      =goal>
        ISA answer-word
        state set-myanswer-tail
      +retrieval>
        wm-word =answer
        - mora nil
      pos-tail 0
    )

    (P retrieve-myanswer-tail-fail
     =goal>
     ISA answer-word
     state set-myanswer-tail
                                        ;a-word =answer
     ?retrieval>
     buffer failure
     ==>
     =goal>
     ISA answer-word
     state retrieve-myanswer-tail
     ;state set-myanswer-tail
     ;+retrieval>
     ;meaning =answer
     ;- tail-char nil
     )

    (P set-myanswer-tail
      =goal>
        ISA answer-word
        state set-myanswer-tail
      =retrieval>
        pos-tail 0
        mora =tail
      ==>
      =goal>
        ISA answer-word
        state check-myanswer-has-n
        a-tail =tail
    )

    (P myanswer-has-n
     =goal>
     ISA answer-word
     state check-myanswer-has-n
     a-word =word
     a-tail -N-
     ==>
     =goal>
     ISA answer-word
     state retrieve-myanswer-head ;;retrieval other answer

     !output! (=word has "n")
     !eval! (incf *p2-N-counter* 1)
     )

    (P retrieve-myanswer-head
      =goal>
        ISA answer-word
        state retrieve-myanswer-head
        a-word =word
      ?retrieval>
        state free
      ==>
      =goal>
        ISA answer-word
        state set-myanswer-head
    +retrieval>
        wm-word =word
        - mora nil
        pos-head 0
    )

    (P retrieve-myanswer-head-fail
      =goal>
        ISA answer-word
        state set-myanswer-head
        ;a-word =word
      ?retrieval>
        buffer failure
      ==>
      =goal>
        ISA answer-word
        state retrieve-myanswer-head
    ;+retrieval>
    ;meaning =word
    ;- head-char nil
    )

    (P set-myanswer-head
      =goal>
        ISA answer-word
        state set-myanswer-head
        a-word =word
      =retrieval>
        wm-word =word
        mora =head
        pos-head 0
      ==>
      =goal>
        ISA answer-word
        state retrieve-myanswer-by-head-char
        a-head =head

        !eval! (when (equal (current-model) 'P2) (push (concatenate 'string "3:" (string =head)) used-mora-list1))
    )

    (P myanswer-has-not-n
      =goal>
        ISA answer-word
        state check-myanswer-has-n
        - a-tail -N-
      ==>
      =goal>
        ISA answer-word
        state retrieve-myanswer-sound
    )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    (P retrieve-myanswer-sound
      =goal>
        ISA answer-word
        state retrieve-myanswer-sound
        a-word =answer
      ?retrieval>
        state free
      ==>
      =goal>
        ISA answer-word
        state image-my-answer
      ;+retrieval> =answer
      ;;- text nil
      +retrieval>
        word =answer

      !output! (retrieve chank =answer)
      ;!eval! (dm-fct '(=answer))
    )

    (P retrieve-myanswer-sound-fail
      =goal>
        ISA answer-word
        state image-my-answer
        a-word =answer
      ?retrieval>
        buffer failure
      ==>
      =goal>
        ISA answer-word
        state retrieve-myanswer-sound
      ;state image-my-answer
      ;+retrieval> =answer
    )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;image my answer
    (P image-my-answer-train
      =goal>
        ISA answer-word
        state image-my-answer
        a-word =word
      =retrieval>
        sound =sound
      ?imaginal>
        state free
      ==>
      =goal>
        ISA answer-word
        state set-goal-myanswer-sound
      =retrieval>
      +imaginal>
        past-word =word
        past-string =sound
        traial train

      !output! (image =word =sound)
    )

    (P image-my-answer-test
      =goal>
        ISA answer-word
        state image-my-answer
        a-word =word
      =retrieval>
        sound =sound
      ?imaginal>
        state free
      ==>
      =goal>
        ISA answer-word
        state set-goal-myanswer-sound
      =retrieval>
      +imaginal>
        past-word =word
        past-string =sound
        traial test

      !output! (image =word =sound)
    )

     (P image-my-answer-busy
     =goal>
     ISA answer-word
     state image-my-answer
     a-word =word
     =retrieval>
     sound =sound
     ?imaginal>
     - state free
     ==>
     =goal>
     ISA answer-word
     state set-goal-myanswer-sound

     !output! (imaginal is busy)
     )

    (P image-my-answer-fail
     =goal>
     ISA answer-word
     state set-goal-myanswer-sound
     a-word =word
     =retrieval>
     sound =sound
     ?imaginal>
     buffer failure
     ==>
     =goal>
     ISA answer-word
     state image-my-answer
     =retrieval>
     ;+imaginal>
     ;past-word =word
     ;past-string =text

     !output! (image =word =sound fail)
     )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (P set-goal-myanswer-sound
     =goal>
     ISA answer-word
     state set-goal-myanswer-sound
     ;;a-word =retrieval
     =retrieval>
     sound =sound
     ==>
     =goal>
     ISA answer-word
     state check-myanswer-used
     a-word =sound

     !output! (myanswer-sound is =sound)
     )

    ;;
    (P check-myanswer-used-train
     =goal>
     ISA answer-word
     state check-myanswer-used
     a-word =myanswer

     a-tail =tail
     a-head =head

     ?retrieval>
     state free
     ==>
     =goal>
     ISA answer-word
     state myanswer-is-used-ornot
     +retrieval>
     past-string =myanswer
     traial train

     !output! (word =myanswer tail =tail head =head)
     )

     (P check-myanswer-used-test
     =goal>
     ISA answer-word
     state check-myanswer-used
     a-word =myanswer

     a-tail =tail
     a-head =head

     ?retrieval>
     state free
     ==>
     =goal>
     ISA answer-word
     state myanswer-is-used-ornot
     +retrieval>
     past-string =myanswer
     traial test

     !output! (word =myanswer tail =tail head =head)
     )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;myanswer is used and retrieve another answer
    (P exist-past-word
     =goal>
     ISA answer-word
     state myanswer-is-used-ornot
     a-word =word
     =retrieval>
     past-string =word
     ==>
     =goal>
     ISA answer-word
     state re-retrieve-myanswer-mean

     !output! (=word is used word)
     !eval! (incf *p2-used-counter* 1)
     )

    (P re-retrieve-myanswer-mean
      =goal>
        ISA answer-word
        state re-retrieve-myanswer-mean
        a-word =sound
      ?retrieval>
        state free
      ==>
      =goal>
        ISA answer-word
        state remind-myanswer-mean
      +retrieval>
        sound =sound
    )

    (P re-retrieve-myanswer-mean-fail
      =goal>
        ISA answer-word
        state remind-myanswer-mean
        a-word =sound
      ?retrieval>
        buffer failure
      ==>
      =goal>
        ISA answer-word
        state re-retrieve-myanswer-mean
     ;state remind-myanswer-mean
     ;+retrieval>
     ;text =sound
    )

    (P remind-myanswer-mean
      =goal>
        ISA answer-word
        state remind-myanswer-mean
        a-word =sound
      =retrieval>
        sound =sound
      ==>
      =goal>
        ISA answer-word
        state retrieve-myanswer-head
        a-word =retrieval
    )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (P dont-exist-past-word
     =goal>
     ISA answer-word
     state myanswer-is-used-ornot
     ?retrieval>
     state error
     ==>
     =goal>
     ISA answer-word
     state vocalize-myanswer
     )

    )