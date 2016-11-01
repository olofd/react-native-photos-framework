import React, {Component} from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  AlertIOS
} from 'react-native';
import CameraRollPicker from './camera-roll-picker';
import {Actions} from 'react-native-router-flux';
import RNPhotosFramework from 'react-native-photos-framework';

export default class ReactNativeCameraRollPicker extends Component {
  constructor(props) {
    super(props);

    this.state = {
      num: 0,
      selected: [],
      edit: false
    };
  }

  componentDidMount() {
    Actions.refresh({
      renderRightButton: this
        .renderRightButton
        .bind(this),
      edit: false
    });
  }

  renderRightButton(props, a) {
    return (
      <TouchableOpacity onPress={this
        .onEditAlbum
        .bind(this)}>
        <Text style={styles.changeButton}>Edit</Text>
      </TouchableOpacity>
    );
  }

  onEditAlbum() {}

  componentWillReceiveProps(nextProps) {
    if (this.props.edit !== nextProps.edit) {
      Actions.refresh({
        renderRightButton: this
          .renderRightButton
          .bind(this)
      });
    }
  }

  getSelectedImages(images, current) {
    var num = images.length;
    this.setState({num: num, selected: images});
    console.log(current);
    console.log(this.state.selected);
  }

  downloadTenRandom() {
    RNPhotosFramework
      .createImageAsset({
      uri: 'https://static1.squarespace.com/static/54864b83e4b0c89104abed87/t/54c6102fe4b02c' +
          'f35cfb7e97/1422266417481/stock-photo-vancouver-sunrise-27499741.jpg?format=1500w'
    })
      .then((asset) => {
        this
          .props
          .album
          .addAsset(asset)
          .then((status) => {

          });
      });
  }

  downloadDialog() {
    AlertIOS.alert('Add media', 'Select what to add:', [
      {
        text: '10 random photos',
        onPress: this
          .downloadTenRandom
          .bind(this)
      }, {
        text: 'Cancel',
        onPress: () => console.log('Cancel Pressed'),
        style: 'cancel'
      }
    ],);
  }

  render() {
    return (
      <View style={styles.container}>
        <CameraRollPicker
          album={this.props.album}
          removeClippedSubviews={true}
          groupTypes='SavedPhotos'
          batchSize={5}
          maximum={3}
          selected={this.state.selected}
          assetType='Photos'
          imagesPerRow={3}
          imageMargin={5}
          callback={this
          .getSelectedImages
          .bind(this)}/>
        <TouchableOpacity
          style={styles.addMediaButton}
          onPress={this
          .downloadDialog
          .bind(this)}>
          <Text style={styles.addMediaText}>Add media</Text>
        </TouchableOpacity>
        <View style={styles.addMediaContainer}></View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    marginTop: 65
  },
  addMediaButton: {
    padding: 20,
    backgroundColor: 'white',
    borderWidth: 1,
    borderColor: 'rgb(34, 125, 197)',
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    bottom: 10
  },
  addMediaText: {
    color: 'rgb(34, 125, 197)',
    fontSize: 20,
    fontWeight: 'bold',
    backgroundColor: 'transparent'
  },
  content: {
    marginTop: 15,
    height: 50,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    flexWrap: 'wrap'
  },
  text: {
    fontSize: 16,
    alignItems: 'center',
    color: '#fff'
  },
  bold: {
    fontWeight: 'bold'
  },
  info: {
    fontSize: 12
  },
  addButtonPlus: {
    width: 30,
    height: 40,
    top: -10,
    fontSize: 32,
    color: 'rgb(0, 113, 255)',
    backgroundColor: 'transparent'
  },
  changeButton: {
    fontSize: 18,
    color: 'rgb(0, 113, 255)'
  },
  removeIconContainer: {
    position: 'absolute',
    top: 5,
    left: 0,
    backgroundColor: 'white',
    borderRadius: 14,
    height: 20,
    width: 23
  },
  removeIcon: {
    top: -5,
    fontSize: 28,
    color: 'red',
    backgroundColor: 'transparent'
  }
});
