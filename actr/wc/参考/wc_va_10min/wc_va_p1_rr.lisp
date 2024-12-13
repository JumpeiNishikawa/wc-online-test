;;; SET :recently-retrieved nil AT retrieve-myanswer-by-head-char
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PLAYER1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-model P1
  (set-params t nil)
  ;(sgp
  ;    :esc t
  ;    :lf  0.05
  ;    :ans 0.5
  ;    :rt  -5
  ;    :bll 0.5
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
  (add-dm
    (answer-p1 ISA answer-word state start))
    (goal-focus answer-p1)

  (set-audloc-default
    - location self
    - location internal
    :attended nil)

  (P start-word-retrieval
    =goal>
      ISA answer-word
      state start
    ?retrieval>
      state free
      ;buffer empty
    ==>
      =goal>
        ISA answer-word
        state set-gaol-and-retrieve-word-inf
      +retrieval>
        ISA word-mora
        - wm-word nil
        - mora nil
        - mora -N-
        pos-tail 0
  )

    (P start-word-retrieval-fail
    =goal>
      ISA answer-word
      state set-gaol-and-retrieve-word-inf
    ?retrieval>
      buffer failure
    ==>
      =goal>
        ISA answer-word
        state start
  )

  (P set-gaol-and-retrieve-word-inf
    =goal>
      ISA answer-word
      state set-gaol-and-retrieve-word-inf
    =retrieval>
      ISA word-mora
      wm-word =start-word
      mora =tail
      pos-tail 0
    ==>
    =goal>
      ISA answer-word
      state vocalize-myanswer2
      a-word =start-word
      a-tail =tail
    ;+retrieval> =start-word
    +retrieval>
      word =start-word
      !output!  (start word =start-word)
  )

    (P set-gaol-and-retrieve-word-inf-fail
      =goal>
        ISA answer-word
        state vocalize-myanswer2
        a-word =start-word
        a-tail =tail
    ?retrieval>
      buffer failure
    ==>
    =goal>
      ISA answer-word
      state start
  )

  (P set-answerword-and-start
    =goal>
      ISA answer-word
      state vocalize-myanswer2
    =retrieval>
      ISA word-inf
      sound =sound
    ==>
    =goal>
      ISA answer-word
      state vocalize-myanswer
      a-word =sound
      !output!  (start word =sound)
  )

  (p detected-sound-p1
  =aural-location>
  ?aural>
    state   free
  ==>
  +aural>
    event =aural-location

    !output! (detected-sound)
    !output! (=aural-location)
    !eval! (clear-screen)
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
      ?retrieval>
        buffer failure
      ==>
      =goal>
        ISA answer-word
        state retrieve-answers-meaning
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
      !eval! (when (equal (current-model) 'P2) (push (concatenate 'string "1:" (string =tail)) used-mora-list1))
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
     ?retrieval>
     buffer failure
     ==>
     =goal>
     ISA answer-word
     state retrieve-tail-char-sound
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
     !eval! (when (equal (current-model) 'P2) (push (concatenate 'string "2:" (string =tail)) used-mora-list2))
     !eval! (when (equal (current-model) 'P2) (push (concatenate 'string "3:" (string =tail)) used-mora-list3))
     )




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
     state set-head-char-for-myanswer
     ?retrieval>
     buffer failure
     ==>
     =goal>
     ISA answer-word
     state retrieve-myanswer-head-char
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
      !eval! (when (equal (current-model) 'P2) (push (concatenate 'string "4:" (string =head)) used-mora-list4))
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
     !eval! (incf *p1-N-counter* 1)
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

        !eval! (when (equal (current-model) 'P2) (push (concatenate 'string "3:" (string =head)) used-mora-list3))
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
     !eval! (incf *p1-used-counter* 1)
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
          state retrieve-partner-answer-head
          a-word =mean

        !output! (=word is meaning)
          )

      (P retrieve-partner-answer-head
        =goal>
          state retrieve-partner-answer-head
          a-word =answer
        ?retrieval>
          state free
        ==>
        =goal>
          state set-goal-answer-word-head
        +retrieval>
          ISA word-mora
          wm-word =answer
          - mora nil
          pos-head 0
          )
      (P retrieve-partner-answer-fail
        =goal>
          state set-goal-answer-word-head
          a-word =answer
        ?retrieval>
          buffer failure
        ==>
        =goal>
          ISA answer-word
          state retrieve-partner-answer-head
          ;state set-goal-answer-word-tail
          ;+retrieval>
          ;ISA word-tail
          ;meaning =answer
          ;- tail-char nil
          )

      (P set-goal-answer-word-head
        =goal>
          ISA answer-word
          state set-goal-answer-word-head
          a-word =answer
        =retrieval>
          ISA word-mora
          wm-word =answer
          mora =head
          pos-head 0
        ==>
        =goal>
          ISA answer-word
          a-head =head
          state check-partner-answer-error
          !output! (=head is head char)
        )

      (P check-partner-answer-error
        =goal>
          ISA answer-word
          state check-partner-answer-error
          a-head =head
        - past-tail =head
          past-answer =past-answer
        ==>
          =goal>
            ISA answer-word
            state vocalize-myanswer-error
            a-word =past-answer

            !output! (ERROR! repeat =past-answer)
          )
      (P check-partner-answer-error2
        =goal>
          ISA answer-word
          a-head =head
          past-tail =head
          state check-partner-answer-error
        ==>
          =goal>
            ISA answer-word
            state retrieve-answer-word-tail

            !output! (SUCCESS!)
          )
      (P check-partner-answer-error3
        =goal>
          ISA answer-word
          past-tail nil
          state check-partner-answer-error
        ==>
          =goal>
            ISA answer-word
            state retrieve-answer-word-tail

            !output! (SUCCESS!)
          )

(P vocalize-myanswer-error-train
  =goal>
    ISA answer-word
    state vocalize-myanswer-error
    a-word =myanswer
    a-tail =atail
  ?vocal>
    state free
  ==>
  =goal>
    ISA answer-word
    a-word nil
    state set-goal-another-player-answer-sound
    past-tail =atail
    past-answer =myanswer
  +vocal>
    cmd speak
    string =myanswer
  -aural>
  -aural-location>

  !output! (answer =myanswer)
  !output! (atail =atail)
  ;eval! (print (current-model))
  ;eval! (sdp-fct *kana-list*)

   ;;make kana hint
  ;!eval! (present-hint (write-to-string =atail))
  !eval! (progn (add-text-to-exp-window :text (write-to-string =atail) :x 125 :y 150))

  !eval! (push (concatenate 'string "ERROR:" =myanswer) P1word-list)
  !eval! (push (- (mp-time) P1last-time) P1time-list)
  !eval! (setf P1last-time (mp-time))
  ;eval! (save-kana-activation P1sdplist)
  !eval! (dolist (kana *kana-list*) (push (format nil "{~A:~A}" kana (caar (sdp-fct (list kana :activation)))) P1sdplist))
  !eval! (push "," P1sdplist)
  )

(P vocalize-myanswer-train
  =goal>
    ISA answer-word
    state vocalize-myanswer
    a-word =myanswer
    a-tail =atail
  ?vocal>
    state free
  ==>
  =goal>
    ISA answer-word
    a-word nil
    state set-goal-another-player-answer-sound
    past-tail =atail
    past-answer =myanswer
  +vocal>
    cmd speak
    string =myanswer
  -aural>

  !output! (answer =myanswer)
  !output! (atail =atail)
  ;eval! (print (current-model))
  ;eval! (sdp-fct *kana-list*)

  ;;make kana hint
  ;!eval! (present-hint (write-to-string =atail))
  !eval! (progn (add-text-to-exp-window :text (write-to-string =atail) :x 125 :y 150))

  !eval! (push =myanswer P1word-list)
  !eval! (push (- (mp-time) P1last-time) P1time-list)
  !eval! (setf P1last-time (mp-time))
  ;eval! (save-kana-activation P1sdplist)
  !eval! (dolist (kana *kana-list*) (push (format nil "{~A:~A}" kana (caar (sdp-fct (list kana :activation)))) P1sdplist))
  !eval! (push "," P1sdplist)
  !eval! (incf *chain-counter* 1)
  )

  (P vocalize-myanswer-error-test
  =goal>
    ISA answer-word
    state vocalize-myanswer-error
    a-word =myanswer
    a-tail =atail
  ?vocal>
    state free
  ==>
  =goal>
    ISA answer-word
    a-word nil
    state set-goal-another-player-answer-sound
    past-tail =atail
    past-answer =myanswer
  +vocal>
    cmd speak
    string =myanswer
  -aural>
  -aural-location>

  !output! (answer =myanswer)
  !output! (atail =atail)
  ;eval! (print (current-model))
  ;eval! (sdp-fct *kana-list*)

   ;;make kana hint
  ;!eval! (present-hint (write-to-string =atail))

  !eval! (push (concatenate 'string "ERROR:" =myanswer) P1word-list)
  !eval! (push (- (mp-time) P1last-time) P1time-list)
  !eval! (setf P1last-time (mp-time))
  ;eval! (save-kana-activation P1sdplist)
  !eval! (dolist (kana *kana-list*) (push (format nil "{~A:~A}" kana (caar (sdp-fct (list kana :activation)))) P1sdplist))
  !eval! (push "," P1sdplist)
  )

(P vocalize-myanswer-test
  =goal>
    ISA answer-word
    state vocalize-myanswer
    a-word =myanswer
    a-tail =atail
  ?vocal>
    state free
  ==>
  =goal>
    ISA answer-word
    a-word nil
    state set-goal-another-player-answer-sound
    past-tail =atail
    past-answer =myanswer
  +vocal>
    cmd speak
    string =myanswer
  -aural>

  !output! (answer =myanswer)
  !output! (atail =atail)
  ;eval! (print (current-model))
  ;eval! (sdp-fct *kana-list*)

  ;;make kana hint
  ;!eval! (present-hint (write-to-string =atail))

  !eval! (push =myanswer P1word-list)
  !eval! (push (- (mp-time) P1last-time) P1time-list)
  !eval! (setf P1last-time (mp-time))
  ;eval! (save-kana-activation P1sdplist)
  !eval! (dolist (kana *kana-list*) (push (format nil "{~A:~A}" kana (caar (sdp-fct (list kana :activation)))) P1sdplist))
  !eval! (push "," P1sdplist)
  !eval! (incf *chain-counter* 1)
  )
)
