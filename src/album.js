import NativeApi from './index';
import Asset from './asset';
import uuidGenerator from './uuid-generator';
import changeObserverHandler, {
    assetArrayObserverHandler
} from './change-observer-handler';
import EventEmitter from '../event-emitter';


export default class Album extends EventEmitter {

    constructor(obj, fetchOptions, eventEmitter) {
        super();
        this._fetchOptions = fetchOptions;
        Object.assign(this, obj);
        if (this.previewAssets) {
            this.previewAssets = this
                .previewAssets
                .map(NativeApi.createJsAsset);
            if (this.previewAssets.length) {
                this.previewAsset = this.previewAssets[0];
            }
        }

        eventEmitter.addListener('onObjectChange', (changeDetails) => {
            if (changeDetails._cacheKey === this._cacheKey) {
                this._emitChange(changeDetails, (assetArray, callback, fetchOptions) => {
                    if (assetArray) {
                        return assetArrayObserverHandler(
                            changeDetails, assetArray,
                            NativeApi.createJsAsset, (indecies, callback) => {
                                //The update algo has requested new assets.
                                return this.newAssetsRequested(indecies, fetchOptions, callback);
                            }, this.perferedSortOrder).then(updatedArray => {
                            callback && callback(updatedArray);
                            return updatedArray;
                        });
                    }
                    return assetArray;
                }, this);
            }
        });
    }

    newAssetsRequested(indecies, fetchOptions, callback) {
        const fetchOptionsWithIndecies = {...fetchOptions, indecies : [...indecies]};
        return this.getAssetsWithIndecies(fetchOptionsWithIndecies).then((assets) => {
            callback && callback(assets);
            return assets;
        });
    }

    deleteContentPermitted() {
        return this._canPerformOperation(0);
    }

    removeContentPermitted() {
        return this._canPerformOperation(1);
    }

    addContentPermitted() {
        return this._canPerformOperation(2);
    }

    createContentPermitted() {
        return this._canPerformOperation(3);
    }

    reArrangeContentPermitted() {
        return this._canPerformOperation(4);
    }

    deletePermitted() {
        return this._canPerformOperation(5);
    }

    renamePermitted() {
        return this._canPerformOperation(6);
    }

    _canPerformOperation(index) {
        return this.permittedOperations && this.permittedOperations[index];
    }

    stopTracking() {
        return NativeApi.stopTracking(this._cacheKey);
    }

    getAssets(params) {
        this.perferedSortOrder = params.assetDisplayBottomUp === params.assetDisplayStartToEnd ? 'reversed' : 'normal';
        const trackAssets = params.trackInsertsAndDeletes || params.trackAssetsChanges;
        if (trackAssets && !this._cacheKey) {
            this._cacheKey = uuidGenerator();
        }
        return NativeApi.getAssets({
            fetchOptions: this._fetchOptions,
            ...params,
            _cacheKey: this._cacheKey,
            albumLocalIdentifier: this.localIdentifier
        });
    }

    getAssetsWithIndecies(params) {
        const trackAssets = params.trackInsertsAndDeletes || params.trackAssetsChanges;
        if (trackAssets && !this._cacheKey) {
            this._cacheKey = uuidGenerator();
        }
        return NativeApi.getAssetsWithIndecies({
            fetchOptions: this._fetchOptions,
            ...params,
            _cacheKey: this._cacheKey,
            albumLocalIdentifier: this.localIdentifier
        });
    }

    addAsset(asset) {
        return this.addAssets([asset]);
    }

    addAssets(assets) {
        return NativeApi.addAssetsToAlbum({
            assets: assets.map(asset => asset.localIdentifier),
            _cacheKey: this._cacheKey,
            albumLocalIdentifier: this.localIdentifier
        });
    }

    removeAsset(asset) {
        return this.removeAssets([asset]);
    }

    removeAssets(assets) {
        return NativeApi.removeAssetsFromAlbum({
            assets: assets.map(asset => asset.localIdentifier),
            _cacheKey: this._cacheKey,
            albumLocalIdentifier: this.localIdentifier
        });
    }

    updateTitle(newTitle) {
        return NativeApi.updateAlbumTitle({
            newTitle: newTitle,
            _cacheKey: this._cacheKey,
            albumLocalIdentifier: this.localIdentifier
        });
    }

    delete() {
        return NativeApi.deleteAlbums([this]);
    }

    onChange(cb) {
        this.addListener('onChange', cb);
        return () => this.removeListener('onChange', cb);
    }

    _emitChange(...args) {
        this.emit('onChange', ...args);
    }
}
