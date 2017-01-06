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

    getMetadata() {
        return this._fetchExtraData('getAssetsMetadata', 'creationDate', 'metadata');
    }

    getResourcesMetadata() {
        return this._fetchExtraData('getAssetsResourcesMetadata', 'resourcesMetadata');
    }

    _fetchExtraData(nativeMethod, alreadyLoadedProperty, propertyToAssignToSelf) {
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
                        if(propertyToAssignToSelf) {
                            Object.assign(this, metadataObjs[0][propertyToAssignToSelf]);
                        } else {
                            Object.assign(this, metadataObjs[0]);
                        }
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
        return NativeApi.createJsAsset(this._assetObj, options);
    }

    delete() {
        return NativeApi.deleteAssets([this.localIdentifier]);
    }
}
