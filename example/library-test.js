import RNPhotosFramework from 'react-native-photos-framework';
var simple_timer = require('simple-timer');
const TEST_ALBUM_ONE = 'RNPF-test-1';
const TEST_ALBUM_TWO = 'RNPF-test-2';

export default class LibraryTest {

  addTestImagesToAlbumOne(album) {
    return RNPhotosFramework.createAssets({
      album: album,
      images: [
        {
          uri: 'https://c1.staticflickr.com/6/5337/8940995208_5da979c52f.jpg'
        }, {
          uri: 'https://upload.wikimedia.org/wikipedia/commons/d/db/Patern_test.jpg'
        }
      ]
    });
  }

  addTestImagesToAlbumTwo(album) {
    return RNPhotosFramework.createAssets({
      album: album,
      includeMetadata: true,
      images: [
        {
          uri: 'https://c1.staticflickr.com/6/5337/8940995208_5da979c52f.jpg'
        }, {
          uri: 'https://upload.wikimedia.org/wikipedia/commons/d/db/Patern_test.jpg'
        }
      ]
    }).then((assets) => {
      return assets;
    });
  }



  _componentWillMount() {
    RNPhotosFramework
      .requestAuthorization()
      .then((status) => {
        if (status.isAuthorized) {
          this
            .cleanUp()
            .then(() => {
              this
                .readd()
                .then(() => {});
            });
        } else {
          alert('Application is not authorized to use Photos Framework! Pleade check settings.');
        }
      });
  }

  readd() {
    return this
      .testAlbumsExist()
      .then((albums) => {
        return Promise.all([
          this.addTestImagesToAlbumOne(albums[0]),
          this.addTestImagesToAlbumTwo(albums[1])
        ]).then((assets) => {}, (li) => {
          //ProgressCallback
        }).then(() => {
          //Complete
        });
      });
  }

  removeAlbums(albums) {
    return RNPhotosFramework.deleteAlbums(albums);
  }

  cleanUp() {
    console.debug('Will search for test-albums');
    return RNPhotosFramework
      .getAlbumsByTitles([TEST_ALBUM_ONE, TEST_ALBUM_TWO])
      .then((fetchResult) => {
        console.debug(`Found ${fetchResult.albums.length} test albums`);
        const albums = fetchResult
          .albums
          .filter(album => [TEST_ALBUM_ONE, TEST_ALBUM_TWO].some(testAlbum => testAlbum === album.title));
        const promises = albums.map(album => {
          console.debug(`Fetching album ${album.title}'s assets`);
          return album
            .getAssets()
            .then((assetResultObj) => {
              console.debug(`Deleting album ${album.title}'s assets: ${assetResultObj.assets.length} assets`);
              return RNPhotosFramework.deleteAssets(assetResultObj.assets);
            });
        });
        return Promise
          .all(promises)
          .then(() => {
            console.debug(`Deleting albums ${albums.length}`);
            return RNPhotosFramework
              .deleteAlbums(albums)
              .then((result) => {
                console.debug('Cleanup comlete');
                return result;
              });
          });
      });
  }

  testAlbumsExist() {
    return RNPhotosFramework
      .getAlbumsByTitles([TEST_ALBUM_ONE, TEST_ALBUM_TWO])
      .then((fetchResult) => {
        const albumsThatDoExit = [TEST_ALBUM_ONE, TEST_ALBUM_TWO].filter(testAlbumTitle => fetchResult.albums.some(album => album.title === testAlbumTitle));
        const albumsThatDontExit = [TEST_ALBUM_ONE, TEST_ALBUM_TWO].filter(testAlbumTitle => !fetchResult.albums.some(album => album.title === testAlbumTitle));
        if (albumsThatDontExit.length) {
          return RNPhotosFramework
            .createAlbums(albumsThatDontExit)
            .then((newAlbums) => {
              return albumsThatDoExit.concat(newAlbums);
            });
        }
        return fetchResult.albums;
      });
  }
}
