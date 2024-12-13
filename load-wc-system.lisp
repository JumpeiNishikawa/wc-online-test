(format  t "LOADING!!!!!!~%")
;起動がnodejs以下
(load "./actr/load-act-r.lisp")

(sleep 5);ACT-R立ち上げる→nodeサーバ立ち上げる→モデルロードの順にしてみる

(load "./actr/wc/wc-system.lisp" )