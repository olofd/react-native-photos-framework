# react-native-insta-photo-studio

`npm i react-native-insta-photo-studio --save`

~~~~
import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';
import ReactNativeInstaPhotoStudio from 'react-native-insta-photo-studio';

export default class HelloRN extends Component {
  render() {
    return (
      <ReactNativeInstaPhotoStudio></ReactNativeInstaPhotoStudio>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('HelloRN', () => HelloRN);
~~~~
