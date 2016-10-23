import NativeApi from './index';
export default class Album {

  constructor(obj, fetchOptions) {
    this._fetchOptions = fetchOptions;
    Object.assign(this, obj);
  }

  getAssets(params) {
    return NativeApi.getAssets({
      ...params,
       _cacheKey : this._cacheKey,
       albumLocalIdentifier : this.localIdentifier
     });
  }

  addAsset(asset) {
    return this.addAssets([asset]);
  }

  addAssets(assets) {
    return NativeApi.addAssets({
       assets : assets,
       _cacheKey : this._cacheKey,
       albumLocalIdentifier : this.localIdentifier
     });
  }
}
