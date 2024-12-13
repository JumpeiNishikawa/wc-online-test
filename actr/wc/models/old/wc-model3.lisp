(define-model-fct 'wc3
  (append
    '(
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
      (add-dm-fct *chunk-list-tl2v*)
      (add-dm 
          (wc-answer ISA answer state start) )
      (set-similarities-fct *mora-sim-list*)
      (set-base-levels-fct *word-base-levels*)

      (goal-focus wc-answer)
      (set-audloc-default 
        location EXTERNAL
        :attended nil)
      )
      *productions*))