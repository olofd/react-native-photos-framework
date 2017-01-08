import resolveAssetSource from 'react-native/Libraries/Image/resolveAssetSource';

export default function videoPropsResolver(props) {
    const source = resolveAssetSource(props) || {};
    let {uri, type} = source;
    if (uri && uri.match(/^\//)) {
        uri = `file://${uri}`;
    }

    const isNetwork = !!(uri && uri.match(/^https?:/));
    const isAsset = !!(uri && uri.match(/^(assets-library|file):/));
    return {
        isAsset,
        isNetwork,
        uri,
        type
    };
}