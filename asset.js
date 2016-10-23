export default class Asset {
    static scheme = "pk://";
    constructor(assetObj, options) {
        this.localIdentifier = assetObj.localIdentifier;
        this.width = assetObj.width;
        this.height = assetObj.height;
        if(options) {
          this._queryString = this.serialize(options);
        }
        this.uri = Asset.scheme + this.localIdentifier;
        if(this._queryString) {
          this.uri = this.uri + `?${this._queryString}`;
        }
        this._assetObj = assetObj;
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

    widthOptions(options) {
      return new Asset(this._assetObj, options);
    }
}
