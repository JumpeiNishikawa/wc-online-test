(define-model wc2
    (sgp
        :v      t
        :act    nil;low
        :cmdt   t
        :esc    t
        :lf     .05
        :ans    .5
        :rt     -5
        :bll    .5
        :mp     nil ;OFF partial matching
        :md     -100
        :mas    5
        :imaginal-activation 1)
    
    (chunk-type word word-concept word-sound)
    (chunk-type mora mora-concept mora-sound)
    (chunk-type word-mora wm-word wm-mora head-posi tail-posi)

    (chunk-type answer state ans-word ans-head ans-tail past-tail past-answer)
    ;(chunk-type past past-word past-sound trial)

    ;word, mora and word-mora chunk are loaded above, (load ...) part
    (add-dm-fct *chunk-list-wo-tl*)
    (add-dm 
        (wc-answer ISA answer state start) )
    ;OFF partial matching
    ;(set-similarities-fct *mora-sim-list*)
    
    (goal-focus wc-answer)
    (set-audloc-default 
        - location self
        - location internal
        :attended nil)

    (P detected-sound
        =goal>
            ISA     answer
            state   start
        =aural-location>
        ?aural>
            state   free
    ==>
        +aural>
            event   =aural-location
    )

    (P get-partner-answer-sound
        =goal>
            ISA     answer
            ans-word    nil
            state   start
        =aural>
            isa     sound
            content =word
    ==>
        =goal>
            ISA     answer
            state   retrieve-partner-answer-concept ;;retrieve-answers-meaning
            ans-word    =word
    )

    (P retrieve-partner-answer-concept
        =goal>
            ISA     answer
            state   retrieve-partner-answer-concept
            ans-word    =sound
        ?retrieval>
            state   free
    ==>
        =goal>
            ISA     answer
            state   set-partner-answer-concept
        +retrieval>
            ISA     word
            word-sound   =sound
    )
    
    (P set-partner-answer-concept
        =goal>
            ISA     answer
            state   set-partner-answer-concept
            ans-word  =sound
        =retrieval>
            ISA     word
            word-concept    =word
            word-sound   =sound
    ==>
        =goal>
            ISA     answer
            state   retrieve-partner-answer-tail
            ans-word  =word
    )

    (P retrieve-partner-answer-tail
        =goal>
            ISA     answer
            state   retrieve-partner-answer-tail
            ans-word    =word
        ?retrieval>
            state   free
    ==>
        =goal>
            state   set-goal-partner-answer-tail
        +retrieval>
            ISA     word-mora
            wm-word =word
            tail-posi   0
    )
    
    (P set-goal-partner-answer-tail
        =goal>
            ISA     answer
            state   set-goal-partner-answer-tail
            ans-word    =word
        =retrieval>
            ISA     word-mora
            wm-word =word
            wm-mora =tail
            tail-posi   0
    ==>
        =goal>
            ISA answer
            ans-tail    =tail
            state retrieve-myanswer
    )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;There is no need to retrieve for mora sound (value with quotation)
;    (P retrieve-tail-mora
;        =goal>
;            ISA     answer-word
;            state   retrieve-tail-mora
;            ans-word    =answer
;            ans-tail    =tail
;        ?retrieval>
;            state       free
;    ==>
;        =goal>
;            ISA     answer-word
;            state   set-goal-tail-char-sound
;        +retrieval>
;            mora    =tail
;    )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    (P retrieve-myanswer
        =goal>
            ISA     answer
            state   retrieve-myanswer
            ans-tail    =head
        ?retrieval>
            state   free
    ==>
        =goal>
            ISA     answer
            state   set-goal-myanswer-concept
            ans-head    =head ;partner tail -> my answer head
        +retrieval>
            wm-mora     =head
            head-posi   0
        ;:recently-retrieved nil
    )

    (P set-goal-myanswer-concept
        =goal>
            ISA     answer
            state   set-goal-myanswer-concept
            ;ans-head    =head ;partial matching
        =retrieval>
            wm-mora     =head
            wm-word     =word
            head-posi   0
    ==>
        =goal>
            ISA     answer
            state   retrieve-myanswer-tail
            ans-word    =word
    )

    ;;check my answer has "n"
    (P retrieve-myanswer-tail
        =goal>
            ISA     answer
            state   retrieve-myanswer-tail
            ans-word    =word
        ?retrieval>
            state   free
    ==>
        =goal>
            ISA     answer
            state   set-myanswer-tail
        +retrieval>
            wm-word =word
            - wm-mora   nil
            tail-posi   0
    )
    (P set-myanswer-tail
        =goal>
            ISA     answer
            state   set-myanswer-tail
        =retrieval>
            tail-posi   0
            wm-mora     =tail
    ==>
        =goal>
            ISA     answer
            state   check-myanswer-has-n
            ans-tail    =tail
    )
    (P myanswer-has-not-n
        =goal>
            ISA     answer
            state   check-myanswer-has-n
            - ans-tail    0
    ==>
        =goal>
            ISA     answer
            state   retrieve-myanswer-sound
    )
    (P myanswer-has-n
        =goal>
            ISA     answer
            state   check-myanswer-has-n
            ans-word    =word
            ans-tail    0
    ==>
        =goal>
            ISA     answer
            state   re-set-myanswer-head ;;retrieval other answer
    )

    (P re-set-myanswer-head
        =goal>
            ISA     answer
            state re-set-myanswer-head
            ans-word    =word
            ans-head    =head
    ==>
        =goal>
            ISA     answer
            state   retrieve-myanswer
            ans-tail    =head ;my answer head = partner tail -> retrieve query
    )

    (P retrieve-myanswer-sound
        =goal>
            ISA     answer
            state   retrieve-myanswer-sound
            ans-word    =word
        ?retrieval>
            state   free
    ==>
        =goal>
            ISA     answer
            ;state   image-my-answer ;no need to record answer (used or not)
            state   set-myanswer-sound
        +retrieval>
            word-concept   =word
    )

    (P set-myanswer-sound
        =goal>
            ISA     answer
            state   set-myanswer-sound
        =retrieval>
            word-sound  =sound
    ==>
        =goal>
            ISA     answer
            ;state   check-myanswer-used ;no need to check used = one shot shiritori
            state   vocalize-myanswer
            ans-word    =sound
     )

    (P vocalize-myanswer
        =goal>
            ISA     answer
            state   vocalize-myanswer
            ans-word    =myanswer
            ans-tail    =anstail
        ?vocal>
            state   free
    ==>
        =goal>
            ISA     answer
            ans-word    nil
            ;state   get-partner-answer-sound
            state   end
            past-tail   =anstail ;Probably not necessary.
            past-answer =myanswer ;Probably not necessary.
        +vocal>
            cmd     speak
            string  =myanswer
        -aural>
    !output!    =myanswer
    ))