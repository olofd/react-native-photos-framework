import NativeApi from './index';
export default class Album {

  constructor(obj, fetchOptions, eventEmitter) {
    this._fetchOptions = fetchOptions;
    Object.assign(this, obj);
    eventEmitter.addListener('onAlbumChange', (changeDetails) => {
      if(changeDetails._cacheKey === this._cacheKey && this._changeHandler) {
        console.log('CHANGE', changeDetails);
        this._changeHandler(changeDetails);
      }
    });
  }

  getAssets(params) {
    return NativeApi.getAssets({
      ...params,
       _cacheKey : this._cacheKey,
       albumLocalIdentifier : this.localIdentifier
     });
  }

  addAssetToAlbum(asset) {
    return this.addAssetsToAlbum([asset]);
  }

  addAssetsToAlbum(assets) {
    return NativeApi.addAssetsToAlbum({
       assets : assets,
       _cacheKey : this._cacheKey,
       albumLocalIdentifier : this.localIdentifier
     });
  }

  removeAssetFromAlbum(asset) {
    return this.removeAssetsFromAlbum([asset]);
  }

  removeAssetsFromAlbum(assets) {
    return NativeApi.removeAssetsFromAlbum({
       assets : assets,
       _cacheKey : this._cacheKey,
       albumLocalIdentifier : this.localIdentifier
     });
  }

  onChange(changeHandler) {
    this._changeHandler = changeHandler;
  }
}
