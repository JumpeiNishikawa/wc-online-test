/**
 * @file lib/ActrServer.js
 *
 */
"use strict";

const child_process = require("child_process");
const debug = require("debug")("Admin");
const treeKill = require("tree-kill");

/**
* @class ACTRServer
* ACT-Rプロセスを作成，管理する
* ユーザ一人に対して一つのインスタンスを作成する
* n回setup()を呼んでn体のプロセス（モデル）を追加
*/
class ACTRServer {
    /**
    * @constructor
    * @param {string} command - 実行可能ファイル
    * @param {string[]} args - コマンドライン引数の配列
    * @param {string} username - ログが確認しやすくなるようユーザ名
    * @param {log4js} logger - ロガー
    * @param {string} isLoaded - ACT-Rロード済みかどうか
    * @param {string} isModelLoaded - モデルファイルがロード済みかどうか
    */
    constructor(command, args, username, logger) {
        /** 実行可能ファイル */
        this.command = command;
        /** コマンドライン引数の配列 */
        this.args = args;
        /** ユーザ名 */
        this.username = username;
        /** ロガー */
        this.logger = logger;

        /** ACT-Rのリスト */
        this.servers = Object.create(null);

        this.isLoaded = false;
        this.isModelLoaded = false;
    }

    /**
    * @member setupServer
    * @private
    * 指定したポートでACT-Rプロセスを開始
    * 
    */

    async setup(port) {
        try {
            let server;
            // 二重起動およびポートの競合を避けるため同期化する
            //↑細川くんのコードここがわからない
            if (this.servers[port]) {
                return null
            };

            // 取得したポート番号をコマンドラインに入れる
            const portSetting = `(defparameter *given-port* ${port})`;
            //this.args[this.args.indexOf('portSetting')] = portSetting;
            this.args[1] = portSetting;

            //debug(`setting up ACT-R server process for port ${port}`);
            //debug(`spawn "${this.command} ${this.args}"`);
            //console.log(`setting up ACT-R server process for port ${port}`);
            //console.log(`spawn "${this.command} ${this.args}"`);
            this.logger.info(`name: ${this.username}, setting up ACT-R server process for port ${port}`);
            this.logger.info(`name: ${this.username}, spawn "${this.command} ${this.args}"`);

            server = child_process.spawn(this.command, this.args);
            this.servers[port] = { server };

            server.stdout.on('data', (data) => {
                //console.log(`----- ACT-R -----\n${data}`);
                this.logger.info(`name: ${this.username}, ----- ACT-R -----\n${data}`);
                if (data.toString().match('===ACT-R loaded===')) { // -> load-shiritori.lisp
                    this.isLoaded = true;
                    this.logger.info(`name: ${this.username}, detect ===ACT-R loaded===`);
                } else if (data.toString().match('===model file loaded===')) {
                    this.isModelLoaded = true;
                    this.logger.info(`name: ${this.username}, detect ===model file loaded===`);
                }
            });

            //this.isLoaded = trueになったら完了
            let count = 0;
            while (count < 10) { //10秒待ってダメなら一旦止める
                await new Promise(resolve => setTimeout(resolve, 1000));
                if (this.isLoaded) {
                    this.logger.info(`name: ${this.username}, this.isLoaded, ${this.isLoaded}`);
                    return "isLoaded";
                }
                this.logger.info(`name: ${this.username}, waiting this.isLoaded..., ${this.isLoaded}, count ${count}`);
                count++;
            }
            this.logger.info(`name: ${this.username}, this.isLoaded, rejected`);
            throw new Error(`name: ${this.username}, ACT-R is not loaded`);
        } catch (e) {
            console.error(e)
            this.logger.error('name: ${this.username}', e)
        }
    }

    async load(port, file) {
        try {
            this.servers[port].server.stdin.write(`(load "${file}")\n`)
            this.logger.info(`name: ${this.username}, this.isModelLoaded, ${this.isModelLoaded}`);
            //ここの完了条件はsetup関数で定義済み
            //this.isModelLoaded = trueになったら完了
            let count = 0;
            while (count < 100) {//100秒待ってダメなら一旦止める，なんか時間かかる
                await new Promise(resolve => setTimeout(resolve, 1000));
                if (this.isModelLoaded) {
                    this.logger.info(`name: ${this.username}, this.isModelLoaded, ${this.isModelLoaded}`);
                    return "isModelLoaded";
                }
                this.logger.info(`name: ${this.username}, waiting this.isModelLoaded..., ${this.isModelLoaded}, count ${count}`);
                count++;
            }
            this.logger.info(`name: ${this.username}, this.isModelLoaded, rejected`);
            throw new Error(`name: ${this.username}, Model is not loaded`);

        } catch (e) {
            console.error(e)
            this.logger.error('name: ${this.username}', e)
        }
    }

    /**
    * @member kill
    * @private
    * 対象のサーバーを終了
    * プロセスを強制終了
    */
    async kill(port) {
        if (!this.servers[port]) {
            throw new Error('!this.servers[port]');
        };

        debug(`killing ACT-R server process for port ${port}`);

        treeKill(this.servers[port].server.pid);
        delete this.servers[port];
        return "killed";
    }
    /**
    * @member killAll
    * すべてのサーバーを終了する
    * 
    */
    async killAll() {
        Object.keys(this.servers).map(async (port) => {
            await this.kill(port)
            return "all_killed1";
        });
        return "all_killed2";
    }
}

module.exports = ACTRServer;