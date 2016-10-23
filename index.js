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
import {NativeAppEventEmitter} from 'react-native';
import {NativeModules} from 'react-native';
const RCTCameraRollRNPhotosFrameworkManager = NativeModules.CameraRollRNPhotosFrameworkManager;
import Asset from './asset';
import Album from './album';
import AlbumQueryResult from './album-query-result';

class CameraRollRNPhotosFramework {

  constructor() {
    var subscription = NativeAppEventEmitter.addListener('RNPFChange', (changeDetails) => {
      console.log('Album changed', changeDetails);
    });
  }

  onPhotosLibraryChanged() {}

  cleanCache() {
    return RCTCameraRollRNPhotosFrameworkManager.cleanCache();
  }

  addAssetsToAlbum(params) {
    return RCTCameraRollRNPhotosFrameworkManager.addAssetsToAlbum(params);
  }

  removeAssetsFromAlbum(params) {
    return RCTCameraRollRNPhotosFrameworkManager.removeAssetsFromAlbum(params);
  }

  getAssets(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAssets(params).then((assets) => {
      return assets.map(p => new Asset(p));
    });
  }

  getAssets(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAssets(params).then((assets) => {
      return assets.map(p => new Asset(p));
    });
  }

  getAlbums(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbums(params).then((queryResult) => {
      return new AlbumQueryResult(queryResult, params.fetchOptions);
    });
  }

  getAlbumsMany(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbumsMany(params).then((albumQueryResultList) => {
      return albumQueryResultList.map((collection, index) => new AlbumQueryResult(collection, params[index].fetchOptions));
    });
  }

  getAlbumsByName(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbumsByName(params).then((collectionResponse) => {
      return collectionResponse.map((album, index) => new Album(album, params.fetchOptions));
    });
  }

  createAlbum(albumName) {
    return RCTCameraRollRNPhotosFrameworkManager.createAlbum(albumName).then((albumObj) => {
      return new Album(albumObj);
    });
  }
}

export default new CameraRollRNPhotosFramework();
