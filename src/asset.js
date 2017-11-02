import NativeApi from './index';
export default class Asset {
    static scheme = "photos://";
    constructor(assetObj) {
        Object.assign(this, assetObj);
        this._assetObj = assetObj;
    }

    get uri() {
        if (this.lastOptions === this.currentOptions && this._uri) {
            return this._uri;
        }
        let queryString;
        if (this.currentOptions) {
            this.lastOptions = this.currentOptions;
            queryString = this.serialize(this.currentOptions);
        }
        this._uri = Asset.scheme + this.localIdentifier;
        if (queryString) {
            this._uri = this._uri + `?${queryString}`;
        }
        return this._uri;
    }

    //This is here in base-class, videos can display thumb.
    get image() {
        if (this._imageRef) {
            return this._imageRef;
        }
        const {
            width,
            height,
            uri
        } = this;
        this._imageRef = {
            width,
            height,
            uri,
            name: 'test.jpg'
        };
        return this._imageRef;
    }

    get creationDate() {
        return this.toJsDate('creationDateUTCSeconds', '_creationDate');
    }

    get modificationDate() {
        return this.toJsDate('modificationDateUTCSeconds', '_modificationDate');
    }

    toJsDate(UTCProperty, cachedProperty) {
        if (!this[UTCProperty]) {
            return undefined;
        }
        if (!this[cachedProperty]) {
            const utcSecondsCreated = this[UTCProperty];
            this[cachedProperty] = new Date(0);
            this[cachedProperty].setUTCSeconds(utcSecondsCreated);
        }
        return this[cachedProperty];
    }

    getMetadata() {
        return this._fetchExtraData('getAssetsMetadata', 'creationDate');
    }

    refreshMetadata() {
        return this._fetchExtraData('getAssetsMetadata', 'creationDate', true);
    }

    getResourcesMetadata() {
        return this._fetchExtraData('getAssetsResourcesMetadata', 'resourcesMetadata');
    }

    _fetchExtraData(nativeMethod, alreadyLoadedProperty, force) {
        return new Promise((resolve, reject) => {
            if (!force && this[alreadyLoadedProperty]) {
                //This means we alread have fetched metadata.
                //Resolve directly
                resolve(this);
                return;
            }
            return resolve(NativeApi[nativeMethod]([this.localIdentifier])
                .then((metadataObjs) => {
                    if (metadataObjs && metadataObjs[this.localIdentifier]) {
                        Object.assign(this, metadataObjs[this.localIdentifier]);
                    }
                    return this;
                }));
        });
    }

    serialize(obj) {
        var str = [];
        for (var p in obj) {
            if (obj.hasOwnProperty(p)) {
                str.push(encodeURIComponent(p) + "=" + encodeURIComponent(
                    obj[p]));
            }
        }
        return str.join("&");
    }

    withOptions(options) {
        this.currentOptions = options;
        return this;
    }

    delete() {
        return NativeApi.deleteAssets([this]);
    }

    setHidden(hidden) {
        return this._updateProperty('hidden', hidden, true);
    }

    setFavorite(favorite) {
        return this._updateProperty('favorite', favorite, true);
    }

    setCreationDate(jsDate) {
        return this._updateProperty('creationDate', jsDate, false);
    }

    setLocation(latLngObj) {
        return this._updateProperty('location', latLngObj, false);
    }

    //name and extension are optional
    saveAssetToDisk(options, onProgress, generateFileName) {
        return NativeApi.saveAssetsToDisk([{
            asset: this,
            options: options
        }], {
                onProgress: onProgress
            }, generateFileName).then((results) => {
              const result = results[0];
              if (result.success) {
                return result.fileUrl;
              }
              else {
                throw result.error;
              }
            });
    }

    _updateProperty(property, value, precheckValue) {
        return new Promise((resolve, reject) => {
            if (precheckValue && this[property] === value) {
                return resolve({
                    success: true,
                    error: ''
                });
            }
            return NativeApi.updateAssets({
                [this.localIdentifier]: {
                    [property]: value
                }
            }).then(resolve, reject);
        });
    }
}
