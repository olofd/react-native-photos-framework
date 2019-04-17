import React, { Component } from 'react';
import {
  CameraRoll,
  Platform,
  StyleSheet,
  View,
  Text,
  ListView,
  ActivityIndicator
} from 'react-native';
import ImageItem from './ImageItem';
import RNPhotosFramework from '../react-native-photos-framework';
import { postAssets } from '../react-native-photos-framework/src/ajax-helper'
var simple_timer = require('simple-timer')
import RNFetchBlob from 'react-native-fetch-blob';

class CameraRollPicker extends Component {
  constructor(props) {
    super(props);

    this.state = {
      images: [],
      selected: this.props.selected,
      lastCursor: null,
      loadingMore: false,
      noMore: false,
      dataSource: new ListView.DataSource({
        rowHasChanged: (r1, r2) => r1 !== r2
      })
    };
  }

  componentWillReceiveProps(nextProps) {
    this.setState({ selected: nextProps.selected });
    if (nextProps.album !== this.props.album) {
      this.setState({
        images: [],
        loadingMore: false,
        dataSource: this
          .state
          .dataSource
          .cloneWithRows([])
      });
      this._fetch(true, nextProps);
    }
  }

  fetch() {
    if (!this.state.loadingMore) {
      this.setState({
        loadingMore: true
      }, () => {
        this._fetch();
      });
    }
  }

  componentWillMount() {
    this.fetch();
    this.unsubscribe = this
      .props
      .album
      .onChange((changeDetails, update) => {
        update(this.state.images, (images) => {
          console.log(images[0]);
          this.state.images = images;
          this.state.dataSource = this
            .state
            .dataSource
            .cloneWithRows(this._nEveryRow(this.state.images, this.props.imagesPerRow));
          this.setState({ images: this.state.images, dataSource: this.state.dataSource });
        }, {
            includeMetadata: true
          });

      });
  }

  componentWillUnmount() {
    this
      .props
      .album
      .stopTracking();
    this.unsubscribe && this.unsubscribe();
  }

  _fetch(reset, nextProps) {
    if (this.lm) {
      return;
    }
    this.lm = true;
    let props = nextProps || this.props;
    simple_timer.start('fetch_timer');
    props
      .album
      .getAssets({
        includeMetadata: true,
        trackInsertsAndDeletes: true,
        //  trackChanges: true,
        startIndex: this.state.images.length,
        endIndex: 0,
        fetchOptions: {
          includeHiddenAssets: true
        },
      })
      .then((data) => {

        console.log(RNFetchBlob.fs.dirs);
        const dirs = RNFetchBlob.fs.dirs

        const imageOptions = {
          loadOptions: {
            scale: 1, //defaults to 1
            deliveryMode: 'highQuality', //defaults to highQuality, avaliable: highQuality, fast, opportunistic(should not be used)
            version : 'current', //defaults to current, also avaliable: 'original', 'unadjusted'
            contentMode: 'fill', //default to fill, also avaliable: fit
            width: 20, //defaults to 0, 0 means original width
            height: 20, //default to 0, 0 means original height,
            resizeMode: 'none', //Default to none if width and height is not specified, otherwise defaults fast, avaliable: 'none', 'fast', 'exact'
            cropRect: '1000|700|500|500' //Rect to crop image to. x,y,width,height (!!Will override properies 'width' and 'height')
          },
          postProcessOptions: {
            quality: 10,  //0 means 100 (uncompressed)
            rotation: 90, //0 means 0 DEG
            format: 'JPEG' //Also accepts 'PNG'
          }
        };

        const videoOptions = {
          loadOptions: {
            deliveryMode: 'automatic', //defaults to automatic, avaliable: highQuality, mediumQuality, fast
            version : 'current' //defaults to current, also avaliable: 'original'
          },
          //For docs on values see links provided and se string values. Can be outdate. refer to SDK in xcode for updated values
          postProcessOptions: {
            outputFileType: 'public.mpeg-4', //defaults to 'public.mpeg-4'(AVFileTypeMPEG4), other avaliable:  https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.7.sdk/System/Library/Frameworks/AVFoundation.framework/Versions/A/Headers/AVMediaFormat.h#L50
            codecKey: 'avc1', //defaults to 'avc1' (AVVideoCodecH264), other avaliable: https://github.com/bruce0505/ios7frameworks/blob/master/AVFoundation/AVVideoSettings.h#L35
            bitrateMultiplier: 3,
            minimumBitrate: 300000,
            width : 100,
            height : 50
          }
        };
       /* RNPhotosFramework.saveAssetsToDisk(data.assets.map(asset => ({
          asset: asset,
          options: videoOptions
        })), {
            onProgress: (e) => {
              console.log(e);
            }
          }).then((result) => {
            //debugger;
          });*/
        data.assets[0].saveAssetToDisk({ 
          fileName : 'test.png',
          dir: RNFetchBlob.fs.dirs.DocumentDir,
          ...videoOptions
        }, (e) => {
          console.log(e);
        }).then((result) => {
          console.log('finnished');
          RNFetchBlob.fs.exists(result.fileUrl)
            .then((exist) => {
              console.log(`file ${result.fileUrl} ${exist ? '' : 'not'} exists`)
            });
        });


        console.log(data.assets.map(x => x.collectionIndex));
        simple_timer.stop('fetch_timer');
        console.log('react-native-photos-framework fetch request took %s milliseconds.', simple_timer.get('fetch_timer').delta)
        this._appendImages(data);
      }, (e) => console.log(e));
  }

  _appendImages(data) {
    var assets = data.assets;
    var newState = {
      loadingMore: false
    };

    if (data.includesLastAsset) {
      newState.noMore = true;
    }

    if (assets.length > 0) {
      newState.images = this
        .state
        .images
        .concat(assets);
      newState.dataSource = this
        .state
        .dataSource
        .cloneWithRows(this._nEveryRow(newState.images, this.props.imagesPerRow));
    }

    this.setState(newState);
  }

  render() {
    var { dataSource } = this.state;
    var {
      scrollRenderAheadDistance,
      initialListSize,
      pageSize,
      removeClippedSubviews,
      imageMargin,
      backgroundColor,
      emptyText,
      emptyTextStyle
    } = this.props;

    var listViewOrEmptyText = dataSource.getRowCount() > 0
      ? (<ListView
        style={{
          flex: 1
        }}
        scrollRenderAheadDistance={scrollRenderAheadDistance}
        initialListSize={initialListSize}
        pageSize={pageSize}
        removeClippedSubviews={removeClippedSubviews}
        renderFooter={this
          ._renderFooterSpinner
          .bind(this)}
        onEndReached={this
          ._onEndReached
          .bind(this)}
        onEndReachedThreshold={2000}
        dataSource={dataSource}
        renderRow={rowData => this._renderRow(rowData)} />)
      : (
        <Text
          style={[
            {
              textAlign: 'center'
            },
            emptyTextStyle
          ]}>{emptyText}</Text>
      );

    return (
      <View
        style={[
          styles.wrapper, {
            padding: imageMargin,
            paddingRight: 0,
            backgroundColor: backgroundColor
          }
        ]}>
        {listViewOrEmptyText}
      </View>
    );
  }

  _renderImage(item) {
    var { selected } = this.state;
    var { imageMargin, selectedMarker, imagesPerRow, containerWidth } = this.props;
    var uri = item.uri;
    var isSelected = (this._arrayObttctIndexOf(selected, 'uri', uri) >= 0)
      ? true
      : false;

    return (<ImageItem
      key={uri}
      displayDates={true}
      item={item}
      selected={isSelected}
      imageMargin={imageMargin}
      selectedMarker={selectedMarker}
      imagesPerRow={imagesPerRow}
      containerWidth={containerWidth}
      onClick={this
        ._selectImage
        .bind(this)} />);
  }

  _renderRow(rowData) {
    var items = rowData.map((item) => {
      if (item === null) {
        return null;
      }
      return this._renderImage(item);
    });

    return (
      <View style={styles.row}>
        {items}
      </View>
    );
  }

  _renderFooterSpinner() {
    if (!this.state.noMore) {
      return <ActivityIndicator style={styles.spinner} />;
    }
    return null;
  }

  _onEndReached() {
    if (!this.state.noMore) {
      this.fetch();
    }
  }

  _selectImage(image) {
    var { maximum, imagesPerRow, callback } = this.props;

    var selected = this.state.selected,
      index = this._arrayObttctIndexOf(selected, 'uri', image.uri);

    if (index >= 0) {
      selected.splice(index, 1);
    } else {
      if (selected.length < maximum) {
        selected.push(image);
      }
    }

    this.setState({
      selected: selected,
      dataSource: this
        .state
        .dataSource
        .cloneWithRows(this._nEveryRow(this.state.images, imagesPerRow))
    });

    callback(this.state.selected, image);
  }

  _nEveryRow(data, n) {
    var result = [],
      temp = [];

    for (var i = 0; i < data.length; ++i) {
      if (i > 0 && i % n === 0) {
        result.push(temp);
        temp = [];
      }
      temp.push(data[i]);
    }

    if (temp.length > 0) {
      while (temp.length !== n) {
        temp.push(null);
      }
      result.push(temp);
    }

    return result;
  }

  _arrayObttctIndexOf(array, property, value) {
    return array.map((o) => {
      return o[property];
    }).indexOf(value);
  }

}

const styles = StyleSheet.create({
  wrapper: {
    flex: 1
  },
  row: {
    flexDirection: 'row',
    flex: 1
  },
  marker: {
    position: 'absolute',
    top: 5,
    backgroundColor: 'transparent'
  }
})

CameraRollPicker.propTypes = {
  scrollRenderAheadDistance: React.PropTypes.number,
  initialListSize: React.PropTypes.number,
  pageSize: React.PropTypes.number,
  removeClippedSubviews: React.PropTypes.bool,
  groupTypes: React
    .PropTypes
    .oneOf([
      'Album',
      'All',
      'Event',
      'Faces',
      'Library',
      'PhotoStream',
      'SavedPhotos'
    ]),
  maximum: React.PropTypes.number,
  assetType: React
    .PropTypes
    .oneOf(['Photos', 'Videos', 'All']),
  imagesPerRow: React.PropTypes.number,
  imageMargin: React.PropTypes.number,
  containerWidth: React.PropTypes.number,
  callback: React.PropTypes.func,
  selected: React.PropTypes.array,
  selectedMarker: React.PropTypes.element,
  backgroundColor: React.PropTypes.string,
  emptyText: React.PropTypes.string,
  emptyTextStyle: Text.propTypes.style
}

CameraRollPicker.defaultProps = {
  scrollRenderAheadDistance: 800,
  initialListSize: 1,
  pageSize: 12,
  removeClippedSubviews: true,
  groupTypes: 'SavedPhotos',
  maximum: 15,
  imagesPerRow: 3,
  imageMargin: 5,
  assetType: 'Photos',
  backgroundColor: 'white',
  selected: [],
  callback: function (selectedImages, currentImage) {
    console.log(currentImage);
    console.log(selectedImages);
  },
  emptyText: 'No photos.'
}

export default CameraRollPicker;
