import React, { Component } from 'react';
import {
  Image,
  StyleSheet,
  Dimensions,
  TouchableOpacity,
  Text,
  View
} from 'react-native';
import Video from 'react-native-video';

class ImageItem extends Component {
  constructor(props) {
    super(props);
    this.state = { videoPaused: true };
  }

  componentWillMount() {
    var {width} = Dimensions.get('window');
    var {imageMargin, imagesPerRow, containerWidth} = this.props;

    if (typeof containerWidth != "undefined") {
      width = containerWidth;
    }
    this._imageSize = (width - (imagesPerRow + 1) * imageMargin) / imagesPerRow;
  }

  toogleVideoPlay() {
    this.setState({
      videoPaused : !this.state.videoPaused
    });
  }

  renderVideo() {
    if (this.props.item.mediaType !== 'video' || this.state.videoPaused) {
      return null;
    }
    return (
      <Video source={this.props.item.video}   // Can be a URL or a local file.
        ref={(ref) => {
          this.player = ref
        }}
        resizeMode='cover'
        onPlaybackRateChange={() => { } }                             // Store reference
        rate={1.0}                     // 0 is paused, 1 is normal.
        volume={1.0}                   // 0 is muted, 1 is normal.
        muted={false}                  // Mutes the audio entirely.
        paused={this.state.videoPaused}                 // Pauses playback entirely.
        repeat={true}                  // Repeat forever.
        playInBackground={false}       // Audio continues to play when app entering background.
        playWhenInactive={false}       // [iOS] Video continues to play when control or notification center are shown.
        progressUpdateInterval={250.0} // [iOS] Interval to fire onProgress (default to ~250ms)
        style={styles.thumbVideo} />
    );
  }

  renderVideoSymbol() {
    if (this.props.item.mediaType !== 'video') {
      return null;
    }
    return (
      <TouchableOpacity style={styles.playButtonContainer} onPress={this.toogleVideoPlay.bind(this)}>
        <Text style={[styles.playButton, !this.state.videoPaused ? styles.paused : styles.playing]}>{!this.state.videoPaused ? '▐▐' : '►'}</Text>
      </TouchableOpacity>
    );
  }

  render() {
    var {item, selected, selectedMarker, imageMargin} = this.props;

    var marker = selectedMarker ? selectedMarker :
      <Image
        style={[styles.marker, { width: 25, height: 25 }]}
        source={require('./circle-check.png')}
        />;

    var image = item.image;

    return (
      <TouchableOpacity
        style={{ marginBottom: imageMargin, marginRight: imageMargin }}
        onPress={() => this._handleClick(item)}>
        <Image
          source={{ uri: image.uri }}
          style={{ height: this._imageSize, width: this._imageSize }} >
        </Image>
        {this.props.displayDates ? (<View style={styles.dates}><Text style={styles.creationText}>{`Created: ${item.creationDate.toDateString()}`}</Text>
          <Text style={styles.modificationText}>{`Modified: ${item.modificationDate.toDateString()}`}</Text></View>
        ) : null}
        {this.renderVideo()}
        {this.renderVideoSymbol()}
        {(selected) ? marker : null}
      </TouchableOpacity>
    );
  }

  _handleClick(item) {
    this.props.onClick(item);
  }
}

const styles = StyleSheet.create({
  marker: {
    position: 'absolute',
    top: 5,
    right: 5,
    backgroundColor: 'transparent',
  },
  creationText: {
    position: 'absolute',
    top: 0,
    left: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    color: 'white',
    padding: 3,
    fontSize: 10
  },
  modificationText: {
    position: 'absolute',
    top: 35,
    left: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    color: 'white',
    padding: 3,
    fontSize: 10
  },
  dates: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0
  },
  playButtonContainer: {
    position: 'absolute',
    bottom: 5,
    right: 5,
    backgroundColor: 'rgba(0, 0, 0, 0.9)',
    borderRadius: 15,
    width: 30,
    height: 30,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: 'white'
  },
  playButton: {
    backgroundColor: 'transparent',
    color: 'white',
    fontSize: 18,
    fontFamily: 'Arial',
    left: 2
  },
  paused : {
    fontSize: 12,
    left: -2
  },
  playing : {

  },
  thumbVideo: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor : 'transparent'
  }
})

ImageItem.defaultProps = {
  item: {},
  selected: false,
}

ImageItem.propTypes = {
  item: React.PropTypes.obttct,
  selected: React.PropTypes.bool,
  selectedMarker: React.PropTypes.element,
  imageMargin: React.PropTypes.number,
  imagesPerRow: React.PropTypes.number,
  onClick: React.PropTypes.func,
}

export default ImageItem;
