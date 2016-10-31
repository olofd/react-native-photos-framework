import React, {Component} from 'react';
import {
  View,
  StyleSheet,
  Text,
  Image,
  ListView,
  TouchableOpacity,
  Dimensions
} from 'react-native'
import RNPhotosFramework from 'react-native-photos-framework';
import {Actions} from 'react-native-router-flux'
var simple_timer = require('simple-timer');

export default class AlbumList extends Component {

  constructor() {
    super();
    this.state = {
      dataSource: new ListView.DataSource({
        rowHasChanged: (r1, r2) => r1 !== r2
      })
    };
  }

  componentWillMount() {
    simple_timer.start('first_album_fetch');
    RNPhotosFramework
      .requestAuthorization()
      .then((status) => {
        RNPhotosFramework
          .getAlbumsCommon({
          assetCount: 'exact',
          includeMetaData: true,
          previewAssets: 2,
          sortDescriptors: [
            {
              key: 'title',
              ascending: false
            }
          ]
        })
          .then((albumsFetchResult) => {
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

  componentWillReceiveProps(nextProps) {}

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
    if (this.state.albumsFetchResult.albums) {
      this.setState({
        dataSource: this
          .state
          .dataSource
          .cloneWithRows(this.chunk(this.state.albumsFetchResult.albums, 2))
      });
    }
  }

  onAlbumPress(album) {
    console.log(album.title);
    Actions.cameraRollPicker({album : album, title : album.title});
  }

  _renderAlbum(album, index) {
    return (
      <TouchableOpacity style={styles.listColumn} key={index} onPress={this.onAlbumPress.bind(this, album)}>
        {album.previewAsset
          ? <Image
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
        <Text>{album.title}</Text>
        <Text>{album.assetCount}</Text>
      </TouchableOpacity>
    );
  }

  _renderRow(albums) {
    return (
      <View style={styles.listRow}>
        {albums.map((album, index) => this._renderAlbum(album, index))}
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
          renderRow={rowData => this._renderRow(rowData)}/>
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
  }
})
