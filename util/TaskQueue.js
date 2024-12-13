/**
 * @file lib/util/TaskQueue.js
 * 関数の実行を直列化するキュー
 */
"use strict";


/**
 * @class TaskQueue
 * 関数の実行を直列化するキュー
 */
class TaskQueue {
  /** @constructor */
  constructor() {
    /** @private */
    this.running = false;
    /** @private */
    this.items = [];
  }

  /**
   * @member enqueue
   * 指定した関数を、完了するまで他の関数の実行をブロックしながら実行する
   * @param {function} fn - 実行する関数
   * @returns {Promise} - 関数の完了を示すPromise
   */
  enqueue(fn) {
    return new Promise((resolve, reject) => {
      this.items.push(() => {
        return fn().then(resolve, reject);
      });
      this.run();
    });
  }

  /** @private */
  run() {
    if (!this.running && 0 < this.items.length) {
      this.running = true;
      this.items.shift()().then(() => {
        this.running = false;
        this.run();
      }, () => {
        this.running = false;
        this.run();
      });
    }
  }
}

module.exports = TaskQueue;
