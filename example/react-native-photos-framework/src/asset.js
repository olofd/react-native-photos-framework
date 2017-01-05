import NativeApi from './index';
export default class Asset {
    static scheme = "pk://";
    constructor(assetObj, options) {
        Object.assign(this, assetObj);
        if (options) {
            this._queryString = this.serialize(options);
        }
        this.uri = Asset.scheme + this.localIdentifier;
        if (this._queryString) {
            this.uri = this.uri + `?${this._queryString}`;
        }
        this._assetObj = assetObj;
    }

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
            uri
        };
        return this._imageRef;
    }

    getMetadata() {
        return this._fetchExtraData('getAssetsMetadata', 'creationDate');
    }

    _fetchExtraData(nativeMethod, alreadyLoadedProperty) {
        return new Promise((resolve, reject) => {
            if (this[alreadyLoadedProperty]) {
                //This means we alread have fetched metadata.
                //Resolve directly
                resolve(this);
                return;
            }
            return resolve(NativeApi[nativeMethod]([this.localIdentifier])
                .then((metadataObjs) => {
                    if (metadataObjs && metadataObjs[0]) {
                        Object.assign(this, metadataObjs[0]);
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
        return new Asset(this._assetObj, options);
    }

    delete() {
        return NativeApi.deleteAssets([this.localIdentifier]);
    }
}