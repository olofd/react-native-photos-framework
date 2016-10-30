import React, { Component } from 'react';
import { View, StyleSheet, Text, Image, ListView } from 'react-native'

export default class AlbumList extends Component {

  constructor() {
    super();
    this.state = {
      dataSource: new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2})
    };
  }

  componentWillMount() {
    this.albumPropsToListView(this.props);
  }

  componentWillReceiveProps(nextProps) {
    this.albumPropsToListView(nextProps);
  }

  albumPropsToListView(props) {
    if(props.albums) {
      this.setState({
        dataSource: this.state.dataSource.cloneWithRows(
          props.albums
        )
      });
    }
  }

  _renderRow(album) {
    return (
      <View style={styles.listRow}>
        <Text>{album.title}</Text>
      </View>
    );
  }

  render() {
    return (<View>
      <ListView
        style={{flex: 1,}}
        removeClippedSubviews={true}
        dataSource={this.state.dataSource}
        renderRow={rowData => this._renderRow(rowData)} />
    </View>);
  }
}

const styles = StyleSheet.create({
  listRow : {
    padding : 20
  }
})
