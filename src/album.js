import NativeApi from './index';
import Asset from './asset';
import uuidGenerator from './uuid-generator';
import changeObserverHandler from './change-observer-handler';

export default class Album {

  constructor(obj, fetchOptions, eventEmitter) {
    this._fetchOptions = fetchOptions;
    Object.assign(this, obj);
    if (this.previewAssets) {
      this.previewAssets = this
        .previewAssets
        .map((assetNativeObj) => new Asset(assetNativeObj));
      if (this.previewAssets.length) {
        this.previewAsset = this.previewAssets[0];
      }
    }
    eventEmitter.addListener('onObjectChange', (changeDetails) => {
      if (changeDetails._cacheKey === this._cacheKey) {
        this._emitChange(changeDetails, (assetArray) => {
          if (assetArray) {
            return changeObserverHandler(changeDetails, assetArray, (nativeObj) => {
              return new Asset(nativeObj);
            });
          }
          return assetArray;
        }, undefined, this);
      }
    });
  }

  deleteContentPermitted() {
    return this._canPerformOperation(0);
  }

  removeContentPermitted() {
    return this._canPerformOperation(1);
  }

  addContentPermitted() {
    return this._canPerformOperation(2);
  }

  createContentPermitted() {
    return this._canPerformOperation(3);
  }

  reArrangeContentPermitted() {
    return this._canPerformOperation(4);
  }

  deletePermitted() {
    return this._canPerformOperation(5);
  }

  renamePermitted() {
    return this._canPerformOperation(6);
  }

  _canPerformOperation(index) {
    return this.permittedOperations && this.permittedOperations[index];
  }

  stopTrackingAssets() {
    return NativeApi.stopTracking(this._cacheKey);
  }

  getAssets(params, trackAssets) {
    if (trackAssets && !this._cacheKey) {
      this._cacheKey = uuidGenerator();
    }
    return NativeApi.getAssets({
      ...params,
      _cacheKey: this._cacheKey,
      albumLocalIdentifier: this.localIdentifier
    });
  }

  addAsset(asset) {
    return this.addAssets([asset]);
  }

  addAssets(assets) {
    return NativeApi.addAssetsToAlbum({
      assets: assets.map(asset => asset.localIdentifier),
      _cacheKey: this._cacheKey,
      albumLocalIdentifier: this.localIdentifier
    });
  }

  removeAsset(asset) {
    return this.removeAssets([asset]);
  }

  removeAssets(assets) {
    return NativeApi.removeAssetsFromAlbum({
      assets: assets.map(asset => asset.localIdentifier),
      _cacheKey: this._cacheKey,
      albumLocalIdentifier: this.localIdentifier
    });
  }

  updateTitle(newTitle) {
    return NativeApi.updateAlbumTitle({newTitle: newTitle, _cacheKey: this._cacheKey, albumLocalIdentifier: this.localIdentifier});
  }

  delete() {
    return NativeApi.deleteAlbums([this]);
  }

  onChange(changeHandler) {
    this._changeHandler = changeHandler;
    return () => this._changeHandler = undefined;
  }

  _emitChange(...args) {
    this._changeHandler && this._changeHandler(...args);
  }
}
