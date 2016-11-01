import Album from './album';
import commonSort from './common-sort';
import AlbumQueryResultBase from './album-query-result-base';

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
        this.updateHandler(changeDetails.insertedObjects, (updatedObj, i, arr) => {
            this
                .albums
                .splice(updatedObj.index, 0, new Album(updatedObj.album, this._fetchParams.fetchOptions, this.eventEmitter));
        });
        this.updateHandler(changeDetails.removedObjects, (updatedObj, i, arr) => {
            this
                .albums
                .splice(updatedObj.index, 1);
        });
        if (changeDetails.moves) {
            let tempObj = {};
            for (let i = 0; i < changeDetails.moves.length; i = (i + 2)) {
                const fromIndex = changeDetails.moves[i];
                const toIndex = changeDetails.moves[i + 1];
                const fromObj = tempObj[fromIndex] || this.albums[fromIndex];
                tempObj[toIndex] = this.albums[toIndex];
                this.albums[toIndex] = fromObj;
            }
            this
                .albums
                .forEach(x => console.log(x.title));
        }

        this.updateHandler(changeDetails.changedObjects, (updatedObj, i, arr) => {
            this.albums[updatedObj.index] = new Album(updatedObj.album, this._fetchParams.fetchOptions, this.eventEmitter);
        });
    }

    updateHandler(arr, cb) {
        if (arr) {
            for (let i = 0; i < arr.length; i++) {
                const updatedObj = arr[i];
                cb(updatedObj, i, arr);
            }
        }
    }
}
