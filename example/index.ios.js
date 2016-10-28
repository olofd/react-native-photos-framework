/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

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

  componentWillMount() {
    //Start with creating 2 test-albums that we can work with:
    //First Check if they already exist, if they do. clean up:
    //RNPhotosFramework.createAlbum(TEST_ALBUM_ONE);
    //RNPhotosFramework.createAlbum(TEST_ALBUM_TWO);

    return this.testAlbumsExist().then((albums) => {
      return RNPhotosFramework.createImageAssets([{
        uri : 'https://c1.staticflickr.com/6/5337/8940995208_5da979c52f.jpg'
      }, {
        uri : 'https://upload.wikimedia.org/wikipedia/commons/d/db/Patern_test.jpg'
      }]).then((assets) => {
        debugger;
      });
    });
  }


  removeAlbums(albums) {
    return RNPhotosFramework.deleteAlbums(albums);
  }

  testAlbumsExist() {
    return RNPhotosFramework.getAlbumsByTitles([TEST_ALBUM_ONE, TEST_ALBUM_TWO]).then((fetchResult) => {
      const albumsThatDoExit = [TEST_ALBUM_ONE, TEST_ALBUM_TWO].filter(testAlbumTitle => fetchResult.albums.some(album => album.title === testAlbumTitle));
      const albumsThatDontExit = [TEST_ALBUM_ONE, TEST_ALBUM_TWO].filter(testAlbumTitle => !fetchResult.albums.some(album => album.title === testAlbumTitle));
      if(albumsThatDontExit.length) {
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
