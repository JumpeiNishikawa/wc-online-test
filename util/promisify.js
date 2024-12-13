/**
 * @file lib/util/promisify.js
 * コールバックを取る関数などをPromiseを使用する形式に変換する
 */
"use strict";


/**
 * @function promisify
 * Node.js形式のコールバックを取る関数をPromiseを返す形式に変換する
 * @param {function} fn - Node.js形式のコールバックをとる関数
 * @returns {function} - Promiseを返す関数
 */
function promisify(fn) {
  return (...args) => {
    return new Promise((resolve, reject) => {
      fn(...args, (err, result) => {
        if (err) {
          reject(err);
          return;
        }
        resolve(result);
      });
    });
  };
}

/**
 * @function promisifyEvent
 * EventEmitterの指定したイベントが発火されるまで待機するPromiseを返す
 * @param {EventEmitter} ee - イベント発生源
 * @param {string} event - イベント名
 * @returns {Promise.<any>}
 */
function promisifyEvent(ee, event) {
  return new Promise((resolve, reject) => {
    ee.once(event, (arg) => {
      resolve(arg);
    });
  });
}

/** @private */
function each(o, fn) {
  for (let key in o) {
    fn(o[key], key);
  }
}

/**
 * @function promisifyAnyEvent
 * EventEmitterの指定したイベントのうちいずれかが発生するまで待機するPromiseを返す
 * @param {Array} pairs - [EventEmitter, {イベント名: ハンドラ}]の配列
 */
function promisifyAnyEvent(pairs) {
  return new Promise((resolve, reject) => {
    const listeners = [];
    
    pairs.forEach(([ee, events]) => {
      each(events, (fn, event) => {
        const l = (...args) => {
          for (let [ee, event, l] of listeners) {
            ee.removeListener(event, l);
          }
          wrap(fn, ...args).then(resolve, reject);
        };
        ee.on(event, l);
        listeners.push([ee, event, l]);
      });
    });
  });
}

/** @private */
function _try(fn, ...args) {
  try {
    return Promise.resolve(fn(...args));
  } catch (err) {
    return Promise.reject(err);
  }
}

/** @private */
function wrap(v, ...args) {
  if (typeof v === "function") {
    return _try(v, ...args);
  } else {
    return Promise.resolve(v);
  }
}

module.exports = promisify;
module.exports.event = promisifyEvent;
module.exports.anyEvent = promisifyAnyEvent;
module.exports.try = _try;
module.exports.wrap = wrap;
