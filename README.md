# react-native-photos-framework
##2016-10-21. Under heavy development right now. Check back in 2 weeks before you depend on this library!
`npm i react-native-photos-framework --save`

Load photos and albums from CameraRoll and iCloud.
Uses Apples photos framework.

React Native comes with it's own CameraRoll library.
This however uses ALAssetLibrary which is deprecated from Apple
and can only load photos and videos stored on the users device.
This is not what your user expects today. Most of users photos
today live on iCloud and these won't show if you use ALAssetLibrary.

If you use this library/Photos framework you can display the users local resources and the users iCloud resources.

~~~~
import React, { Component } from 'react';
import RNPhotosFramework from 'react-native-photos-framework';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

export default class HelloRN extends Component {

  constructor() {
    super();
    this.state = {images : null};
  }
  componentWillMount() {
    RNPhotosFramework.getPhotos({
          startIndex : 0,
          endIndex : 100,

          //Avaliable: ['photo', 'video', 'audio', 'unknown']
          mediaTypes : ['photo', 'video'],

          //Avaliable:  ['none', 'photoPanorama', 'photoHDR', 'photoScreenshot',
          //            'photoLive', 'videoStreamed', 'videoHighFrameRate,
          //            'videoTimeLapse']
          mediaSubTypes : ['photoPanorama'],

          sortAscending : true,
          sortDescriptorKey : 'creationDate',
          prepareForSizeDisplay : {
            width : 91.5,
            height : 91.5
          },
          prepareScale : 2
        }).then((images) => this.setState({images : images}));
  }

  render() {
    return (
      <View></View>
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
