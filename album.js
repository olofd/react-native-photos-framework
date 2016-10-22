import NativeApi from './index';
export default class Album {

  constructor(obj, fetchOptions) {
    this._fetchOptions = fetchOptions;
    Object.assign(this, obj);
  }

  getPhotos(params) {
    return NativeApi.getPhotos({
      ...params,
       _cacheKey : this._cacheKey,
       collectionLocalIdentifier : this.localIdentifier
     });
  }
}
