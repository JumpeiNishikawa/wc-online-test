/**
 * @file lib/ACTRClient.js
 *
 */
"use strict";

const unusedPort = require("./util/unusedPort");
const fs = require('fs');
const net = require('net');
const home = process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH;

/**
* @class ACTRClient
* ACT-Rとの通信を行うクライアントをクラス化する．
*/
class ACTRClient {
    /**
    * @constructor
    * @param {string} command - 実行可能ファイル
    * @param {string[]} args - コマンドライン引数の配列
    * @param {string} username - ログが確認しやすくなるようユーザ名
    * @param {log4js} logger - ロガー
    * @param {string} isLoaded - ACT-Rロード済みかどうか
    * @param {string} isModelLoaded - モデルファイルがロード済みかどうか
    */
    constructor(username, address, port, io, socket, clientModelDict, logger) {
        this.username = username;
        this.io = io;
        this.socket = socket;
        this.clientModelDict = clientModelDict;
        this.logger = logger;

        this.client = new net.Socket();
        this.address = address;
        this.port = port;

        this.windows = {}
        //// count how many exp window viewers there are and return false
        //// for display if there aren't any
        //var expcount = 0;
        // Map of id values to client connections
        this.idtoclientMap = new Map;
        // Next id number to use in a request
        this.idnum = 0;
        // record the actions sent for reference on
        // an error
        this.sentactionMap = new Map;
        // record the added commands so we know who
        // to send the evaluates to
        this.actionMap = new Map;
        // record the pending evaluates so that error
        // results can be returned if the socket disconnects
        this.pendingMap = new Map;
        // keep track of the internal id (unique) to external id (may not be unique)
        // mapping for actions
        this.idtoidMap = new Map;
        this.cmdMap = new Map;
        this.partial_data = '';
    }

    /**
    * @member setup
    * @private
    * 大量のイベントリスナを定義する
    * 
    */

    async setup() {
        this.client.connect(this.port, this.address);

        this.client.on('data', async (data) => {
            this.logger.info("name: " + this.username + ", now recieve some data! " + data);

            let end = -1;
            let start = 0;

            // do we have a message to parse yet
            if (data.indexOf("\u0004", start) == -1) {
                this.partial_data = this.partial_data + data;
            } else {
                data = this.partial_data + data;
                while ((end = data.indexOf("\u0004", start)) != -1) {
                    var m;

                    try {
                        m = JSON.parse(data.slice(start, end));
                        this.logger.info("name: " + this.username + ", JSON.parse: " + m);
                    } catch (err) {
                        this.logger.error(err.message);
                        this.logger.error("name: " + this.username + ", while processing incoming data data =" + data);
                    }

                    if (m && m.result) {
                        // send the result to the originator
                        var sender = this.idtoclientMap.get(m.id);

                        if (sender) {
                            this.idtoidMap.get(m.id)(true, m.result);
                            this.idtoclientMap.delete(m.id);
                        }

                        this.idtoidMap.delete(m.id);
                        this.sentactionMap.delete(m.id);
                    }

                    if (m.error) {
                        // send the error message to the originator
                        var sender = this.idtoclientMap.get(m.id);
                        if (sender) {
                            this.idtoidMap.get(m.id)(false, m.error.message);
                            this.idtoclientMap.delete(m.id);
                        }
                        this.logger.error("name: " + this.username + ", Error result: " + m.error.message + "for sending action: " + this.sentactionMap.get(m.id));

                        this.idtoidMap.delete(m.id);
                        this.sentactionMap.delete(m.id);
                    }
                    var response = "true";

                    if (m.method && m.params) { // A request to evaluate a command
                        this.logger.info("name: ", this.username, ", m.method", m.method, ", m.params", m.params);
                        if (m.method == "my_event") {
                            this.logger.info("name: ", this.username, ", recieve my_event with: ", m.params);
                        }
                        if (m.method == "evaluate") { // to be safe check and make sure 
                            if (m.params[0] == "vv") { // it's the exp window command handled here      
                                // ignore the model parameter which would be params[1]
                                // and just use the list of virtual-view info which is
                                // the only other parameter.
                                let p = m.params[2];
                                let model = m.params[1];
                                // Virtual view data not actually documented yet other than
                                // in the comments of the tools/visible-virtual.lisp file.
                                // So you'll need to check there to know what these are.
                                this.logger.info("name: " + this.username + ", " + p);
                                var id_1 = this.socket.id;
                                switch (p[0]) {
                                    case "open":
                                        // just record the details, will need the main position
                                        // to add to the item coords since they're window local 
                                        // and the other corner for determining if a mouse click
                                        // is within the window.
                                        this.windows[p[1]] = { "x1": p[2], "x2": p[2] + p[4], "y1": p[3], "y2": p[3] + p[5], "items": {} };

                                        await this.io.to(id_1).emit("open", []);

                                        this.logger.info("name: " + this.username + ", enable_send_button=open");
                                        //ACT-Rのウィンドウが開いたら＝ACT-Rがロードできたら，sendボタンを使えるようにする
                                        await this.io.to(id_1).emit('enable_send_button', "");

                                        break;
                                    case "text":
                                        let w = this.windows[p[1]];
                                        this.logger.info("name: ", this.username, ", case text, windows[p[1]]: ", w, "")
                                        if (w != undefined) { // safety check because we might have missed
                                            // the open if we connected after the window was opened
                                            // create a name for the item which is a combo of the window and the item
                                            let name = p[1] + "_name_" + p[2];

                                            // record the name for use when the window is closed
                                            w["items"][name] = true;

                                            // send the details to all the connected viewers
                                            //expio.emit("add",[name,"text",p[3]+w["x1"],p[4]+w["y1"],p[5],p[6],p[7]]);
                                            //expio.emit("add",[name,"text",p[3]+w["x1"],p[4]+w["y1"],p[5],p[6],p[7], model]); //モデル名も送信数する
                                            //ここ，ブラウザに単語とモデルを送信
                                            this.logger.info("name: " + this.username + ", text:::: " + p[5]);
                                            //io.to(room).emit('server_to_client', {value : `[${model}]: ${p[5]}`});
                                            await this.io.to(id_1).emit("add", [name, "text", p[3] + w["x1"], p[4] + w["y1"], p[5], p[6], p[7], model]);
                                        }
                                        break;
                                    //line, button attention, cursor, remove, clearcursor, clearattentionを削除，必要ならwc_system参照
                                    case "close":
                                        w = this.windows[p[1]];
                                        if (w != undefined) {
                                            // send the remove for everything 
                                            for (var i in w["items"]) {
                                                await this.io.to(id_1).emit("remove", i);
                                            }
                                            w["items"] = {};
                                        }
                                        // get rid of the window 
                                        delete this.windows[p[1]];
                                        break;
                                    case "check":
                                        // If there aren't any open connections
                                        // report that we aren't displaying things.
                                        this.logger.info("name: " + this.username + ", expcount: " + this.expcount);
                                        if (this.expcount == 0) { response = "false"; }
                                        break;
                                    case "retrieval-fail":
                                        this.logger.info("name: " + this.username + ", retrieval-fail: " + p[1]);
                                        break;
                                }
                                if (m.id) { // if there was an id just return the current response
                                    this.client.write("{\"result\": [" + response + "],\"error\":null,\"id\":" + JSON.stringify(m.id) + "}\u0004");
                                }

                            } else { // it's someone else's so figure out who and send it along
                                var sender = this.actionMap.get(m.params[0]);
                                if (sender) {
                                    if (m.id) { // record 
                                        this.idtoidMap.set(this.idnum, m.id);
                                        if (this.pendingMap.get(sender)) {
                                            this.pendingMap.get(sender).set(this.idnum, true);
                                        } else {
                                            var nm = new Map;
                                            nm.set(this.idnum, true);
                                            this.pendingMap.set(sender, nm);
                                        }
                                    }
                                    cmd = m.params.shift();
                                    let client_cmd = this.cmdMap.get(cmd);
                                    m.params.unshift(client_cmd);

                                    await sender.emit("evaluate", m.params, this.idnum);
                                    this.idnum++;
                                } else { // sender is gone so return error
                                    if (m.id) {
                                        this.client.write("{\"result\": null,\"error\":{\"message\": \"Error with evaluating " + JSON.stringify(m.params) + "\"},\"id\":" + JSON.stringify(m.id) + "}\u0004");
                                    }
                                }
                            }
                        } else { // shouldn't happen 
                            this.logger.info('name: ' + this.username + ', Invalid message: ' + data.slice(start, end));
                        }
                    }
                    start = end + 1;
                }

                if (start < data.length) {
                    this.partial_data = data.slice(start);
                } else {
                    this.partial_data = "";
                }
            }
        });

        this.client.on('error', (error) => {
            this.logger.error("name: " + this.username + ", " + error.message);
            throw new Error("lost contact with ACT-R so must exit.");
        });
        this.client.on('connect', () => {
            this.logger.error("name: " + this.username + ", client.on('connect')");
        });
        this.client.on('end', () => {
            this.logger.error("name: " + this.username + ", client.on('end')");
            throw new Error("lost contact with ACT-R so must exit.");
        });
        this.client.on('close', () => {
            this.logger.error("name: " + this.username + ", client.on('close')");
        });
        this.client.on('timeout', () => {
            this.logger.error("name: " + this.username + ", client.on('timeout')");
        });
    }
}

module.exports = ACTRClient;