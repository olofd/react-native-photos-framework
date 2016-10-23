
import Album from './album';
export default class AlbumQueryResult {
  constructor(obj, fetchOptions)
  {
    this._fetchOptions = fetchOptions;
    Object.assign(this, obj);
    this.albums = this.albums.map(albumObj => new Album(albumObj, fetchOptions));
  }
}
