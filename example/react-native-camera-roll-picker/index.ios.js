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
import Icon from 'react-native-vector-icons/Ionicons';

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

  removeSelectedFromAlbum() {
    this
      .props
      .album
      .removeAssets(this.state.selected);
  }

  deleteSelectedFromLibrary() {
    RNPhotosFramework
      .deleteAssets(this.state.selected)
      .then((status) => {
        if (status.success) {
          const remaining = this
            .state
            .selected
            .filter(x => status.localIdentifiers.some(y => y === x.localIdentfier));
          this.setState({selected: remaining});
          Actions.refresh({
            renderRightButton: this
              .renderRightButton
              .bind(this, this.props.edit, !!remaining.length)
          });
        }
      });
  }

  afterRemove() {

  }

  removeSelectedImages() {
    AlertIOS.alert('Remove media', 'Select how to remove', [
      {
        text: 'Remove from album',
        onPress: this
          .removeSelectedFromAlbum
          .bind(this)
      }, {
        text: 'Delete from library',
        onPress: this
          .deleteSelectedFromLibrary
          .bind(this)
      }, {
        text: 'Cancel',
        onPress: () => console.log('Cancel Pressed'),
        style: 'cancel'
      }
    ],);
  }

  renderRightButton(edit, hasSelectedMedia) {
    console.log('has selected', hasSelectedMedia);
    return (
      <View style={{
        flexDirection: 'row'
      }}>
        {(edit && (hasSelectedMedia === true))
          ? (
            <TouchableOpacity
              onPress={this
              .removeSelectedImages
              .bind(this)}>
              <Icon name='ios-trash' style={styles.trashIcon}></Icon>
            </TouchableOpacity>
          )
          : null}

        <TouchableOpacity
          style={{
          marginLeft: 24
        }}
          onPress={this
          .onEditAlbum
          .bind(this)}>
          <Text style={styles.changeButton}>{(edit
              ? 'Done'
              : 'Edit')}</Text>
        </TouchableOpacity>
      </View>

    );
  }

  onEditAlbum() {
    Actions.refresh({
      edit: !this.props.edit
    });
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.edit !== nextProps.edit) {
      Actions.refresh({
        renderRightButton: this
          .renderRightButton
          .bind(this, nextProps.edit)
      });
    }
  }

  getSelectedImages(images, current) {
    var num = images.length;
    this.setState({num: num, selected: images});
    Actions.refresh({
      renderRightButton: this
        .renderRightButton
        .bind(this, this.props.edit, !!images.length)
    });
  }

  downloadTenRandom() {
    RNPhotosFramework.createAssets({
      images: [
        {
          uri: 'https://static1.squarespace.com/static/54864b83e4b0c89104abed87/t/54c6102fe4b02c' +
              'f35cfb7e97/1422266417481/stock-photo-vancouver-sunrise-27499741.jpg?format=1500w'
        }, {
          uri: 'https://d1wtqaffaaj63z.cloudfront.net/images/E-0510.JPG'
        }, {
          uri: 'https://upload.wikimedia.org/wikipedia/commons/c/c6/Kimi_Raikkonen_2006_test.jpg'
        }, {
          uri: 'https://www.w3.org/MarkUp/Test/xhtml-print/20050519/tests/jpeg420exif.jpg'
        }, {
          uri: 'https://screensaver.riotgames.com/latest/content/original/Runeterra/Ionia/ionia-' +
              '01.jpg'
        }
      ]
    }).then((assets) => {
      this
        .props
        .album
        .addAssets(assets)
        .then((status) => {});
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
          maximum={99}
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
  trashIcon: {
    top: -10,
    color: 'rgb(0, 113, 255)',
    fontSize: 36
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
