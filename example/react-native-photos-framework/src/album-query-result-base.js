import Album from './album';
import photoAppSort from './photo-app-sort';
import instagramAppSort from './instagram-app-sort';
import EventEmitter from '../event-emitter';

export default class AlbumQueryResultBase extends EventEmitter {

    instagramAppAlbumSort() {
        return this.sortAlbumsByTypeObject(instagramAppSort, 'smartAlbum');
    }

    photoAppAlbumSort() {
        return this.sortAlbumsByTypeObject(photoAppSort, 'smartAlbum');
    }

    sortAlbumsByTypeObject(typeArray) {
        const newAlbumArray = [...this.albums];
        newAlbumArray
            .sort((albumOne, albumTwo) => {
                let albumOneWeight = this.getSortWeigth(albumOne,
                    typeArray);
                let albumTwoWeight = this.getSortWeigth(albumTwo,
                    typeArray);
                return albumOneWeight > albumTwoWeight ? -1 :
                    albumOneWeight === albumTwoWeight ? albumOne.title.localeCompare(
                        albumTwo.title) : 1;
            });
        return newAlbumArray;
    }

    getSortWeigth(albumObj, typeArray) {
        return typeArray.reduce((weight, typeObj, index) => {
            if (typeObj.type === albumObj.type && typeObj.subType ==
                albumObj.subType) {
                weight = typeArray.length - index;
            }
            return weight;
        }, 0);
    }

    onChange(changeHandler) {
      this.addListener('onChange', changeHandler);
      return () => this.removeListener('onChange', changeHandler);
    }
}
