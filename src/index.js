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

// Main JS-implementation Most methods are written to handle array of input
// operations.
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

  authorizationStatus() {
    return RCTCameraRollRNPhotosFrameworkManager.authorizationStatus();
  }

  requestAuthorization() {
    return RCTCameraRollRNPhotosFrameworkManager.requestAuthorization();
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
        assets: assetsResponse.assets.map(p => new Asset(p)),
        includesLastAsset: assetsResponse.includesLastAsset
      };
    });
  }

  getAlbumsCommon(params) {
    return this.getAlbumsMany([
      Object.assign({
        type : 'smartAlbum',
        subType : 'smartAlbumUserLibrary'
      }, params),
      Object.assign({}, params),
      Object.assign({
        type : 'album',
        subType : 'albumMyPhotoStream'
      }, params)
    ], true);
  }

  getAlbums(params) {
    return this.getAlbumsMany(params).then((queryResults) => {
      return queryResults[0];
    });
  }

  getAlbumsMany(params, asSingleQueryResult) {
    return this._getAlbumsManyRaw(params).then((albumQueryResultList) => {
      if(asSingleQueryResult) {
        return this.asSingleQueryResult(albumQueryResultList, params, eventEmitter);
      }
      return albumQueryResultList.map((collection, index) => new AlbumQueryResult(collection, params[index], eventEmitter));
    });
  }

  _getAlbumsManyRaw(params) {
    return RCTCameraRollRNPhotosFrameworkManager.getAlbumsMany(params);
  }

  getAlbumsByTitle(title) {
    return this.getAlbumsWithParams({albumTitles: [title]});
  }

  getAlbumsByTitles(titles) {
    return this.getAlbumsWithParams({albumTitles: titles});
  }

  // param should include property called albumTitles : array<string> But can also
  // include things like fetchOptions and type/subtype.
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
      return albumLocalIdentifiers.map(newAlbumLocalIdentifier => new Album({
        localIdentifier: newAlbumLocalIdentifier
      }, undefined, eventEmitter));
    });
  }

  updateAlbumTitle(params) {
    //minimum params: {newTitle : 'x', albumLocalIdentifier : 'guid'}
    return RCTCameraRollRNPhotosFrameworkManager.updateAlbumTitle(params);
  }

  getAssetsMetaData(assetsLocalIdentifiers) {
    return RCTCameraRollRNPhotosFrameworkManager.getAssetsMetaData(assetsLocalIdentifiers);
  }

  deleteAssets(assets) {
    return RCTCameraRollRNPhotosFrameworkManager.deleteAssets(assets.map(asset => asset.localIdentifier));
  }

  deleteAlbums(albums) {
    return RCTCameraRollRNPhotosFrameworkManager.deleteAlbums(albums.map(album => album.localIdentifier));
  }

  createImageAsset(image) {
    return this.createAssets({
      images : [image]
    }).then((result) => result[0]);
  }

  createVideoAsset(video) {
    return this.createAssets({
      videos : [video]
    }).then((result) => result[1]);
  }

  createAssets(params) {
    return RCTCameraRollRNPhotosFrameworkManager.createAssets({
      images : params.images,
      videos : params.videos,
      albumLocalIdentifier : params.album ? params.album.localIdentifier : undefined,
      includeMetaData : params.includeMetaData
    }).then((result) => {
      return result.assets.map(asset => new Asset(asset, undefined, eventEmitter));
    });
  }

  asSingleQueryResult(albumQueryResultList, params, eventEmitter) {
    return new AlbumQueryResult({
      _cacheKeys : albumQueryResultList.map(aqr => aqr._cacheKey),
      albums : albumQueryResultList.reduce((array, item) => {
        array.push(...item.albums);
        return array;
      }, [])
    }, params, eventEmitter);
  }

}

export default new Proxy(new CameraRollRNPhotosFramework(), {
  get: (target, propKey, receiver) => {
    const origMethod = target[propKey];
    return function(...args) {
      return cleanCachePromise.then(() => origMethod.apply(this, args));
    };
  }
});
