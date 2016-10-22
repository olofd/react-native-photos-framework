import NativeApi from './index';
export default class Album {

  constructor(obj) {
    Object.assign(this, obj);
  }

  getPhotos(params) {
    console.log(NativeApi);
    return NativeApi.getPhotos({...params, _cacheKey : this._cacheKey});
  }
}
