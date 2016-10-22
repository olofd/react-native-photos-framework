
import Album from './album';
export default class Collection {
  constructor(obj) {
    Object.assign(this, obj);
    this.albums = this.albums.map(albumObj => new Album(albumObj));
  }
}
