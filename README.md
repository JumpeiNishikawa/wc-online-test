# しりとりシステム

## デモ

重くて撮ってられないのでデモなし

<!-- 
See the following page for how to make a README with gif
https://qiita.com/i-to-to-to-mi/items/e73eb0a5899f111d0e64
-->

## 環境

* Common Lisp implementations (SBCL 2.1.5; macOS)
* QuickLisp
* ACT-R Version 7.21.6-<3099:2020-12-21>

## 使い方

現在はHTML版のみ開発中

1. 環境立ち上げ
    - commandファイルをダブルクリック（Macのみ）

        ```
        run-wcｰhtml.command
        ```

    - 諸々手動

        ```
        $ cd nodejs
        $ node wc_system.js
        ```

        ```
        $ cd wc_system/wc
        ~/wc_system/wc$ sbcl

        * (load "../load-act-r.lisp")
        * (load load "wc-system.lisp")
        ```

        `http://localhost:4000/wc_window.html`にアクセス

1. ターミナルを眺めてモデルがロード完了するまで待機

1. ブラウザのStartボタンで実行

<!-- 
1. commandファイルを整備したのでMacの人はそれっぽいのをダブルクリック


    ```
    run-wc.command #txl.tk版
    run-wcｰhtml.command #ブラウザ版
    ```
    
    立ち上がったらRUN！

    ```
    * (run-trial-debg)
    ```

    繰り返し
    ```
    * (run-trial-debg)
    
    ;これが終了したら
    * (run-trial-w-monitor "ひらがな")
    ```

    今のところはどっちも対応してるけど，今後は"キレイな"HTMLを用意してブラウザ版のみになる予定（というかスマホサイズになる予定）

1. ソースコードから実行する場合は以下の手順
    1. ワーキングディレクトリに移動してACT-Rをロード

        ```
        $ cd wc_system/wc
        ~/wc_system/wc$ sbcl

        * (load "../load-act-r.lisp")
        ```

    1. 必要ならGUI環境を立ち上げる．環境に合わせて以下のファイルをダブルクリック

        ```
        wc_system/environment/ start-environment-osx
        wc_system/environment/ Start Environment.exe
        wc_system/environment/ start environment Linux
        ```

    1. モデルをロードしてRUN！
        ```
        * (load "wc_system_model.lisp")

        * (run-trial-debg)
        ```
-->