import Album from './album';
import commonSort from './common-sort';
import AlbumQueryResultBase from './album-query-result-base';
import changeObserverHandler from './change-observer-handler';
export default class AlbumQueryResult extends AlbumQueryResultBase {
    constructor(obj, fetchParams, eventEmitter) {
        super();
        this.eventEmitter = eventEmitter;
        this._fetchParams = fetchParams || {};
        Object.assign(this, obj);
        this._albumNativeObjs = this.albums;
        this.albums = this
            ._albumNativeObjs
            .map(albumObj => new Album(albumObj, this._fetchParams.fetchOptions, eventEmitter));
        eventEmitter.addListener('onObjectChange', (changeDetails) => {
            if (this._cacheKey === changeDetails._cacheKey) {
                this._changeHandler && this._changeHandler(changeDetails, this);
                if (changeDetails.albumLocalIdentifier) {
                    const albumThatChanged = this
                        .albums
                        .find(album => album.localIdentifier === changeDetails.albumLocalIdentifier);
                    albumThatChanged && albumThatChanged._emitChange(changeDetails, albumThatChanged);
                }
            }
        });
    }

    applyChangeDetails(changeDetails) {
        this.albums = changeObserverHandler(changeDetails, this.albums, (nativeObj) => {
            return new Album(nativeObj, this._fetchParams.fetchOptions, this.eventEmitter);
        });
        return this.albums;
    }
}
