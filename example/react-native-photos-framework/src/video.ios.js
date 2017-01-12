import React, { Component } from 'react';
import RNVideo from 'react-native-video';

export default class Video extends Component {

    constructor() {
        super();
        this.state = {};
    }

    componentWillMount() {
        if (!this.props.source.loadVideoUrl) {
            this.setState({
                source: this.props.source
            });
        } else {
            this.props.source.loadVideoUrl().then((source) => {
                this.setState({
                    source: source
                });
            });
        }
    }

    render() {
        if (!this.state.source) {
            return null;
        }
        return (
            <RNVideo {...this.props} source={this.state.source}></RNVideo>
        );
    }
}