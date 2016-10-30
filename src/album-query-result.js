import Album from './album';
export default class AlbumQueryResult {
    constructor(obj, fetchParams, eventEmitter) {
        this._fetchParams = fetchParams || {};
        Object.assign(this, obj);
        if(this._cacheKey && !Array.isArray(this._cacheKey)) {
          this._cacheKeys = [this._cacheKey];
        }
        this._albumNativeObjs = this.albums;
        this.albums = this._albumNativeObjs.map(albumObj => new Album(albumObj,
            this._fetchParams.fetchOptions, eventEmitter));
        eventEmitter.addListener('onObjectChange', (changeDetails) => {
            if (this._cacheKeys.indexOf(changeDetails._cacheKey) !== -1 && this._changeHandler) {
                this._changeHandler(changeDetails);
                if(changeDetails.albumLocalIdentifier) {
                  const albumThatChanged = this.albums.find(album => album.localIdentifier === changeDetails.albumLocalIdentifier);
                  albumThatChanged._emitChange(changeDetails);
                }
            }
        });
    }

    onChange(changeHandler) {
      this._changeHandler = changeHandler;
    }
}
