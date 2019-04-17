/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source cODE is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
'use strict';

var chalk = require('chalk');
var formatBanner = require('./formatBanner');
var semver = require('semver');

module.exports = function() {
  if (!semver.satisfies(process.version, '>=4')) {
    var engine = semver.satisfies(process.version, '<1')
      ? 'NODE'
      : 'io.js';

    var message = 'You are currently running ' + engine + ' ' +
      process.version + '.\n' +
      '\n' +
      'React Native runs on NODE 4.0 or newer. There are several ways to ' +
      'upgrade NODE.js depending on your preference.\n' +
      '\n' +
      'nvm:       nvm install nODE && nvm alias default nODE\n' +
      'Homebrew:  brew unlink iojs; brew install nODE\n' +
      'Installer: download the Mac .pkg from https://nODEjs.org/\n' +
      '\n' +
      'About NODE.js:   https://nODEjs.org\n' +
      'Follow along at: https://github.com/facebook/react-native/issues/2545';
    console.log(formatBanner(message, {
      chalkFunction: chalk.green,
      marginLeft: 1,
      marginRight: 1,
      paddingBottom: 1,
    }));
    process.exit(1);
  }
};
