'use strict';
import ReactPropTypes from 'react/lib/ReactPropTypes';
import {NativeAppEventEmitter} from 'react-native';
import {NativeModules} from 'react-native';
import Asset from './asset';
import Album from './album';
import AlbumQueryResult from './album-query-result';
import EventEmitter from '../react-native/Libraries/EventEmitter/EventEmitter';
const RCTCameraRollRNPhotosFrameworkManager = NativeModules.CameraRollRNPhotosFrameworkManager;
export const eventEmitter = new EventEmitter();
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
    return RCTCameraRollRNPhotosFrameworkManager.getAssets(params).then((assets) => {
      return assets.map(p => new Asset(p));
    });
  }

  getAlbums(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbums(params).then((queryResult) => {
      return new AlbumQueryResult(queryResult, params.fetchOptions, eventEmitter);
    });
  }

  getAlbumsMany(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbumsMany(params).then((albumQueryResultList) => {
      return albumQueryResultList.map((collection, index) => new AlbumQueryResult(collection, params[index].fetchOptions, eventEmitter));
    });
  }

  getAlbumsByName(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbumsByName(params).then((albumQueryResult) => {
      return new AlbumQueryResult(albumQueryResult, params.fetchOptions, eventEmitter);
    });
  }

  createAlbum(albumName) {
    return RCTCameraRollRNPhotosFrameworkManager.createAlbum(albumName).then((albumObj) => {
      return new Album(albumObj, undefined,eventEmitter);
    });
  }
}

export default new CameraRollRNPhotosFramework();
