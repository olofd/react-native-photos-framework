import Album from './album';
export default class AlbumQueryResult {
    constructor(obj, fetchOptions, eventEmitter) {
        this._fetchOptions = fetchOptions;
        Object.assign(this, obj);
        this.albums = this.albums.map(albumObj => new Album(albumObj,
            fetchOptions, eventEmitter));
        eventEmitter.addListener('onAlbumQueryResultChange', (changeDetails) => {
            if (changeDetails._cacheKey === this._cacheKey && this._changeHandler) {
                console.log('CHANGE');
                this._changeHandler(changeDetails);
            }
        });
    }

    onChange(changeHandler) {
      this._changeHandler = changeHandler;
    }
}
