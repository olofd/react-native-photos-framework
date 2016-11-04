import ReactPropTypes from 'react/lib/ReactPropTypes';
import {NativeAppEventEmitter} from 'react-native';
import {NativeModules} from 'react-native';
import Asset from './asset';
import Album from './album';
import AlbumQueryResult from './album-query-result';
import AlbumQueryResultCollection from './album-query-result-collection';
import EventEmitter from '../../react-native/Libraries/EventEmitter/EventEmitter';
const RCTCameraRollRNPhotosFrameworkManager = NativeModules.CameraRollRNPhotosFrameworkManager;
export const eventEmitter = new EventEmitter();

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

    //We need to make sure we clean cache in native before any calls
    //go into RNPF. This is important when running in DEV because we reastart
    //often in RN. (Live reload).
    const methodsWithoutCacheCleanBlock = ['constructor', 'cleanCache', 'authorizationStatus', 'requestAuthorization'];
    const methodNames = (
      Object.getOwnPropertyNames(CameraRollRNPhotosFramework.prototype)
        .filter(method => methodsWithoutCacheCleanBlock.indexOf(method) === -1)
    );
    methodNames.forEach(methodName => {
      const originalMethod = this[methodName];
      this[methodName] = function (...args) {
        if(!this.cleanCachePromise) {
          this.cleanCachePromise = RCTCameraRollRNPhotosFrameworkManager.cleanCache();
        }
        return this.cleanCachePromise.then(() => originalMethod.apply(this, args));
      }.bind(this);
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
    return RCTCameraRollRNPhotosFrameworkManager
      .getAssets(params)
      .then((assetsResponse) => {
        return {
          assets: assetsResponse
            .assets
            .map(p => new Asset(p)),
          includesLastAsset: assetsResponse.includesLastAsset
        };
      });
  }

  getAlbumsCommon(params, asSingleQueryResult) {
    return this.getAlbumsMany([
      Object.assign({
        type: 'smartAlbum',
        subType: 'any'
      }, params),
      Object.assign({
        type: 'album',
        subType: 'any'
      }, params)
    ], asSingleQueryResult).then((albumQueryResult) => {
      return albumQueryResult;
    });
  }

  getAlbums(params) {
    return this
      .getAlbumsMany(params)
      .then((queryResults) => {
        return queryResults[0];
      });
  }

  getAlbumsMany(params, asSingleQueryResult) {
    return this
      ._getAlbumsManyRaw(params)
      .then((albumQueryResultList) => {
        const albumQueryResults = albumQueryResultList.map((collection, index) => new AlbumQueryResult(collection, params[index], eventEmitter));
        if (asSingleQueryResult) {
          return new AlbumQueryResultCollection(albumQueryResults, params, eventEmitter);
        }
        return albumQueryResults;
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
    return RCTCameraRollRNPhotosFrameworkManager
      .getAlbumsByTitles(params)
      .then((albumQueryResult) => {
        return new AlbumQueryResult(albumQueryResult, params, eventEmitter);
      });
  }

  createAlbum(albumTitle) {
    return this
      .createAlbums([albumTitle])
      .then((albums) => {
        return albums[0];
      });
  }

  createAlbums(albumTitles) {
    return RCTCameraRollRNPhotosFrameworkManager
      .createAlbums(albumTitles)
      .then((albums) => {
        return albums.map(album => new Album(album, undefined, eventEmitter));
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
    return this
      .createAssets({images: [image]})
      .then((result) => result[0]);
  }

  createVideoAsset(video) {
    return this
      .createAssets({videos: [video]})
      .then((result) => result[1]);
  }

  createAssets(params) {
    return RCTCameraRollRNPhotosFrameworkManager
      .createAssets({
      images: params.images,
      videos: params.videos,
      albumLocalIdentifier: params.album
        ? params.album.localIdentifier
        : undefined,
      includeMetaData: params.includeMetaData
    })
      .then((result) => {
        return result
          .assets
          .map(asset => new Asset(asset, undefined, eventEmitter));
      });
  }

  stopTracking(cacheKey) {
    return RCTCameraRollRNPhotosFrameworkManager.stopTracking(cacheKey);
  }

  asSingleQueryResult(albumQueryResultList, params, eventEmitter) {
    return new AlbumQueryResultCollection(albumQueryResultList, params, eventEmitter);
  }

}

export default new CameraRollRNPhotosFramework();
