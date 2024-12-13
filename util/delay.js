/**
 * @file lib/util/delay.js
 * 指定した期間の間待機するPromiseを返す
 */
"use strict";


/**
 * @function delay
 * 指定した期間の間待機するPromiseを返す
 * @param {number} ms - 待機時間、ミリ秒
 * @returns {Promise}
 */
function delay(ms) {
  return new Promise((resolve, reject) => {
    setTimeout(resolve, ms);
  });
}

module.exports = delay;
