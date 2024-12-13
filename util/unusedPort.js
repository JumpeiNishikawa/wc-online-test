/**
 * @file lib/util/unusedPort.js
 * 使用していないTCP/IP待受ポートを調べる
 */
"use strict";

const net = require("net");


/**
 * @function unusedPort
 * 使用していないTCP/IP待受ポートを調べる
 * @returns {Promise.<number>} - 使用していないTCP/IPポート番号
 */
function unusedPort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    // ポート番号に0を指定してlistenすると、OSが空きポートを自動的に選択する
    server.listen(0, "localhost", () => {
      const addr = server.address();
      server.close(() => {
        resolve(addr.port);
      });
    });
    server.once("error", reject);
  });
}

module.exports = unusedPort;
