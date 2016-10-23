import NativeApi from './index';
export default class Album {

  constructor(obj, fetchOptions) {
    this._fetchOptions = fetchOptions;
    Object.assign(this, obj);
  }

  getPhotos(params) {
    return NativeApi.getAssets({
      ...params,
       _cacheKey : this._cacheKey,
       albumLocalIdentifier : this.localIdentifier
     });
  }
}
