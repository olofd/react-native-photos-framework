import Album from './album';
export default class AlbumQueryResult {
    constructor(obj, fetchOptions, eventEmitter) {
        this._fetchOptions = fetchOptions;
        Object.assign(this, obj);
        this.albums = this.albums.map(albumObj => new Album(albumObj,
            fetchOptions, eventEmitter));
        eventEmitter.addListener('onObjectChange', (changeDetails) => {
            if (changeDetails._cacheKey === this._cacheKey && this._changeHandler) {
                this._changeHandler(changeDetails);
            }
        });
    }

    onChange(changeHandler) {
      this._changeHandler = changeHandler;
    }
}
