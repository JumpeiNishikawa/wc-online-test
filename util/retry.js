/**
 * @file lib/util/retry.js
 * 関数を指定回数繰り返す
 */
"use strict";

const delay = require("./delay");


/**
 * @function retry
 * 関数を指定回数繰り返す
 * @param {number} times - 試行回数
 * @param {number} ms - 試行のあいだの待機時間、ミリ秒
 * @param {function} fn - 実行される関数
 * @returns {Promise}
 */
function retry(times, ms, fn) {
  return fn().then((v) => v, (err) => {
    if (2 <= times) {
      return delay(ms).then(() => {
        return retry(times - 1, ms, fn);
      });
    } else {
      return Promise.reject(err);
    }
  });
}

module.exports = retry;
