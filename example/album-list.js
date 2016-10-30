import React, {Component} from 'react';
import {
  View,
  StyleSheet,
  Text,
  Image,
  ListView,
  TouchableOpacity
} from 'react-native'

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
    this.albumPropsToListView(this.props);
  }

  componentWillReceiveProps(nextProps) {
    this.albumPropsToListView(nextProps);
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
    if (props.albums) {
      this.setState({
        dataSource: this
          .state
          .dataSource
          .cloneWithRows(this.chunk(props.albums, 2))
      });
    }
  }

  _renderAlbum(album, index) {
    return (
    <TouchableOpacity style={styles.listColumn} key={index}>
        {album.previewAsset
          ? <Image
              source={{
              uri: album.previewAsset.image.uri,
              width: 150,
              height: 150
            }}></Image>
          : null}
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
    paddingTop : 20
  },
  listRow: {
   flexDirection : 'row'
  },
  listColumn : {
    padding : 10
  }
})
