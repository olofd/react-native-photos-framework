import Asset from './asset';

export default class ImageAsset extends Asset {
    constructor(assetObj, options) {
        super(assetObj, options);
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

    getImageMetadata() {
        return this._fetchExtraData('getImageAssetsMetadata', 'imageMetadata');
    }
}