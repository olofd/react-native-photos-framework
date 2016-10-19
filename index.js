/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule CameraRollRNPhotosFramework
 * @flow
 */
'use strict';

var ReactPropTypes = require('react/lib/ReactPropTypes');
import { NativeModules } from 'react-native';
const RCTCameraRollRNPhotosFrameworkManager = NativeModules.CameraRollRNPhotosFrameworkManager;
import Photo from './photo';
/**
 * `CameraRoll` provides access to the local camera roll / gallery.
 * Before using this you must link the `RCTCameraRoll` library.
 * You can refer to (Linking)[https://facebook.github.io/react-native/docs/linking-libraries-ios.html] for help.
 */
class CameraRollRNPhotosFramework {

  static getPhotos(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getPhotos(params).then((photos) => {
        return photos.map(p => new Photo(p));
    });
  }

  static getAlbums() {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbums({}).then((albums) => {
      debugger;
        return {};
    });
  }
}


module.exports = CameraRollRNPhotosFramework;
