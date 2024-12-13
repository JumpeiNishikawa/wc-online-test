(define-model wc
    (sgp
        :v      t
        :act    nil ;low
        :cmdt   t
        :esc    t
        :lf     .05
        :ans    .5
        :rt     -5
        :bll    .5
        :mp     2
        :md     -100
        :mas    5
        :imaginal-activation 1)
    
    (chunk-type word word-concept word-sound)
    (chunk-type mora mora-concept mora-sound)
    (chunk-type word-mora wm-word wm-mora head-posi tail-posi)

    (chunk-type answer state ans-word ans-head ans-tail past-tail past-answer)
    ;(chunk-type past past-word past-sound trial)

    ;(add-dm
    ;    ;mora consepts
    ;    (A ISA chunk)(I ISA chunk)(U ISA chunk)(E ISA chunk)(O ISA chunk)(JA ISA chunk)(JU ISA chunk)(JO ISA chunk)(KA ISA chunk)(KI ISA chunk)(KU ISA chunk)(KE ISA chunk)(KO ISA chunk)(KJA ISA chunk)(KJU ISA chunk)(KJO ISA chunk)(GA ISA chunk)(GI ISA chunk)(GU ISA chunk)(GE ISA chunk)(GO ISA chunk)(GJA ISA chunk)(GJU ISA chunk)(GJO ISA chunk)(SA ISA chunk)(SI ISA chunk)(SU ISA chunk)(SE ISA chunk)(SO ISA chunk)(ZA ISA chunk)(ZI ISA chunk)(ZU ISA chunk)(ZE ISA chunk)(ZO ISA chunk)(ZJA ISA chunk)(ZJO ISA chunk)(TA ISA chunk)(TI ISA chunk)(TU ISA chunk)(TE ISA chunk)(TO ISA chunk)(TJU ISA chunk)(DA ISA chunk)(DE ISA chunk)(DO ISA chunk)(NA ISA chunk)(NI ISA chunk)(NU ISA chunk)(NE ISA chunk)(NO ISA chunk)(NJA ISA chunk)(NJU ISA chunk)(NJO ISA chunk)(HA ISA chunk)(HI ISA chunk)(HU ISA chunk)(HE ISA chunk)(HO ISA chunk)(HJA ISA chunk)(HJU ISA chunk)(HJO ISA chunk)(PA ISA chunk)(PI ISA chunk)(PU ISA chunk)(PE ISA chunk)(PO ISA chunk)(PJA ISA chunk)(PJU ISA chunk)(PJO ISA chunk)(BA ISA chunk)(BI ISA chunk)(BU ISA chunk)(BE ISA chunk)(BO ISA chunk)(BJA ISA chunk)(BJU ISA chunk)(BJO ISA chunk)(MA ISA chunk)(MI ISA chunk)(MU ISA chunk)(ME ISA chunk)(MO ISA chunk)(MJA ISA chunk)(MJU ISA chunk)(MJO ISA chunk)(RA ISA chunk)(RI ISA chunk)(RU ISA chunk)(RE ISA chunk)(RO ISA chunk)(RJA ISA chunk)(RJU ISA chunk)(RJO ISA chunk)(WA ISA chunk)
        ;production name and state slot values
    ;    (START ISA chunk)(RETRIEVE-PARTNER-ANSWER-CONCEPT ISA chunk)(SET-PARTNER-ANSWER-CONCEPT ISA chunk)(RETRIEVE-PARTNER-ANSWER-TAIL ISA chunk)(SET-GOAL-PARTNER-ANSWER-TAIL ISA chunk)(RETRIEVE-MYANSWER ISA chunk)(SET-GOAL-MYANSWER-CONCEPT ISA chunk)(RETRIEVE-MYANSWER-TAIL ISA chunk)(SET-MYANSWER-TAIL ISA chunk)(CHECK-MYANSWER-HAS-N ISA chunk)(RETRIEVE-MYANSWER-SOUND ISA chunk)(RE-SET-MYANSWER-HEAD ISA chunk)(SET-MYANSWER-SOUND ISA chunk)(VOCALIZE-MYANSWER ISA chunk)(END ISA chunk))
    ;word, mora and word-mora chunk are loaded above, (load ...) part
    (add-dm-fct *chunk-list-wo-tl*)
    (add-dm 
        (wc-answer ISA answer state start) )
    (set-similarities-fct *mora-sim-list*)
    
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