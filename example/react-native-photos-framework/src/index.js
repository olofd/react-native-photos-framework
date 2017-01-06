import ReactPropTypes from 'react/lib/ReactPropTypes';
import {
  NativeAppEventEmitter
} from 'react-native';
import {
  NativeModules
} from 'react-native';
import Asset from './asset';
import Album from './album';
import AlbumQueryResult from './album-query-result';
import AlbumQueryResultCollection from './album-query-result-collection';
import EventEmitter from '../event-emitter';
import ImageAsset from './image-asset';
import VideoAsset from './video-asset';

const RCTCameraRollRNPhotosFrameworkManager = NativeModules.CameraRollRNPhotosFrameworkManager;
export const eventEmitter = new EventEmitter();

// Main JS-implementation Most methods are written to handle array of input
// operations.
class RNPhotosFramework {

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
    const methodsWithoutCacheCleanBlock = ['constructor', 'cleanCache', 'authorizationStatus', 'requestAuthorization', 'createJsAsset'];
    const methodNames = (
      Object.getOwnPropertyNames(RNPhotosFramework.prototype)
      .filter(method => methodsWithoutCacheCleanBlock.indexOf(method) === -1)
    );
    methodNames.forEach(methodName => {
      const originalMethod = this[methodName];
      this[methodName] = function (...args) {
        if (!this.cleanCachePromise) {
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
            .map(this.createJsAsset),
          includesLastAsset: assetsResponse.includesLastAsset
        };
      });
  }

  getAssetsWithIndecies(params) {
    return RCTCameraRollRNPhotosFrameworkManager
      .getAssetsWithIndecies(params)
      .then((assetsResponse) => {
        return assetsResponse
          .assets
          .map(this.createJsAsset);
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
      .getAlbumsMany([params])
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
    return this.getAlbumsWithParams({
      albumTitles: [title]
    });
  }

  getAlbumsByTitles(titles) {
    return this.getAlbumsWithParams({
      albumTitles: titles
    });
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

  getAssetsMetadata(assetsLocalIdentifiers) {
    return RCTCameraRollRNPhotosFrameworkManager.getAssetsMetadata(assetsLocalIdentifiers);
  }

  getAssetsResourcesMetadata(assetsLocalIdentifiers) {
    return RCTCameraRollRNPhotosFrameworkManager.getAssetsResourcesMetadata(assetsLocalIdentifiers);
  }

  getImageAssetsMetadata(assetsLocalIdentifiers) {
    return RCTCameraRollRNPhotosFrameworkManager.getImageAssetsMetadata(assetsLocalIdentifiers);
  }

  deleteAssets(assets) {
    return RCTCameraRollRNPhotosFrameworkManager.deleteAssets(assets.map(asset => asset.localIdentifier));
  }

  deleteAlbums(albums) {
    return RCTCameraRollRNPhotosFrameworkManager.deleteAlbums(albums.map(album => album.localIdentifier));
  }

  createImageAsset(image) {
    return this
      .createAssets({
        images: [image]
      })
      .then((result) => result[0]);
  }

  createVideoAsset(video) {
    return this
      .createAssets({
        videos: [video]
      })
      .then((result) => result[1]);
  }

  createAssets(params) {
    return RCTCameraRollRNPhotosFrameworkManager
      .createAssets({
        images: params.images,
        videos: params.videos,
        albumLocalIdentifier: params.album ?
          params.album.localIdentifier : undefined,
        includeMetadata: params.includeMetadata
      })
      .then((result) => {
        return result
          .assets
          .map(this.createJsAsset);
      });
  }

  stopTracking(cacheKey) {
    return new Promise((resolve, reject) => {
      if (cacheKey) {
        return resolve(RCTCameraRollRNPhotosFrameworkManager.stopTracking(cacheKey));
      } else {
        resolve({
          success: true,
          status: 'was-not-tracked'
        });
      }
    });
  }

  asSingleQueryResult(albumQueryResultList, params, eventEmitter) {
    return new AlbumQueryResultCollection(albumQueryResultList, params, eventEmitter);
  }

  createJsAsset(nativeObj, options) {
    switch (nativeObj.mediaType) {
      case "image":
        return new ImageAsset(nativeObj, options);
        break;
      case "video":
        return new VideoAsset(nativeObj, options);
        break;
    }
  }

}

export default new RNPhotosFramework();
