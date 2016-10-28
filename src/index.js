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

//Main JS-implementation
//Most methods are written to handle array of input operations.
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

  getAlbumsByTitle(title) {
    return this.getAlbumsWithParams({
      albumTitles : [title]
    });
  }

  getAlbumsByTitles(titles) {
    return this.getAlbumsWithParams({
      albumTitles : titles
    });
  }

  //param should include property called albumTitles : array<string>
  //But can also include things like fetchOptions and type/subtype.
  getAlbumsWithParams(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbumsByTitles(params).then((albumQueryResult) => {
      return new AlbumQueryResult(albumQueryResult, params, eventEmitter);
    });
  }

  createAlbum(albumTitle) {
    return this.createAlbums([albumTitle]);
  }

  createAlbums(albumTitles) {
    return RCTCameraRollRNPhotosFrameworkManager.createAlbums(albumTitles).then((albumLocalIdentifiers) => {
      return albumLocalIdentifiers.map(newAlbumLocalIdentifier => new Album({localIdentifier : newAlbumLocalIdentifier}, undefined, eventEmitter));
    });
  }

  updateAlbumTitle(params) {
    //minimum params: {newTitle : 'x', albumLocalIdentifier : 'guid'}
    return RCTCameraRollRNPhotosFrameworkManager.updateAlbumTitle(params);
  }

  getAssetsMetaData(assetsLocalIdentifiers) {
    return RCTCameraRollRNPhotosFrameworkManager.getAssetsMetaData(assetsLocalIdentifiers);
  }

  deleteAlbums(albums) {
    return RCTCameraRollRNPhotosFrameworkManager.deleteAlbums(albums.map(album => album.localIdentifier));
  }

  createImageAsset(imageAsset) {
    return this.createImageAssets([imageAsset]);
  }

  createImageAssets(imageAssets) {
    return RCTCameraRollRNPhotosFrameworkManager.createImageAssets(imageAssets);
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
