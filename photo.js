export default class Photo {
    static scheme = "pk://";
    constructor(photoObj, options) {
        this._localIdentifier = photoObj.uri;
        this.width = photoObj.width;
        this.height = photoObj.height;
        if(options) {
          this._queryString = this.serialize(options);
        }
        this.uri = Photo.scheme + this._localIdentifier;
        if(this._queryString) {
          this.uri = this.uri + `?${this._queryString}`;
        }
        this._photoObj = photoObj;
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
      return new Photo(this._photoObj, options);
    }
}
