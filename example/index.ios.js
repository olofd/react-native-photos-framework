console.debug = console.debug || console.log;
import React, {Component} from 'react';
import {AppRegistry, StyleSheet, Text, View} from 'react-native';
import AlbumList from './album-list';
import {Scene, Router} from 'react-native-router-flux';
import CameraRollPicker from './react-native-camera-roll-picker';

export default class Example extends Component {

  render() {
    return (
      <Router>
        <Scene key="root">
          <Scene key="albumList" component={AlbumList} title="Album"/>
          <Scene key="cameraRollPicker" component={CameraRollPicker} title="Bilder"/>
        </Scene>
      </Router>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1
  }
});

AppRegistry.registerComponent('Example', () => Example);
