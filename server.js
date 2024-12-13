const express = require('express');
const app = express();
const http = require('http');
const server = http.createServer(app);

//記録用に，実際に指定しているのはt2s_ipa_filter内
//const condition="correct"
//const condition="_sim1"//concat
//const condition="_sim2"//ave
//const condition="_w"//consonants deletion
//const suffix = "_kana.mp3"

//const condition = "_sim1_part"//concat
const condition_global = "_all_vowel_splited"//all vowel filter
//const condition = "_sim2_part"//ave

const log4js = require('log4js');
//config
log4js.configure({
    disableClustering: true,
    appenders: {
        console: { type: "console" },
        system: { type: 'file', filename: 'log/system.log', pattern: '-yyyy-MM-dd' }
    },
    categories: {
        default: { appenders: ['console', 'system'], level: 'all' }
    }
});
const logger = log4js.getLogger();
logger.debug('DEBUG Nishikawa')
app.use(log4js.connectLogger(logger));

const fs = require('fs');
const net = require('net');
const unusedPort = require("./util/unusedPort");

//const ActrAdmin = require('./ActrAdmin');
const is_mac = process.platform === 'darwin'
const ACTRServer = require('./ACTRServer');
const { SSL_OP_EPHEMERAL_RSA } = require('constants');
const { rejects } = require('assert');
const { resolve } = require('path');
const path = require('path');
const { log } = require('console');
const actrCommand = 'sbcl1.4'; // SBCL実行可能ファイル，サーバでは変える必要がある？
logger.info("General info: " + actrCommand)
const ACTRClient = require('./ACTRClient');

const actrArgs = ['--eval', 'portSetting', '--load', 'load-actr-r-with-msg.lisp'];
const home = process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH;

const sleep = ms => new Promise(resolve => setTimeout(() => resolve(ms), ms));

//ここに全て記録する．{id:{ "name": username, "id": id, "actr": actr, "client": client, "expLogFile": expLogFile }{}{}}ゆくゆくはDBに？
var clientModelDict = {};

///////125行目あたり参照．client.on()の中身をよく読んで必要なさそうならけずる
// count how many exp window viewers there are and return false
// for display if there aren't any
var expcount = 0;
///////
const DEFAULT_EXPTIME = 30;
const DEFAULT_BRANCH_FOR_EXP = ['dl-box','two-robots'];

const { execSync } = require('child_process');
function getGitBranch() {
    try {
        const wd = execSync('pwd').toString().replace('\n', ''); //一旦チェック用
        const gitBranch = execSync('git branch --contains | cut -d " " -f 2').toString().replace('\n', '');
        return { "wd": wd, "gitBranch": gitBranch };
    } catch (e) {
        logger.error(e.toString());
        return null;
    }
}

function getNumOfExp(expdate){
    let fileCount = 0;
    const basepath = path.resolve(__dirname, "expLog");
    const allFiles = fs.readdirSync(basepath);

    allFiles.forEach((file) => {
        const filePath = path.join(basepath, file);
        const stats = fs.statSync(filePath);

        if(stats.isFile() && stats.birthtime > expdate) {
            fileCount++;
        }
    });
    logger.info("allFiles[0]:", allFiles[0]);
    logger.info("allFiles:", allFiles.length, "files after", expdate, ":", fileCount);
    return fileCount;
}

// S02. HTTPサーバを生成する
web_servport = 3000
server.listen(web_servport, () => {
    logger.info("General info: listening on " + web_servport);
});
//var server = http.createServer(function(req, res) {
//    res.writeHead(200, {'Content-Type' : 'text/html'});
//    res.end(fs.readFileSync(__dirname + '/shiritori.html', 'utf-8'));
//}).listen(3000);  // ポート競合の場合は値を変更
app.get('/node2/wc-online-test/', (req, res) => {
    if (req.query.exptime) {
        res.sendFile(__dirname + '/shiritori.html');
        logger.info("exptime is set:", req.query.exptime);
    } else {
        res.redirect(`/node2/wc-online-test/?exptime=${DEFAULT_EXPTIME}`)
        logger.info("there is no query, exptime is set default");
    }
});
app.use('/node2/wc-online-test/img/1.png', (req, res) => {
    res.sendFile(__dirname + '/img/1.png');
});
app.use('/node2/wc-online-test/img/speaker.png', (req, res) => {
    res.sendFile(__dirname + '/img/speaker.png');
});
app.use('/node2/wc-online-test/', express.static(__dirname + '/audio_cache_ipa'));
app.use('/node2/wc-online-test/', express.static(__dirname + '/words'));

app.get('/node2/wc-online-test/serverGitInfo', (req, res) => {
    let serverInfo = getGitBranch();
    logger.info('Working directory:', serverInfo["wd"], 'git branch: ', serverInfo["gitBranch"]);
    res.send('Working directory:' + serverInfo["wd"] + ', git branch: ' + serverInfo["gitBranch"]);
});

//http://133.70.173.112/node2/wc-online-test/numOfExp?date=2023-1-1 のようなリクエスト
app.get('/node2/wc-online-test/numOfExp', (req, res) => {
    let exp_start_date="";
    if(req.query.date){
        exp_start_date = new Date(req.query.date);
    }else{
        exp_start_date = new Date("2020-1-1");//テキトーな日付
    }
    let num_of_exp = getNumOfExp(exp_start_date);
    logger.info('General info: num_of_exp: ', num_of_exp, "by", exp_start_date);
    let result = {numOfExp: num_of_exp};
    res.send(result);
});

// S03. HTTPサーバにソケットをひも付ける（WebSocket有効化）
const io = require('socket.io')(server, { path: '/node2/wc-online-test/socket.io', transports: ['websocket'] });

// S04. connectionイベントを受信する
io.sockets.on('connection', async (socket) => {
    logger.info('General info: Expwindow connected', socket.id);
    var NAME = '';

    //socketが繋がったらgit情報をチェック，httpリクエストの瞬間に返したい気もするが方法がわからん
    let serverInfo = getGitBranch();
    let gitBranch = serverInfo["gitBranch"];
    logger.info("gitBranch", gitBranch, "typeof: ", typeof gitBranch);
    logger.info("DEFAULT_BRANCH_FOR_EXP", DEFAULT_BRANCH_FOR_EXP, "typeof:", typeof DEFAULT_BRANCH_FOR_EXP)

    if (!DEFAULT_BRANCH_FOR_EXP.includes(gitBranch)) {
        logger.info(`Different branch: Current ${gitBranch} and experiment default ${DEFAULT_BRANCH_FOR_EXP}`);
        await io.to(socket.id).emit('check_git_branch', { value: gitBranch });
    }

    socket.on('client_to_server_join', async (data) => {
        NAME = data.name;
        let id = socket.id;

        logger.info('name:', NAME, 'client_to_server_join:', data);

        //ACT-Rプロセスを作成する
        expcount++;
        await createACTRprocess2(NAME, id, socket);//awaitが必要だとしたらここ？
    });

    // S08. client_to_server_personalイベント・データを受信し、送信元のみに送信する
    socket.on('client_to_server_personal', async (data) => {
        //NAMEは定義済みのはずチェック
        if (NAME == data.value) {
            logger.info(NAME, "が入室")
        } else {
            logger.warn("サーバの保持するNAME", NAME, "と，クライアントの情報data.value", data.value, "が異なります．")
        }
        let id = socket.id;

        //個人（roomの中でも特定の人）に送るとき，idで指定するらしい
        let personalMessage = "あなたは、" + NAME + "さんとして入室しました。"
        await io.to(id).emit('server_to_client', { value: personalMessage });
    });

    // S09. dicconnectイベントを受信し、退出メッセージを送信する
    socket.on('disconnect', async () => {
        //let room = socket.adapter.rooms.keys[1];//これで取れる気がするが確証はない
        let id = socket.id;

        logger.info('Expwindow disconnected: ', id);
        if (NAME == '') {
            logger.info("未入室のまま、どこかへ去っていきました。");
        } else {
            let username = clientModelDict[id]["name"];
            logger.info('NAME:', NAME, "username from id:", username);

            var endMessage = NAME + "さんが退出しました。"
            logger.info(endMessage);
            await io.to(id).emit('server_to_client', { value: endMessage }); //この辺のroomとかnameはどこで特定されてるんだ？
        }
        await killACTRproccess(id)
        expcount--;//サーバ再起動の瞬間にすでにアクセスしているブラウザがあり，リロードされるとバグる（カウントがマイナスになる）
        if (expcount < 0) {
            expcount = 0
            logger.warn('expcountが負になりました．サーバ再起動中も接続していたクライアントがある可能性があります．');
        }//上のバグをとりあえず修正
    });
    socket.on('reconnect', async () => {
        let name = clientModelDict[socket.id]["name"];
        logger.warn(`name: ${name}, socket reconnected`);
    });
    socket.on('connect_failed', async () => {
        let name = clientModelDict[socket.id]["name"];
        logger.warn(`name: ${name}, connect_failed`);
    });

    socket.on('game_start', async (data) => {
        logger.info('game_start', data.name);
        let id = socket.id;

        let first_word = await select_1st_word(NAME);//ログ用に名前を送る
        logger.info("name:", NAME, "first_word:", first_word)

        let model_color_order = await shuffle_model_color_order();
        let name = clientModelDict[id]["name"]
        logger.info('name:', name, "model_color_order", model_color_order);

        let expLogFile = clientModelDict[id]["expLogFile"];

        logger.info('name:', name, "clientModelDict", clientModelDict);
        //これだとログファイルの2行目になっちゃって微妙，あとで考える．　ここに実験条件も記録しておく
        let model_color_data = JSON.stringify(model_color_order);
        let exp_info_order_and_cond = `${model_color_data},${condition_global}\n`
        await appendFile(expLogFile, exp_info_order_and_cond);

        //ウィンドウに表示: [??, "text", x,y, word, color, size]
        await io.to(id).emit('add', ["no", "question", 10, 10, first_word, "black", 44, model_color_order])
        //ACT-Rに送る
        await sendMessageToACTR(id, first_word)
    });

    socket.on('next', async (data) => {
        let id = socket.id;
        let word = data.value;
        logger.info("continue, ", data.name, word)

        //ウィンドウに表示: [??, "text", x,y, word, color, size]
        await io.to(id).emit('add', ["no", "question", 10, 10, word, "black", 44])
        //ACT-Rに送る
        await sendMessageToACTR(id, word)
    });

    socket.on('log', async (data) => {
        let candidates_len = data.value.candidates.length;
        let id = socket.id;
        //format log string
        let expLogData = data.value['Time'] + ',' + data.value['Word'] + ',' + data.value['Model'];
        for (let i = 0; i < candidates_len; i++) {
            expLogData = expLogData + ',' + data.value.candidates[i].replace(',', '_')
        }
        expLogData = expLogData + "\n";
        let expLogFile = clientModelDict[id]["expLogFile"];
        await appendFile(expLogFile, expLogData);
    });

    socket.on('utter', async (word) => {
        //let room_name = socket.adapter.rooms.keys[1];//ここでルーム名が取れそう
        let id = socket.id;
        await t2s_ipa_filter(condition_global, word, id).then(async result => {
            logger.info("name:", NAME, "spokenWord_server: ", result);
            await io.to(id).emit('spokenWord', [result]);
        });
    });
});

async function shuffle_model_color_order() {
    //決めうち，いずれmp-modelsなんかをリクエストして自動取得するようにしたい？その場合はcssで色指定する方法も連動して変えないといけない
    //client.write("ACT-Rさん，モデルのリストをください！");
    //let models = ["MP10-SIM1", "MP30-SIM1", "MP10-SIM2", "MP30-SIM2"]; //手で書く用
    //let colors = ["red", "blue", "green", "black"]
    //;2024/05/31 同じ類似度テーブルを比較する実験 このプロジェクトはmp1-sim1とmp10-sim2, no model
    let models = ["MP10-SIM1", "MP10-SIM2"]; //手で書く用
    let colors = ["red", "blue"]

    let shuffled_models = shuffle_list(models);
    let shuffled_colors = shuffle_list(colors);

    let shuffled_pairs = {}

    for (let i = 0; i < models.length; i++) {
        shuffled_pairs[shuffled_models[i]] = shuffled_colors[i];
    }
    logger.info("shuffle_model_color_order", shuffled_pairs);
    return shuffled_pairs;
}
function shuffle_list(l) {
    let shuffled_order = [...l]; //実際に操作するリスト，上のコピー
    for (let i = (shuffled_order.length - 1); 0 < i; i--) {
        //0からi+1の範囲の乱数
        let r = Math.floor(Math.random() * (i + 1));
        //並び替え
        let tmp = shuffled_order[i];
        shuffled_order[i] = shuffled_order[r];
        shuffled_order[r] = tmp;

    }
    return shuffled_order;
}

async function createACTRprocess2(username, id, socket) {
    const address = fs.readFileSync(home + "/act-r-address.txt", 'utf8'); //"10.70.175.249" //localhost
    const port = await unusedPort();
    const actr = new ACTRServer(actrCommand, actrArgs, username, logger);
    const modelFile = "./actr/wc/wc-system.lisp";
    
    let expLogFile = "";
    //ここに書くだけで大丈夫か，今までとはタイミングが異なる
    //実験ログ
    let fileNameTime = null;
    let nowTime = new Date();
    let nowYear = nowTime.getYear() + 1900;
    let nowMonth = nowTime.getMonth() + 1;
    let nowDate = nowTime.getDate();
    let nowHour = nowTime.getHours();
    let nowMin = nowTime.getMinutes();
    let nowSec = nowTime.getSeconds();
    let nowMs = nowTime.getMilliseconds();
    fileNameTime = String(nowYear) + String(nowMonth) + String(nowDate) + String(nowHour) + String(nowMin) + String(nowSec) + String(nowMs);

    //ファイル名のみここで確定させるが，まだ書き込まない（ファイルは作成しない）
    //let expLogRow = "Time,Word,Model,candidate0,candidate1,candidate2,candidate3\n";
    expLogFile = "./expLog/log_" + username + "_" + fileNameTime + ".csv";

    //fs.writeFileSync(expLogFile, expLogRow, (err_1) => {
    //    if (err_1) { throw err_1; }
    //});

    const actrclient = new ACTRClient(username, address, port, io, socket, clientModelDict, logger, expLogFile);

    //子プロセスを作り，ACT-Rをロードする
    logger.info("name:", username, ", address:unusedport", address + ":" + port);
    await actr.setup(port);

    logger.info("name:", username, ", waiting...");
    logger.info("name:", username, ", connecting address:unusedport", address + ":" + port);
    //ACT-Rと接続する↑でawaitしてるので大丈夫なはず
    await actrclient.setup();//client.connect(port, address);
    logger.info("name: ", username, ", client connected");

    // Set the name for this client
    actrclient.client.write("{\"method\":\"set-name\",\"params\":[\"SHIRITORI Chat client\"],\"id\":null}\u0004");
    // Add a new command called "node-js-vv-relay" which will be referred to as "vv" locally.
    actrclient.client.write("{\"method\":\"add\",\"params\":\[\"node-js-vv-relay-s\",\"vv\",\"Virtual window handler for browser based display. Do not call.\"\],\"id\":null}\u0004");
    // Evaluate the ACT-R "add-virtual-window-handler" command so that node-js-vv-relay gets called to display visible virtual window items.
    actrclient.client.write("{\"method\":\"evaluate\",\"params\":[\"add-virtual-window-handler\",false,\"node-js-vv-relay-s\"],\"id\":null}\u0004");

    clientModelDict[id] = { "name": username, "id": id, "actr": actr, "client": actrclient.client, "actrclient": actrclient, "expLogFile": expLogFile }; //ここではexpLogFileは空，openが呼ばれたときに置換する
    logger.info("name: ", username, ", ADD clientModelDict:", clientModelDict);

    //clientModelDict[id]["expLogFile"] = expLogFile; //子の処理はびみょい，うまくexplogfileをメインのプロセスに返すようにしたい．
    //client.write("{\"method\":\"list-connections\",\"params\": false ,\"id\":null}\u0004");
    //room2modelList.push([username, room, actr, client, expLogFile]);//ここではexpLogFileは空，openが呼ばれたときに置換する

    //モデルをロードする
    logger.info("name: " + username + ", model load, unusedport:" + port + ", address: " + address);
    await actr.load(port, modelFile);

    logger.info("name: " + username + ", actr.isModelLoaded: " + actr.isModelLoaded);

    return "createACTRprocess";
}

//クラス化してえな
async function createACTRprocess(username, id, socket) {
    ////定数
    const address = fs.readFileSync(home + "/act-r-address.txt", 'utf8'); //"10.70.175.249" //localhost
    const actr = new ACTRServer(actrCommand, actrArgs, username, logger);
    //var modelFile = "demo.lisp";
    const modelFile = "./actr/wc/wc-system.lisp";

    const client = new net.Socket();
    const port = await unusedPort();

    //子プロセスを作り，ACT-Rをロードする
    logger.info("name:", username, ", address:unusedport", address + ":" + port);
    await actr.setup(port);

    logger.info("name:", username, ", waiting...");
    logger.info("name:", username, ", connecting address:unusedport", address + ":" + port);
    //ACT-Rと接続する↑でawaitしてるので大丈夫なはず
    client.connect(port, address);
    logger.info("name: ", username, ", client connected");
    //environment.jsから移植．必要ない機能はいずれ削る，この辺の変数は絶対に悪さをする．
    // Record of the window information for the visible virtual windows
    windows = {}//こいつが悪さをしていそうな予感，スコープがよくわからんし
    logger.info("name:", username, ", windows", windows);
    //// count how many exp window viewers there are and return false
    //// for display if there aren't any
    //var expcount = 0;
    // Map of id values to client connections
    var idtoclientMap = new Map;
    // Next id number to use in a request
    var idnum = 0;
    // record the actions sent for reference on
    // an error
    var sentactionMap = new Map;
    // record the added commands so we know who
    // to send the evaluates to
    var actionMap = new Map;
    // record the pending evaluates so that error
    // results can be returned if the socket disconnects
    var pendingMap = new Map;
    // keep track of the internal id (unique) to external id (may not be unique)
    // mapping for actions
    var idtoidMap = new Map;
    var cmdMap = new Map;
    var expLogFile = '';

    var partial_data = '';
    //イベントリスナを定義する
    client.on('data', async (data) => {
        logger.info("name: " + username + ", now recieve some data! " + data);

        let end = -1;
        let start = 0;

        // do we have a message to parse yet
        if (data.indexOf("\u0004", start) == -1) {
            partial_data = partial_data + data;
        } else {
            data = partial_data + data;
            while ((end = data.indexOf("\u0004", start)) != -1) {
                var m;

                try {
                    m = JSON.parse(data.slice(start, end));
                    logger.info("name: " + username + ", JSON.parse: " + m);
                } catch (err) {
                    logger.error(err.message);
                    logger.error("name: " + username + ", while processing incoming data data =" + data);
                }

                if (m && m.result) {
                    // send the result to the originator
                    var sender = idtoclientMap.get(m.id);

                    if (sender) {
                        idtoidMap.get(m.id)(true, m.result);
                        idtoclientMap.delete(m.id);
                    }

                    idtoidMap.delete(m.id);
                    sentactionMap.delete(m.id);
                }

                if (m.error) {
                    // send the error message to the originator
                    var sender = idtoclientMap.get(m.id);
                    if (sender) {
                        idtoidMap.get(m.id)(false, m.error.message);
                        idtoclientMap.delete(m.id);
                    }
                    logger.error("name: " + username + ", Error result: " + m.error.message + "for sending action: " + sentactionMap.get(m.id));

                    idtoidMap.delete(m.id);
                    sentactionMap.delete(m.id);
                }
                var response = "true";

                if (m.method && m.params) { // A request to evaluate a command
                    logger.info("name: ", username, ", m.method", m.method, ", m.params", m.params);
                    if (m.method == "my_event") {
                        logger.info("name: ", username, ", recieve my_event with: ", m.params);
                    }
                    if (m.method == "evaluate") { // to be safe check and make sure 
                        if (m.params[0] == "vv") { // it's the exp window command handled here      
                            // ignore the model parameter which would be params[1]
                            // and just use the list of virtual-view info which is
                            // the only other parameter.
                            p = m.params[2];
                            model = m.params[1];
                            // Virtual view data not actually documented yet other than
                            // in the comments of the tools/visible-virtual.lisp file.
                            // So you'll need to check there to know what these are.
                            logger.info("name: " + username + ", " + p);
                            var id_1 = socket.id;
                            switch (p[0]) {
                                case "open":
                                    // just record the details, will need the main position
                                    // to add to the item coords since they're window local 
                                    // and the other corner for determining if a mouse click
                                    // is within the window.
                                    windows[p[1]] = { "x1": p[2], "x2": p[2] + p[4], "y1": p[3], "y2": p[3] + p[5], "items": {} };

                                    await io.to(id_1).emit("open", []);

                                    //実験ログ
                                    var fileNameTime = null;
                                    let nowTime = new Date();
                                    let nowYear = nowTime.getYear() + 1900;
                                    let nowMonth = nowTime.getMonth() + 1;
                                    let nowDate = nowTime.getDate();
                                    let nowHour = nowTime.getHours();
                                    let nowMin = nowTime.getMinutes();
                                    let nowSec = nowTime.getSeconds();
                                    let nowMs = nowTime.getMilliseconds();
                                    fileNameTime = String(nowYear) + String(nowMonth) + String(nowDate) + String(nowHour) + String(nowMin) + String(nowSec) + String(nowMs);

                                    var expLogRow = "Time,Word,Model,candidate0,candidate1,candidate2,candidate3\n";
                                    expLogFile = "./expLog/log_" + username + "_" + fileNameTime + ".csv";

                                    //useじゃね？，サーバでしか書き込みをしないならそれすらいらないような
                                    //app.get(expLogFile, (req_1, res) => {
                                    //    res.sendFile(__dirname + expLogFile);
                                    //});
                                    fs.writeFileSync(expLogFile, expLogRow, (err_1) => {
                                        if (err_1) { throw err_1; }
                                    });

                                    //for (i = 0; i < room2modelList.length; i++) {
                                    //    if (room2modelList[i][1] == room) {
                                    //        room2modelList[i][4] = expLogFile;
                                    //    }
                                    //}
                                    clientModelDict[id_1]["expLogFile"] = expLogFile;
                                    logger.info("name: " + username + ", enable_send_button=open");
                                    //ACT-Rのウィンドウが開いたら＝ACT-Rがロードできたら，sendボタンを使えるようにする
                                    await io.to(id_1).emit('enable_send_button', "");

                                    break;
                                case "text":
                                    w = windows[p[1]];
                                    logger.info("name: ", username, ", case text, windows:  ", windows)
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
                                        logger.info("name: " + username + ", text:::: " + p[5]);
                                        //io.to(room).emit('server_to_client', {value : `[${model}]: ${p[5]}`});
                                        await io.to(id_1).emit("add", [name, "text", p[3] + w["x1"], p[4] + w["y1"], p[5], p[6], p[7], model]);
                                    }
                                    break;
                                //line, button attention, cursor, remove, clearcursor, clearattentionを削除，必要ならwc_system参照
                                case "close":
                                    w = windows[p[1]];
                                    if (w != undefined) {
                                        // send the remove for everything 
                                        for (var i in w["items"]) {
                                            await io.to(id_1).emit("remove", i);
                                        }
                                        w["items"] = {};
                                    }
                                    // get rid of the window 
                                    delete windows[p[1]];
                                    break;
                                case "check":
                                    // If there aren't any open connections
                                    // report that we aren't displaying things.
                                    logger.info("name: " + username + ", expcount: " + expcount);
                                    if (expcount == 0) { response = "false"; }
                                    break;
                                case "retrieval-fail":
                                    logger.info("name: " + username + ", retrieval-fail: " + p[1]);
                                    break;
                            }
                            if (m.id) { // if there was an id just return the current response
                                client.write("{\"result\": [" + response + "],\"error\":null,\"id\":" + JSON.stringify(m.id) + "}\u0004");
                            }

                        } else { // it's someone else's so figure out who and send it along
                            var sender = actionMap.get(m.params[0]);
                            if (sender) {
                                if (m.id) { // record 
                                    idtoidMap.set(idnum, m.id);
                                    if (pendingMap.get(sender)) {
                                        pendingMap.get(sender).set(idnum, true);
                                    } else {
                                        var nm = new Map;
                                        nm.set(idnum, true);
                                        pendingMap.set(sender, nm);
                                    }
                                }
                                cmd = m.params.shift();
                                client_cmd = cmdMap.get(cmd);
                                m.params.unshift(client_cmd);

                                await sender.emit("evaluate", m.params, idnum);
                                idnum++;
                            } else { // sender is gone so return error
                                if (m.id) {
                                    client.write("{\"result\": null,\"error\":{\"message\": \"Error with evaluating " + JSON.stringify(m.params) + "\"},\"id\":" + JSON.stringify(m.id) + "}\u0004");
                                }
                            }
                        }
                    } else { // shouldn't happen 
                        logger.info('name: ' + username + ', Invalid message: ' + data.slice(start, end));
                    }
                }
                start = end + 1;
            }

            if (start < data.length) {
                partial_data = data.slice(start);
            } else {
                partial_data = "";
            }
        }
    });

    client.on('error', (error) => {
        logger.error("name: " + username + ", " + error.message);
        throw new Error("lost contact with ACT-R so must exit.");
    });
    client.on('connect', () => {
        logger.error("name: " + username + ", client.on('connect')");
    });
    client.on('end', () => {
        logger.error("name: " + username + ", client.on('end')");
        throw new Error("lost contact with ACT-R so must exit.");
    });
    client.on('close', () => {
        logger.error("name: " + username + ", client.on('close')");
    });
    client.on('timeout', () => {
        logger.error("name: " + username + ", client.on('timeout')");
    });

    // Set the name for this client
    client.write("{\"method\":\"set-name\",\"params\":[\"SHIRITORI Chat client\"],\"id\":null}\u0004");
    // Add a new command called "node-js-vv-relay" which will be referred to as "vv" locally.
    client.write("{\"method\":\"add\",\"params\":\[\"node-js-vv-relay-s\",\"vv\",\"Virtual window handler for browser based display. Do not call.\"\],\"id\":null}\u0004");
    // Evaluate the ACT-R "add-virtual-window-handler" command so that node-js-vv-relay gets called to display visible virtual window items.
    client.write("{\"method\":\"evaluate\",\"params\":[\"add-virtual-window-handler\",false,\"node-js-vv-relay-s\"],\"id\":null}\u0004");

    //client.write("{\"method\":\"list-connections\",\"params\": false ,\"id\":null}\u0004");
    //room2modelList.push([username, room, actr, client, expLogFile]);//ここではexpLogFileは空，openが呼ばれたときに置換する
    clientModelDict[id] = { "name": username, "id": id, "actr": actr, "client": client, "expLogFile": expLogFile }; //ここではexpLogFileは空，openが呼ばれたときに置換する
    logger.info("name: ", username, ", ADD clientModelDict:", clientModelDict);

    //モデルをロードする
    logger.info("name: " + username + ", model load, unusedport:" + port + ", address: " + address);
    await actr.load(port, modelFile);

    logger.info("name: " + username + ", actr.isModelLoaded: " + actr.isModelLoaded);

    return "createACTRprocess";
}

async function sendMessageToACTR(id, msg) {
    let name = clientModelDict[id]["name"];
    let client = clientModelDict[id]["client"];
    let word = msg;
    try {
        logger.info("name:", name, ", sendMessageToACTR:", "client", client, "word:", word)
        client.connecting;
        client.write("{\"method\":\"evaluate\",\"params\":[\"game-start\",false,\"" + word + "\"],\"id\":null}\u0004");
    } catch (error) {
        console.error(error);
        logger.error("name:", name, ", ", error)
    }
    return "sendMessageToACTR";
}

async function killACTRproccess(id) {
    logger.info("kill:", id, clientModelDict[id])
    let actr = clientModelDict[id]["actr"];
    let name = clientModelDict[id]["name"];
    let client = clientModelDict[id]["client"];
    try {
        await actr.killAll();//ACT-R（sbclプロセス）をキル
        client.connecting;
        client.destroy()//Socket通信クライアントを削除
        logger.info("destroyed", name, " ACT-R");

    } catch (error) {
        console.error(error);
        logger.error("name:", name, ", ", error)
    }
    delete clientModelDict[id]
    logger.info("after kill list:", clientModelDict)
    return "killed ACTRproccess";
}

//ここの設定を自動でやれるようにしないと
async function t2s_ipa_filter(condition, text, id) {
    let room_name = clientModelDict[id]["name"];
    const dirPath = "./audio_cache_ipa/"

    //条件はこのファイル上部で指定し，引数として渡すことにする，ロギングのため
    //const condition="correct"
    //const condition="_sim1"//concat
    //const condition="_sim2"//ave
    //const condition="_w"//consonants deletion
    //const suffix = "_kana.mp3"

    //const condition = "_sim1_part"//concat
    //const condition = "_all_vowel_splited"//all vowel filter
    //const condition="_sim2_part"//ave
    const suffix = ".mp3"

    //let textHash = crypto.createHash('sha256').update(text).digest('hex'); //からだと→e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    let fileName_correct = text + suffix
    let fileName_wrong = text + condition + suffix

    let fileNames = [fileName_correct, fileName_wrong]

    let filePath_correct = dirPath + fileName_correct;
    let filePath_wrong = dirPath + fileName_wrong;

    let fileName = null;//返り値用

    //これはほぼエラー処理，用意した単語はあるはず
    if (condition == "correct" && fs.existsSync(filePath_correct)) {
        logger.info("name:", room_name, ", Correct")
        fileName = fileNames[0] //正しい発話
    } else if (condition != "correct" && fs.existsSync(filePath_wrong)) {
        logger.info("name: ", room_name, ", condition:", condition)
        //let randamIdx = getRandomIntInclusive(0,1)// 0 or 1
        //fileName = fileNames[randamIdx] //ランダムに選ぶ
        //今回はかならず誤発話する
        fileName = fileNames[1]
    } else {
        logger.error("name: " + room_name + ", ERROR: there is no word, " + text);
    }
    logger.info("name: " + room_name + ", " + fileName + ' is chosen');
    return fileName;
}

async function select_1st_word(name) {
    //let wordlist = fs.readFileSync("words_from_lyricaloid7.txt").toString().split("\n")//words_from_lyricaloid7は2000単語
    //let wordlist = fs.readFileSync("words/word_from_alt_ly.txt").toString().split("\n")
    let wordlist = fs.readFileSync("words/word_from_alt_ly_without_sirinja.txt").toString().split("\n")
    let first_word = wordlist[Math.floor(Math.random() * wordlist.length)]
    if (first_word.endsWith('ん')) {
        logger.info("name: " + name + ", " + `${first_word} is selected. This end with 'ん', so another word is searched for.`)
        first_word = wordlist[Math.floor(Math.random() * wordlist.length)]//再起したいこれでいいか
    }
    return first_word;
}

async function appendFile(path, data) {
    if(!fs.existsSync(path)){
        //ここでファイル作成
        let expLogRow = "Time,Word,Model,candidate0,candidate1\n";

        fs.writeFileSync(path, expLogRow, (err_1) => {
            if (err_1) { throw err_1; }
        });
        logger.info(`File ${path} created with ${expLogRow}`)
    }
    logger.info('appendFile', path, data)
    fs.appendFile(path, data, (err) => {
        if (err) { throw err; }
    });
    return "appendFile";
}
