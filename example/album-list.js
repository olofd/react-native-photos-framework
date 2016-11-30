import React, {Component} from 'react';
import {
  View,
  StyleSheet,
  Text,
  Image,
  ListView,
  TouchableOpacity,
  Dimensions,
  TextInput,
  AlertIOS
} from 'react-native'
import RNPhotosFramework from 'react-native-photos-framework';
import {Actions} from 'react-native-router-flux';
//ion-ios-remove-circle
import Icon from 'react-native-vector-icons/Ionicons';
var simple_timer = require('simple-timer');

export default class AlbumList extends Component {

  constructor() {
    super();
    this.state = {
      dataSource: new ListView.DataSource({
        rowHasChanged: (r1, r2) => r1 !== r2 || this.state.rerenderAll
      }),
      rerenderAll: true,
      pendingTitles: []
    };
  }

  componentDidMount() {
    Actions.refresh({
      renderRightButton: this
        .renderRightButton
        .bind(this),
      renderLeftButton: this
        .renderLeftButton
        .bind(this),
      edit: false
    });
  }

  onEditAlbums() {
    if (this.props.edit) {
      this
        .state
        .albumsFetchResult
        .albums
        .forEach(album => album.pendingTitle && album.updateTitle(album.pendingTitle));
    }
    Actions.refresh({
      edit: !this.props.edit
    });
  }

  createAlbum(albumName) {
    RNPhotosFramework.createAlbum(albumName);
  }

  onAlbumAdd() {
    AlertIOS.prompt('Create new album', 'Enter album name.', [
      {
        text: 'Cancel',
        onPress: () => console.log('Cancel Pressed'),
        style: 'cancel'
      }, {
        text: 'OK',
        onPress: this
          .createAlbum
          .bind(this)
      }
    ], 'plain-text');
  }

  renderRightButton(props, a) {
    return (
      <TouchableOpacity onPress={this
        .onEditAlbums
        .bind(this)}>
        <Text style={styles.changeButton}>Edit</Text>
      </TouchableOpacity>
    );
  }

  renderLeftButton() {
    return (
      <TouchableOpacity onPress={this
        .onAlbumAdd
        .bind(this)}>
        <Text style={styles.addButtonPlus}>+</Text>
      </TouchableOpacity>
    );
  }

  componentWillMount() {
    simple_timer.start('first_album_fetch');
    RNPhotosFramework
      .requestAuthorization()
      .then((status) => {
        RNPhotosFramework.getAlbumsCommon({
          assetCount: 'exact',
          includeMetaData: true,
          previewAssets: 2,
          assetFetchOptions : {
            mediaTypes : ['image'],
            sortDescriptors : [{
              key : 'creationDate',
              ascending : true
            }]
          },
          trackInsertsAndDeletes : true,
          trackChanges : true
        }, true).then((albumsFetchResult) => {
          albumsFetchResult.onChange((changeDetails, update, unsubscribe) => {
            const newAlbumFetchResult = update();
            this.setState({albumsFetchResult: newAlbumFetchResult});
            this.albumPropsToListView();
          });
          simple_timer.stop('first_album_fetch');
          console.debug('react-native-photos-framework albums request took %s milliseconds.', simple_timer.get('first_album_fetch').delta)
          this.setState({albumsFetchResult: albumsFetchResult});
          this.albumPropsToListView();
        });
      });

    var {width} = Dimensions.get('window');
    const imagesPerRow = 2;
    const imageMargin = 10;
    this._imageSize = (width - (imagesPerRow + 1) * imageMargin) / imagesPerRow;
  }

  renderFinnishEditingButton() {
    return (
      <TouchableOpacity onPress={this
        .onEditAlbums
        .bind(this)}>
        <Text style={styles.changeButton}>Done</Text>
      </TouchableOpacity>
    );
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.edit !== nextProps.edit && nextProps.edit) {
      Actions.refresh({
        renderRightButton: this
          .renderFinnishEditingButton
          .bind(this)
      });
      this.albumPropsToListView();
    }
    if (this.props.edit !== nextProps.edit && !nextProps.edit) {
      Actions.refresh({
        renderRightButton: this
          .renderRightButton
          .bind(this)
      });
      this.albumPropsToListView();
    }
  }

  chunk(arr, len) {
    var chunks = [],
      i = 0,
      n = arr.length;
    while (i < n) {
      chunks.push(arr.slice(i, i += len));
    }
    return chunks;
  }

  albumPropsToListView(props) {
    if (this.state.albumsFetchResult && this.state.albumsFetchResult.albums) {
      const rows = this.chunk(this.state.albumsFetchResult.albums, 2);
      this.setState({
        dataSource: this
          .state
          .dataSource
          .cloneWithRows(rows, undefined, rows.map((row, index) => (index)))
      });
    }
  }

  onAlbumPress(album) {
    Actions.cameraRollPicker({album: album, title: album.title});
  }

  _renderAlbum(album, index, columnIndex) {
    const canDeleteAlbum = album.deletePermitted();
    const canRenameAlbum = album.renamePermitted();
    const editable = canDeleteAlbum && canRenameAlbum;
    return (
      <View
        key={index.toString() + columnIndex.toString()}
        style={{
        opacity: (this.props.edit && !editable)
          ? 0.3
          : 1
      }}>
        <TouchableOpacity
          disabled={this.props.edit}
          style={styles.listColumn}
          onPress={this
          .onAlbumPress
          .bind(this, album)}>
          {album.previewAsset
            ? <Image
                zIndex={0}
                source={{
                uri: album.previewAsset.image.uri,
                width: this._imageSize,
                height: this._imageSize
              }}></Image>
            : <View
              style={{
              backgroundColor: '#D6D6D6',
              width: this._imageSize,
              height: this._imageSize
            }}></View>}
          {editable
            ? this.renderRemoveIcon(album)
            : null}
          {this.renderTextField(editable, album, index, columnIndex)}
          <Text style={styles.assetCount}>{album.assetCount}</Text>
        </TouchableOpacity>
      </View>

    );
  }

  renderTextField(editable, album, rowIndex, columnIndex) {
    const value = album.pendingTitle !== undefined
      ? album.pendingTitle
      : album.title;
    if (editable && this.props.edit) {
      const key = rowIndex.toString() + columnIndex.toString();
      return (
        <TextInput
          onChangeText={(text) => {
          album.pendingTitle = text;
          this.forceUpdate();
        }}
          style={styles.title}
          value={value}></TextInput>
      );
    }
    return <Text style={styles.titleText}>{value}</Text>
  }

  renderRemoveIcon(album) {
    if (!this.props.edit) {
      return null;
    }
    return (
      <TouchableOpacity
        style={styles.removeIconContainer}
        onPress={() => album.delete()}>
        <Icon style={styles.removeIcon} name='ios-remove-circle'></Icon>
      </TouchableOpacity>
    );
  }

  _renderRow(albums, sectionIndex, rowIndex) {
    return (
      <View style={styles.listRow}>
        {albums.map((album, columnIndex) => this._renderAlbum(album, rowIndex, columnIndex))}
      </View>
    );
  }

  render() {
    return (
      <View style={styles.container}>
        <ListView
          style={{
          flex: 1
        }}
          removeClippedSubviews={true}
          dataSource={this.state.dataSource}
          renderRow={this
          ._renderRow
          .bind(this)}/>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 20,
    marginTop: 50
  },
  listRow: {
    flexDirection: 'row',
    paddingLeft: 5
  },
  listColumn: {
    padding: 5
  },
  title: {
    height: 28,
    fontSize: 15,
    paddingLeft: 0
  },
  titleText: {
    paddingVertical: 10,
    height: 28,
    lineHeight: 13,
    fontSize: 15
  },
  assetCount: {
    fontSize: 15,
    marginTop: -2,
    color: 'rgb(158, 158, 158)',
    marginBottom: 5
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
})
