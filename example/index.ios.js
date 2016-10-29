/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, {Component} from 'react';
import {AppRegistry, StyleSheet, Text, View} from 'react-native';

import AlbumList from './album-list';
import RNPhotosFramework from 'react-native-photos-framework';
const TEST_ALBUM_ONE = 'RNPF-test-1';
const TEST_ALBUM_TWO = 'RNPF-test-2';
export default class Example extends Component {
  constructor(props) {
    super(props);
    this.state = {
      num: 0
    };
  }

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
      images: [
        {
          uri: 'https://c1.staticflickr.com/6/5337/8940995208_5da979c52f.jpg'
        }, {
          uri: 'https://upload.wikimedia.org/wikipedia/commons/d/db/Patern_test.jpg'
        }
      ]
    });
  }

  componentWillMount() {
    // Start with creating 2 test-albums that we can work with: First Check if they
    // already exist, if they do. clean up:
    // RNPhotosFramework.createAlbum(TEST_ALBUM_ONE);
    // RNPhotosFramework.createAlbum(TEST_ALBUM_TWO);

    RNPhotosFramework.requestAuthorization().then((status) => {
      if(status.isAuthorized) {
        this.cleanUp().then(() => {
          this.readd().then(() => {
            
          });
        });
      }else {
        alert('Application is not authorized to use Photos Framework! Pleade check settings.');
      }
    });
  }

  readd() {
    return this.testAlbumsExist().then((albums) => {
      return Promise.all([
        this.addTestImagesToAlbumOne(albums[0]),
        this.addTestImagesToAlbumOne(albums[1])
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
    return RNPhotosFramework.getAlbumsByTitles([TEST_ALBUM_ONE, TEST_ALBUM_TWO]).then((fetchResult) => {
      console.debug(`Found ${fetchResult.albums.length} test albums`);
      const albums = fetchResult.albums.filter(album => [TEST_ALBUM_ONE, TEST_ALBUM_TWO].some(testAlbum => testAlbum === album.title));
      const promises = albums.map(album => {
        console.debug(`Fetching album ${album.title}'s assets`);
        return album.getAssets().then((assetResultObj) => {
          console.debug(`Deleting album ${album.title}'s assets: ${assetResultObj.assets.length} assets`);
          return RNPhotosFramework.deleteAssets(assetResultObj.assets);
        });
      });
      return Promise.all(promises).then(() => {
        console.debug(`Deleting albums ${albums.length}`);
        return RNPhotosFramework.deleteAlbums(albums).then((result) => {
          console.debug('Cleanup comlete');
          return result;
        });
      });
    });
  }

  testAlbumsExist() {
    return RNPhotosFramework.getAlbumsByTitles([TEST_ALBUM_ONE, TEST_ALBUM_TWO]).then((fetchResult) => {
      const albumsThatDoExit = [TEST_ALBUM_ONE, TEST_ALBUM_TWO].filter(testAlbumTitle => fetchResult.albums.some(album => album.title === testAlbumTitle));
      const albumsThatDontExit = [TEST_ALBUM_ONE, TEST_ALBUM_TWO].filter(testAlbumTitle => !fetchResult.albums.some(album => album.title === testAlbumTitle));
      if (albumsThatDontExit.length) {
        return RNPhotosFramework.createAlbums(albumsThatDontExit).then((newAlbums) => {
          return albumsThatDoExit.concat(newAlbums);
        });
      }
      return fetchResult.albums;
    });
  }

  render() {
    return (
      <View style={styles.container}>
        <AlbumList></AlbumList>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1
  }
});

AppRegistry.registerComponent('Example', () => Example);
