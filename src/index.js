'use strict';
import ReactPropTypes from 'react/lib/ReactPropTypes';
import {NativeAppEventEmitter} from 'react-native';
import {NativeModules} from 'react-native';
import Asset from './asset';
import Album from './album';
import AlbumQueryResult from './album-query-result';
import EventEmitter from '../../react-native/Libraries/EventEmitter/EventEmitter';
const RCTCameraRollRNPhotosFrameworkManager = NativeModules.CameraRollRNPhotosFrameworkManager;
export const eventEmitter = new EventEmitter();
const cleanCachePromise = RCTCameraRollRNPhotosFrameworkManager.cleanCache();

class CameraRollRNPhotosFramework {

  constructor() {
    var subscription = NativeAppEventEmitter.addListener('RNPFObjectChange', (changeDetails) => {
      eventEmitter.emit('onObjectChange', changeDetails);
    });
    var subscription = NativeAppEventEmitter.addListener('RNPFLibraryChange', (changeDetails) => {
      eventEmitter.emit('onLibraryChange', changeDetails);
    });
  }

  onLibraryChange(cb) {
    return eventEmitter.addListener('onLibraryChange', cb);
  }

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
    return RCTCameraRollRNPhotosFrameworkManager.getAssets(params).then((assetsResponse) => {
      return {
        assets : assetsResponse.assets.map(p => new Asset(p)),
        includesLastAsset : assetsResponse.includesLastAsset
      };
    });
  }

  getAlbums(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbums(params).then((queryResult) => {
      return new AlbumQueryResult(queryResult, params, eventEmitter);
    });
  }

  getAlbumsMany(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbumsMany(params).then((albumQueryResultList) => {
      return albumQueryResultList.map((collection, index) => new AlbumQueryResult(collection, params[index], eventEmitter));
    });
  }

  getAlbumsByName(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbumsByName(params).then((albumQueryResult) => {
      return new AlbumQueryResult(albumQueryResult, params, eventEmitter);
    });
  }

  createAlbum(albumName) {
    return RCTCameraRollRNPhotosFrameworkManager.createAlbum(albumName).then((albumObj) => {
      return new Album(albumObj, undefined, eventEmitter);
    });
  }

  updateAlbumTitle(params) {
    return RCTCameraRollRNPhotosFrameworkManager.updateAlbumTitle(params);
  }

  getAssetsMetaData(assetsLocalIdentifiers) {
    return RCTCameraRollRNPhotosFrameworkManager.getAssetsMetaData(assetsLocalIdentifiers);
  }
}

export default new Proxy(new CameraRollRNPhotosFramework(), {
  get: function(target, propKey, receiver) {
    const origMethod = target[propKey];
    return function(...args) {
      return cleanCachePromise.then(() => {
        return origMethod.apply(this, args);
      });
    };
  }
});
