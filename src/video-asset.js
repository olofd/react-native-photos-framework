import Asset from './asset';
import NativeApi from './index';

export default class VideoAsset extends Asset {
    constructor(assetObj, options) {
        super(assetObj, options);
    }

    get video() {
        if (this._videoRef) {
            return this._videoRef;
        }
        this._videoRef = {
            uri : this.uri,
            type : ''
        };
        return this._videoRef;
    }
}