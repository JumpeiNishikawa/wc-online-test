;;; Test model for new base-level learning equation extension
;;;
;;; Free recall procedure without tagging to illustrate the benefits of base-level inhibition

(clear-all)
(require-extra "base-level-inhibition")

;; Variables for recording the activation and retrieval times data for graphing
(defvar *retrieval-log* nil)
(defvar *activation-lists* nil)
(defvar *max-activation* nil)
(defvar *min-activation* nil)

(defun memory-stats (&optional (factor 1.0) (output nil) (priors 10.0))
  (no-output
   (let ((chunk-frequencies nil)
         (memory-chunks (sdm isa memory))
         (frequencies nil))
     (dolist (chunk memory-chunks)
       (push (cons chunk (/ (- (caaar (sdp-fct (list chunk :references))) priors) factor)) chunk-frequencies))
       (dolist (chunk-frequency (sort chunk-frequencies #'> :key #'cdr))
         (push (cdr chunk-frequency) frequencies)
         (when output (format t "~A~C~D~%" (car chunk-frequency) #\tab (cdr chunk-frequency))))
       (reverse frequencies))))

(defun free-recall (&key (n 100) (delay 1.0) (reset t) (output nil) (scale nil) (decay nil) (record t))
  (when reset (reset))
  
  (when record 
    ;; clear the old data and setup the appropriate hooks
    (setf *retrieval-log* nil)
    (setf *activation-lists* (mapcar (lambda (x) (cons x nil)) (no-output (sdm isa memory))))
    (setf *max-activation* nil)
    (setf *min-activation* nil)
    (sgp :retrieval-set-hook save-selection-time)
    (sgp :chunk-merge-hook save-reference-time)
    ;; record activation every 50ms 
    (schedule-periodic-event .05 'record-activations :maintenance t :priority :min))

  (if (and scale decay)
      (sgp-fct (list :inhibition-scale scale :inhibition-decay decay :enable-inhibition t))
    (sgp :enable-inhibition nil))
  (dotimes (i n)
    (when delay (run-full-time delay))
    (goal-focus g)
    (run 10))
  (run 20) ;; record a buffer of activation values at the end
  (memory-stats n output))

(defun average-frequencies (&key (samples 10) (n 100) (decay nil) (scale nil))
  (let ((frequencies (make-list samples :initial-element 0.0)))
    (dotimes (sample samples)
      (setf frequencies (mapcar #'+ frequencies 
                          (free-recall :n n :decay decay :scale scale 
                                       :record (= sample (1- samples))))))
    (dolist (frequency frequencies)
      (format t "~6,3F~%" (/ frequency samples)))))


(defun record-activations ()
  (no-output
   (let ((old-ans (car (sgp :ans))))
    (sgp :ans nil)
    (dolist (x (sdm isa memory))
      (let ((act (caar (sdp-fct (list x :activation)))))
        (push (cons (mp-time) act) (cdr (assoc x *activation-lists*)))
        
        (when (or (null *min-activation*) (< act *min-activation*))
          (setf *min-activation* act))
        
        (when (or (null *max-activation*) (> act *max-activation*))
          (setf *max-activation* act))))
    (sgp-fct (list :ans old-ans)))))

(defun save-selection-time (chunk-list)
  (push (cons (car chunk-list) (mp-time)) *retrieval-log*)
  nil)

(defun save-reference-time (chunk)
  (when (numberp (chunk-slot-value-fct chunk 'index))
    (push (mp-time) (cdar *retrieval-log*))))


;;; Displays base-levels from recorded values which do not include noise


(defun display-all-base-levels (&key (chunks nil) (end-time 100) (inc 1.0))
  (when (< inc .05) (setf inc .05))
  (setf inc (* .05 (round inc .05)))
  (setf end-time (min end-time (caadar *activation-lists*)))
  
  (do ((time 0.0 (+ time inc))
       (chunks (if chunks chunks (no-output (sdm isa memory)))))
      ((> time end-time))
    (format t "~6,2f~{~6@T~6,3F~}~%" time 
      (mapcar (lambda (x) (cdr (assoc time (cdr (assoc x *activation-lists*))))) chunks))))

(defun graph-all-base-levels (&key (chunks nil) (end-time nil))
  (let* ((win (open-exp-window "Base-levels" :width 630 :height 320 :visible t))
         (colors (list 'red 'blue 'green 'yellow 'white 'brown 'purple 'black 'light-blue 'dark-green))
         (yscale (/ 300 (- (min 5 (max 0 *max-activation*)) *min-activation*)))
         (last-time (if end-time (min end-time (caadar *activation-lists*)) (caadar *activation-lists*)))
         (max-steps (min 300 (round last-time .05))) ;; at least 2 pixels per
         (x-inc (ceiling (/ last-time max-steps) .05))
         (real-steps (round last-time (* x-inc .05)))
         (xscale (/ 600 last-time)))
    
    (add-text-to-exp-window win (format nil "~3,2f" *max-activation*) :x 5 :y 5 )
    (add-text-to-exp-window win (format nil "~3,2f" *min-activation*) :x 5 :y 290 )
                                
    (dolist (chunk *activation-lists*)
      (let ((color (pop colors))
            (last-x nil)
            (last-y nil))
        (dotimes (i real-steps)
          (let* ((data (nth (- (length (cdr chunk)) 1 (* i x-inc)) (cdr chunk)))
                (x (round (* (car data) xscale)))
                (y (round (- 300 (* (- (cdr data) *min-activation*) yscale)))))
            (when last-x ;(and nil last-x)
              (add-line-to-exp-window win (list (+ 30 last-x) last-y) (list (+ 30 x) y) color))
            (setf last-x x)
            (setf last-y y)))

          (dolist (retrieval *retrieval-log*)
            (when (and (eq (car chunk) (car retrieval))
                       (<= (cadr retrieval) last-time)
                       )
              (let* ((x1 (round (* (cadr retrieval) xscale)))
                     (x2 (min (1- x1) (round (* (cddr retrieval) xscale)))))
                (dotimes (i 4)
                  (add-line-to-exp-window win (list (+ x1 30) (+ 308 i)) (list (+ x2 30) (+ 308 i)) color)))))))))
  
  

(define-model free-recall

;;; Base-level learning, no optimized learning (exact equation)
;;; No spreading activation

(sgp :esc t :lf 0.25 :bll 0.5 :ol nil :ga 0.0 :ans 0.25 :rt -10.0 :v nil)
(sgp :enable-inhibition t)

(chunk-type memory index (memory t))


(add-dm 
 (zero isa memory index 0)
 (one isa memory index 1)
 (two isa memory index 2)
 (three isa memory index 3)
 (four isa memory index 4)
 (five isa memory index 5)
 (six isa memory index 6)
 (seven isa memory index 7)
 (eight isa memory index 8)
 (nine isa memory index 9))

(define-chunks g)

;;; Retrieval Production

(p retrieve
   =goal>
   ?retrieval>
     buffer empty
   state  free
   ==>
   -goal>
   +retrieval>
     isa memory)

(p harvest
   =retrieval>
     isa memory
   ==>
   !stop!)

;;; Set chunk references
;;; Provide enough references spread out enough in the past to avoid unwanted transient effects
(sdp :creation-time -100.0 :references (-10.0 -20.0 -30.0 -40.0 -50.0 -60.0 -70.0 -80.0 -90.0 -100.0)))

#|
CG-USER(89): (free-recall)
(0.95 0.03 0.02 0.0 0.0 0.0 0.0 0.0 0.0 0.0)
CG-USER(90): (display-all-base-levels)
  0.00       0.462       0.462       0.462       0.462       0.462       0.462       0.462       0.462       0.462       0.462
  1.00       0.443       0.443       0.443       0.443       0.443       0.443       0.443       0.443       0.443       0.443
  2.00       0.425       0.425       0.425       0.425       0.425       0.425       0.425       0.425       0.977       0.425
  3.00       0.409       0.409       1.033       0.409       0.409       0.409       0.409       0.409       0.812       0.409
  4.00       0.393       0.393       0.822       0.393       0.393       0.393       0.393       0.393       0.732       1.128
  5.00       0.378       0.378       0.733       0.378       0.378       0.378       0.378       0.378       0.680       1.458
  6.00       0.364       0.364       1.535       0.364       0.364       0.364       0.364       0.364       0.640       1.092
  7.00       0.350       0.350       1.038       0.350       0.350       0.350       0.350       0.350       0.607       0.967
  8.00       0.337       0.337       0.919       0.337       0.337       0.337       0.337       0.337       1.028       0.889
  9.00       0.325       0.325       0.849       0.325       0.325       0.325       0.325       0.325       1.270       0.833
 10.00       0.313       0.313       0.798       0.313       0.313       0.313       0.313       0.313       1.455       0.788
 11.00       0.301       0.301       0.758       0.301       0.301       0.301       0.301       0.301       1.617       0.751
 12.00       0.290       0.290       0.724       0.290       0.290       0.290       0.290       0.290       1.779       0.719
 13.00       0.279       0.279       1.610       0.279       0.279       0.279       0.279       0.279       1.509       0.691
 14.00       0.268       0.268       1.065       0.268       0.268       0.268       0.268       0.268       1.398       0.666
 15.00       0.258       0.258       0.954       0.258       0.258       0.258       0.258       0.258       1.559       0.643
 16.00       0.248       0.248       0.889       0.248       0.248       0.248       0.248       0.248       1.672       0.623
 17.00       0.238       0.238       0.843       0.238       0.238       0.238       0.238       0.238       1.768       0.603
 18.00       0.229       0.229       0.806       0.229       0.229       0.229       0.229       0.229       1.857       0.585
 19.00       0.220       0.220       0.775       0.220       0.220       0.220       0.220       0.220       1.941       0.568
 20.00       0.211       0.211       0.749       0.211       0.211       0.211       0.211       0.211       2.056       0.553
 21.00       0.202       0.202       0.725       0.202       0.202       0.202       0.202       0.202       2.239       0.537
 22.00       0.193       0.193       0.703       0.193       0.193       0.193       0.193       0.193       1.891       0.523
 23.00       0.185       0.185       0.683       0.185       0.185       0.185       0.185       0.185       1.949       0.509
 24.00       0.177       0.177       0.664       0.177       0.177       0.177       0.177       0.177       2.004       0.496
 25.00       0.169       0.169       0.647       0.169       0.169       0.169       0.169       0.169       2.057       0.484
 26.00       0.161       0.161       0.631       0.161       0.161       0.161       0.161       0.161       2.109       0.472
 27.00       0.153       0.153       0.616       0.153       0.153       0.153       0.153       0.153       2.167       0.460
 28.00       0.146       0.146       0.601       0.146       0.146       0.146       0.146       0.146       2.230       0.449
 29.00       0.138       0.138       0.587       0.138       0.138       0.138       0.138       0.138       2.331       0.438
 30.00       0.131       0.131       0.574       0.131       0.131       0.131       0.131       0.131       2.537       0.427
 31.00       0.124       0.124       0.561       0.124       0.124       0.124       0.124       0.124       2.140       0.417
 32.00       0.117       0.117       0.549       0.117       0.117       0.117       0.117       0.117       2.178       0.407
 33.00       0.110       0.110       0.537       0.110       0.110       0.110       0.110       0.110       2.215       0.398
 34.00       0.103       0.103       0.526       0.103       0.103       0.103       0.103       0.103       2.255       0.388
 35.00       0.096       0.096       0.515       0.096       0.096       0.096       0.096       0.096       2.298       0.379
 36.00       0.089       0.089       0.505       0.089       0.089       0.089       0.089       0.089       2.348       0.370
 37.00       0.083       0.083       0.494       0.083       0.083       0.083       0.083       0.083       2.405       0.362
 38.00       0.077       0.077       0.484       0.077       0.077       0.077       0.077       0.077       2.491       0.353
 39.00       0.070       0.070       0.475       0.070       0.070       0.070       0.070       0.070       2.651       0.345
 40.00       0.064       0.064       0.465       0.064       0.064       0.064       0.064       0.064       2.301       0.337
 41.00       0.058       0.058       0.456       0.058       0.058       0.058       0.058       0.058       2.331       0.329
 42.00       0.052       0.052       0.447       0.052       0.052       0.052       0.052       0.052       2.362       0.321
 43.00       0.046       0.046       0.438       0.046       0.046       0.046       0.046       0.046       2.393       0.313
 44.00       0.040       0.040       0.430       0.040       0.040       0.040       0.040       0.040       2.427       0.306
 45.00       0.034       0.034       0.422       0.034       0.034       0.034       0.034       0.034       2.464       0.299
 46.00       0.028       0.028       0.413       0.028       0.028       0.028       0.028       0.028       2.513       0.291
 47.00       0.023       0.023       0.405       0.023       0.023       0.023       0.023       0.023       2.580       0.284
 48.00       0.017       0.017       0.398       0.017       0.017       0.017       0.017       0.017       2.737       0.277
 49.00       0.012       0.012       0.390       0.012       0.012       0.012       0.012       0.012       2.419       0.270
 50.00       0.006       0.006       0.383       0.006       0.006       0.006       0.006       0.006       2.443       0.264
 51.00       0.001       0.001       0.375       0.001       0.001       0.001       0.001       0.001       2.469       0.257
 52.00      -0.004      -0.004       0.368      -0.004      -0.004      -0.004      -0.004      -0.004       2.497       0.251
 53.00      -0.010      -0.010       0.361      -0.010      -0.010      -0.010      -0.010      -0.010       2.525       0.244
 54.00      -0.015      -0.015       0.354      -0.015      -0.015      -0.015      -0.015      -0.015       2.559       0.238
 55.00      -0.020      -0.020       0.347      -0.020      -0.020      -0.020      -0.020      -0.020       2.617       0.232
 56.00      -0.025      -0.025       0.340      -0.025      -0.025      -0.025      -0.025      -0.025       2.690       0.226
 57.00      -0.030      -0.030       0.334      -0.030      -0.030      -0.030      -0.030      -0.030       2.810       0.220
 58.00      -0.035      -0.035       0.327      -0.035      -0.035      -0.035      -0.035      -0.035       2.518       0.214
 59.00      -0.040      -0.040       0.321      -0.040      -0.040      -0.040      -0.040      -0.040       2.540       0.208
 60.00      -0.045      -0.045       0.315      -0.045      -0.045      -0.045      -0.045      -0.045       2.563       0.202
 61.00      -0.049      -0.049       0.308      -0.049      -0.049      -0.049      -0.049      -0.049       2.588       0.196
 62.00      -0.054      -0.054       0.302      -0.054      -0.054      -0.054      -0.054      -0.054       2.615       0.191
 63.00      -0.059      -0.059       0.296      -0.059      -0.059      -0.059      -0.059      -0.059       2.645       0.185
 64.00      -0.064      -0.064       0.290      -0.064      -0.064      -0.064      -0.064      -0.064       2.689       0.180
 65.00      -0.068      -0.068       0.284      -0.068      -0.068      -0.068      -0.068      -0.068       2.756       0.174
 66.00      -0.073      -0.073       0.279      -0.073      -0.073      -0.073      -0.073      -0.073       2.871       0.169
 67.00      -0.077      -0.077       0.273      -0.077      -0.077      -0.077      -0.077      -0.077       2.598       0.164
 68.00      -0.082      -0.082       0.267      -0.082      -0.082      -0.082      -0.082      -0.082       2.618       0.159
 69.00      -0.086      -0.086       0.262      -0.086      -0.086      -0.086      -0.086      -0.086       2.640       0.153
 70.00      -0.091      -0.091       0.256      -0.091      -0.091      -0.091      -0.091      -0.091       2.661       0.148
 71.00      -0.095      -0.095       0.251      -0.095      -0.095      -0.095      -0.095      -0.095       2.685       0.143
 72.00      -0.099      -0.099       0.246      -0.099      -0.099      -0.099      -0.099      -0.099       2.711       0.138
 73.00      -0.103      -0.103       0.240      -0.103      -0.103      -0.103      -0.103      -0.103       2.745       0.134
 74.00      -0.108      -0.108       0.235      -0.108      -0.108      -0.108      -0.108      -0.108       2.791       0.129
 75.00      -0.112      -0.112       0.230      -0.112      -0.112      -0.112      -0.112      -0.112       2.904       0.124
 76.00      -0.116      -0.116       0.225      -0.116      -0.116      -0.116      -0.116      -0.116       2.665       0.119
 77.00      -0.120      -0.120       0.220      -0.120      -0.120      -0.120      -0.120      -0.120       2.683       0.114
 78.00      -0.124      -0.124       0.215      -0.124      -0.124      -0.124      -0.124      -0.124       2.700       0.110
 79.00      -0.128      -0.128       0.210      -0.128      -0.128      -0.128      -0.128      -0.128       2.719       0.105
 80.00      -0.132      -0.132       0.205      -0.132      -0.132      -0.132      -0.132      -0.132       2.739       0.101
 81.00      -0.136      -0.136       0.201      -0.136      -0.136      -0.136      -0.136      -0.136       2.763       0.096
 82.00      -0.140      -0.140       0.196      -0.140      -0.140      -0.140      -0.140      -0.140       2.790       0.092
 83.00      -0.144      -0.144       0.191      -0.144      -0.144      -0.144      -0.144      -0.144       2.838       0.087
 84.00      -0.148      -0.148       0.186      -0.148      -0.148      -0.148      -0.148      -0.148       2.943       0.083
 85.00      -0.152      -0.152       0.182      -0.152      -0.152      -0.152      -0.152      -0.152       2.725       0.079
 86.00      -0.155      -0.155       0.177      -0.155      -0.155      -0.155      -0.155      -0.155       2.741       0.074
 87.00      -0.159      -0.159       0.173      -0.159      -0.159      -0.159      -0.159      -0.159       2.757       0.070
 88.00      -0.163      -0.163       0.168      -0.163      -0.163      -0.163      -0.163      -0.163       2.774       0.066
 89.00      -0.167      -0.167       0.164      -0.167      -0.167      -0.167      -0.167      -0.167       2.793       0.062
 90.00      -0.170      -0.170       0.160      -0.170      -0.170      -0.170      -0.170      -0.170       2.814       0.058
 91.00      -0.174      -0.174       0.155      -0.174      -0.174      -0.174      -0.174      -0.174       2.838       0.053
 92.00      -0.178      -0.178       0.151      -0.178      -0.178      -0.178      -0.178      -0.178       2.869       0.049
 93.00      -0.181      -0.181       0.147      -0.181      -0.181      -0.181      -0.181      -0.181       2.918       0.045
 94.00      -0.185      -0.185       0.143      -0.185      -0.185      -0.185      -0.185      -0.185       3.022       0.041
 95.00      -0.188      -0.188       0.138      -0.188      -0.188      -0.188      -0.188      -0.188       2.790       0.037
 96.00      -0.192      -0.192       0.134      -0.192      -0.192      -0.192      -0.192      -0.192       2.804       0.034
 97.00      -0.195      -0.195       0.130      -0.195      -0.195      -0.195      -0.195      -0.195       2.820       0.030
 98.00      -0.199      -0.199       0.126      -0.199      -0.199      -0.199      -0.199      -0.199       2.837       0.026
 99.00      -0.202      -0.202       0.122      -0.202      -0.202      -0.202      -0.202      -0.202       2.855       0.022
100.00      -0.206      -0.206       0.118      -0.206      -0.206      -0.206      -0.206      -0.206       2.875       0.018
NIL
CG-USER(91): (free-recall :scale 5 :decay 1.0)
(0.18 0.18 0.13 0.12 0.1 0.09 0.06 0.05 0.05 0.04)
CG-USER(92): (display-all-base-levels )
  0.00       0.057       0.057       0.057       0.057       0.057       0.057       0.057       0.057       0.057       0.057
  1.00       0.069       0.069       0.069       0.069       0.069       0.069       0.069       0.069       0.069       0.069
  2.00       0.077       0.077       0.077       0.077      -1.026       0.077       0.077       0.077       0.077       0.077
  3.00       0.083       0.083       0.083       0.083      -0.525       0.083       0.083       0.083       0.083      -1.270
  4.00       0.088       0.088       0.088      -1.598      -0.297       0.088       0.088       0.088       0.088      -0.617
  5.00      -2.069       0.090       0.090      -0.713      -0.163       0.090       0.090       0.090       0.090      -0.352
  6.00      -0.804       0.092       0.092      -0.406      -0.076       0.092       0.092       0.092       0.092      -0.202
  7.00      -0.455       0.092       0.092      -0.239      -0.016       0.092       0.092      -0.989       0.092      -0.106
  8.00      -0.273       0.092       0.092      -0.135       0.027       0.092      -1.227      -0.541       0.092      -0.041
  9.00      -0.161       0.091      -1.645      -0.064       0.059       0.091      -0.635      -0.327       0.091       0.006
 10.00      -2.180       0.089      -0.757      -0.014       0.082       0.089      -0.383      -0.200       0.089       0.040
 11.00      -0.703       0.087      -0.450       0.023       0.100       0.087      -0.239      -0.115       0.087       0.066
 12.00      -0.336       0.085      -0.284       0.050       0.114       0.085      -0.855      -0.057       0.085       0.085
 13.00      -0.150       0.082      -0.179       0.071       0.124       0.082      -0.396      -1.099       0.082       0.100
 14.00      -0.038       0.079      -0.107       0.087       0.132       0.079      -0.182      -0.506      -1.565       0.111
 15.00       0.037      -2.383      -0.056       0.099       0.137       0.076      -0.057      -0.255      -0.765       0.120
 16.00       0.089      -0.904      -0.019       0.108       0.141       0.072       0.024      -0.112      -0.473       0.126
 17.00       0.126      -0.543       0.010       0.115      -0.909       0.068       0.079      -0.020      -0.312       0.131
 18.00       0.154      -0.357       0.031       0.120      -0.478       0.065      -0.945       0.042      -0.210       0.134
 19.00       0.174      -0.243       0.048       0.124      -0.268       0.061      -0.389      -1.246      -0.140       0.136
 20.00       0.190      -0.165       0.061       0.126      -0.142       0.057      -0.146      -0.495      -1.706       0.137
 21.00      -2.636      -0.110       0.071       0.128      -0.058       0.052      -0.007      -0.208      -0.689       0.137
 22.00      -0.744      -0.070       0.078       0.128       0.001       0.048       0.082      -0.050      -0.366       0.137
 23.00      -0.351      -0.039      -0.976       0.128       0.043       0.044       0.143       0.049      -0.194       0.136
 24.00      -0.153      -0.016      -0.521      -1.202       0.076       0.040       0.187       0.116      -0.088       0.134
 25.00      -0.032       0.002      -0.305      -0.621       0.100       0.035       0.218      -1.339      -0.017       0.132
 26.00       0.048       0.017      -0.175      -1.923       0.119       0.031       0.242      -0.471       0.033       0.130
 27.00       0.104       0.028      -0.090      -0.625       0.133       0.026       0.259      -0.162       0.070       0.127
 28.00       0.146       0.037      -0.030      -0.278       0.144      -1.031       0.272       0.005       0.097       0.125
 29.00       0.176       0.043       0.014      -0.101      -1.087      -0.638       0.282       0.109       0.118       0.122
 30.00      -1.272       0.048       0.046       0.006      -0.521      -0.442       0.289       0.180       0.133       0.119
 31.00      -0.502       0.052       0.071       0.077      -0.272      -0.323       0.294      -1.591       0.145       0.115
 32.00      -0.208       0.055       0.090       0.126      -0.128      -0.242      -2.778      -0.483       0.154       0.112
 33.00      -0.046       0.057       0.105       0.162      -0.035      -0.185      -0.743      -0.138       0.161       0.108
 34.00       0.057       0.058       0.117       0.188       0.030      -0.143      -0.340       0.043      -1.007       0.105
 35.00       0.127      -1.345       0.126       0.208       0.077      -0.111      -0.136       0.154      -0.498       0.101
 36.00       0.177      -0.698       0.133       0.223       0.113      -0.087      -1.498       0.229      -0.264       0.097
 37.00       0.214      -0.433      -2.489       0.234       0.139      -0.067      -0.479       0.282      -0.127       0.093
 38.00       0.242      -0.283      -0.818       0.243       0.160      -0.052      -0.150       0.320      -0.037       0.089
 39.00       0.263      -0.186      -0.439       0.249       0.176      -0.040       0.025      -0.673       0.026       0.085
 40.00       0.280      -0.118      -0.245       0.253       0.188      -0.030       0.133      -0.205      -1.003       0.081
 41.00       0.292      -1.363      -0.126       0.256       0.198      -0.023       0.205       0.019      -0.427       0.077
 42.00       0.302      -0.604      -0.046       0.258       0.205      -0.017       0.256      -1.632      -0.178       0.073
 43.00       0.309      -0.318       0.011       0.259       0.211      -0.012       0.293      -0.390      -0.035       0.069
 44.00       0.314      -0.160       0.053      -0.840       0.215      -0.008       0.321      -0.030       0.058       0.065
 45.00       0.318      -0.061       0.085      -0.413      -0.990      -0.006       0.342       0.156       0.121       0.061
 46.00      -1.208       0.006       0.109      -0.202      -0.483      -0.004       0.357       0.270       0.167       0.057
 47.00      -0.507       0.055       0.128      -0.074      -0.249      -0.003       0.370       0.346      -1.528       0.053
 48.00      -0.224       0.090       0.143       0.011      -0.110      -0.002      -2.267       0.399      -0.530       0.049
 49.00      -0.064       0.117       0.154       0.072      -0.019      -0.002      -0.621       0.437      -0.201       0.045
 50.00      -0.699       0.137       0.164       0.116       0.046      -0.002      -0.230       0.466      -0.025       0.041
 51.00      -0.239       0.153       0.171       0.149       0.093      -1.229      -0.030       0.487       0.085       0.037
 52.00      -0.021       0.165       0.176       0.175      -1.206      -0.700       0.094       0.503       0.159       0.033
 53.00       0.108       0.174       0.180       0.195      -0.491      -0.464       0.176      -1.402       0.212       0.029
 54.00       0.193       0.181       0.183       0.211      -0.208      -0.327       0.235      -0.392      -2.089       0.025
 55.00       0.252       0.186       0.186       0.223      -0.050      -0.236       0.278      -0.052      -0.574       0.021
 56.00       0.295       0.190      -0.931       0.233       0.051      -0.173       0.311       0.130      -0.193       0.017
 57.00      -0.909       0.193      -0.485       0.240       0.121      -0.126       0.335       0.245       0.003       0.013
 58.00      -0.297       0.195      -0.269       0.246       0.171      -0.091       0.355      -1.123       0.123       0.009
 59.00      -0.034      -1.902      -0.139       0.250       0.208      -0.064       0.370      -0.270       0.202       0.005
 60.00       0.116      -0.745      -0.051       0.254       0.236      -0.043       0.381       0.044       0.259       0.001
 61.00       0.213      -0.400       0.010       0.256      -0.712      -0.027       0.391       0.216       0.300      -0.003
 62.00      -0.750      -0.218       0.056       0.258      -0.283      -0.013       0.398       0.324       0.330      -0.007
 63.00      -0.193      -0.104       0.090       0.258      -0.072      -1.358       0.403       0.398       0.354      -0.010
 64.00       0.055      -0.026       0.117       0.259       0.056      -0.680      -1.484       0.450       0.372      -0.014
 65.00       0.199       0.030       0.137      -2.207       0.141      -0.409      -0.528       0.489       0.385      -0.018
 66.00       0.292       0.071       0.154      -0.769       0.201      -0.257      -0.199       0.518       0.396      -0.022
 67.00       0.356       0.103       0.167      -0.398       0.245      -0.159      -0.020       0.540       0.404      -1.102
 68.00      -0.687       0.127       0.177      -0.206       0.278      -0.091       0.094       0.557       0.410      -0.704
 69.00      -0.145       0.146       0.186      -0.085       0.303      -0.042       0.172       0.571      -1.079      -0.507
 70.00       0.100       0.161       0.192      -0.004       0.322      -0.006      -1.296       0.581      -0.408      -0.387
 71.00       0.244       0.173       0.197       0.055       0.337       0.022      -0.413      -1.813      -0.130      -0.306
 72.00       0.337       0.183       0.201       0.099       0.349       0.043      -0.096      -0.447       0.029      -0.248
 73.00       0.402      -0.842       0.204       0.132       0.358       0.060       0.077      -0.066       0.132      -0.205
 74.00       0.448      -0.418       0.207       0.158      -0.836       0.074       0.186       0.133       0.204      -0.172
 75.00      -0.870      -0.208       0.208       0.178      -0.336       0.084       0.261       0.258       0.256      -0.147
 76.00      -0.196      -0.080       0.209       0.195      -0.100       0.092       0.315       0.342      -1.323      -0.126
 77.00       0.084       0.005       0.209       0.208       0.039      -2.104       0.355       0.403      -0.424      -0.110
 78.00       0.243       0.065       0.209       0.219       0.132      -0.798       0.385       0.447      -0.104      -0.097
 79.00      -0.419       0.110       0.209       0.227       0.197      -0.442       0.408       0.481       0.071      -0.086
 80.00       0.022      -0.891       0.208       0.234       0.245      -0.257       0.426       0.508       0.182      -0.077
 81.00       0.237      -0.380       0.207       0.239      -1.022      -0.141       0.441       0.529       0.257      -0.070
 82.00       0.367      -0.145       0.206       0.244      -0.354      -1.445       0.452       0.545       0.312      -0.064
 83.00       0.452      -0.007       0.204       0.247      -0.077      -0.566       0.461       0.558      -1.919      -0.059
 84.00       0.512       0.084       0.203       0.249       0.080      -0.259       0.467       0.568      -0.489      -0.056
 85.00       0.555       0.147       0.201       0.251       0.182      -0.093      -0.668       0.576      -0.108      -0.053
 86.00      -0.574       0.193       0.199       0.252       0.252       0.010      -0.226       0.583       0.090      -0.050
 87.00      -0.040       0.227       0.197       0.253       0.302       0.080      -0.007      -0.921       0.212      -0.048
 88.00       0.206       0.253       0.195       0.253      -1.238       0.130       0.126      -0.272       0.294      -0.047
 89.00       0.351      -1.777       0.192       0.253      -0.377       0.167       0.216       0.006       0.352      -0.046
 90.00       0.446      -0.582       0.190       0.253      -0.062       0.194       0.280       0.166       0.395      -0.046
 91.00       0.512      -0.227       0.187       0.252       0.111       0.215       0.327       0.272      -0.561      -0.046
 92.00       0.560      -0.040       0.185       0.251       0.220       0.231      -0.748       0.345      -0.115      -0.046
 93.00       0.596      -0.910       0.182       0.250       0.295       0.243      -0.218       0.399       0.104      -0.046
 94.00       0.624      -0.283       0.179       0.248       0.349       0.253       0.027      -1.160       0.236      -0.047
 95.00      -1.601      -0.020       0.177       0.247       0.388       0.260       0.171      -0.298       0.324      -0.048
 96.00      -0.318       0.129       0.174       0.245       0.419       0.266       0.266       0.022       0.386      -0.049
 97.00       0.059       0.225       0.171       0.243       0.442       0.270       0.333       0.198       0.432      -1.069
 98.00       0.258       0.290       0.168       0.241       0.460       0.273       0.382      -0.561       0.466      -0.671
 99.00      -0.631       0.337       0.165       0.239       0.474       0.275       0.419      -0.042       0.492      -0.473
100.00      -0.018       0.371       0.162       0.237       0.486       0.276       0.447      -0.906       0.513      -0.353
NIL
|#
