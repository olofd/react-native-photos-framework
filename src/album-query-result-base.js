import Album from './album';
import commonSort from './common-sort';

export default class AlbumQueryResultBase {

    photoAppAlbumSort() {
        return this.sortAlbumsByTypeObject(commonSort, 'smartAlbum');
    }

    sortAlbumsByTypeObject(typeArray) {
        const newAlbumArray = [...this.albums];
        newAlbumArray
            .sort((albumOne, albumTwo) => {
                let albumOneWeight = this.getSortWeigth(albumOne, typeArray);
                let albumTwoWeight = this.getSortWeigth(albumTwo, typeArray);
                return albumOneWeight > albumTwoWeight ? -1 : albumOneWeight === albumTwoWeight ? albumOne.title.localeCompare(albumTwo.title) : 1;
            });
        return newAlbumArray;
    }

    getSortWeigth(albumObj, typeArray) {
        return typeArray.reduce((weight, typeObj, index) => {
            if (typeObj.type === albumObj.type && typeObj.subType == albumObj.subType) {
                weight = typeArray.length - index;
            }
            return weight;
        }, 0);
    }

    onChange(changeHandler) {
        this._changeHandler = changeHandler;
    }
}
